class_name Arena
extends Node3D
## Top of the ownership spine. Children report up to here; Arena routes between them.

@export_group("Debug")
## Reloads never drain the reserve, so feel can be tested without the ammo economy.
@export var debug_infinite_reserve: bool = true
## Start the spawn ramp this many seconds in, to test late-run density.
@export var debug_start_time: float = 0.0

var _kills: int = 0

@onready var _player: Player = $Player
@onready var _hud: Hud = $Hud
@onready var _impact_pool: ScenePool = $ImpactPool
@onready var _spawner: Spawner = $Spawner
@onready var _weapon: Weapon = _player.get_weapon()


func _ready() -> void:
	_weapon.infinite_reserve = debug_infinite_reserve
	_weapon.shot_fired.connect(_on_weapon_shot_fired)
	_weapon.dry_fired.connect(_hud.flash_dry_fire)
	_weapon.ammo_changed.connect(_on_weapon_ammo_changed)
	_on_weapon_ammo_changed(_weapon.get_mag(), _weapon.get_reserve())

	_player.health_changed.connect(_hud.set_health)
	_player.damaged.connect(_on_player_damaged)
	_player.died.connect(_on_player_died)

	_spawner.enemy_died.connect(_on_enemy_died)
	_spawner.set_elapsed(debug_start_time)
	_spawner.target = _player


func _process(_delta: float) -> void:
	_hud.set_dash_charge(_player.get_dash_charge())
	_hud.set_reload(_weapon.is_reloading(), _weapon.get_reload_progress())
	_hud.set_stats(_kills, _spawner.get_alive_count(), _spawner.get_elapsed())


func _on_weapon_shot_fired(hit: HitInfo) -> void:
	if hit == null:
		return
	var marker: ImpactMarker = _impact_pool.acquire() as ImpactMarker
	if marker != null:
		marker.play(hit)
	if hit.landed():
		_hud.flash_hit_marker(hit.is_headshot)


func _on_weapon_ammo_changed(mag: int, reserve: int) -> void:
	_hud.set_ammo(mag, _weapon.get_mag_size(), -1 if _weapon.infinite_reserve else reserve)


func _on_player_damaged(_hit: HitInfo) -> void:
	_hud.flash_damage()


func _on_player_died() -> void:
	# Stand-in until the run summary exists: death restarts the run.
	get_tree().reload_current_scene.call_deferred()


func _on_enemy_died(_enemy: Enemy, _hit: HitInfo) -> void:
	_kills += 1
