class_name AmmoStation
extends StaticBody3D
## Fixed dispenser that stocks either ammo or health, rolled afresh at every restock.
## The light says which: blue for ammo, red for health. Steady means stocked, flashing means
## arriving soon, and no light means there is nothing here and nothing on the way.
## Walk up to a stocked one to take what it holds.

signal collected(station: AmmoStation)

enum Stock { AMMO, HEALTH }

@export var data: AmmoStationData
## Seconds until this station's first stock. Zero means stocked from the start.
## Give each station a different value so they don't all restock together.
@export var first_stock_delay: float = 0.0

var _stocked: bool = false
var _restock_left: float = 0.0
## What it holds, or what is on the way while it is empty.
var _stock: Stock = Stock.AMMO

@onready var _pickup_area: Area3D = $PickupArea
@onready var _light: MeshInstance3D = $Light
@onready var _pickup_mesh: MeshInstance3D = $Pickup
@onready var _material: StandardMaterial3D = _light.material_override as StandardMaterial3D
@onready var _pickup_material: StandardMaterial3D = _pickup_mesh.material_override as StandardMaterial3D


func _ready() -> void:
	_restock_left = first_stock_delay
	_stocked = first_stock_delay <= 0.0
	_roll_stock()
	_refresh()


func is_stocked() -> bool:
	return _stocked


func get_stock() -> Stock:
	return _stock


func get_color() -> Color:
	return data.health_color if _stock == Stock.HEALTH else data.ammo_color


func _physics_process(delta: float) -> void:
	if _stocked:
		for body: Node3D in _pickup_area.get_overlapping_bodies():
			if body is Player and _is_wanted_by(body as Player):
				_stocked = false
				_restock_left = data.restock_time
				collected.emit(self)
				_roll_stock()
				break
	else:
		_restock_left -= delta
		if _restock_left <= 0.0:
			_stocked = true
	_refresh()


## Health stays on the shelf for a player who has nothing to heal.
func _is_wanted_by(player: Player) -> bool:
	return _stock == Stock.AMMO or player.get_health() < player.data.max_health


func _roll_stock() -> void:
	_stock = Stock.HEALTH if randf() < data.health_chance else Stock.AMMO


func _refresh() -> void:
	_pickup_mesh.visible = _stocked
	_pickup_material.albedo_color = get_color()
	var arriving: bool = not _stocked and _restock_left <= data.warning_time
	_light.visible = _stocked or arriving
	if _stocked:
		_material.albedo_color = get_color()
	elif arriving:
		var lit: bool = fmod(_restock_left * data.flash_rate, 1.0) < 0.5
		_material.albedo_color = get_color() if lit else data.dark_color
