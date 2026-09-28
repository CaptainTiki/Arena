class_name Arena
extends Node3D
## Top of the ownership spine. Children report up to here; Arena routes between them.

@onready var _player: Player = $Player
@onready var _hud: Hud = $Hud


func _process(_delta: float) -> void:
	_hud.set_dash_charge(_player.get_dash_charge())
