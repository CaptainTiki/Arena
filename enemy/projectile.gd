class_name Projectile
extends Node3D
## Pooled enemy shot. Has no collision shape; it sweeps a ray along its path each tick.

## Returns the projectile to its pool.
signal released

@export var lifetime: float = 4.0
@export_flags_3d_physics var hit_mask: int = 3

var _velocity: Vector3 = Vector3.ZERO
var _damage: float = 0.0
var _source: Node
var _life_left: float = 0.0


func launch(origin: Vector3, shot_velocity: Vector3, damage: float, source: Node) -> void:
	global_position = origin
	_velocity = shot_velocity
	_damage = damage
	_source = source
	_life_left = lifetime


func _physics_process(delta: float) -> void:
	_life_left -= delta
	if _life_left <= 0.0:
		released.emit()
		return

	var next_position: Vector3 = global_position + _velocity * delta
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			global_position, next_position, hit_mask)
	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		global_position = next_position
		return

	var collider: Object = result[&"collider"]
	if collider.has_method(&"take_hit"):
		var hit: HitInfo = HitInfo.new()
		hit.damage = _damage
		hit.position = result[&"position"]
		hit.normal = result[&"normal"]
		hit.direction = _velocity.normalized()
		hit.target = collider as Node
		hit.source = _source
		collider.call(&"take_hit", hit)
	released.emit()
