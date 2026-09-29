class_name ProfileStore
extends RefCounted
## Everything kept between fights: sponsor reputation, cash, and which contract is booked.

const REPUTATION: String = "reputation"
const WALLET: String = "wallet"
const BOOKING: String = "booking"
## Reputation earned before cash existed lives here; read once so it isn't lost.
const LEGACY_PATH: String = "user://reputation.cfg"

var _path: String
var _config: ConfigFile = ConfigFile.new()


func _init(path: String) -> void:
	_path = path
	# A missing file just means a first run.
	if FileAccess.file_exists(_path):
		_config.load(_path)
	elif FileAccess.file_exists(LEGACY_PATH):
		_config.load(LEGACY_PATH)


func get_reputation(sponsor: SponsorData) -> int:
	return int(_config.get_value(REPUTATION, sponsor.display_name, 0))


func set_reputation(sponsor: SponsorData, value: int) -> void:
	_config.set_value(REPUTATION, sponsor.display_name, value)


func get_cash() -> int:
	return int(_config.get_value(WALLET, "cash", 0))


func set_cash(value: int) -> void:
	_config.set_value(WALLET, "cash", value)


func get_contract_index() -> int:
	return int(_config.get_value(BOOKING, "contract_index", 0))


func set_contract_index(value: int) -> void:
	_config.set_value(BOOKING, "contract_index", value)


func save() -> void:
	var error: Error = _config.save(_path)
	if error != OK:
		push_warning("Could not save profile to %s (error %d)" % [_path, error])
