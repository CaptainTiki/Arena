class_name Enemy
extends CharacterBody3D
## Pooled enemy. One script for every type; EnemyData decides how it attacks.

## Returns the enemy to its pool.
signal released
signal died(enemy: Enemy, hit: HitInfo)
## The owner turns this into a projectile.
signal projectile_fired(enemy: Enemy, origin: Vector3, shot_velocity: Vector3)
## Reported for the run log: &"spawn", &"windup", &"attack", &"alert", &"lost", &"search" and &"calm".
signal acted(enemy: Enemy, action: StringName)

## IDLE knows nothing. ALERTED is walking to a last-known position, SEARCH is looking around it.
## CHASE and everything after it is engaged: it has seen the target.
enum State { IDLE, ALERTED, SEARCH, CHASE, WINDUP, LUNGE, RECOVER, DYING }
## What the current windup is building toward.
enum Attack { LUNGE, CHARGE, SLAM, SHOT }

@export var data: EnemyData
@export_flags_3d_physics var sight_mask: int = 1
## Layers a charge ploughs through, so a crowd of grunts can't stop it.
@export_flags_3d_physics var charge_ignore_mask: int = 4

## Set by the spawner, counting up through the run, so one enemy can be followed through the log.
var id: int = 0

var _target: Node3D
var _state: State = State.CHASE
var _attack: Attack = Attack.LUNGE
var _state_left: float = 0.0
var _health: float = 0.0
var _speed: float = 0.0
var _lead_time: float = 0.0
var _lead_accuracy: float = 0.0
var _charge_left: float = 0.0
var _damage_scale: float = 1.0
var _move_velocity: Vector3 = Vector3.ZERO
var _knockback: Vector3 = Vector3.ZERO
var _lunge_direction: Vector3 = Vector3.ZERO
var _lunge_connected: bool = false
var _path: PackedVector3Array = PackedVector3Array()
var _path_index: int = 0
var _repath_left: float = 0.0
## True once the route in hand has been walked to its end.
var _path_done: bool = false
var _sees_target: bool = false
var _look_left: float = 0.0
var _unseen_time: float = 0.0
## Where the target was last seen or heard.
var _last_known: Vector3 = Vector3.ZERO
## Where it is walking to while it is not engaged.
var _goal: Vector3 = Vector3.ZERO
var _has_goal: bool = false
var _goal_left: float = 0.0
var _pause_left: float = 0.0
## What raised it last: &"sight", &"gunfire", &"zone" or &"hit".
var _alert_cause: StringName = &""
var _flanking: bool = false
var _flank_angle: float = 0.0
## Compass bearing, from the target, of the side this one comes in from.
var _flank_bearing: float = 0.0
var _body_layer: int = 0
var _body_mask: int = 0
var _weak_points: Array[Hitbox] = []

## Turns with the visual, so a weak point stays on the side of the body it was authored on.
@onready var _weak_point_pivot: Node3D = $WeakPoints
@onready var _visual: Node3D = $Visual
@onready var _body_mesh: MeshInstance3D = $Visual/BodyMesh
@onready var _material: StandardMaterial3D = _body_mesh.material_override as StandardMaterial3D
## Only slam enemies have arms: a pivot at shoulder height with the arms hanging below it.
@onready var _arms: Node3D = get_node_or_null(^"Visual/Arms")
@onready var _mark: Label3D = $Mark


func _ready() -> void:
	_body_layer = collision_layer
	_body_mask = collision_mask
	for child: Node in _weak_point_pivot.get_children():
		if child is Hitbox:
			_weak_points.append(child as Hitbox)


