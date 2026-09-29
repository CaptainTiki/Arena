class_name Enemy
extends CharacterBody3D
## Pooled enemy. One script for every type; EnemyData decides how it attacks.

## Returns the enemy to its pool.
signal released
signal died(enemy: Enemy, hit: HitInfo)
## The owner turns this into a projectile.
signal projectile_fired(enemy: Enemy, origin: Vector3, shot_velocity: Vector3)

enum State { CHASE, WINDUP, LUNGE, RECOVER, DYING }

@export var data: EnemyData
@export_flags_3d_physics var sight_mask: int = 1
## Layers a charge ploughs through, so a crowd of grunts can't stop it.
@export_flags_3d_physics var charge_ignore_mask: int = 4

var _target: Node3D
var _state: State = State.CHASE
var _state_left: float = 0.0
var _health: float = 0.0
var _speed: float = 0.0
var _lead_time: float = 0.0
var _lead_accuracy: float = 0.0
var _aura_left: float = 0.0
var _charge_left: float = 0.0
var _move_velocity: Vector3 = Vector3.ZERO
var _knockback: Vector3 = Vector3.ZERO
var _lunge_direction: Vector3 = Vector3.ZERO
var _lunge_connected: bool = false
var _path: PackedVector3Array = PackedVector3Array()
var _path_index: int = 0
var _repath_left: float = 0.0
var _body_layer: int = 0
var _body_mask: int = 0
var _head_layer: int = 0

@onready var _head: Hitbox = $Head
@onready var _visual: Node3D = $Visual
@onready var _body_mesh: MeshInstance3D = $Visual/BodyMesh
@onready var _material: StandardMaterial3D = _body_mesh.material_override as StandardMaterial3D
## Only aura enemies have one: a unit-radius disc, scaled here to the aura's reach.
@onready var _aura: Node3D = get_node_or_null(^"Aura")


func _ready() -> void:
	_body_layer = collision_layer
	_body_mask = collision_mask
	_head_layer = _head.collision_layer
	if _aura != null:
		_aura.scale = Vector3(data.aura_radius, 1.0, data.aura_radius)


func spawn(at: Vector3, target: Node3D) -> void:
	_target = target
	_state = State.CHASE
	_health = data.max_health
	_speed = data.move_speed * randf_range(1.0 - data.speed_variance, 1.0 + data.speed_variance)
	_lead_time = randf_range(0.0, data.lead_time_max)
	_lead_accuracy = randf_range(data.lead_accuracy_min, data.lead_accuracy_max)
	_aura_left = data.aura_interval
	# First charge comes partway into the cooldown, and not from every heavy at once.
	_charge_left = data.charge_cooldown * randf_range(0.3, 0.6)
	_move_velocity = Vector3.ZERO
	_knockback = Vector3.ZERO
	_path = PackedVector3Array()
	_path_index = 0
	# Stagger the first replan too, so a batch spawned together doesn't plan together.
	_repath_left = randf_range(0.0, data.repath_interval_min)
	velocity = Vector3.ZERO
	global_position = at
	collision_layer = _body_layer
	collision_mask = _body_mask
	_head.collision_layer = _head_layer
	_visual.scale = Vector3.ONE
	_material.albedo_color = data.body_color
	if _aura != null:
		_aura.visible = true


func is_alive() -> bool:
	return _state != State.DYING


func take_hit(hit: HitInfo) -> void:
	if not is_alive():
		return
	_health -= hit.damage
	_material.albedo_color = data.hit_flash_color
	var shove: Vector3 = Vector3(hit.direction.x, 0.0, hit.direction.z).normalized()
	_knockback += shove * hit.knockback * data.knockback_scale
	if _health <= 0.0:
		hit.killed = true
		_die(hit)


