class_name Player
extends CharacterBody3D

@export var data: PlayerData

var _pitch: float = 0.0
var _dash_time_left: float = 0.0
var _dash_cooldown_left: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO

@onready var _intent: PlayerIntent = $Intent
@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera3D


func _ready() -> void:
	_camera.fov = data.base_fov


func _process(delta: float) -> void:
	_apply_look()
	_update_fov(delta)


func _physics_process(delta: float) -> void:
	_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)

	var wish_direction: Vector3 = _get_wish_direction()
	if _intent.consume_dash() and _dash_cooldown_left <= 0.0:
		_start_dash(wish_direction)

	if is_dashing():
		_dash_time_left = maxf(_dash_time_left - delta, 0.0)
		velocity.x = _dash_direction.x * data.dash_speed
		velocity.z = _dash_direction.z * data.dash_speed
	else:
		_apply_ground_movement(wish_direction, delta)

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity += get_gravity() * delta

	move_and_slide()


func is_dashing() -> bool:
	return _dash_time_left > 0.0


## Dash grants i-frames for its whole duration.
func is_invulnerable() -> bool:
	return is_dashing()


## 0.0 just after dashing, 1.0 when the dash is ready.
func get_dash_charge() -> float:
	if data.dash_cooldown <= 0.0:
		return 1.0
	return 1.0 - _dash_cooldown_left / data.dash_cooldown


func _get_wish_direction() -> Vector3:
	var move: Vector2 = _intent.get_move()
	var direction: Vector3 = global_basis * Vector3(move.x, 0.0, move.y)
	direction.y = 0.0
	return direction.limit_length(1.0)


func _start_dash(wish_direction: Vector3) -> void:
	_dash_direction = wish_direction.normalized()
	if _dash_direction.is_zero_approx():
		_dash_direction = -global_basis.z
	_dash_time_left = data.dash_duration
	_dash_cooldown_left = data.dash_cooldown


func _apply_ground_movement(wish_direction: Vector3, delta: float) -> void:
	var top_speed: float = data.sprint_speed if _intent.is_sprinting() else data.walk_speed
	var target: Vector3 = wish_direction * top_speed
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var rate: float = data.deceleration if wish_direction.is_zero_approx() else data.acceleration
	horizontal = horizontal.move_toward(target, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _apply_look() -> void:
	var look: Vector2 = _intent.consume_look()
	if look.is_zero_approx():
		return
	rotate_y(-look.x * data.mouse_sensitivity)
	var max_pitch: float = deg_to_rad(data.max_pitch_degrees)
	_pitch = clampf(_pitch - look.y * data.mouse_sensitivity, -max_pitch, max_pitch)
	_head.rotation.x = _pitch


func _update_fov(delta: float) -> void:
	var target_fov: float = data.base_fov
	if is_dashing():
		target_fov += data.dash_fov_bonus
	elif _intent.is_sprinting() and not _intent.get_move().is_zero_approx():
		target_fov += data.sprint_fov_bonus
	var weight: float = 1.0 - exp(-data.fov_lerp_speed * delta)
	_camera.fov = lerpf(_camera.fov, target_fov, weight)
