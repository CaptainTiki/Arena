class_name Kiosk
extends Area3D
## Something in the base to walk up to. The base decides what it does: most open a menu,
## the door leads to the fight.

enum Kind { LOADOUT, SHOP, TERMINAL, DOOR }

@export var kind: Kind = Kind.LOADOUT
@export var title: String = "KIOSK"
@export var color: Color = Color(0.8, 0.8, 0.8)

@onready var _label: Label3D = $Label
@onready var _top: MeshInstance3D = $Top
@onready var _material: StandardMaterial3D = _top.material_override as StandardMaterial3D


func _ready() -> void:
	_label.text = title
	set_color(color)


func set_color(value: Color) -> void:
	color = value
	_label.modulate = color
	_material.albedo_color = color


func is_player_near() -> bool:
	for body: Node3D in get_overlapping_bodies():
		if body is Player:
			return true
	return false
