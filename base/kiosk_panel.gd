class_name KioskPanel
extends CanvasLayer
## The plain text panel a kiosk opens. Ugly on purpose.

@onready var _text: Label = $Back/Text


func _ready() -> void:
	visible = false


func show_text(text: String) -> void:
	_text.text = text
	visible = true


func close() -> void:
	visible = false