func _physics_process(delta: float) -> void:
	if _state == State.DYING:
		_tick_pop(delta)
		return

	var wish_velocity: Vector3 = Vector3.ZERO
	match _state:
		State.CHASE:
			wish_velocity = _get_chase_velocity(delta)
			if _should_attack():
				_enter(State.WINDUP, data.attack_windup)
		State.WINDUP:
			_state_left -= delta
			if _state_left <= 0.0:
				_finish_windup()
		State.LUNGE:
			_state_left -= delta
			_move_velocity = _lunge_direction * data.lunge_speed
			wish_velocity = _move_velocity
			if not _lunge_connected and _get_target_distance() <= data.attack_reach and _is_target_level():
				_lunge_connected = true
				_strike(_lunge_direction, _get_lunge_damage())
			# A charge that slams into a wall stops there.
			if _state_left <= 0.0 or (is_on_wall() and data.attack_style == EnemyData.AttackStyle.AURA):
				_move_velocity = Vector3.ZERO
				wish_velocity = Vector3.ZERO
				collision_mask = _body_mask
				_enter(State.RECOVER, data.attack_recover)
		State.RECOVER:
			_state_left -= delta
			if data.attack_style == EnemyData.AttackStyle.RANGED:
				# Shooters reposition between shots instead of standing still.
				wish_velocity = _get_chase_velocity(delta)
			if _state_left <= 0.0:
				_enter(State.CHASE, 0.0)

	if data.attack_style == EnemyData.AttackStyle.AURA:
		_tick_aura(delta)
		_charge_left = maxf(_charge_left - delta, 0.0)

	_move_velocity = _move_velocity.move_toward(wish_velocity, data.acceleration * delta)
	_knockback = _knockback.move_toward(Vector3.ZERO, data.knockback_friction * delta)
	velocity.x = _move_velocity.x + _knockback.x
	velocity.z = _move_velocity.z + _knockback.z
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity += get_gravity() * delta
	move_and_slide()

	_update_feedback(delta)


func _get_chase_velocity(delta: float) -> Vector3:
	var distance: float = _get_target_distance()
	match data.attack_style:
		EnemyData.AttackStyle.AURA:
			if distance <= data.attack_range:
				return Vector3.ZERO
		EnemyData.AttackStyle.RANGED:
			if distance < data.retreat_range:
				return -_get_direction_to(_target.global_position) * _speed
			if distance <= data.preferred_range and _can_see_target():
				return Vector3.ZERO
	return _get_move_direction(delta) * _speed


func _should_attack() -> bool:
	match data.attack_style:
		EnemyData.AttackStyle.LUNGE:
			return _get_target_distance() <= data.attack_range and _is_target_level()
		EnemyData.AttackStyle.AURA:
			if data.charge_cooldown <= 0.0 or _charge_left > 0.0:
				return false
			var gap: float = _get_target_distance()
			return (gap >= data.charge_min_distance and gap <= data.charge_max_distance
					and _is_target_level() and _is_ground_clear())
		EnemyData.AttackStyle.RANGED:
			# Too close means back off first; rushing a shooter shuts it down.
			var distance: float = _get_target_distance()
			return distance >= data.retreat_range and distance <= data.preferred_range and _can_see_target()
	return false


func _finish_windup() -> void:
	match data.attack_style:
		EnemyData.AttackStyle.LUNGE:
			_lunge_direction = _get_direction_to(_target.global_position)
			_lunge_connected = false
			_enter(State.LUNGE, data.lunge_duration)
		EnemyData.AttackStyle.AURA:
			_charge_left = data.charge_cooldown
			collision_mask = _body_mask & ~charge_ignore_mask
			_lunge_direction = _get_direction_to(_target.global_position)
			_lunge_connected = false
			_enter(State.LUNGE, data.lunge_duration)
		EnemyData.AttackStyle.RANGED:
			_shoot()
			_enter(State.RECOVER, data.attack_recover)


## The one place that decides where to walk: along a navigation route to a point ahead of the target.
func _get_move_direction(delta: float) -> Vector3:
	_repath_left -= delta
	if _repath_left <= 0.0:
		_repath_left = randf_range(data.repath_interval_min, data.repath_interval_max)
		_path = NavigationServer3D.map_get_path(
				get_world_3d().navigation_map, global_position, _get_aim_point(), true)
		# The first point is where we already stand.
		_path_index = 1

	while _path_index < _path.size() and _get_flat_distance(_path[_path_index]) <= data.waypoint_reach:
		_path_index += 1
	if _path_index >= _path.size():
		return _get_direction_to(_target.global_position)
	return _get_direction_to(_path[_path_index])


