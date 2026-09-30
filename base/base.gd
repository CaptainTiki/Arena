class_name Base
extends Node3D
## The room between fights. Walk up to a kiosk, press the key, and a menu comes up:
## move through it with the movement keys or the mouse, choose with the key or a click.
## A contract is booked at the terminal; the door starts the fight once one is booked.
## Everything bought or worn here goes through the locker.

signal arena_entered(contract: ContractData)

@export var catalog: Catalog
## Where favour, cash and everything owned are kept.
@export var profile_path: String = "user://profile.cfg"

@export_group("Menu Colours")
@export var heading_color: Color = Color(1.0, 1.0, 1.0, 0.6)
@export var owned_color: Color = Color(0.6, 1.0, 0.6)
@export var request_color: Color = Color(1.0, 0.85, 0.2)
@export var unread_color: Color = Color(1.0, 0.85, 0.2)
## The newest this many are listed at the terminal.
@export var max_mail_shown: int = 13

@export_group("Door")
@export var door_shut_color: Color = Color(0.8, 0.15, 0.15)
@export var door_open_color: Color = Color(0.3, 1.0, 0.4)

var _locker: Locker
var _kiosks: Array[Kiosk] = []
## The kiosk whose menu is up, or null.
var _open: Kiosk
## The contract whose card is up on the terminal, or null.
var _card: ContractData
## True while the terminal is showing the mail.
var _reading_mail: bool = false
## The contract taken at the terminal, or null. The door leads to it.
var _booked: ContractData
## The last thing that happened at this kiosk, shown at the foot of the menu.
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
	_refresh_door()
	_panel.entry_clicked.connect(_choose)
	_prompt.text = ""
	_log.open_session()
	var entry: Dictionary = _describe_wallet()
	entry["unread_mail"] = _get_unread_ids()
	_log.log_world("base_enter", entry)


func get_locker() -> Locker:
	return _locker


func _process(_delta: float) -> void:
	if _open != null:
		_tick_menu()
		return
	# Read every frame so a press made away from a kiosk is not acted on at one.
	var interact: bool = _intent.consume_interact()
	_intent.consume_cancel()
	var near: Kiosk = _get_near_kiosk()
	_prompt.text = "" if near == null else _get_prompt(near)
	if near == null or not interact:
		return
	if near.kind != Kiosk.Kind.DOOR:
		_open_kiosk(near)
	elif _booked != null:
		_enter_arena()


func _get_prompt(kiosk: Kiosk) -> String:
	match kiosk.kind:
		Kiosk.Kind.DOOR:
			if _booked == null:
				return "Locked. Book a contract at the agent's terminal first."
			return "[E] Enter the arena:  %s" % _booked.display_name
		Kiosk.Kind.TERMINAL:
			var unread: int = _locker.count_unread()
			if unread > 0:
				return "[E] %s      %d new mail" % [kiosk.title, unread]
	return "[E] %s" % kiosk.title


func _tick_menu() -> void:
	var move: Vector2i = _intent.consume_menu_move()
	var accept: bool = _intent.consume_accept()
	if _intent.consume_cancel():
		_step_back()
		return
	# More than one step can arrive in a frame.
	for step: int in absi(move.y):
		_panel.move(signi(move.y))
	var picked: MenuEntry = _panel.get_picked()
	if picked == null:
		return
	if move.x != 0 and picked.nudge.is_valid():
		picked.nudge.call(signi(move.x))
		_build()
	elif accept:
		_choose(picked)


## Out of a contract card or the mail to the terminal's first page, or out of the menu altogether.
func _step_back() -> void:
	if _card != null:
		_show_card(null)
		_build()
	elif _reading_mail:
		_show_mail(false)
		_build()
	else:
		_close()