## `aware` puts it on the floor already engaged, whatever its senses say.
func spawn(at: Vector3, target: Node3D, health_scale: float = 1.0, damage_scale: float = 1.0,
		aware: bool = false) -> void:
	_target = target
	_state = State.CHASE if aware or data.always_aware else State.IDLE
	_sees_target = false
	_look_left = randf_range(0.0, data.sight_interval)
	_unseen_time = 0.0
	_last_known = target.global_position
	_has_goal = false
	_pause_left = randf_range(0.0, data.patrol_pause_max)
	_alert_cause = &""
	_flanking = false
	_flank_angle = deg_to_rad(randf_range(-data.flank_angle_degrees, data.flank_angle_degrees))
	_health = data.max_health * health_scale
	_damage_scale = damage_scale
	_speed = data.move_speed * randf_range(1.0 - data.speed_variance, 1.0 + data.speed_variance)
	_lead_time = randf_range(0.0, data.lead_time_max)
	_lead_accuracy = randf_range(data.lead_accuracy_min, data.lead_accuracy_max)
	# First charge comes partway into the cooldown, and not from every heavy at once.
	_charge_left = data.charge_cooldown * randf_range(0.3, 0.6)
	_move_velocity = Vector3.ZERO
	_knockback = Vector3.ZERO
	_path = PackedVector3Array()
	_path_index = 0
	_path_done = false
	# Stagger the first replan too, so a batch spawned together doesn't plan together.
	_repath_left = randf_range(0.0, data.repath_interval_min)
	velocity = Vector3.ZERO
	global_position = at
	collision_layer = _body_layer
	collision_mask = _body_mask
	_refresh_weak_points()
	_visual.scale = Vector3.ONE
	# Unaware, it could be looking anywhere.
	_visual.rotation.y = randf() * TAU
	_material.albedo_color = data.body_color
	if _arms != null:
		_arms.rotation.x = 0.0
	_refresh_mark()
	acted.emit(self, &"spawn")


func is_alive() -> bool:
	return _state != State.DYING


func get_health() -> float:
	return maxf(_health, 0.0)


## "grunt", "heavy" or "shooter": the name of the data file.
func get_type_name() -> String:
	return data.resource_path.get_file().get_basename()


func get_state_name() -> String:
	return State.keys()[_state]


## Has seen the target and is fighting it.
func is_engaged() -> bool:
	return _state >= State.CHASE and _state != State.DYING


func get_alert_cause() -> StringName:
	return _alert_cause


## A noise at `noise_position`. Sends it to look, unless it is already fighting.
func hear(noise_position: Vector3, cause: StringName) -> void:
	if not is_alive() or is_engaged() or data.always_aware:
		return
	var error: Vector3 = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)) * data.hearing_error
	_alert_to(noise_position + error, cause)


## Set by the owner: whether enough of its kind are engaged to come in from different sides.
func set_flanking(flanking: bool) -> void:
	if flanking and not _flanking:
		var from_target: Vector3 = global_position - _target.global_position
		_flank_bearing = atan2(from_target.z, from_target.x) + _flank_angle
	_flanking = flanking


## The attack it is winding up, making, or made last.
func get_attack_name() -> String:
	return Attack.keys()[_attack]


## Damage of one lunge or projectile, after the contract's scaling.
func get_attack_damage() -> float:
	return data.attack_damage * _damage_scale


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
	elif not is_engaged() and hit.source is Node3D:
		_alert_to((hit.source as Node3D).global_position, &"hit")


func _physics_process(delta: float) -> void:
	if _state == State.DYING:
		_tick_pop(delta)
		return

	_charge_left = maxf(_charge_left - delta, 0.0)
	_tick_senses(delta)

	var wish_velocity: Vector3 = Vector3.ZERO
	match _state:
		State.IDLE:
			wish_velocity = _tick_idle(delta)
		State.ALERTED:
			wish_velocity = _tick_alerted(delta)
		State.SEARCH:
			wish_velocity = _tick_search(delta)
		State.CHASE:
			if _unseen_time >= data.lose_sight_time and not data.always_aware:
				_lose_target()
			else:
				wish_velocity = _get_chase_velocity(delta)
				if _pick_attack():
					_enter(State.WINDUP, _get_windup_time())
					acted.emit(self, &"windup")
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
			if _state_left <= 0.0 or (is_on_wall() and _attack == Attack.CHARGE):
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


func _tick_senses(delta: float) -> void:
	if data.always_aware:
		return
	_unseen_time += delta
	_look_left -= delta
	if _look_left <= 0.0:
		_look_left = data.sight_interval
		_sees_target = _look()
	if not _sees_target:
		return
	_unseen_time = 0.0
	_last_known = _target.global_position
	if _state < State.CHASE:
		_alert_cause = &"sight"
		_enter(State.CHASE, 0.0)
		_restart_route()
		acted.emit(self, &"alert")


