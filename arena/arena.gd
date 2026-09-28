class_name Arena
extends Node3D
## Top of the ownership spine. Children report up to here; Arena routes between them.

@onready var _player: Player = $Player
@onready var _hud: Hud = $Hud
@onready var _impact_pool: ScenePool = $ImpactPool
@onready var _weapon: Weapon = _player.get_weapon()


func _ready() -> void:
	_weapon.shot_fired.connect(_on_weapon_shot_fired)
	_weapon.dry_fired.connect(_hud.flash_dry_fire)
	_weapon.ammo_changed.connect(_on_weapon_ammo_changed)
	_on_weapon_ammo_changed(_weapon.get_mag(), _weapon.get_reserve())


func _process(_delta: float) -> void:
	_hud.set_dash_charge(_player.get_dash_charge())
	_hud.set_reload(_weapon.is_reloading(), _weapon.get_reload_progress())


func _on_weapon_shot_fired(hit: HitInfo) -> void:
	if hit == null:
		return
	var marker: ImpactMarker = _impact_pool.acquire() as ImpactMarker
	if marker != null:
		marker.play(hit)
	if hit.landed():
		_hud.flash_hit_marker(hit.is_headshot)


func _on_weapon_ammo_changed(mag: int, reserve: int) -> void:
	_hud.set_ammo(mag, _weapon.get_mag_size(), reserve)
