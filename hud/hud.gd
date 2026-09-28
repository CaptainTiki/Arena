class_name Hud
extends CanvasLayer

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

@onready var _health_bar: ProgressBar = $HealthBar
@onready var _damage_flash: ColorRect = $DamageFlash
@onready var _stats_label: Label = $StatsLabel

@onready var _dash_bar: ProgressBar = $DashBar
@onready var _crosshair: ColorRect = $Crosshair
@onready var _ammo_label: Label = $AmmoLabel
@onready var _status_label: Label = $StatusLabel
@onready var _reload_bar: ProgressBar = $ReloadBar


func _ready() -> void:
	_crosshair.pivot_offset = _crosshair.size * 0.5
	_reload_bar.visible = false


func set_dash_charge(charge: float) -> void:
	_dash_bar.value = charge


func set_health(health: float, max_health: float) -> void:
	_health_bar.value = health / max_health


func flash_damage() -> void:
	if _damage_tween != null:
		_damage_tween.kill()
	_damage_flash.color.a = damage_flash_alpha
	_damage_tween = create_tween()
	_damage_tween.tween_property(_damage_flash, ^"color:a", 0.0, damage_flash_time)


func set_stats(kills: int, alive: int, elapsed: float) -> void:
	var seconds: int = int(elapsed)
	@warning_ignore("integer_division")
	var minutes: int = seconds / 60
	_stats_label.text = "%02d:%02d   KILLS %d   ALIVE %d" % [minutes, seconds % 60, kills, alive]


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
