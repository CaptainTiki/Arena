class_name MenuRow
extends Control
## One line of a kiosk menu. Reports clicks and the mouse passing over; the panel decides what is picked out.

signal clicked(row: MenuRow)
signal hovered(row: MenuRow)

@export var unavailable_alpha: float = 0.45

@onready var _highlight: ColorRect = $Highlight
@onready var _button: Button = $Button
@onready var _label: Label = $Label
@onready var _note: Label = $Note


func _ready() -> void:
	_button.pressed.connect(_on_button_pressed)
	_button.mouse_entered.connect(_on_button_mouse_entered)


func show_entry(entry: MenuEntry) -> void:
	visible = true
	_label.text = entry.label
	_note.text = entry.note
	_label.modulate = entry.color
	_note.modulate = entry.color
	modulate.a = 1.0 if entry.available else unavailable_alpha
	_button.visible = entry.selectable
	set_picked(false)


func set_picked(picked: bool) -> void:
	_highlight.visible = picked


func _on_button_pressed() -> void:
	clicked.emit(self)


func _on_button_mouse_entered() -> void:
	hovered.emit(self)
