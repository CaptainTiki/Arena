class_name ScenePool
extends Node
## Pre-instances a scene and hands instances out. Instances that declare a
## `released` signal are returned to the pool when they emit it.

@export var scene: PackedScene
@export var size: int = 16
## When the pool is dry, take back the oldest active instance instead of returning null.
@export var recycle_oldest: bool = false

var _free: Array[Node] = []
var _active: Array[Node] = []


func _ready() -> void:
	for i: int in size:
		var instance: Node = scene.instantiate()
		add_child(instance)
		if instance.has_signal(&"released"):
			instance.connect(&"released", release.bind(instance))
		_set_active(instance, false)
		_free.append(instance)


func acquire() -> Node:
	var instance: Node
	if not _free.is_empty():
		instance = _free.pop_back()
	elif recycle_oldest and not _active.is_empty():
		instance = _active.pop_front()
	else:
		return null
	_active.append(instance)
	_set_active(instance, true)
	return instance


func release(instance: Node) -> void:
	if not _active.has(instance):
		return
	_active.erase(instance)
	_set_active(instance, false)
	_free.append(instance)


func get_active_count() -> int:
	return _active.size()


func _set_active(instance: Node, active: bool) -> void:
	instance.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if instance is Node3D:
		(instance as Node3D).visible = active
	elif instance is CanvasItem:
		(instance as CanvasItem).visible = active
