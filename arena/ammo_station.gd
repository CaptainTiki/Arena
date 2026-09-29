class_name AmmoStation
extends StaticBody3D
## Fixed ammo dispenser. Red when empty, flashing amber when a restock is close, green when stocked.
## Walk up to a stocked one to take its ammo.

signal collected(station: AmmoStation)

@export var data: AmmoStationData
## Seconds until this station's first stock. Zero means stocked from the start.
## Give each station a different value so they don't all restock together.
@export var first_stock_delay: float = 0.0

var _stocked: bool = false
var _restock_left: float = 0.0

@onready var _pickup_area: Area3D = $PickupArea
@onready var _light: MeshInstance3D = $Light
@onready var _pickup_mesh: MeshInstance3D = $Pickup
@onready var _material: StandardMaterial3D = _light.material_override as StandardMaterial3D


func _ready() -> void:
	_restock_left = first_stock_delay
	_stocked = first_stock_delay <= 0.0
	_refresh()


func is_stocked() -> bool:
	return _stocked


func get_ammo() -> int:
	return data.ammo


func _physics_process(delta: float) -> void:
	if _stocked:
		for body: Node3D in _pickup_area.get_overlapping_bodies():
			if body is Player:
				_stocked = false
				_restock_left = data.restock_time
				collected.emit(self)
				break
	else:
		_restock_left -= delta
		if _restock_left <= 0.0:
			_stocked = true
	_refresh()


func _refresh() -> void:
	_pickup_mesh.visible = _stocked
	if _stocked:
		_material.albedo_color = data.stocked_color
	elif _restock_left <= data.warning_time:
		var lit: bool = fmod(_restock_left * data.flash_rate, 1.0) < 0.5
		_material.albedo_color = data.warning_color if lit else data.dark_color
	else:
		_material.albedo_color = data.empty_color