func _look() -> bool:
	var to_target: Vector3 = _target.global_position - global_position
	if to_target.length() > data.sight_range:
		return false
	to_target.y = 0.0
	if to_target.length() > data.notice_range:
		var facing: Vector3 = -_visual.global_basis.z
		facing.y = 0.0
		if rad_to_deg(facing.angle_to(to_target)) > data.sight_cone_degrees * 0.5:
			return false
	return _can_see_target()


## Goes to look at `point`. Already on its way somewhere, it changes where without announcing it again.
func _alert_to(point: Vector3, cause: StringName) -> void:
	_last_known = _get_floor_point(point)
	_alert_cause = cause
	_set_goal(_pick_vantage() if data.attack_style == EnemyData.AttackStyle.RANGED else _last_known)
	var announce: bool = _state != State.ALERTED
	_enter(State.ALERTED, data.alert_timeout)
	if announce:
		acted.emit(self, &"alert")


## Engaged, and the target has been out of sight too long.
func _lose_target() -> void:
	acted.emit(self, &"lost")
	_set_goal(_pick_vantage() if data.attack_style == EnemyData.AttackStyle.RANGED else _last_known)
	_enter(State.ALERTED, data.alert_timeout)


func _tick_idle(delta: float) -> Vector3:
	if _pause_left > 0.0:
		_pause_left -= delta
		return Vector3.ZERO
	if not _has_goal:
		_set_goal(_get_floor_point_near(global_position, 0.0, data.patrol_radius))
	if _tick_goal(delta):
		_has_goal = false
		_pause_left = randf_range(data.patrol_pause_min, data.patrol_pause_max)
		return Vector3.ZERO
	return _walk_to(_goal, delta) * _speed * data.patrol_speed_scale


func _tick_alerted(delta: float) -> Vector3:
	_state_left -= delta
	if _state_left <= 0.0 or _tick_goal(delta):
		_has_goal = false
		_pause_left = 0.0
		_enter(State.SEARCH, data.search_time)
		acted.emit(self, &"search")
		return Vector3.ZERO
	return _walk_to(_goal, delta) * _speed


func _tick_search(delta: float) -> Vector3:
	_state_left -= delta
	if _state_left <= 0.0:
		_has_goal = false
		_pause_left = randf_range(data.patrol_pause_min, data.patrol_pause_max)
		_enter(State.IDLE, 0.0)
		acted.emit(self, &"calm")
		return Vector3.ZERO
	if _pause_left > 0.0:
		_pause_left -= delta
		return Vector3.ZERO
	if not _has_goal:
		_set_goal(_get_floor_point_near(_last_known, 0.0, data.search_radius))
	if _tick_goal(delta):
		_has_goal = false
		_pause_left = data.patrol_pause_min
		return Vector3.ZERO
	return _walk_to(_goal, delta) * _speed * lerpf(data.patrol_speed_scale, 1.0, 0.5)


func _set_goal(point: Vector3) -> void:
	_goal = point
	_has_goal = true
	# Long enough to walk there; after that it is stuck, and gives up.
	_goal_left = data.alert_timeout
	_restart_route()


## True once the goal is reached, or can't be.
func _tick_goal(delta: float) -> bool:
	_goal_left -= delta
	return _goal_left <= 0.0 or _path_done or _get_flat_distance(_goal) <= data.arrive_distance


func _restart_route() -> void:
	_path = PackedVector3Array()
	_path_index = 0
	_path_done = false
	_repath_left = 0.0


func _get_floor_point(point: Vector3) -> Vector3:
	return NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, point)


func _get_floor_point_near(centre: Vector3, distance_min: float, distance_max: float) -> Vector3:
	var angle: float = randf() * TAU
	var distance: float = randf_range(distance_min, distance_max)
	return _get_floor_point(centre + Vector3(cos(angle), 0.0, sin(angle)) * distance)


## A spot that can see the last-known position from a distance. Falls back to the position itself.
func _pick_vantage() -> Vector3:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	for attempt: int in 8:
		var spot: Vector3 = _get_floor_point_near(
				_last_known, data.vantage_distance_min, data.vantage_distance_max)
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
				spot + Vector3.UP * data.muzzle_height, _last_known + Vector3.UP, sight_mask)
		if space.intersect_ray(query).is_empty():
			return spot
	return _last_known


