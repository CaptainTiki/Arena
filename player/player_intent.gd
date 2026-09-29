class_name PlayerIntent
extends Node
## The only place input is read. Everything else asks this node what the player wants.

var _look_accum: Vector2 = Vector2.ZERO
var _dash_queued: bool = false
var _fire_queued: bool = false
var _reload_queued: bool = false
var _slot_queued: int = -1
var _cycle_queued: bool = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	if not is_active():
		if event is InputEventMouseButton and event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event is InputEventMouseMotion:
		_look_accum += (event as InputEventMouseMotion).screen_relative
	elif event.is_action_pressed(&"dash"):
		_dash_queued = true
	elif event.is_action_pressed(&"fire"):
		_fire_queued = true
	elif event.is_action_pressed(&"reload"):
		_reload_queued = true
	elif event.is_action_pressed(&"weapon_1"):
		_slot_queued = 0
	elif event.is_action_pressed(&"weapon_2"):
		_slot_queued = 1
	elif event.is_action_pressed(&"weapon_3"):
		_slot_queued = 2
	elif event.is_action_pressed(&"weapon_next"):
		_cycle_queued = true


## False while the mouse is released; all intents read as idle.
func is_active() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


## X is strafe (right positive), Y is forward/back (back positive).
func get_move() -> Vector2:
	if not is_active():
		return Vector2.ZERO
	return Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")


func is_sprinting() -> bool:
	return is_active() and Input.is_action_pressed(&"sprint")


func consume_look() -> Vector2:
	var look: Vector2 = _look_accum
	_look_accum = Vector2.ZERO
	return look


func consume_dash() -> bool:
	var queued: bool = _dash_queued
	_dash_queued = false
	return queued


func consume_fire() -> bool:
	var queued: bool = _fire_queued
	_fire_queued = false
	return queued


func consume_reload() -> bool:
	var queued: bool = _reload_queued
	_reload_queued = false
	return queued


## The number key pressed, counting from zero, or -1 for none. A weapon slot in a fight, a menu choice outside one.
func consume_weapon_slot() -> int:
	var queued: int = _slot_queued
	_slot_queued = -1
	return queued


func consume_weapon_cycle() -> bool:
	var queued: bool = _cycle_queued
	_cycle_queued = false
	return queued
