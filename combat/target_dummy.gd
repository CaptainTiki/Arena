class_name TargetDummy
extends StaticBody3D
## Stand-in damageable for testing the weapon before real enemies exist.

@export var max_health: float = 30.0
@export var respawn_delay: float = 2.0
@export var flash_color: Color = Color(1.0, 1.0, 1.0)
@export var flash_fade_speed: float = 8.0

var _health: float = 0.0
var _respawn_left: float = 0.0
var _body_layer: int = 0
var _head_layer: int = 0
var _base_color: Color

@onready var _head: Hitbox = $Head
@onready var _body_mesh: MeshInstance3D = $BodyMesh
@onready var _material: StandardMaterial3D = _body_mesh.material_override as StandardMaterial3D


func _ready() -> void:
	_health = max_health
	_body_layer = collision_layer
	_head_layer = _head.collision_layer
	_base_color = _material.albedo_color


func _process(delta: float) -> void:
	if _respawn_left > 0.0:
		_respawn_left -= delta
		if _respawn_left <= 0.0:
			_respawn()
		return
	var weight: float = 1.0 - exp(-flash_fade_speed * delta)
	_material.albedo_color = _material.albedo_color.lerp(_base_color, weight)


func take_hit(hit: HitInfo) -> void:
	if _respawn_left > 0.0:
		return
	_health -= hit.damage
	_material.albedo_color = flash_color
	print("%s took %.0f%s, health %.0f" % [name, hit.damage, " HEADSHOT" if hit.is_headshot else "", _health])
	if _health <= 0.0:
		_die()


func _die() -> void:
	print("%s killed" % name)
	visible = false
	collision_layer = 0
	_head.collision_layer = 0
	_respawn_left = respawn_delay


func _respawn() -> void:
	_health = max_health
	_material.albedo_color = _base_color
	visible = true
	collision_layer = _body_layer
	_head.collision_layer = _head_layer
