class_name SponsorMeter
extends Control
## One sponsor's row on the HUD: name, standing toward the next drop, latest reaction.
## Out of sight until the sponsor likes something; then it shows, holds and fades.
## The debug HUD keeps every row up, with what the sponsor wants under it.

@export var liked_color: Color = Color(1.0, 1.0, 1.0)
@export var disliked_color: Color = Color(1.0, 0.3, 0.3)
@export var hold_time: float = 1.0
@export var fade_time: float = 1.5
## Row height with and without the line saying what the sponsor wants.
@export var height: float = 32.0
@export var debug_height: float = 50.0

var _debug: bool = false
var _fade_tween: Tween

@onready var _name_label: Label = $NameLabel
@onready var _wants_label: Label = $WantsLabel
@onready var _bar: ProgressBar = $Bar
@onready var _reaction_label: Label = $ReactionLabel


func setup(sponsor: SponsorData) -> void:
	_name_label.text = sponsor.display_name
	_name_label.modulate = sponsor.color
	_wants_label.text = sponsor.wants
	_bar.modulate = sponsor.color
	_bar.value = 0.0
	_reaction_label.text = ""
	modulate.a = 1.0 if _debug else 0.0


func set_debug(debug: bool) -> void:
	_debug = debug
	_wants_label.visible = debug
	custom_minimum_size.y = debug_height if debug else height
	if _fade_tween != null:
		_fade_tween.kill()
	modulate.a = 1.0 if debug else 0.0


func set_progress(progress: float) -> void:
	_bar.value = progress


## Brings the row up, then lets it fade.
func pop() -> void:
	if _debug:
		return
	if _fade_tween != null:
		_fade_tween.kill()
	modulate.a = 1.0
	_fade_tween = create_tween()
	_fade_tween.tween_interval(hold_time)
	_fade_tween.tween_property(self, ^"modulate:a", 0.0, fade_time)


func show_reaction(reason: String, positive: bool) -> void:
	_reaction_label.text = ("+ " if positive else "- ") + reason
	_reaction_label.modulate = liked_color if positive else disliked_color
