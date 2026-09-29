class_name Enemy
extends CharacterBody3D
## Pooled melee grunt. Runs at its target, winds up, lunges.

## Returns the enemy to its pool.
signal released
signal died(enemy: Enemy, hit: HitInfo)

enum State { CHASE, WINDUP, LUNGE, RECOVER, DYING }

@export var data: EnemyData

var _target: Node3D
var _state: State = State.CHASE
var _state_left: float = 0.0
var _health: float = 0.0
var _speed: float = 0.0
var _lead_time: float = 0.0
var _move_velocity: Vector3 = Vector3.ZERO
var _knockback: Vector3 = Vector3.ZERO
var _lunge_direction: Vector3 = Vector3.ZERO
var _lunge_connected: bool = false
var _body_layer: int = 0
var _body_mask: int = 0
var _head_layer: int = 0

@onready var _head: Hitbox = $Head
@onready var _visual: Node3D = $Visual
@onready var _body_mesh: MeshInstance3D = $Visual/BodyMesh
@onready var _material: StandardMaterial3D = _body_mesh.material_override as StandardMaterial3D


func _ready() -> void:
	_body_layer = collision_layer
	_body_mask = collision_mask
	_head_layer = _head.collision_layer


func spawn(at: Vector3, target: Node3D) -> void:
	_target = target
	_state = State.CHASE
	_health = data.max_health
	_speed = data.move_speed * randf_range(1.0 - data.speed_variance, 1.0 + data.speed_variance)
	_lead_time = randf_range(0.0, data.lead_time_max)
	_move_velocity = Vector3.ZERO
	_knockback = Vector3.ZERO
	velocity = Vector3.ZERO
	global_position = at
	collision_layer = _body_layer
	collision_mask = _body_mask
	_head.collision_layer = _head_layer
	_visual.scale = Vector3.ONE
	_material.albedo_color = data.body_color


func is_alive() -> bool:
	return _state != State.DYING


func take_hit(hit: HitInfo) -> void:
	if not is_alive():
		return
	_health -= hit.damage
	_material.albedo_color = data.hit_flash_color
	var shove: Vector3 = Vector3(hit.direction.x, 0.0, hit.direction.z).normalized()
	_knockback += shove * hit.knockback
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
			wish_velocity = _get_move_direction() * _speed
			if _get_target_distance() <= data.attack_range:
				_enter(State.WINDUP, data.attack_windup)
		State.WINDUP:
			_state_left -= delta
			if _state_left <= 0.0:
				_lunge_direction = _get_direction_to(_target.global_position)
				_lunge_connected = false
				_enter(State.LUNGE, data.lunge_duration)
		State.LUNGE:
			_state_left -= delta
			_move_velocity = _lunge_direction * data.lunge_speed
			wish_velocity = _move_velocity
			if not _lunge_connected and _get_target_distance() <= data.attack_reach:
				_lunge_connected = true
				_strike()
			if _state_left <= 0.0:
				_move_velocity = Vector3.ZERO
				wish_velocity = Vector3.ZERO
				_enter(State.RECOVER, data.attack_recover)
		State.RECOVER:
			_state_left -= delta
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


## The one place that decides where to walk. Swap for navigation when the arena grows cover.
func _get_move_direction() -> Vector3:
	var aim_point: Vector3 = _target.global_position
	if _target is CharacterBody3D:
		var target_velocity: Vector3 = (_target as CharacterBody3D).velocity
		target_velocity.y = 0.0
		var lead_scale: float = clampf(_get_target_distance() / data.lead_falloff_distance, 0.0, 1.0)
		aim_point += target_velocity * _lead_time * lead_scale
	return _get_direction_to(aim_point)


func _get_direction_to(point: Vector3) -> Vector3:
	var to_point: Vector3 = point - global_position
	to_point.y = 0.0
	return to_point.normalized()


func _get_target_distance() -> float:
	var to_target: Vector3 = _target.global_position - global_position
	to_target.y = 0.0
	return to_target.length()


func _enter(state: State, duration: float) -> void:
	_state = state
	_state_left = duration


func _strike() -> void:
	if not _target.has_method(&"take_hit"):
		return
	var hit: HitInfo = HitInfo.new()
	hit.damage = data.attack_damage
	hit.position = _target.global_position
	hit.direction = _lunge_direction
	hit.target = _target
	hit.source = self
	_target.call(&"take_hit", hit)


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
	died.emit(self, hit)


func _tick_pop(delta: float) -> void:
	_state_left -= delta
	if _state_left <= 0.0:
		released.emit()
		return
	var progress: float = 1.0 - _state_left / data.pop_time
	_visual.scale = Vector3.ONE * lerpf(1.0, data.pop_scale, progress)
