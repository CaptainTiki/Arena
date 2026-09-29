@tool
class_name Block
extends StaticBody3D
## Greybox building block: a solid flat-color box. Set the size here instead of scaling the node.

@export var size: Vector3 = Vector3(2.0, 2.0, 2.0):
	set(value):
		size = value
		_apply()
@export var color: Color = Color(0.5, 0.5, 0.5):
	set(value):
		color = value
		_apply()


func _ready() -> void:
	_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	var collision: CollisionShape3D = $CollisionShape3D
	var mesh_instance: MeshInstance3D = $MeshInstance3D
	(collision.shape as BoxShape3D).size = size
	(mesh_instance.mesh as BoxMesh).size = size
	(mesh_instance.material_override as StandardMaterial3D).albedo_color = color