func _choose(entry: MenuEntry) -> void:
	if not entry.action.is_valid():
		return
	entry.action.call()
	if _open != null:
		_build()


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
	_reading_mail = false
	_message = ""
	_prompt.text = ""
	# The player stands still while the menu is up; the intent keeps listening.
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	_intent.process_mode = Node.PROCESS_MODE_ALWAYS
	_intent.menu_mode = true
	_build()


func _close() -> void:
	if _reading_mail:
		_show_mail(false)
	_open = null
	_card = null
	_panel.close()
	_intent.menu_mode = false
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_intent.process_mode = Node.PROCESS_MODE_INHERIT


func _build() -> void:
	var entries: Array[MenuEntry] = []
	var title: String = _open.title
	match _open.kind:
		Kiosk.Kind.LOADOUT:
			_list_loadout(entries)
		Kiosk.Kind.SHOP:
			_list_shop(entries)
		Kiosk.Kind.TERMINAL:
			if _card != null:
				title = _card.display_name
				_list_card(entries)
			elif _reading_mail:
				title = "MAIL"
				_list_mail(entries)
			else:
				_list_terminal(entries)
	entries.append(MenuEntry.heading(""))
	entries.append(MenuEntry.option("Step away", "", "Back to the room.", _close))
	_panel.show_menu(title, _locker.get_wallet_text(), entries, _message)


## Something for sale. It can always be picked out and read; choosing it when it can't be bought says why.
func _make_sale(item: ItemData) -> MenuEntry:
	var refusal: String = _locker.get_refusal(item)
	var about: String = "%s\n\nCosts %s." % [item.description, item.get_price_text()]
	if item.stack_limit > 1:
		about += "\nYou have %d of %d." % [_locker.count_owned(item), item.stack_limit]
	if not refusal.is_empty():
		about += "\n\nNot now: %s." % refusal
	return MenuEntry.option(
			"Buy  %s" % item.display_name, item.get_price_text(), about, _buy.bind(item), refusal.is_empty())


func _make_owned(item: ItemData, state: String) -> MenuEntry:
	var entry: MenuEntry = MenuEntry.option(item.display_name, state, item.description, Callable())
	entry.color = owned_color
	return entry


func _list_loadout(entries: Array[MenuEntry]) -> void:
	entries.append(MenuEntry.heading("CARRIED INTO THE FIGHT", heading_color))
	for slot: int in Locker.WEAPON_SLOTS:
		var held: ItemData = _locker.get_weapon_in(slot)
		var about: String = "Nothing in this slot." if held == null else held.description
		about += "\n\nChoose, or press A or D, to change what this slot carries."
		if _get_owned_weapons().size() < 2:
			about += "\n\nYou own one weapon. Sponsors who like what they see send offers by mail."
		var entry: MenuEntry = MenuEntry.option(
				"Slot %d" % (slot + 1), "<  %s  >" % ("empty" if held == null else held.display_name),
				about, _cycle_weapon.bind(slot, 1))
		entry.nudge = _nudge_weapon.bind(slot)
		entries.append(entry)
	var worn: ItemData = _locker.get_vest()
	var vest_about: String = "No vest." if worn == null else worn.description
	vest_about += "\n\nChoose, or press A or D, to change what you wear. The shop sells vests."
	var vest: MenuEntry = MenuEntry.option(
			"Vest", "<  %s  >" % ("none" if worn == null else worn.display_name), vest_about, _cycle_vest.bind(1))
	vest.nudge = _cycle_vest
	entries.append(vest)
	var pocket: ItemData = _locker.get_pocket()
	entries.append(MenuEntry.option(
			"Pocket", "empty" if pocket == null else "%s  x%d" % [pocket.display_name, _locker.count_owned(pocket)],
			"One goes into each fight. The shop sells them." if pocket == null else pocket.description,
			Callable()))
	for item: ItemData in catalog.get_items_in(ItemData.Category.MOD):
		if _locker.owns(item):
			entries.append(_make_owned(item, "fitted"))


