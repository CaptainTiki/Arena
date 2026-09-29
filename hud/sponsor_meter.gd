class_name SponsorMeter
extends Control
## One sponsor's row on the HUD: name, what they want, standing toward the next drop, latest reaction.

@export var liked_color: Color = Color(1.0, 1.0, 1.0)
@export var disliked_color: Color = Color(1.0, 0.3, 0.3)
@export var reaction_time: float = 1.2

var _reaction_tween: Tween

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


func set_progress(progress: float) -> void:
	_bar.value = progress


func show_reaction(reason: String, positive: bool) -> void:
	if _reaction_tween != null:
		_reaction_tween.kill()
	_reaction_label.text = ("+ " if positive else "- ") + reason
	_reaction_label.modulate = liked_color if positive else disliked_color
	_reaction_tween = create_tween()
	_reaction_tween.tween_property(_reaction_label, ^"modulate:a", 0.0, reaction_time)
