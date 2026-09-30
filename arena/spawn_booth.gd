class_name SpawnBooth
extends Marker3D
## A gate at the edge of the arena. Enemies that arrive during a fight come in through one,
## and its light comes on as they do.

@export var lit_color: Color = Color(1.0, 0.3, 0.1)
@export var dark_color: Color = Color(0.12, 0.12, 0.12)
## Seconds the light stays on after someone comes through.
@export var lit_time: float = 2.0

var _lit_left: float = 0.0

@onready var _light: MeshInstance3D = $Light
@onready var _material: StandardMaterial3D = _light.material_override as StandardMaterial3D


func _ready() -> void:
	_material.albedo_color = dark_color
	set_process(false)


func open() -> void:
	_lit_left = lit_time
	_material.albedo_color = lit_color
	set_process(true)


func _process(delta: float) -> void:
	_lit_left -= delta
	if _lit_left <= 0.0:
		_material.albedo_color = dark_color
		set_process(false)
