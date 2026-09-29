class_name Arena
extends Node3D
## Top of the ownership spine. Children report up to here; Arena routes between them.

@export var feel: FeelData

@export_group("Pity Drop")
## Dropped when the player has no ammo at all, so a run can't lock up.
@export var pity_pod: PodData
## Seconds with zero ammo before the pity pod drops.
@export var pity_delay: float = 6.0

@export_group("Debug")
## Reloads never drain the reserve, so feel can be tested without the ammo economy.
@export var debug_infinite_reserve: bool = false
## Start the spawn ramp this many seconds in, to test late-run density.
@export var debug_start_time: float = 0.0

var _kills: int = 0
var _empty_time: float = 0.0

@onready var _level: Level = $Level
@onready var _player: Player = $Player
@onready var _hud: Hud = $Hud
@onready var _impact_pool: ScenePool = $ImpactPool
@onready var _number_pool: ScenePool = $DamageNumberPool
@onready var _hitstop: Hitstop = $Hitstop
@onready var _spawner: Spawner = $Spawner
@onready var _sponsors: SponsorDirector = $SponsorDirector
@onready var _pod_dropper: PodDropper = $PodDropper
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
	_spawner.set_spawn_points(_level.get_spawn_points())
	_spawner.set_elapsed(debug_start_time)
	_spawner.target = _player

	_hud.setup_sponsors(_sponsors.sponsors)
	_sponsors.standing_changed.connect(_hud.set_sponsor_progress)
	_sponsors.sponsor_reacted.connect(_hud.show_sponsor_reaction)
	_sponsors.drop_earned.connect(_on_sponsor_drop_earned)

	_pod_dropper.target = _player
	_pod_dropper.pod_landed.connect(_on_pod_landed)
	_pod_dropper.pod_collected.connect(_on_pod_collected)


func _process(_delta: float) -> void:
	_hud.set_dash_charge(_player.get_dash_charge())
	_hud.set_reload(_weapon.is_reloading(), _weapon.get_reload_progress())
	_hud.set_stats(_kills, _spawner.get_alive_count(), _spawner.get_elapsed())


func _physics_process(delta: float) -> void:
	_tick_pity(delta)


func _tick_pity(delta: float) -> void:
	var out_of_ammo: bool = _weapon.get_mag() + _weapon.get_reserve() <= 0 and not _weapon.infinite_reserve
	if not out_of_ammo or pity_pod == null or _pod_dropper.has_active_effect(PodData.Effect.AMMO):
		_empty_time = 0.0
		return
	_empty_time += delta
	if _empty_time >= pity_delay:
		_empty_time = 0.0
		_pod_dropper.drop(pity_pod, null)
		_hud.show_pickup("OUT OF AMMO - SCRAPS INCOMING", Color.WHITE)


func _on_weapon_shot_fired(hit: HitInfo) -> void:
	_sponsors.on_shot(hit)
	if hit == null:
		return
	var marker: ImpactMarker = _impact_pool.acquire() as ImpactMarker
	if marker != null:
		marker.play(hit)
	if not hit.landed():
		return
	_hud.flash_hit_marker(hit.is_headshot)
	_player.add_trauma(hit.damage * feel.trauma_per_damage_dealt)
	var number: DamageNumber = _number_pool.acquire() as DamageNumber
	if number != null:
		number.play(hit)


func _on_weapon_ammo_changed(mag: int, reserve: int) -> void:
	_hud.set_ammo(mag, _weapon.get_mag_size(), -1 if _weapon.infinite_reserve else reserve)


func _on_player_damaged(hit: HitInfo) -> void:
	_hud.flash_damage()
	_player.add_trauma(hit.damage * feel.trauma_per_damage_taken)
	_sponsors.on_player_damaged(hit)


func _on_player_died() -> void:
	# Stand-in until the run summary exists: death restarts the run.
	get_tree().reload_current_scene.call_deferred()


func _on_enemy_died(_enemy: Enemy, hit: HitInfo) -> void:
	_kills += 1
	_player.add_trauma(feel.trauma_per_kill)
	var freeze: float = feel.hitstop_headshot_kill if hit.is_headshot else feel.hitstop_kill
	_hitstop.trigger(freeze, feel.hitstop_time_scale)
	_sponsors.on_kill(hit)


func _on_sponsor_drop_earned(sponsor: SponsorData, pod: PodData) -> void:
	_pod_dropper.drop(pod, sponsor)
	_hud.show_approval(sponsor, pod)


func _on_pod_landed(pod: Pod) -> void:
	var distance: float = pod.global_position.distance_to(_player.global_position)
	var closeness: float = clampf(1.0 - distance / feel.pod_landing_falloff, 0.0, 1.0)
	_player.add_trauma(feel.trauma_pod_landing * closeness)


func _on_pod_collected(pod_data: PodData, sponsor: SponsorData) -> void:
	match pod_data.effect:
		PodData.Effect.AMMO:
			_weapon.add_reserve(roundi(pod_data.amount))
		PodData.Effect.HEALTH:
			_player.heal(pod_data.amount)
		PodData.Effect.MAG_SIZE:
			_weapon.add_mag_size(roundi(pod_data.amount))
		PodData.Effect.FIRE_RATE:
			_weapon.quicken_fire(pod_data.amount)
		PodData.Effect.DASH_COOLDOWN:
			_player.quicken_dash(pod_data.amount)
	_hud.show_pickup(pod_data.display_name, Color.WHITE if sponsor == null else sponsor.color)
