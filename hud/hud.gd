class_name Hud
extends CanvasLayer

@onready var _dash_bar: ProgressBar = $DashBar


func set_dash_charge(charge: float) -> void:
	_dash_bar.value = charge