func _list_shop(entries: Array[MenuEntry]) -> void:
	var offered: Array[MenuEntry] = []
	for item: ItemData in catalog.get_items_in(ItemData.Category.WEAPON):
		if item.starter or not _locker.is_on_sale(item):
			continue
		offered.append(_make_owned(item, "owned") if _locker.owns(item) else _make_sale(item))
	entries.append(MenuEntry.heading(
			"WEAPONS", heading_color, "" if not offered.is_empty() else "none on offer yet"))
	entries.append_array(offered)
	entries.append(MenuEntry.heading(""))
	entries.append(MenuEntry.heading("GEAR", heading_color))
	for category: ItemData.Category in [
			ItemData.Category.VEST, ItemData.Category.CONSUMABLE, ItemData.Category.MOD]:
		for item: ItemData in catalog.get_items_in(category):
			if item.stack_limit == 1 and _locker.owns(item):
				entries.append(_make_owned(item, "owned"))
			else:
				entries.append(_make_sale(item))


func _list_terminal(entries: Array[MenuEntry]) -> void:
	var unread: int = _locker.count_unread()
	var mail: MenuEntry = MenuEntry.option(
			"Read your mail", "%d new" % unread if unread > 0 else "nothing new",
			"Messages from your agent and from the sponsors.", _show_mail.bind(true))
	if unread > 0:
		mail.color = unread_color
	entries.append(mail)
	entries.append(MenuEntry.heading(""))
	entries.append(MenuEntry.heading("CONTRACTS ON OFFER", heading_color))
	for contract: ContractData in catalog.contracts:
		var asked_by: SponsorData = _locker.get_request_for(contract)
		var open: bool = _locker.is_unlocked(contract)
		var about: String = contract.get_card(asked_by)
		if not open:
			about += "\n\nLocked. Win a tier %d contract first." % contract.unlocked_by
		var entry: MenuEntry = MenuEntry.option(
				"Tier %d   %s" % [contract.tier, contract.display_name],
				"$%d   x%s" % [contract.cash_reward, String.num(contract.favour_multiplier, 1)],
				about, _show_card.bind(contract), open)
		if asked_by != null:
			entry.color = request_color
			entry.note = "%s asks   %s" % [asked_by.display_name.trim_prefix("THE "), entry.note]
		if contract == _booked:
			entry.color = owned_color
			entry.note = "BOOKED   %s" % entry.note
		entries.append(entry)


func _list_card(entries: Array[MenuEntry]) -> void:
	var about: String = _card.get_card(_locker.get_request_for(_card))
	about += "\n\nTaking it opens the door to the arena. You can still shop and change what you carry."
	entries.append(MenuEntry.option("Take the contract", "", about, _book.bind(_card)))
	entries.append(MenuEntry.option("Back to the board", "", about, _show_card.bind(null)))


func _list_mail(entries: Array[MenuEntry]) -> void:
	var arrived: Array[MailData] = _locker.get_mail()
	# The panel has a fixed number of rows; the oldest mail falls off the end.
	for message: MailData in arrived.slice(0, max_mail_shown):
		var about: String = "From: %s\n\n%s" % [message.get_sender_name(), message.body]
		if message.unlocks != null:
			about += "\n\nNow in the shop: %s." % message.unlocks.display_name
		if message.gift_cash > 0:
			about += "\n\n$%d was added to your wallet." % message.gift_cash
		var entry: MenuEntry = MenuEntry.option(
				message.subject, message.get_sender_name().trim_prefix("THE "), about, Callable())
		if _locker.is_unread(message):
			entry.color = unread_color
			entry.note = "NEW   %s" % entry.note
		elif message.sender != null:
			entry.color = message.sender.color
		entries.append(entry)
	entries.append(MenuEntry.option("Back to the terminal", "", "", _show_mail.bind(false)))


func _get_owned_weapons() -> Array[ItemData]:
	var owned: Array[ItemData] = []
	for item: ItemData in catalog.get_items_in(ItemData.Category.WEAPON):
		if _locker.owns(item):
			owned.append(item)
	return owned


