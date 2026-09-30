class_name ProfileStore
extends RefCounted
## Everything kept between fights: favour, cash, what is owned, what is worn, and how far up the ladder.

const VERSION: int = 2
const META: String = "meta"
const FAVOUR: String = "favour"
const WALLET: String = "wallet"
const OWNED: String = "owned"
const LOADOUT: String = "loadout"
const LADDER: String = "ladder"
const REQUEST: String = "request"

var _path: String
var _config: ConfigFile = ConfigFile.new()


func _init(path: String) -> void:
	_path = path
	# A missing file just means a first run. A save from before the economy starts again from nothing.
	if FileAccess.file_exists(_path):
		_config.load(_path)
		if int(_config.get_value(META, "version", 1)) != VERSION:
			_config = ConfigFile.new()
	_config.set_value(META, "version", VERSION)


## False until the profile has been given what every new one starts with.
func is_started() -> bool:
	return bool(_config.get_value(META, "started", false))


func set_started() -> void:
	_config.set_value(META, "started", true)


func get_favour(sponsor: SponsorData) -> int:
	return int(_config.get_value(FAVOUR, sponsor.display_name, 0))


func set_favour(sponsor: SponsorData, value: int) -> void:
	_config.set_value(FAVOUR, sponsor.display_name, value)


func get_cash() -> int:
	return int(_config.get_value(WALLET, "cash", 0))


func set_cash(value: int) -> void:
	_config.set_value(WALLET, "cash", value)


func get_owned(id: StringName) -> int:
	return int(_config.get_value(OWNED, String(id), 0))


func set_owned(id: StringName, count: int) -> void:
	_config.set_value(OWNED, String(id), count)


## The item id in weapon slot `slot`, or empty.
func get_weapon_slot(slot: int) -> StringName:
	return StringName(str(_config.get_value(LOADOUT, "weapon_%d" % slot, "")))


func set_weapon_slot(slot: int, id: StringName) -> void:
	_config.set_value(LOADOUT, "weapon_%d" % slot, String(id))


func get_vest() -> StringName:
	return StringName(str(_config.get_value(LOADOUT, "vest", "")))


func set_vest(id: StringName) -> void:
	_config.set_value(LOADOUT, "vest", String(id))


## The highest tier of contract won so far. Zero before the first win.
func get_tier_won() -> int:
	return int(_config.get_value(LADDER, "tier_won", 0))


func set_tier_won(tier: int) -> void:
	_config.set_value(LADDER, "tier_won", tier)


func get_fights() -> int:
	return int(_config.get_value(LADDER, "fights", 0))


func set_fights(count: int) -> void:
	_config.set_value(LADDER, "fights", count)


## The contract a sponsor has asked for, by name, and who asked. Empty when nothing has been asked yet.
func get_request_contract() -> String:
	return str(_config.get_value(REQUEST, "contract", ""))


func get_request_sponsor() -> String:
	return str(_config.get_value(REQUEST, "sponsor", ""))


func set_request(contract_name: String, sponsor_name: String) -> void:
	_config.set_value(REQUEST, "contract", contract_name)
	_config.set_value(REQUEST, "sponsor", sponsor_name)


func save() -> void:
	var error: Error = _config.save(_path)
	if error != OK:
		push_warning("Could not save profile to %s (error %d)" % [_path, error])
