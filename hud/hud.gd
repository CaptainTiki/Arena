class_name Hud
extends CanvasLayer
## Kept small: health, ammo, the objective, and things that show only while they matter.
## The debug HUD (toggled by the owner) adds the run's numbers and keeps every sponsor row up.

@export var ammo_ok_color: Color = Color(1.0, 1.0, 1.0)
@export var ammo_low_color: Color = Color(1.0, 0.8, 0.2)
@export var ammo_empty_color: Color = Color(1.0, 0.2, 0.2)
@export var hit_color: Color = Color(1.0, 0.2, 0.2)
@export var headshot_color: Color = Color(1.0, 0.9, 0.1)
@export var hit_marker_time: float = 0.12
@export var hit_marker_scale: float = 3.0

@export var damage_flash_alpha: float = 0.35
@export var damage_flash_time: float = 0.3

var _status_text: String = ""
var _status_tween: Tween
var _crosshair_tween: Tween
var _damage_tween: Tween
var _approval_tween: Tween
var _pickup_tween: Tween
var _briefing_tween: Tween
var _meters: Array[SponsorMeter] = []
var _sponsors: Array[SponsorData] = []

## Outlives the scene, so the choice holds from one fight to the next.
static var _debug: bool = false

@export var approval_hold_time: float = 1.6
@export var approval_fade_time: float = 0.6
@export var pickup_time: float = 1.4

@onready var _objective_label: Label = $ObjectiveLabel
@onready var _briefing_label: Label = $BriefingLabel
@onready var _meters_root: Control = $TopLeft/SponsorMeters
@onready var _approval_label: Label = $ApprovalLabel
@onready var _approval_detail: Label = $ApprovalDetail
@onready var _pickup_label: Label = $PickupLabel
@onready var _health_bar: ProgressBar = $HealthBar
@onready var _damage_flash: ColorRect = $DamageFlash
@onready var _stats_label: Label = $TopLeft/StatsLabel

@onready var _dash_bar: ProgressBar = $DashBar
@onready var _crosshair: ColorRect = $Crosshair
@onready var _ammo_label: Label = $AmmoLabel
@onready var _status_label: Label = $StatusLabel
@onready var _reload_bar: ProgressBar = $ReloadBar
@onready var _prompt_label: Label = $PromptLabel
@onready var _pocket_label: Label = $PocketLabel


func _ready() -> void:
	_crosshair.pivot_offset = _crosshair.size * 0.5
	_reload_bar.visible = false
	_approval_label.modulate.a = 0.0
	_approval_detail.modulate.a = 0.0
	_pickup_label.modulate.a = 0.0
	_briefing_label.modulate.a = 0.0
	for child: Node in _meters_root.get_children():
		_meters.append(child as SponsorMeter)
	_apply_debug()


func toggle_debug() -> void:
	_debug = not _debug
	_apply_debug()


func _apply_debug() -> void:
	_stats_label.visible = _debug
	for meter: SponsorMeter in _meters:
		meter.set_debug(_debug)


## One meter row per sponsor, in order. Rows without a sponsor are hidden.
func setup_sponsors(sponsors: Array[SponsorData]) -> void:
	_sponsors = sponsors
	for index: int in _meters.size():
		_meters[index].visible = index < sponsors.size()
		if index < sponsors.size():
			_meters[index].setup(sponsors[index])


func set_sponsor_progress(index: int, progress: float) -> void:
	if index < _meters.size():
		_meters[index].set_progress(progress)


## `minor` is small change, a body hit say: recorded on the row, but not worth bringing it up for.
func show_sponsor_reaction(index: int, reason: String, positive: bool, minor: bool) -> void:
	if index >= _meters.size():
		return
	_meters[index].show_reaction(reason, positive)
	if positive and not minor:
		_meters[index].pop()


func show_approval(sponsor: SponsorData, pod: PodData) -> void:
	if _approval_tween != null:
		_approval_tween.kill()
	var index: int = _sponsors.find(sponsor)
	if index >= 0 and index < _meters.size():
		_meters[index].pop()
	_approval_label.text = "%s APPROVES" % sponsor.display_name
	_approval_detail.text = "%s incoming - look up" % pod.display_name
	_approval_label.modulate = sponsor.color
	_approval_detail.modulate = sponsor.color
	_approval_label.pivot_offset = _approval_label.size * 0.5
	_approval_label.scale = Vector2.ONE * 1.4
	_approval_tween = create_tween()
	_approval_tween.tween_property(_approval_label, ^"scale", Vector2.ONE, 0.2)
	_approval_tween.tween_interval(approval_hold_time)
	_approval_tween.tween_property(_approval_label, ^"modulate:a", 0.0, approval_fade_time)
	_approval_tween.parallel().tween_property(_approval_detail, ^"modulate:a", 0.0, approval_fade_time)