func _get_aim_point() -> Vector3:
	var lead_scale: float = clampf(_get_target_distance() / data.lead_falloff_distance, 0.0, 1.0)
	return _target.global_position + _get_target_velocity() * _lead_time * lead_scale


func _get_target_velocity() -> Vector3:
	if not _target is CharacterBody3D:
		return Vector3.ZERO
	var target_velocity: Vector3 = (_target as CharacterBody3D).velocity
	target_velocity.y = 0.0
	return target_velocity


func _get_direction_to(point: Vector3) -> Vector3:
	var to_point: Vector3 = point - global_position
	to_point.y = 0.0
	return to_point.normalized()


func _get_flat_distance(point: Vector3) -> float:
	var to_point: Vector3 = point - global_position
	to_point.y = 0.0
	return to_point.length()


func _get_target_distance() -> float:
	return _get_flat_distance(_target.global_position)


func _is_target_level() -> bool:
	return absf(_target.global_position.y - global_position.y) <= data.attack_height_tolerance


func _get_muzzle() -> Vector3:
	return global_position + Vector3.UP * data.muzzle_height


func _can_see_target() -> bool:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			_get_muzzle(), _target.global_position + Vector3.UP, sight_mask)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## Like sight, but at shin height, so low cover that can be seen over still blocks a charge.
func _is_ground_clear() -> bool:
	var lift: Vector3 = Vector3.UP * 0.4
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			global_position + lift, _target.global_position + lift, sight_mask)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _enter(state: State, duration: float) -> void:
	_state = state
	_state_left = duration


func _get_lunge_damage() -> float:
	if data.attack_style == EnemyData.AttackStyle.AURA:
		return data.charge_damage
	return data.attack_damage


func _strike(direction: Vector3, damage: float) -> void:
	if not _target.has_method(&"take_hit"):
		return
	var hit: HitInfo = HitInfo.new()
	hit.damage = damage
	hit.position = _target.global_position
	hit.direction = direction
	hit.target = _target
	hit.source = self
	_target.call(&"take_hit", hit)


func _shoot() -> void:
	var origin: Vector3 = _get_muzzle()
	var flight_time: float = origin.distance_to(_target.global_position) / data.projectile_speed
	var aim: Vector3 = _target.global_position + Vector3.UP
	aim += _get_target_velocity() * flight_time * _lead_accuracy
	projectile_fired.emit(self, origin, (aim - origin).normalized() * data.projectile_speed)


func _tick_aura(delta: float) -> void:
	_aura_left -= delta
	if _aura_left > 0.0:
		return
	_aura_left = data.aura_interval
	if _get_target_distance() <= data.aura_radius and _is_target_level():
		_strike(_get_direction_to(_target.global_position), data.attack_damage)


func _update_feedback(delta: float) -> void:
	var winding_up: bool = _state == State.WINDUP
	var resting: Color = data.windup_color if winding_up else data.body_color
	var weight: float = 1.0 - exp(-data.flash_fade_speed * delta)
	_material.albedo_color = _material.albedo_color.lerp(resting, weight)
	var squash: float = data.windup_squash if winding_up else 1.0
	var squash_weight: float = 1.0 - exp(-20.0 * delta)
	_visual.scale.y = lerpf(_visual.scale.y, squash, squash_weight)


func _die(hit: HitInfo) -> void:
	_enter(State.DYING, data.pop_time)
	collision_layer = 0
	collision_mask = 0
	_head.collision_layer = 0
	_material.albedo_color = data.hit_flash_color
	if _aura != null:
		_aura.visible = false
	died.emit(self, hit)


func _tick_pop(delta: float) -> void:
	_state_left -= delta
	if _state_left <= 0.0:
		released.emit()
		return
	var progress: float = 1.0 - _state_left / data.pop_time
	_visual.scale = Vector3.ONE * lerpf(1.0, data.pop_scale, progress)
