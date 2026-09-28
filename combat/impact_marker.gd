class_name ImpactMarker
extends MeshInstance3D
## Flat-color cube that marks where a shot landed, then shrinks away.

signal released

@export var lifetime: float = 0.6
@export var world_color: Color = Color(0.9, 0.9, 0.9)
@export var body_color: Color = Color(1.0, 0.2, 0.2)
@export var head_color: Color = Color(1.0, 0.9, 0.1)

var _time_left: float = 0.0

@onready var _material: StandardMaterial3D = material_override as StandardMaterial3D


func play(hit: HitInfo) -> void:
	global_position = hit.position
	scale = Vector3.ONE
	_time_left = lifetime
	if not hit.landed():
		_material.albedo_color = world_color
	elif hit.is_headshot:
		_material.albedo_color = head_color
	else:
		_material.albedo_color = body_color


func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		released.emit()
		return
	scale = Vector3.ONE * (_time_left / lifetime)
