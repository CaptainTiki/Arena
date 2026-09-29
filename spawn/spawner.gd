class_name Spawner
extends Node3D
## Puts enemies on the floor. Runs either a density ramp (keep N alive, rising over time)
## or a roster (named groups that arrive on a schedule, and early if the floor is cleared).

signal enemy_died(enemy: Enemy, hit: HitInfo)
signal enemy_acted(enemy: Enemy, action: StringName)

## Spawn points closer to the target than this are skipped when any other is available.
@export var min_spawn_distance: float = 20.0
@export var spawn_jitter: float = 2.0
## Roster enemies arrive one at a time, this far apart.
@export var roster_stagger: float = 0.4
## A cleared floor brings the next roster wave forward after this pause.
@export var early_arrival_delay: float = 3.0

## Set by the owner. Nothing spawns until there is a target.
var target: Node3D
var health_scale: float = 1.0
var damage_scale: float = 1.0

var _ramp: Array[SpawnWave] = []
var _roster: Array[RosterWave] = []
var _next_roster_wave: int = 0
var _pending: Array[ScenePool] = []
var _stagger_left: float = 0.0
var _clear_time: float = 0.0
var _elapsed: float = 0.0
var _spawn_timer: float = 0.0
var _next_id: int = 0
var _spawn_points: Array[Marker3D] = []
## Every enemy pool, in the order ramp weights refer to them.
var _pools: Array[ScenePool] = []

@onready var _pools_root: Node = $Pools
@onready var _grunts: ScenePool = $Pools/Grunts
@onready var _heavies: ScenePool = $Pools/Heavies
@onready var _shooters: ScenePool = $Pools/Shooters
@onready var _projectiles: ScenePool = $Projectiles


func _ready() -> void:
	for pool_node: Node in _pools_root.get_children():
		var pool: ScenePool = pool_node as ScenePool
		_pools.append(pool)
		for child: Node in pool.get_children():
			var enemy: Enemy = child as Enemy
			enemy.died.connect(_on_enemy_died)
			enemy.projectile_fired.connect(_on_enemy_projectile_fired)
			enemy.acted.connect(_on_enemy_acted)


func start_ramp(waves: Array[SpawnWave]) -> void:
	_ramp = waves
	_roster = []


func start_roster(waves: Array[RosterWave]) -> void:
	_roster = waves
	_ramp = []
	_next_roster_wave = 0
	_pending.clear()


func _physics_process(delta: float) -> void:
	if target == null or _spawn_points.is_empty():
		return
	_elapsed += delta
	if not _roster.is_empty():
		_tick_roster(delta)
	elif not _ramp.is_empty():
		_tick_ramp(delta)


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


func get_alive_enemies() -> Array[Enemy]:
	var alive: Array[Enemy] = []
	for pool: ScenePool in _pools:
		for node: Node in pool.get_active():
			var enemy: Enemy = node as Enemy
			if enemy.is_alive():
				alive.append(enemy)
	return alive


## Roster enemies not yet dead: on the floor, arriving, or still to come.
func get_roster_remaining() -> int:
	var remaining: int = get_alive_count() + _pending.size()
	for index: int in range(_next_roster_wave, _roster.size()):
		remaining += _roster[index].get_total()
	return remaining


func is_roster_finished() -> bool:
	return not _roster.is_empty() and get_roster_remaining() == 0


## Seconds until the next roster wave is due, or -1.0 when none is left.
func get_next_wave_in() -> float:
	if _next_roster_wave >= _roster.size():
		return -1.0
	return maxf(_roster[_next_roster_wave].start_time - _elapsed, 0.0)


func get_target_alive() -> int:
	var wave_start: float = 0.0
	for wave: SpawnWave in _ramp:
		if _elapsed < wave_start + wave.duration:
			var progress: float = (_elapsed - wave_start) / wave.duration
			return roundi(lerpf(wave.alive_at_start, wave.alive_at_end, progress))
		wave_start += wave.duration
	return _ramp[-1].alive_at_end


func _tick_ramp(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return
	var wave: SpawnWave = _get_current_ramp_wave()
	_spawn_timer = wave.spawn_interval
	var missing: int = get_target_alive() - get_alive_count()
	for i: int in mini(wave.batch_size, missing):
		var enemy: Enemy = _pick_pool(wave).acquire() as Enemy
		if enemy == null:
			# That type is at its cap; fall back to the first pool.
			enemy = _pools[0].acquire() as Enemy
		if enemy != null:
			_place(enemy)


func _tick_roster(delta: float) -> void:
	var floor_clear: bool = get_alive_count() == 0 and _pending.is_empty()
	_clear_time = _clear_time + delta if floor_clear else 0.0

	if _next_roster_wave < _roster.size():
		var wave: RosterWave = _roster[_next_roster_wave]
		var brought_forward: bool = _next_roster_wave > 0 and _clear_time >= early_arrival_delay
		if _elapsed >= wave.start_time or brought_forward:
			# Skip the clock ahead so the waves after this one keep their spacing.
			_elapsed = maxf(_elapsed, wave.start_time)
			_queue_wave(wave)
			_next_roster_wave += 1
			_clear_time = 0.0

	_stagger_left -= delta
	if _pending.is_empty() or _stagger_left > 0.0:
		return
	_stagger_left = roster_stagger
	# A full pool means that type is at its cap; it stays queued until one dies.
	for index: int in _pending.size():
		var enemy: Enemy = _pending[index].acquire() as Enemy
		if enemy != null:
			_pending.remove_at(index)
			_place(enemy)
			return


func _queue_wave(wave: RosterWave) -> void:
	for i: int in wave.heavies:
		_pending.append(_heavies)
	for i: int in wave.shooters:
		_pending.append(_shooters)
	for i: int in wave.grunts:
		_pending.append(_grunts)
	_pending.shuffle()


func _get_current_ramp_wave() -> SpawnWave:
	var wave_start: float = 0.0
	for wave: SpawnWave in _ramp:
		if _elapsed < wave_start + wave.duration:
			return wave
		wave_start += wave.duration
	return _ramp[-1]


func _place(enemy: Enemy) -> void:
	var jitter: Vector3 = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)) * spawn_jitter
	_next_id += 1
	enemy.id = _next_id
	enemy.spawn(_pick_spawn_point().global_position + jitter, target, health_scale, damage_scale)


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


func _on_enemy_acted(enemy: Enemy, action: StringName) -> void:
	enemy_acted.emit(enemy, action)


func _on_enemy_projectile_fired(enemy: Enemy, origin: Vector3, shot_velocity: Vector3) -> void:
	var projectile: Projectile = _projectiles.acquire() as Projectile
	if projectile != null:
		projectile.launch(origin, shot_velocity, enemy.get_attack_damage(), enemy)
