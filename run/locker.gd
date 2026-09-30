class_name Locker
extends RefCounted
## The player's account, read through the catalog: what they own, what they can afford,
## what they carry, and which contracts are open to them. Every change is saved at once.

const WEAPON_SLOTS: int = 2

var catalog: Catalog
var profile: ProfileStore


func _init(game_catalog: Catalog, profile_path: String) -> void:
	catalog = game_catalog
	profile = ProfileStore.new(profile_path)
	_give_starters()


func get_cash() -> int:
	return profile.get_cash()


func get_favour(sponsor: SponsorData) -> int:
	return profile.get_favour(sponsor)


## Cash, then where the player stands with each sponsor: "$300   MARKSMAN 12   BUTCHER 40 ..."
func get_wallet_text() -> String:
	var parts: PackedStringArray = ["$%d" % get_cash()]
	for sponsor: SponsorData in catalog.sponsors:
		parts.append("%s %d" % [sponsor.display_name.trim_prefix("THE "), get_favour(sponsor)])
	return "   ".join(parts)


func count_owned(item: ItemData) -> int:
	return profile.get_owned(item.id)


func owns(item: ItemData) -> bool:
	return count_owned(item) > 0


## False while `item` is waiting on a sponsor's offer to put it in the shop.
func is_on_sale(item: ItemData) -> bool:
	return catalog.find_offer(item) == null or profile.is_offered(item.id)


## Why `item` can't be bought, worded for the player. Empty when it can.
func get_refusal(item: ItemData) -> String:
	if not is_on_sale(item):
		return "not on offer"
	if count_owned(item) >= item.stack_limit:
		return "already owned" if item.stack_limit == 1 else "carrying all you can"
	if get_cash() < item.price_cash:
		return "need $%d more" % (item.price_cash - get_cash())
	return ""


func buy(item: ItemData) -> bool:
	if not get_refusal(item).is_empty():
		return false
	profile.set_cash(get_cash() - item.price_cash)
	profile.set_owned(item.id, count_owned(item) + 1)
	# A first second weapon goes straight into the empty slot.
	if item.category == ItemData.Category.WEAPON and get_weapon_slot(item) < 0:
		for slot: int in WEAPON_SLOTS:
			if profile.get_weapon_slot(slot).is_empty():
				profile.set_weapon_slot(slot, item.id)
				break
	profile.save()
	return true


## Takes `cash` from the wallet. False, and nothing taken, when there isn't enough.
func pay(cash: int) -> bool:
	if get_cash() < cash:
		return false
	profile.set_cash(get_cash() - cash)
	profile.save()
	return true


## Everything that has arrived, newest first.
func get_mail() -> Array[MailData]:
	var arrived: Array[MailData] = []
	for id: String in profile.get_mail_delivered():
		var message: MailData = catalog.find_mail(StringName(id))
		if message != null:
			arrived.push_front(message)
	return arrived


func is_unread(message: MailData) -> bool:
	return not profile.get_mail_read().has(String(message.id))


func count_unread() -> int:
	var count: int = 0
	for message: MailData in get_mail():
		if is_unread(message):
			count += 1
	return count


func mark_mail_read() -> void:
	profile.set_mail_read(profile.get_mail_delivered())
	profile.save()


## The slot `item` sits in, or -1.
func get_weapon_slot(item: ItemData) -> int:
	for slot: int in WEAPON_SLOTS:
		if profile.get_weapon_slot(slot) == item.id:
			return slot
	return -1


func get_weapon_in(slot: int) -> ItemData:
	return catalog.find_item(profile.get_weapon_slot(slot))


## Puts an owned weapon in `slot`. If it was in the other slot, the two swap.
func set_weapon_in(slot: int, item: ItemData) -> void:
	if not owns(item) or item.category != ItemData.Category.WEAPON:
		return
	var was_in: int = get_weapon_slot(item)
	if was_in >= 0:
		profile.set_weapon_slot(was_in, profile.get_weapon_slot(slot))
	profile.set_weapon_slot(slot, item.id)
	profile.save()


func get_vest() -> ItemData:
	return catalog.find_item(profile.get_vest())


## Null takes the vest off.
func set_vest(item: ItemData) -> void:
	profile.set_vest(&"" if item == null else item.id)
	profile.save()


## The first consumable owned goes in the pocket.
func get_pocket() -> ItemData:
	for item: ItemData in catalog.get_items_in(ItemData.Category.CONSUMABLE):
		if owns(item):
			return item
	return null


## Called when the thing in the pocket has been used.
func spend(item: ItemData) -> void:
	profile.set_owned(item.id, maxi(count_owned(item) - 1, 0))
	profile.save()


func build_loadout() -> Loadout:
	var loadout: Loadout = Loadout.new()
	for slot: int in WEAPON_SLOTS:
		var item: ItemData = get_weapon_in(slot)
		if item != null and owns(item) and item.weapon != null:
			loadout.weapons.append(item.weapon)
	loadout.vest = get_vest()
	loadout.consumable = get_pocket()
	for item: ItemData in catalog.get_items_in(ItemData.Category.MOD):
		if owns(item):
			loadout.mods.append(item)
	return loadout


