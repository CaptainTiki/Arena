class_name Pod
extends Area3D
## Pooled reward. Falls from the sky, waits under a beacon, and is collected by walking into it.

## Returns the pod to its pool.
signal released
signal landed(pod: Pod)
signal collected(pod: Pod)

@export var fall_height: float = 45.0
@export var fall_speed: float = 35.0
## The pod blinks for this long before it despawns.
@export var blink_time: float = 6.0
@export var blink_rate: float = 6.0
@export var neutral_color: Color = Color(0.9, 0.9, 0.9)

var pod_data: PodData
## Null for drops that no sponsor paid for.
var sponsor: SponsorData

var _falling: bool = false
var _ground_y: float = 0.0
var _life_left: float = 0.0

@onready var _visual: Node3D = $Visual
@onready var _body_mesh: MeshInstance3D = $Visual/Body
@onready var _beacon_mesh: MeshInstance3D = $Visual/Beacon
@onready var _label: Label3D = $Visual/Label


func drop(at: Vector3, data: PodData, from_sponsor: SponsorData) -> void:
	pod_data = data
	sponsor = from_sponsor
	var color: Color = neutral_color if sponsor == null else sponsor.color
	(_body_mesh.material_override as StandardMaterial3D).albedo_color = color
	(_beacon_mesh.material_override as StandardMaterial3D).albedo_color = color
	_label.modulate = color
	_label.text = data.display_name
	_ground_y = at.y
	global_position = at + Vector3.UP * fall_height
	_falling = true
	_life_left = data.lifetime
	_visual.visible = true


func is_landed() -> bool:
	return not _falling


func _physics_process(delta: float) -> void:
	if _falling:
		global_position.y -= fall_speed * delta
		if global_position.y <= _ground_y:
			global_position.y = _ground_y
			_falling = false
			landed.emit(self)
		return

	for body: Node3D in get_overlapping_bodies():
		if body is Player:
			collected.emit(self)
			released.emit()
			return

	_life_left -= delta
	if _life_left <= 0.0:
		released.emit()
	elif _life_left <= blink_time:
		_visual.visible = fmod(_life_left * blink_rate, 1.0) < 0.5
