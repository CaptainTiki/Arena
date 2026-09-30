class_name Base
extends Node3D
## The room between fights. Walk up to a kiosk, press the key, read the panel, pick by number.
## Everything bought, worn or booked here goes through the locker.

signal contract_booked(contract: ContractData)

@export var catalog: Catalog
## Where favour, cash and everything owned are kept.
@export var profile_path: String = "user://profile.cfg"

var _locker: Locker
var _kiosks: Array[Kiosk] = []
## The kiosk whose panel is up, or null.
var _open: Kiosk
## What each number on the panel does, in the order they are listed.
var _options: Array[Callable] = []
## The contract whose card is up on the terminal, or null.
var _card: ContractData
## The last thing that happened at this kiosk, shown at the foot of the panel.
var _message: String = ""

@onready var _player: Player = $Player
@onready var _player_spawn: Marker3D = $PlayerSpawn
@onready var _intent: PlayerIntent = _player.get_intent()
@onready var _kiosks_root: Node3D = $Kiosks
@onready var _panel: KioskPanel = $KioskPanel
@onready var _prompt: Label = $Prompt/Label
@onready var _log: RunLog = $RunLog


func _ready() -> void:
	_locker = Locker.new(catalog, profile_path)
	_player.global_position = _player_spawn.global_position
	_player.rotation.y = _player_spawn.global_rotation.y
	_intent.release_mouse_on_cancel = false
	for child: Node in _kiosks_root.get_children():
		if child is Kiosk:
			_kiosks.append(child as Kiosk)
	_prompt.text = ""
	_log.open_session()
	_log.log_world("base_enter", _describe_wallet())


func get_locker() -> Locker:
	return _locker


func _process(_delta: float) -> void:
	# Read every frame so nothing pressed in one place is acted on in another.
	var interact: bool = _intent.consume_interact()
	var cancel: bool = _intent.consume_cancel()
	var digit: int = _intent.consume_digit()
	if _open != null:
		if interact or cancel:
			_close()
		elif digit >= 0 and digit < _options.size():
			_options[digit].call()
			if _open != null:
				_build()
		return

	var near: Kiosk = _get_near_kiosk()
	_prompt.text = "" if near == null else "[E] %s" % near.title
	if near != null and interact:
		_open_kiosk(near)


func _get_near_kiosk() -> Kiosk:
	var nearest: Kiosk = null
	for kiosk: Kiosk in _kiosks:
		if not kiosk.is_player_near():
			continue
		if nearest == null or _get_distance(kiosk) < _get_distance(nearest):
			nearest = kiosk
	return nearest


func _get_distance(kiosk: Kiosk) -> float:
	return kiosk.global_position.distance_to(_player.global_position)


func _open_kiosk(kiosk: Kiosk) -> void:
	_open = kiosk
	_card = null
	_message = ""
	_prompt.text = ""
	# The player stands still while reading; the intent keeps listening.
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	_intent.process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func _close() -> void:
	_open = null
	_card = null
	_options.clear()
	_panel.close()
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_intent.process_mode = Node.PROCESS_MODE_INHERIT


func _build() -> void:
	_options.clear()
	var lines: PackedStringArray = [_open.title, "You have  %s" % _locker.get_wallet_text(), ""]
	match _open.kind:
		Kiosk.Kind.WEAPON_RACK:
			_list_weapon_rack(lines)
		Kiosk.Kind.WARDROBE:
			_list_wardrobe(lines)
		Kiosk.Kind.TERMINAL:
			_list_terminal(lines)
		Kiosk.Kind.SPONSOR_BOARD:
			_list_sponsor_board(lines)
	lines.append("")
	if not _message.is_empty():
		lines.append(_message)
	lines.append("Press a number to choose.   [E] or [Esc] to step away.")
	_panel.show_text("\n".join(lines))


## Adds a numbered line. Past nine there are no more keys, so the rest are listed without a number.
func _add_option(lines: PackedStringArray, text: String, action: Callable) -> void:
	if _options.size() >= 9:
		lines.append("      %s" % text)
		return
	_options.append(action)
	lines.append("[%d]  %s" % [_options.size(), text])


## Lists something for sale: a numbered line if it can be bought now, a plain one saying why not otherwise.
func _list_for_sale(lines: PackedStringArray, item: ItemData) -> void:
	var refusal: String = _locker.get_refusal(item)
	var label: String = "%s   %s   %s" % [item.display_name, item.get_price_text(), item.description]
	if item.stack_limit > 1:
		label += "   (have %d of %d)" % [_locker.count_owned(item), item.stack_limit]
	if refusal.is_empty():
		_add_option(lines, "Buy %s" % label, _buy.bind(item))
	else:
		lines.append("      %s   (%s)" % [label, refusal])


