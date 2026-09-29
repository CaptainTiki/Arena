class_name RunLog
extends Node
## Writes one JSON line per event so a playtest can be read back afterwards.
## One file per session: it stays open from launch to quit, across every fight and the time between.
## The owner feeds it. Nothing in the game reads it.

@export var enabled: bool = true
## Inside the project while running from source, so the files are easy to find and to throw away.
@export var directory: String = "res://.logs"
## Used when `directory` can't be written, as in an exported build.
@export var fallback_directory: String = "user://logs"
## Seconds between breadcrumbs: where the player is and how they are doing.
@export var breadcrumb_interval: float = 1.0
## Every this many breadcrumbs, one also lists where each enemy is.
@export var enemy_snapshot_every: int = 3
## Older session files beyond this many are deleted when a session starts.
@export var max_files: int = 10

## Set by the owner.
var player: Player
var spawner: Spawner

## Shared by every RunLog in the session; the scene reloads between fights, the file does not.
static var _file: FileAccess
static var _time: float = 0.0
static var _run_number: int = 0

var _running: bool = false
var _breadcrumb_left: float = 0.0
var _crumbs: int = 0


func _physics_process(delta: float) -> void:
	if _file == null:
		return
	_time += delta
	if not _running:
		return
	_breadcrumb_left -= delta
	if _breadcrumb_left <= 0.0:
		_breadcrumb_left += breadcrumb_interval
		_write_breadcrumb()


func _exit_tree() -> void:
	if _file != null:
		_file.flush()


func begin(contract: ContractData) -> void:
	if not enabled:
		return
	if _file == null:
		_start_session()
	if _file == null:
		return
	_run_number += 1
	_running = true
	_breadcrumb_left = 0.0
	_crumbs = 0
	log_world("run_start", {
		"run": _run_number,
		"contract": contract.display_name,
		"type": contract.get_type_name(),
		"time_limit": contract.time_limit,
		"enemy_health_scale": contract.enemy_health_scale,
		"enemy_damage_scale": contract.enemy_damage_scale,
	})


func finish(outcome: String, stats: RunStats) -> void:
	log_player("run_end", {
		"run": _run_number,
		"outcome": outcome,
		"kills": stats.kills,
		"shots": stats.shots,
		"hits": stats.hits,
		"headshots": stats.headshots,
		"pods": stats.pods_collected,
	})
	_running = false
	if _file != null:
		_file.flush()


func get_file_path() -> String:
	return "" if _file == null else _file.get_path_absolute()


## Something that happened to the fight rather than to anyone in it.
func log_world(event: String, extra: Dictionary = {}) -> void:
	if _file == null:
		return
	var line: Dictionary = {"t": _num(_time), "ev": event}
	line.merge(extra)
	_write(line)


## Something the player did, or that happened to them. Stamped with where they stood and looked.
func log_player(event: String, extra: Dictionary = {}) -> void:
	if _file == null:
		return
	var line: Dictionary = _stamp(event)
	line.merge(extra)
	_write(line)


## Something an enemy did.
func log_enemy(event: String, enemy: Enemy, extra: Dictionary = {}) -> void:
	if _file == null:
		return
	var line: Dictionary = {"t": _num(_time), "ev": event}
	line.merge(_describe_enemy(enemy))
	line.merge(extra)
	_write(line)


## One trigger pull. `hit` is the best any pellet did, or null when nothing was struck at all.
func log_shot(weapon: Weapon, hit: HitInfo, pellets_landed: int, damage_dealt: float) -> void:
	if _file == null:
		return
	var line: Dictionary = _stamp("shot")
	line["weapon"] = weapon.get_stats().display_name
	line["mag"] = weapon.get_mag()
	line["reserve"] = weapon.get_reserve()
	if hit == null:
		line["result"] = "sky"
	elif not hit.landed():
		line["result"] = "world"
	else:
		line["result"] = "head" if hit.is_headshot else "body"
		line["damage"] = _num(damage_dealt)
		line["pellets"] = pellets_landed
		line["killed"] = hit.killed
		if hit.target is Enemy:
			line.merge(_describe_enemy(hit.target as Enemy))
	_write(line)