func _get_chase_velocity(delta: float) -> Vector3:
	var distance: float = _get_target_distance()
	match data.attack_style:
		EnemyData.AttackStyle.SLAM:
			if distance <= data.attack_range:
				return Vector3.ZERO
		EnemyData.AttackStyle.RANGED:
			if distance < data.retreat_range:
				return _get_retreat_direction(delta) * _speed
			if distance <= data.preferred_range and _can_see_target():
				return Vector3.ZERO
	return _walk_to(_get_aim_point(), delta, _target.global_position) * _speed


## Backs off along the floor rather than into a wall: of a few ways out, the one that ends furthest from the target.
func _get_retreat_direction(delta: float) -> Vector3:
	if _is_plan_due(delta):
		var away: Vector3 = -_get_direction_to(_target.global_position)
		var best: Vector3 = global_position
		var best_distance: float = 0.0
		var angles: Array[float] = [0.0, 50.0, -50.0, 100.0, -100.0]
		for degrees: float in angles:
			var spot: Vector3 = _get_floor_point(
					global_position + away.rotated(Vector3.UP, deg_to_rad(degrees)) * data.retreat_step)
			var distance: float = spot.distance_to(_target.global_position)
			if distance > best_distance:
				best_distance = distance
				best = spot
		_plan(best)
	return _steer(global_position)


## Decides whether to attack now, and with what. Sets `_attack` when it returns true.
func _pick_attack() -> bool:
	var distance: float = _get_target_distance()
	match data.attack_style:
		EnemyData.AttackStyle.LUNGE:
			_attack = Attack.LUNGE
			return distance <= data.attack_range and _is_target_level()
		EnemyData.AttackStyle.SLAM:
			if distance <= data.slam_trigger_distance and _is_target_level():
				_attack = Attack.SLAM
				return true
			_attack = Attack.CHARGE
			return (data.charge_cooldown > 0.0 and _charge_left <= 0.0
					and distance >= data.charge_min_distance and distance <= data.charge_max_distance
					and _is_target_level() and _is_ground_clear())
		EnemyData.AttackStyle.RANGED:
			# Too close means back off first; rushing a shooter shuts it down.
			_attack = Attack.SHOT
			return distance >= data.retreat_range and distance <= data.preferred_range and _can_see_target()
	return false


func _get_windup_time() -> float:
	return data.slam_windup if _attack == Attack.SLAM else data.attack_windup


func _finish_windup() -> void:
	acted.emit(self, &"attack")
	match _attack:
		Attack.LUNGE:
			_start_lunge()
		Attack.CHARGE:
			_charge_left = data.charge_cooldown
			collision_mask = _body_mask & ~charge_ignore_mask
			_start_lunge()
		Attack.SLAM:
			if _get_target_distance() <= data.slam_radius and _is_target_level():
				_strike(_get_direction_to(_target.global_position), data.slam_damage)
			_enter(State.RECOVER, data.slam_recover)
		Attack.SHOT:
			_shoot()
			_enter(State.RECOVER, data.attack_recover)


func _start_lunge() -> void:
	_lunge_direction = _get_direction_to(_target.global_position)
	_lunge_connected = false
	_enter(State.LUNGE, data.lunge_duration)


## The one place that decides where to walk: along a navigation route to `point`.
## At the end of the route it heads straight for `finish`, or for `point` when none is given.
func _walk_to(point: Vector3, delta: float, finish: Vector3 = Vector3.INF) -> Vector3:
	if _is_plan_due(delta):
		_plan(point)
	return _steer(point if finish == Vector3.INF else finish)


func _is_plan_due(delta: float) -> bool:
	_repath_left -= delta
	return _repath_left <= 0.0


func _plan(point: Vector3) -> void:
	_repath_left = randf_range(data.repath_interval_min, data.repath_interval_max)
	_path = NavigationServer3D.map_get_path(get_world_3d().navigation_map, global_position, point, true)
	# The first point is where we already stand.
	_path_index = 1
	_path_done = false


