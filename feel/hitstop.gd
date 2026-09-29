class_name Hitstop
extends Node
## Briefly slows the whole game. Timed in real milliseconds so the freeze can't stall itself.
## Must run with process mode Always.

var _until_msec: int = 0


func _ready() -> void:
	set_process(false)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func trigger(duration: float, time_scale: float) -> void:
	if duration <= 0.0:
		return
	Engine.time_scale = time_scale
	_until_msec = maxi(_until_msec, Time.get_ticks_msec() + int(duration * 1000.0))
	set_process(true)


func is_active() -> bool:
	return is_processing()


func _process(_delta: float) -> void:
	if Time.get_ticks_msec() >= _until_msec:
		Engine.time_scale = 1.0
		set_process(false)