## A blow that reached the player. `dodged` is one the dash carried them through.
func log_player_hit(hit: HitInfo, dodged: bool) -> void:
	if _file == null:
		return
	var line: Dictionary = _stamp("dodged" if dodged else "damaged")
	line["damage"] = _num(hit.damage)
	line["health"] = _num(player.get_health())
	if hit.source is Enemy:
		var enemy: Enemy = hit.source as Enemy
		line.merge(_describe_enemy(enemy))
		line["attack"] = enemy.get_attack_name()
	_write(line)


func _start_session() -> void:
	var version: String = str(ProjectSettings.get_setting("application/config/version", "unversioned"))
	var stamp: String = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var file_name: String = "%s_%s.jsonl" % [version.validate_filename().replace(" ", "_"), stamp]
	_file = _open(directory, file_name)
	if _file == null:
		_file = _open(fallback_directory, file_name)
	if _file == null:
		push_warning("RunLog: could not open a log file, nothing will be recorded")
		return
	_time = 0.0
	_run_number = 0
	_prune(_file.get_path().get_base_dir())
	log_world("session_start", {
		"version": version,
		"started": Time.get_datetime_string_from_system(),
	})


func _stamp(event: String) -> Dictionary:
	return {
		"t": _num(_time),
		"ev": event,
		"pos": _vec(player.global_position),
		"yaw": roundi(rad_to_deg(player.rotation.y)),
		"pitch": roundi(rad_to_deg(player.get_pitch())),
	}


func _describe_enemy(enemy: Enemy) -> Dictionary:
	return {
		"id": enemy.id,
		"enemy": enemy.get_type_name(),
		"epos": _vec(enemy.global_position),
		"dist": _short(enemy.global_position.distance_to(player.global_position)),
		"ehealth": _short(enemy.get_health()),
	}


func _write_breadcrumb() -> void:
	var weapon: Weapon = player.get_weapon()
	var enemies: Array[Enemy] = spawner.get_alive_enemies()
	var nearest: float = -1.0
	for enemy: Enemy in enemies:
		var distance: float = enemy.global_position.distance_to(player.global_position)
		if nearest < 0.0 or distance < nearest:
			nearest = distance
	var line: Dictionary = _stamp("crumb")
	line["speed"] = _short(Vector2(player.velocity.x, player.velocity.z).length())
	line["health"] = _short(player.get_health())
	line["weapon"] = weapon.get_stats().display_name
	line["mag"] = weapon.get_mag()
	line["reserve"] = weapon.get_reserve()
	line["alive"] = enemies.size()
	line["nearest"] = _short(nearest)
	if _crumbs % maxi(enemy_snapshot_every, 1) == 0 and not enemies.is_empty():
		# Kept terse, this is most of the file: id, type, x, y, z, state.
		var snapshot: Array = []
		for enemy: Enemy in enemies:
			var at: Vector3 = enemy.global_position
			snapshot.append([enemy.id, enemy.get_type_name(), roundi(at.x), roundi(at.y), roundi(at.z),
					enemy.get_state_name()])
		line["enemies"] = snapshot
	_crumbs += 1
	_write(line)
	# Once a second is often enough that a closed window loses almost nothing.
	_file.flush()


func _write(line: Dictionary) -> void:
	_file.store_line(JSON.stringify(line, "", false))


func _open(folder: String, file_name: String) -> FileAccess:
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) != OK:
		return null
	return FileAccess.open(folder.path_join(file_name), FileAccess.WRITE)


## Names start with the version and then the date, so sorted order is oldest first within a version.
func _prune(folder: String) -> void:
	var dir: DirAccess = DirAccess.open(folder)
	if dir == null:
		return
	var logs: Array[String] = []
	for file_name: String in dir.get_files():
		if file_name.get_extension() == "jsonl":
			logs.append(file_name)
	logs.sort_custom(func(a: String, b: String) -> bool:
		return FileAccess.get_modified_time(folder.path_join(a)) < FileAccess.get_modified_time(folder.path_join(b)))
	while logs.size() > max_files:
		dir.remove(logs.pop_front())


func _num(value: float) -> float:
	return snappedf(value, 0.01)


func _short(value: float) -> float:
	return snappedf(value, 0.1)


func _vec(value: Vector3) -> Array[float]:
	return [_short(value.x), _short(value.y), _short(value.z)]