func _list_weapon_rack(lines: PackedStringArray) -> void:
	for slot: int in Locker.WEAPON_SLOTS:
		var held: ItemData = _locker.get_weapon_in(slot)
		lines.append("SLOT %d:  %s" % [slot + 1, "empty" if held == null else held.display_name])
	lines.append("")
	for slot: int in Locker.WEAPON_SLOTS:
		for item: ItemData in catalog.get_items_in(ItemData.Category.WEAPON):
			if _locker.owns(item) and _locker.get_weapon_slot(item) != slot:
				_add_option(lines, "Slot %d: carry the %s" % [slot + 1, item.display_name],
						_carry.bind(slot, item))
	lines.append("")
	lines.append("Weapons are bought from the sponsors, at the sponsor board.")
	lines.append("")
	lines.append("MODS")
	for item: ItemData in catalog.get_items_in(ItemData.Category.MOD):
		if _locker.owns(item):
			lines.append("      %s   fitted" % item.display_name)
		else:
			_list_for_sale(lines, item)


func _list_wardrobe(lines: PackedStringArray) -> void:
	var worn: ItemData = _locker.get_vest()
	lines.append("WEARING:  %s" % ("no vest" if worn == null else worn.display_name))
	var pocket: ItemData = _locker.get_pocket()
	lines.append("POCKET:  %s" % ("empty" if pocket == null else pocket.display_name))
	lines.append("")
	for item: ItemData in catalog.get_items_in(ItemData.Category.VEST):
		if not _locker.owns(item):
			_list_for_sale(lines, item)
		elif item == worn:
			_add_option(lines, "Take off the %s" % item.display_name, _wear.bind(null))
		else:
			_add_option(lines, "Wear the %s   %s" % [item.display_name, item.description], _wear.bind(item))
	lines.append("")
	for item: ItemData in catalog.get_items_in(ItemData.Category.CONSUMABLE):
		_list_for_sale(lines, item)


func _list_terminal(lines: PackedStringArray) -> void:
	if _card != null:
		lines.append(_card.get_card(_locker.get_request_for(_card)))
		lines.append("")
		_add_option(lines, "Take the contract", _book.bind(_card))
		_add_option(lines, "Back to the board", _show_card.bind(null))
		return
	for contract: ContractData in catalog.contracts:
		var label: String = "%s   tier %d   %s   pays $%d   favour x%s" % [
				contract.display_name, contract.tier, contract.get_type_name(), contract.cash_reward,
				String.num(contract.favour_multiplier, 1)]
		var asked_by: SponsorData = _locker.get_request_for(contract)
		if asked_by != null:
			label += "   ** %s ASKS FOR THIS: DOUBLE FAVOUR **" % asked_by.display_name
		if _locker.is_unlocked(contract):
			_add_option(lines, label, _show_card.bind(contract))
		else:
			lines.append("      %s   (locked: win a tier %d contract)" % [label, contract.unlocked_by])
		lines.append("            %s" % contract.get_enemy_summary())


func _list_sponsor_board(lines: PackedStringArray) -> void:
	for sponsor: SponsorData in catalog.sponsors:
		lines.append("%s   favour %d   wants: %s" % [
				sponsor.display_name, _locker.get_favour(sponsor), sponsor.wants])
		var selling: Array[ItemData] = catalog.get_items_sold_by(sponsor)
		if selling.is_empty():
			lines.append("      nothing for sale yet")
		for item: ItemData in selling:
			if _locker.owns(item):
				lines.append("      %s   owned" % item.display_name)
			else:
				_list_for_sale(lines, item)
		lines.append("")
	lines.append("Favour is paid when a contract is won, and only then.")


func _buy(item: ItemData) -> void:
	if not _locker.buy(item):
		_message = "Could not buy the %s: %s." % [item.display_name, _locker.get_refusal(item)]
		return
	_message = "Bought the %s." % item.display_name
	var entry: Dictionary = _describe_wallet()
	entry["item"] = item.display_name
	entry["cash"] = item.price_cash
	entry["favour"] = item.price_favour
	_log.log_world("purchase", entry)


func _carry(slot: int, item: ItemData) -> void:
	_locker.set_weapon_in(slot, item)
	_message = "The %s goes in slot %d." % [item.display_name, slot + 1]


func _wear(item: ItemData) -> void:
	_locker.set_vest(item)
	_message = "No vest." if item == null else "Wearing the %s." % item.display_name


func _show_card(contract: ContractData) -> void:
	_card = contract
	_message = ""


func _book(contract: ContractData) -> void:
	var asked_by: SponsorData = _locker.get_request_for(contract)
	var loadout: Loadout = _locker.build_loadout()
	var weapons: PackedStringArray = []
	for weapon: WeaponData in loadout.weapons:
		weapons.append(weapon.display_name)
	_log.log_world("contract_booked", {
		"contract": contract.display_name,
		"tier": contract.tier,
		"asked_by": "" if asked_by == null else asked_by.display_name,
		"weapons": weapons,
		"vest": "" if loadout.vest == null else loadout.vest.display_name,
		"pocket": "" if loadout.consumable == null else loadout.consumable.display_name,
	})
	_close()
	contract_booked.emit(contract)


func _describe_wallet() -> Dictionary:
	var favour: Dictionary = {}
	for sponsor: SponsorData in catalog.sponsors:
		favour[sponsor.display_name] = _locker.get_favour(sponsor)
	return {"wallet": _locker.get_cash(), "favour_held": favour}
