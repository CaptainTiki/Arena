class_name Level
extends NavigationRegion3D
## The arena's geometry. Bakes its own navigation mesh on load, so moving or
## adding Blocks in the editor never needs a manual rebake.

@onready var _spawn_points_root: Node3D = $SpawnPoints
@onready var _hold_zones_root: Node3D = $HoldZones


func _ready() -> void:
	bake_navigation_mesh(false)


## In the order the active zone rotates through them.
func get_hold_zones() -> Array[HoldZone]:
	var zones: Array[HoldZone] = []
	for child: Node in _hold_zones_root.get_children():
		if child is HoldZone:
			zones.append(child as HoldZone)
	return zones


func get_spawn_points() -> Array[Marker3D]:
	var points: Array[Marker3D] = []
	for child: Node in _spawn_points_root.get_children():
		if child is Marker3D:
			points.append(child as Marker3D)
	return points