func _steer(finish: Vector3) -> Vector3:
	while _path_index < _path.size() and _get_flat_distance(_path[_path_index]) <= data.waypoint_reach:
		_path_index += 1
	if _path_index >= _path.size():
		_path_done = true
		return _get_direction_to(finish)
	return _get_direction_to(_path[_path_index])


func _get_aim_point() -> Vector3:
	var distance: float = _get_target_distance()
	if _flanking and distance > data.flank_radius + data.waypoint_reach:
		var side: Vector3 = Vector3(cos(_flank_bearing), 0.0, sin(_flank_bearing)) * data.flank_radius
		return _get_floor_point(_target.global_position + side)
	var lead_scale: float = clampf(distance / data.lead_falloff_distance, 0.0, 1.0)
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
	_refresh_mark()


func _refresh_mark() -> void:
	_mark.visible = _state != State.IDLE and _state != State.DYING
	var hunting: bool = _state == State.ALERTED or _state == State.SEARCH
	_mark.text = "?" if hunting else "!"
	_mark.modulate = data.alerted_color if hunting else data.engaged_color


func _get_lunge_damage() -> float:
	return data.charge_damage if _attack == Attack.CHARGE else data.attack_damage


func _strike(direction: Vector3, damage: float) -> void:
	if not _target.has_method(&"take_hit"):
		return
	var hit: HitInfo = HitInfo.new()
	hit.damage = damage * _damage_scale
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


func _update_feedback(delta: float) -> void:
	var winding_up: bool = _state == State.WINDUP
	var raising_arms: bool = winding_up and _attack == Attack.SLAM

	var resting: Color = data.windup_color if winding_up else data.body_color
	var weight: float = 1.0 - exp(-data.flash_fade_speed * delta)
	_material.albedo_color = _material.albedo_color.lerp(resting, weight)

	var squash: float = data.windup_squash if winding_up and not raising_arms else 1.0
	_visual.scale.y = lerpf(_visual.scale.y, squash, 1.0 - exp(-20.0 * delta))

	# Face the target, the way it is hurtling, or the way it is walking.
	var facing: Vector3 = _get_direction_to(_target.global_position)
	if _state == State.LUNGE:
		facing = _lunge_direction
	elif not is_engaged():
		facing = Vector3(_move_velocity.x, 0.0, _move_velocity.z).normalized()
	var can_turn: bool = data.turn_while_recovering or _state != State.RECOVER
	if _state == State.SEARCH and facing.is_zero_approx():
		# Standing still, it looks around.
		_visual.rotation.y += data.turn_speed * 0.2 * delta
	elif can_turn and not facing.is_zero_approx():
		var yaw: float = atan2(-facing.x, -facing.z)
		_visual.rotation.y = lerp_angle(_visual.rotation.y, yaw, 1.0 - exp(-data.turn_speed * delta))
	_weak_point_pivot.rotation.y = _visual.rotation.y
	_refresh_weak_points()

	if _arms != null:
		var arm_target: float = deg_to_rad(data.arm_raise_degrees) if raising_arms else 0.0
		var arm_speed: float = data.arm_raise_speed if raising_arms else data.arm_slam_speed
		_arms.rotation.x = lerpf(_arms.rotation.x, arm_target, 1.0 - exp(-arm_speed * delta))


func _refresh_weak_points() -> void:
	var attacking: bool = _state == State.WINDUP or _state == State.RECOVER
	for weak_point: Hitbox in _weak_points:
		weak_point.set_exposed(weak_point.exposure == Hitbox.Exposure.ALWAYS or attacking)


func _die(hit: HitInfo) -> void:
	_enter(State.DYING, data.pop_time)
	collision_layer = 0
	collision_mask = 0
	for weak_point: Hitbox in _weak_points:
		weak_point.set_exposed(false)
	_material.albedo_color = data.hit_flash_color
	died.emit(self, hit)


func _tick_pop(delta: float) -> void:
	_state_left -= delta
	if _state_left <= 0.0:
		released.emit()
		return
	var progress: float = 1.0 - _state_left / data.pop_time
	_visual.scale = Vector3.ONE * lerpf(1.0, data.pop_scale, progress)
