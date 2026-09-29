@tool
class_name HoldZone
extends Area3D
## A marked patch of floor. Standing in the active one earns standing with whoever pays for holding ground.
## The node sits at floor level; the zone extends upward from it.

@export var size: Vector3 = Vector3(12.0, 3.0, 8.0):
	set(value):
		size = value
		_apply()
@export var color: Color = Color(1.0, 0.85, 0.2):
	set(value):
		color = value
		_apply()
@export_range(0.0, 1.0) var floor_alpha: float = 0.35

var _active: bool = true


func _ready() -> void:
	_apply()


func set_active(active: bool) -> void:
	_active = active
	visible = active
	monitoring = active


func is_active() -> bool:
	return _active


func is_occupied() -> bool:
	return _active and has_overlapping_bodies()


func _apply() -> void:
	if not is_node_ready():
		return
	var collision: CollisionShape3D = $CollisionShape3D
	var floor_mesh: MeshInstance3D = $FloorMarker
	var beacon: MeshInstance3D = $Beacon
	var label: Label3D = $Label
	(collision.shape as BoxShape3D).size = size
	collision.position = Vector3(0.0, size.y * 0.5, 0.0)
	(floor_mesh.mesh as BoxMesh).size = Vector3(size.x, 0.04, size.z)
	(floor_mesh.material_override as StandardMaterial3D).albedo_color = Color(color, floor_alpha)
	(beacon.material_override as StandardMaterial3D).albedo_color = color
	label.modulate = color
