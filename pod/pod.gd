class_name Pod
extends Area3D
## Pooled reward. Drifts down under a canopy, lands, lights its beacon, and is collected by walking into it.

## Returns the pod to its pool.
signal released
signal landed(pod: Pod)
signal collected(pod: Pod)

@export_group("Descent")
## Each pod rolls how long it takes to come down.
@export var descent_time_min: float = 15.0
@export var descent_time_max: float = 20.0
@export var start_height: float = 40.0
## How far off its landing spot the pod can wander on the way down. Shrinks to nothing as it lands.
@export var drift_radius: float = 14.0
## How many times it swings across during the descent, rolled per axis in this range.
@export var drift_swings_min: float = 1.0
@export var drift_swings_max: float = 2.5

@export_group("On The Ground")
## The pod blinks for this long before it despawns.
@export var blink_time: float = 6.0
@export var blink_rate: float = 6.0
@export var neutral_color: Color = Color(0.9, 0.9, 0.9)

var pod_data: PodData
## Null for drops that no sponsor paid for.
var sponsor: SponsorData

var _falling: bool = false
var _landing_point: Vector3 = Vector3.ZERO
var _descent_time: float = 0.0
var _descent_elapsed: float = 0.0
var _swings: Vector2 = Vector2.ZERO
var _phases: Vector2 = Vector2.ZERO
var _life_left: float = 0.0

@onready var _visual: Node3D = $Visual
@onready var _body_mesh: MeshInstance3D = $Visual/Body
@onready var _canopy: Node3D = $Visual/Canopy
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

	_landing_point = at
	_descent_time = randf_range(descent_time_min, descent_time_max)
	_descent_elapsed = 0.0
	_swings = Vector2(
			randf_range(drift_swings_min, drift_swings_max),
			randf_range(drift_swings_min, drift_swings_max))
	_phases = Vector2(randf_range(0.0, TAU), randf_range(0.0, TAU))
	_falling = true
	_life_left = data.lifetime

	# Nothing marks the spot until it is down. Watch the sky.
	_visual.visible = true
	_canopy.visible = true
	_beacon_mesh.visible = false
	_label.visible = false
	global_position = _get_descent_position(0.0)


func is_landed() -> bool:
	return not _falling


func _physics_process(delta: float) -> void:
	if _falling:
		_descent_elapsed += delta
		var progress: float = _descent_elapsed / _descent_time
		if progress >= 1.0:
			_land()
		else:
			global_position = _get_descent_position(progress)
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


func _get_descent_position(progress: float) -> Vector3:
	var remaining: float = 1.0 - progress
	var sway: Vector3 = Vector3(
			sin(progress * TAU * _swings.x + _phases.x), 0.0,
			sin(progress * TAU * _swings.y + _phases.y))
	return _landing_point + sway * drift_radius * remaining + Vector3.UP * start_height * remaining


func _land() -> void:
	global_position = _landing_point
	_falling = false
	_canopy.visible = false
	_beacon_mesh.visible = true
	_label.visible = true
	landed.emit(self)
