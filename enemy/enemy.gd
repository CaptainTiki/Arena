class_name Enemy
extends CharacterBody3D
## Pooled melee grunt. Runs at its target, winds up, swings.

## Returns the enemy to its pool.
signal released
signal died(enemy: Enemy, hit: HitInfo)

enum State { CHASE, WINDUP, RECOVER, DYING }

@export var data: EnemyData

var _target: Node3D
var _state: State = State.CHASE
var _state_left: float = 0.0
var _health: float = 0.0
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
	if _health <= 0.0:
		_die(hit)


func _physics_process(delta: float) -> void:
	if _state == State.DYING:
		_tick_pop(delta)
		return

	var wish_velocity: Vector3 = Vector3.ZERO
	match _state:
		State.CHASE:
			wish_velocity = _get_move_direction() * data.move_speed
			if _get_target_distance() <= data.attack_range:
				_enter(State.WINDUP, data.attack_windup)
		State.WINDUP:
			_state_left -= delta
			if _state_left <= 0.0:
				_swing()
				_enter(State.RECOVER, data.attack_recover)
		State.RECOVER:
			_state_left -= delta
			if _state_left <= 0.0:
				_enter(State.CHASE, 0.0)

	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(wish_velocity, data.acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity += get_gravity() * delta
	move_and_slide()

	_update_color(delta)


## The one place that decides where to walk. Swap for navigation when the arena grows cover.
func _get_move_direction() -> Vector3:
	var to_target: Vector3 = _target.global_position - global_position
	to_target.y = 0.0
	return to_target.normalized()


func _get_target_distance() -> float:
	var to_target: Vector3 = _target.global_position - global_position
	to_target.y = 0.0
	return to_target.length()


func _enter(state: State, duration: float) -> void:
	_state = state
	_state_left = duration


func _swing() -> void:
	if _get_target_distance() > data.attack_reach or not _target.has_method(&"take_hit"):
		return
	var hit: HitInfo = HitInfo.new()
	hit.damage = data.attack_damage
	hit.position = _target.global_position
	hit.direction = _get_move_direction()
	hit.target = _target
	hit.source = self
	_target.call(&"take_hit", hit)


func _update_color(delta: float) -> void:
	var resting: Color = data.windup_color if _state == State.WINDUP else data.body_color
	var weight: float = 1.0 - exp(-data.flash_fade_speed * delta)
	_material.albedo_color = _material.albedo_color.lerp(resting, weight)


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