func is_unlocked(contract: ContractData) -> bool:
	return profile.get_tier_won() >= contract.unlocked_by


func get_unlocked_contracts() -> Array[ContractData]:
	var open: Array[ContractData] = []
	for contract: ContractData in catalog.contracts:
		if is_unlocked(contract):
			open.append(contract)
	return open


## The sponsor asking for `contract`, or null.
func get_request_for(contract: ContractData) -> SponsorData:
	if profile.get_request_contract() != contract.display_name:
		return null
	return catalog.find_sponsor(profile.get_request_sponsor())


## One open contract at a time is asked for by one sponsor. Picks a new pair, never the same contract twice running.
func rotate_request() -> void:
	var open: Array[ContractData] = get_unlocked_contracts()
	if open.is_empty() or catalog.sponsors.is_empty():
		return
	var choices: Array[ContractData] = []
	for contract: ContractData in open:
		if contract.display_name != profile.get_request_contract():
			choices.append(contract)
	if choices.is_empty():
		choices = open
	var contract: ContractData = choices.pick_random()
	var sponsor: SponsorData = catalog.sponsors.pick_random()
	profile.set_request(contract.display_name, sponsor.display_name)
	profile.save()


## Settles a finished fight. `scores` and `drops` are what each of `sponsors` made of it, in the same order.
## A loss pays nothing, and costs favour with a sponsor who had asked for the fight. Returns one result per sponsor for the summary.
func settle(
		contract: ContractData, won: bool, sponsors: Array[SponsorData], scores: Array[float],
		drops: Array[int], request_multiplier: float) -> Array[SponsorResult]:
	var results: Array[SponsorResult] = []
	var asked_by: SponsorData = get_request_for(contract)
	for index: int in sponsors.size():
		var sponsor: SponsorData = sponsors[index]
		var result: SponsorResult = SponsorResult.new()
		result.sponsor = sponsor
		result.score = scores[index] if index < scores.size() else 0.0
		result.drops = drops[index] if index < drops.size() else 0
		result.requested = sponsor == asked_by
		result.favour_before = get_favour(sponsor)
		var earned: float = result.score * sponsor.favour_per_score * contract.favour_multiplier
		if result.requested:
			earned *= request_multiplier
		result.favour_after = result.favour_before
		if won:
			result.favour_after += roundi(earned)
		elif result.requested:
			result.favour_after -= catalog.request_loss_favour
		profile.set_favour(sponsor, result.favour_after)
		results.append(result)
	if won:
		profile.set_cash(get_cash() + contract.cash_reward)
		profile.set_tier_won(maxi(profile.get_tier_won(), contract.tier))
	profile.set_fights(profile.get_fights() + 1)
	_deliver_mail(results, asked_by, won)
	profile.save()
	rotate_request()
	return results


func _give_starters() -> void:
	var changed: bool = false
	if not profile.is_started():
		profile.set_started()
		profile.set_cash(get_cash() + catalog.starting_cash)
		changed = true
	for item: ItemData in catalog.items:
		if not item.starter:
			continue
		if not owns(item):
			profile.set_owned(item.id, 1)
			changed = true
		if item.category == ItemData.Category.WEAPON and get_weapon_slot(item) < 0 \
				and profile.get_weapon_slot(0).is_empty():
			profile.set_weapon_slot(0, item.id)
			changed = true
	if _deliver_mail([], null, false):
		changed = true
	if profile.get_request_contract().is_empty():
		rotate_request()
	elif changed:
		profile.save()


## Delivers every mail whose trigger has come true and has not arrived before. `results`, `asked_by`
## and `won` describe the fight just settled; between fights they are empty. True when anything arrived.
func _deliver_mail(results: Array[SponsorResult], asked_by: SponsorData, won: bool) -> bool:
	var delivered: PackedStringArray = profile.get_mail_delivered()
	var arrived: bool = false
	for message: MailData in catalog.mail:
		if delivered.has(String(message.id)) or not _is_due(message, results, asked_by, won):
			continue
		delivered.append(String(message.id))
		if message.unlocks != null:
			profile.set_offered(message.unlocks.id)
		profile.set_cash(get_cash() + message.gift_cash)
		arrived = true
	profile.set_mail_delivered(delivered)
	return arrived


func _is_due(message: MailData, results: Array[SponsorResult], asked_by: SponsorData, won: bool) -> bool:
	match message.trigger:
		MailData.Trigger.ALWAYS:
			return true
		MailData.Trigger.FAVOUR_REACHED:
			return message.sender != null and get_favour(message.sender) >= message.amount
		MailData.Trigger.FAVOUR_LOST:
			for result: SponsorResult in results:
				if result.sponsor == message.sender \
						and result.favour_before - result.favour_after >= message.amount:
					return true
			return false
		MailData.Trigger.REQUEST_WON:
			return won and asked_by != null and asked_by == message.sender
		MailData.Trigger.RIVAL_REQUEST_WON:
			return won and asked_by != null and asked_by != message.sender
	return false