func show_pickup(text: String, color: Color) -> void:
	if _pickup_tween != null:
		_pickup_tween.kill()
	_pickup_label.text = text
	_pickup_label.modulate = color
	_pickup_label.pivot_offset = _pickup_label.size * 0.5
	_pickup_label.scale = Vector2.ONE * 1.5
	_pickup_tween = create_tween()
	_pickup_tween.tween_property(_pickup_label, ^"scale", Vector2.ONE, 0.15)
	_pickup_tween.tween_interval(pickup_time * 0.5)
	_pickup_tween.tween_property(_pickup_label, ^"modulate:a", 0.0, pickup_time * 0.5)


## Only on screen while the dash is coming back.
func set_dash_charge(charge: float) -> void:
	_dash_bar.value = charge
	_dash_bar.visible = charge < 1.0


func set_health(health: float, max_health: float) -> void:
	_health_bar.value = health / max_health


func flash_damage() -> void:
	if _damage_tween != null:
		_damage_tween.kill()
	_damage_flash.color.a = damage_flash_alpha
	_damage_tween = create_tween()
	_damage_tween.tween_property(_damage_flash, ^"color:a", 0.0, damage_flash_time)


func set_stats(kills: int, alive: int, time_left: float) -> void:
	_stats_label.text = "%s LEFT   KILLS %d   ALIVE %d" % [format_clock(time_left), kills, alive]


func set_objective(text: String) -> void:
	_objective_label.text = text


## What is in the pocket and the key that uses it. Null for an empty pocket.
func set_pocket(item: ItemData) -> void:
	_pocket_label.text = "" if item == null else "%s [F]" % item.display_name


## A line above the ammo for something that can be done right here. Empty clears it.
func set_prompt(text: String) -> void:
	_prompt_label.text = text


## The contract card shown as the fight starts.
func show_briefing(contract: ContractData, asked_by: SponsorData, seconds: float) -> void:
	if _briefing_tween != null:
		_briefing_tween.kill()
	_briefing_label.text = contract.get_card(asked_by)
	_briefing_label.modulate.a = 1.0
	_briefing_tween = create_tween()
	_briefing_tween.tween_interval(seconds)
	_briefing_tween.tween_property(_briefing_label, ^"modulate:a", 0.0, 0.8)


static func format_clock(seconds: float) -> String:
	var whole: int = maxi(ceili(seconds), 0)
	@warning_ignore("integer_division")
	var minutes: int = whole / 60
	return "%02d:%02d" % [minutes, whole % 60]


## Pass a negative reserve to show it as infinite.
func set_ammo(mag: int, mag_size: int, reserve: int) -> void:
	_ammo_label.text = "%d / INF" % mag if reserve < 0 else "%d / %d" % [mag, reserve]
	if mag <= 0:
		_ammo_label.modulate = ammo_empty_color
		_status_text = "NO AMMO" if reserve == 0 else "EMPTY - RELOAD [R]"
	else:
		_ammo_label.modulate = ammo_low_color if mag * 3 <= mag_size else ammo_ok_color
		_status_text = ""
	_refresh_status()


func set_reload(reloading: bool, progress: float) -> void:
	if _reload_bar.visible != reloading:
		_reload_bar.visible = reloading
		_refresh_status()
	_reload_bar.value = progress


func flash_dry_fire() -> void:
	_punch_status()


func flash_hit_marker(is_headshot: bool) -> void:
	if _crosshair_tween != null:
		_crosshair_tween.kill()
	_crosshair.color = headshot_color if is_headshot else hit_color
	_crosshair.scale = Vector2.ONE * hit_marker_scale
	_crosshair_tween = create_tween().set_parallel()
	_crosshair_tween.tween_property(_crosshair, ^"scale", Vector2.ONE, hit_marker_time)
	_crosshair_tween.tween_property(_crosshair, ^"color", Color.WHITE, hit_marker_time)


func _refresh_status() -> void:
	if _reload_bar.visible:
		_status_label.text = "RELOADING"
		_status_label.modulate = ammo_low_color
	else:
		_status_label.text = _status_text
		_status_label.modulate = ammo_empty_color


func _punch_status() -> void:
	if _status_tween != null:
		_status_tween.kill()
	_status_label.pivot_offset = _status_label.size * 0.5
	_status_label.scale = Vector2.ONE * 1.5
	_status_tween = create_tween()
	_status_tween.tween_property(_status_label, ^"scale", Vector2.ONE, 0.15)
