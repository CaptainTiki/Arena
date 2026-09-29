class_name Spawner
extends Node3D
## Keeps the number of living enemies on the curve described by the wave sequence.

signal enemy_died(enemy: Enemy, hit: HitInfo)

@export var waves: Array[SpawnWave] = []
## Spawn points closer to the target than this are skipped when any other is available.
@export var min_spawn_distance: float = 20.0
@export var spawn_jitter: float = 2.0

## Set by the owner. Nothing spawns until there is a target.
var target: Node3D

var _elapsed: float = 0.0
var _spawn_timer: float = 0.0
var _spawn_points: Array[Marker3D] = []
## One pool per enemy type, in the order wave weights refer to them.
var _pools: Array[ScenePool] = []

@onready var _pools_root: Node = $Pools
@onready var _projectiles: ScenePool = $Projectiles


func _ready() -> void:
	for pool_node: Node in _pools_root.get_children():
		var pool: ScenePool = pool_node as ScenePool
		_pools.append(pool)
		for child: Node in pool.get_children():
			var enemy: Enemy = child as Enemy
			enemy.died.connect(_on_enemy_died)
			enemy.projectile_fired.connect(_on_enemy_projectile_fired)


func _physics_process(delta: float) -> void:
	if target == null or waves.is_empty() or _spawn_points.is_empty():
		return
	_elapsed += delta
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return

	var wave: SpawnWave = _get_current_wave()
	_spawn_timer = wave.spawn_interval
	var missing: int = get_target_alive() - get_alive_count()
	for i: int in mini(wave.batch_size, missing):
		_spawn_one(wave)


## Set by the owner, from whichever level is loaded.
func set_spawn_points(points: Array[Marker3D]) -> void:
	_spawn_points = points


func get_elapsed() -> float:
	return _elapsed


func set_elapsed(seconds: float) -> void:
	_elapsed = seconds


func get_alive_count() -> int:
	var alive: int = 0
	for pool: ScenePool in _pools:
		alive += pool.get_active_count()
	return alive


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


func _spawn_one(wave: SpawnWave) -> void:
	var enemy: Enemy = _pick_pool(wave).acquire() as Enemy
	if enemy == null:
		# That type is at its cap; fall back to the first pool.
		enemy = _pools[0].acquire() as Enemy
	if enemy == null:
		return
	var jitter: Vector3 = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)) * spawn_jitter
	enemy.spawn(_pick_spawn_point().global_position + jitter, target)


func _pick_pool(wave: SpawnWave) -> ScenePool:
	var count: int = mini(wave.weights.size(), _pools.size())
	var total: float = 0.0
	for index: int in count:
		total += wave.weights[index]
	var roll: float = randf() * total
	for index: int in count:
		roll -= wave.weights[index]
		if roll <= 0.0:
			return _pools[index]
	return _pools[0]


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


func _on_enemy_projectile_fired(enemy: Enemy, origin: Vector3, shot_velocity: Vector3) -> void:
	var projectile: Projectile = _projectiles.acquire() as Projectile
	if projectile != null:
		projectile.launch(origin, shot_velocity, enemy.data.attack_damage, enemy)
