class_name Level
extends NavigationRegion3D
## The arena's geometry. Bakes its own navigation mesh on load, so moving or
## adding Blocks in the editor never needs a manual rebake.

@onready var _spawn_points_root: Node3D = $SpawnPoints


func _ready() -> void:
	bake_navigation_mesh(false)


func get_spawn_points() -> Array[Marker3D]:
	var points: Array[Marker3D] = []
	for child: Node in _spawn_points_root.get_children():
		if child is Marker3D:
			points.append(child as Marker3D)
	return points