## A nudge hands over its step first and what was bound after it.
func _nudge_weapon(step: int, slot: int) -> void:
	_cycle_weapon(slot, step)


## Puts the next owned weapon, or the one before, in `slot`. One already in the other slot swaps over.
func _cycle_weapon(slot: int, step: int) -> void:
	var owned: Array[ItemData] = _get_owned_weapons()
	if owned.size() < 2:
		_message = "Nothing else to carry yet."
		return
	var index: int = owned.find(_locker.get_weapon_in(slot))
	var next: ItemData = owned[posmod(index + step, owned.size())]
	_locker.set_weapon_in(slot, next)
	_message = "Slot %d carries the %s." % [slot + 1, next.display_name]


func _cycle_vest(step: int) -> void:
	var choices: Array[ItemData] = [null]
	for item: ItemData in catalog.get_items_in(ItemData.Category.VEST):
		if _locker.owns(item):
			choices.append(item)
	if choices.size() < 2:
		_message = "No vest to wear yet."
		return
	var next: ItemData = choices[posmod(choices.find(_locker.get_vest()) + step, choices.size())]
	_locker.set_vest(next)
	_message = "No vest." if next == null else "Wearing the %s." % next.display_name


func _buy(item: ItemData) -> void:
	if not _locker.buy(item):
		_message = "Can't buy the %s: %s." % [item.display_name, _locker.get_refusal(item)]
		return
	_message = "Bought the %s." % item.display_name
	var entry: Dictionary = _describe_wallet()
	entry["item"] = item.display_name
	entry["cash"] = item.price_cash
	_log.log_world("purchase", entry)


func _show_card(contract: ContractData) -> void:
	if contract != null and not _locker.is_unlocked(contract):
		_message = "Locked. Win a tier %d contract first." % contract.unlocked_by
		return
	_card = contract
	_message = ""
	_panel.reset_pick()


## Opens or leaves the mail. Leaving marks everything there as read.
func _show_mail(reading: bool) -> void:
	if _reading_mail and not reading:
		_log.log_world("mail_read", {"mail": _get_unread_ids()})
		_locker.mark_mail_read()
	_reading_mail = reading
	_message = ""
	_panel.reset_pick()


func _book(contract: ContractData) -> void:
	var asked_by: SponsorData = _locker.get_request_for(contract)
	_booked = contract
	_card = null
	_message = "Booked: %s. The door to the arena is open." % contract.display_name
	_panel.reset_pick()
	_refresh_door()
	_log.log_world("contract_booked", {
		"contract": contract.display_name,
		"tier": contract.tier,
		"asked_by": "" if asked_by == null else asked_by.display_name,
	})


func _enter_arena() -> void:
	var loadout: Loadout = _locker.build_loadout()
	var weapons: PackedStringArray = []
	for weapon: WeaponData in loadout.weapons:
		weapons.append(weapon.display_name)
	_log.log_world("arena_enter", {
		"contract": _booked.display_name,
		"weapons": weapons,
		"vest": "" if loadout.vest == null else loadout.vest.display_name,
		"pocket": "" if loadout.consumable == null else loadout.consumable.display_name,
	})
	arena_entered.emit(_booked)


func _refresh_door() -> void:
	for kiosk: Kiosk in _kiosks:
		if kiosk.kind == Kiosk.Kind.DOOR:
			kiosk.set_color(door_shut_color if _booked == null else door_open_color)


func _get_unread_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	for message: MailData in _locker.get_mail():
		if _locker.is_unread(message):
			ids.append(String(message.id))
	return ids


func _describe_wallet() -> Dictionary:
	var favour: Dictionary = {}
	for sponsor: SponsorData in catalog.sponsors:
		favour[sponsor.display_name] = _locker.get_favour(sponsor)
	return {"wallet": _locker.get_cash(), "favour_held": favour}
