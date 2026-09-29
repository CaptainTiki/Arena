class_name DamageNumber
extends Label3D
## Floating number that rises from a hit and fades.

signal released

@export var lifetime: float = 0.7
@export var rise_speed: float = 1.8
@export var scatter: float = 0.25
@export var body_color: Color = Color(1.0, 1.0, 1.0)
@export var head_color: Color = Color(1.0, 0.9, 0.1)
@export var kill_color: Color = Color(1.0, 0.3, 0.2)
@export var head_scale: float = 1.4
@export var kill_scale: float = 1.8

var _time_left: float = 0.0


func play(hit: HitInfo) -> void:
	text = str(roundi(hit.damage))
	global_position = hit.position + Vector3(
			randf_range(-scatter, scatter), randf_range(0.0, scatter), randf_range(-scatter, scatter))
	_time_left = lifetime
	if hit.killed:
		modulate = kill_color
		scale = Vector3.ONE * kill_scale
	elif hit.is_headshot:
		modulate = head_color
		scale = Vector3.ONE * head_scale
	else:
		modulate = body_color
		scale = Vector3.ONE
	outline_modulate.a = 1.0


func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		released.emit()
		return
	position.y += rise_speed * delta
	var alpha: float = clampf(_time_left / (lifetime * 0.5), 0.0, 1.0)
	modulate.a = alpha
	outline_modulate.a = alpha
