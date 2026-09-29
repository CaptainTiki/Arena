class_name PodDropper
extends Node3D
## Lands pods on reachable floor, away from the player, so collecting one means moving.

signal pod_landed(pod: Pod)
signal pod_collected(pod_data: PodData, sponsor: SponsorData)

## Pods land at least this far from the player when any such spot exists.
@export var min_player_distance: float = 28.0
@export var max_attempts: int = 16
@export_flags_3d_physics var floor_mask: int = 1

## Set by the owner.
var target: Node3D

@onready var _pool: ScenePool = $Pool


func _ready() -> void:
	for child: Node in _pool.get_children():
		var pod: Pod = child as Pod
		pod.landed.connect(_on_pod_landed)
		pod.collected.connect(_on_pod_collected)


func drop(pod_data: PodData, sponsor: SponsorData) -> void:
	var pod: Pod = _pool.acquire() as Pod
	if pod == null:
		return
	pod.drop(_pick_point(), pod_data, sponsor)


## True while a pod with this effect is falling or waiting on the floor.
func has_active_effect(effect: PodData.Effect) -> bool:
	for child: Node in _pool.get_children():
		var pod: Pod = child as Pod
		if pod.process_mode != Node.PROCESS_MODE_DISABLED and pod.pod_data.effect == effect:
			return true
	return false


func _pick_point() -> Vector3:
	var map: RID = get_world_3d().navigation_map
	var origin: Vector3 = target.global_position
	var best: Vector3 = origin
	var best_distance: float = -1.0
	for i: int in max_attempts:
		var point: Vector3 = NavigationServer3D.map_get_random_point(map, 1, true)
		# Rooftops and crate tops have navigation too; skip anything the player can't walk to.
		var path: PackedVector3Array = NavigationServer3D.map_get_path(map, origin, point, true)
		if path.is_empty() or path[-1].distance_to(point) > 1.0:
			continue
		var distance: float = Vector2(point.x - origin.x, point.z - origin.z).length()
		if distance >= min_player_distance:
			return _snap_to_floor(point)
		if distance > best_distance:
			best_distance = distance
			best = point
	return _snap_to_floor(best)


func _snap_to_floor(point: Vector3) -> Vector3:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			point + Vector3.UP, point + Vector3.DOWN * 3.0, floor_mask)
	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return point
	return result[&"position"]


func _on_pod_landed(pod: Pod) -> void:
	pod_landed.emit(pod)


func _on_pod_collected(pod: Pod) -> void:
	pod_collected.emit(pod.pod_data, pod.sponsor)
