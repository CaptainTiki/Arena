class_name Game
extends Node
## Top of the ownership spine. Owns the base and the fight, one at a time, and swaps between them.

@export var catalog: Catalog
@export var base_scene: PackedScene
@export var arena_scene: PackedScene
## Where favour, cash and everything owned are kept.
@export var profile_path: String = "user://profile.cfg"

var _base: Base
var _arena: Arena


func _ready() -> void:
	_enter_base()


func get_base() -> Base:
	return _base


func get_arena() -> Arena:
	return _arena


func _enter_base() -> void:
	if _arena != null:
		_arena.queue_free()
		_arena = null
	_base = base_scene.instantiate() as Base
	_base.catalog = catalog
	_base.profile_path = profile_path
	_base.contract_booked.connect(_on_contract_booked)
	add_child(_base)


func _on_contract_booked(contract: ContractData) -> void:
	_base.queue_free()
	_base = null
	_arena = arena_scene.instantiate() as Arena
	_arena.catalog = catalog
	_arena.profile_path = profile_path
	_arena.contract = contract
	_arena.finished.connect(_enter_base)
	# Deferred: the booking arrives from inside the base's own frame.
	add_child.call_deferred(_arena)
