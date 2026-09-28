class_name Spawner
extends Node3D
## Keeps the number of living enemies on the curve described by the wave sequence.

signal enemy_died(enemy: Enemy, hit: HitInfo)

@export var waves: Array[SpawnWave] = []
## Spawn points closer to the target than this are skipped when any other is available.
@export var min_spawn_distance: float = 14.0
@export var spawn_jitter: float = 2.0

## Set by the owner. Nothing spawns until there is a target.
var target: Node3D

var _elapsed: float = 0.0
var _spawn_timer: float = 0.0
var _spawn_points: Array[Marker3D] = []

@onready var _pool: ScenePool = $Pool
@onready var _points_root: Node3D = $SpawnPoints


func _ready() -> void:
	for child: Node in _points_root.get_children():
		if child is Marker3D:
			_spawn_points.append(child as Marker3D)
	for child: Node in _pool.get_children():
		(child as Enemy).died.connect(_on_enemy_died)


func _physics_process(delta: float) -> void:
	if target == null or waves.is_empty():
		return
	_elapsed += delta
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return

	var wave: SpawnWave = _get_current_wave()
	_spawn_timer = wave.spawn_interval
	var missing: int = get_target_alive() - get_alive_count()
	for i: int in mini(wave.batch_size, missing):
		_spawn_one()


func get_elapsed() -> float:
	return _elapsed


func set_elapsed(seconds: float) -> void:
	_elapsed = seconds


func get_alive_count() -> int:
	return _pool.get_active_count()


func get_target_alive() -> int:
	var wave_start: float = 0.0
	for wave: SpawnWave in waves:
		if _elapsed < wave_start + wave.duration:
			var progress: float = (_elapsed - wave_start) / wave.duration
			return roundi(lerpf(wave.alive_at_start, wave.alive_at_end, progress))
		wave_start += wave.duration
	return waves[-1].alive_at_end


func _get_current_wave() -> SpawnWave:
	var wave_start: float = 0.0
	for wave: SpawnWave in waves:
		if _elapsed < wave_start + wave.duration:
			return wave
		wave_start += wave.duration
	return waves[-1]


func _spawn_one() -> void:
	var enemy: Enemy = _pool.acquire() as Enemy
	if enemy == null:
		return
	var jitter: Vector3 = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)) * spawn_jitter
	enemy.spawn(_pick_spawn_point().global_position + jitter, target)


func _pick_spawn_point() -> Marker3D:
	var far_enough: Array[Marker3D] = []
	for point: Marker3D in _spawn_points:
		if point.global_position.distance_to(target.global_position) >= min_spawn_distance:
			far_enough.append(point)
	if far_enough.is_empty():
		return _spawn_points.pick_random()
	return far_enough.pick_random()


func _on_enemy_died(enemy: Enemy, hit: HitInfo) -> void:
	enemy_died.emit(enemy, hit)
