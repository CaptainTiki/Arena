class_name ReputationStore
extends RefCounted
## One integer per sponsor, kept between runs. A stub for real meta-progression.

const SECTION: String = "reputation"

var _path: String
var _config: ConfigFile = ConfigFile.new()


func _init(path: String) -> void:
	_path = path
	# A missing file just means a first run.
	_config.load(_path)


func get_reputation(sponsor: SponsorData) -> int:
	return int(_config.get_value(SECTION, sponsor.display_name, 0))


func set_reputation(sponsor: SponsorData, value: int) -> void:
	_config.set_value(SECTION, sponsor.display_name, value)


func save() -> void:
	var error: Error = _config.save(_path)
	if error != OK:
		push_warning("Could not save reputation to %s (error %d)" % [_path, error])
