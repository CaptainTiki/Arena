class_name Arena
extends Node3D
## Top of the ownership spine. Children report up to here; Arena routes between them.
## Runs one contract from briefing to summary.

enum Outcome { WON, DIED, OUT_OF_TIME }

@export var feel: FeelData
@export var run: RunData
## Contracts on offer. The booked one is remembered in the profile.
@export var contracts: Array[ContractData] = []
## Where reputation, cash and the booking are kept between fights.
@export var profile_path: String = "user://profile.cfg"

@export_group("Pity Drop")
## Dropped when the player has no ammo at all, so a fight can't lock up.
@export var pity_pod: PodData
## Seconds with zero ammo before the pity pod drops.
@export var pity_delay: float = 6.0

@export_group("Debug")
## Always fight this contract, whatever is booked.
@export var debug_contract: ContractData
## Reloads never drain the reserve, so feel can be tested without the ammo economy.
@export var debug_infinite_reserve: bool = false
## Start a density ramp this many seconds in, to test late-fight crowds.
@export var debug_start_time: float = 0.0

var _contract: ContractData
var _contract_index: int = 0
var _stats: RunStats = RunStats.new()
var _run_time: float = 0.0
var _run_over: bool = false
var _summary_wait: float = 0.0
var _empty_time: float = 0.0
var _target_pods: int = 0
var _hold_zones: Array[HoldZone] = []
var _active_zone: int = 0
var _was_holding: bool = false

@onready var _level: Level = $Level
@onready var _player: Player = $Player
@onready var _hud: Hud = $Hud
@onready var _summary: RunSummary = $RunSummary
@onready var _sfx: Sfx = $Sfx
@onready var _impact_pool: ScenePool = $ImpactPool
@onready var _number_pool: ScenePool = $DamageNumberPool
@onready var _hitstop: Hitstop = $Hitstop
@onready var _spawner: Spawner = $Spawner
@onready var _sponsors: SponsorDirector = $SponsorDirector
@onready var _pod_dropper: PodDropper = $PodDropper
@onready var _log: RunLog = $RunLog
@onready var _weapon: Weapon = _player.get_weapon()
@onready var _intent: PlayerIntent = _player.get_intent()


func _ready() -> void:
	_book_contract()

	_log.player = _player
	_log.spawner = _spawner
	_log.begin(_contract)

	_weapon.infinite_reserve = debug_infinite_reserve
	_weapon.shot_fired.connect(_on_weapon_shot_fired)
	_weapon.dry_fired.connect(_hud.flash_dry_fire)
	_weapon.dry_fired.connect(_log.log_player.bind("dry_fire"))
	_weapon.reload_started.connect(_log.log_player.bind("reload_start"))
	_weapon.reload_finished.connect(_log.log_player.bind("reload_done"))
	_weapon.ammo_changed.connect(_on_weapon_ammo_changed)
	_on_weapon_ammo_changed(_weapon.get_mag(), _weapon.get_reserve())

	_player.health_changed.connect(_hud.set_health)
	_player.damaged.connect(_on_player_damaged)
	_player.died.connect(_on_player_died)
	_player.dashed.connect(_on_player_dashed)
	_player.dodged.connect(_log.log_player_hit.bind(true))

	_spawner.enemy_died.connect(_on_enemy_died)
	_spawner.enemy_acted.connect(_on_enemy_acted)
	_spawner.set_spawn_points(_level.get_spawn_points())
	_spawner.health_scale = _contract.enemy_health_scale
	_spawner.damage_scale = _contract.enemy_damage_scale
	if _contract.type == ContractData.Type.EXTERMINATION:
		_spawner.start_roster(_contract.roster)
	else:
		_spawner.start_ramp(_contract.ramp)
		_spawner.set_elapsed(debug_start_time)
	_spawner.target = _player

	_hud.setup_sponsors(_sponsors.sponsors)
	_hud.show_briefing(_contract, run.briefing_time)
	_sponsors.standing_changed.connect(_hud.set_sponsor_progress)
	_sponsors.sponsor_reacted.connect(_hud.show_sponsor_reaction)
	_sponsors.drop_earned.connect(_on_sponsor_drop_earned)

	_pod_dropper.target = _player
	_pod_dropper.pod_landed.connect(_on_pod_landed)
	_pod_dropper.pod_collected.connect(_on_pod_collected)

	_hold_zones = _level.get_hold_zones()
	_activate_zone(0)

	for station: AmmoStation in _level.get_ammo_stations():
		station.collected.connect(_on_ammo_station_collected)


func _process(delta: float) -> void:
	if _run_over:
		_tick_summary(delta)
		return
	_hud.set_dash_charge(_player.get_dash_charge())
	_hud.set_reload(_weapon.is_reloading(), _weapon.get_reload_progress())
	_hud.set_stats(_stats.kills, _spawner.get_alive_count(), _contract.time_limit - _run_time)
	_hud.set_objective(_get_objective_text())


func _physics_process(delta: float) -> void:
	if _run_over:
		return
	_run_time += delta
	_tick_pity(delta)
	if not _hold_zones.is_empty():
		var holding: bool = _hold_zones[_active_zone].is_occupied()
		_sponsors.set_holding(holding)
		if holding != _was_holding:
			_was_holding = holding
			_log.log_player("zone_enter" if holding else "zone_exit", {"zone": _active_zone})

	if _is_goal_met():
		_end_run.call_deferred(Outcome.WON)
	elif _run_time >= _contract.time_limit:
		var survived: bool = _contract.type == ContractData.Type.SURVIVAL
		_end_run.call_deferred(Outcome.WON if survived else Outcome.OUT_OF_TIME)


func is_run_over() -> bool:
	return _run_over


func get_contract() -> ContractData:
	return _contract


func _book_contract() -> void:
	var profile: ProfileStore = ProfileStore.new(profile_path)
	_contract_index = posmod(profile.get_contract_index(), maxi(contracts.size(), 1))
	_contract = debug_contract if debug_contract != null else contracts[_contract_index]


func _is_goal_met() -> bool:
	match _contract.type:
		ContractData.Type.EXTERMINATION:
			return _spawner.is_roster_finished()
		ContractData.Type.SCAVENGER:
			return _target_pods >= _contract.target_count
	return false


func _get_objective_text() -> String:
	match _contract.type:
		ContractData.Type.EXTERMINATION:
			var text: String = "%d OF %d LEFT" % [_spawner.get_roster_remaining(), _contract.get_roster_total()]
			var next_wave: float = _spawner.get_next_wave_in()
			if next_wave >= 0.0:
				text += "      NEXT WAVE %s" % Hud.format_clock(next_wave)
			return text
		ContractData.Type.SCAVENGER:
			return "%s PODS  %d OF %d" % [
					_contract.target_sponsor.display_name, _target_pods, _contract.target_count]
	return "SURVIVE"


func _end_run(outcome: Outcome) -> void:
	if _run_over:
		return
	_run_over = true
	_stats.time_survived = minf(_run_time, _contract.time_limit)
	_log.finish(Outcome.keys()[outcome], _stats)

	var profile: ProfileStore = ProfileStore.new(profile_path)
	var results: Array[SponsorResult] = []
	for index: int in _sponsors.sponsors.size():
		var result: SponsorResult = SponsorResult.new()
		result.sponsor = _sponsors.sponsors[index]
		result.drops = _sponsors.get_drop_count(index)
		result.standing = _sponsors.get_progress(index)
		result.reputation_before = profile.get_reputation(result.sponsor)
		result.reputation_after = result.reputation_before + _get_reputation_gain(result.drops)
		profile.set_reputation(result.sponsor, result.reputation_after)
		results.append(result)
		_log.log_world("favor", {
			"sponsor": result.sponsor.display_name,
			"drops": result.drops,
			"gained": result.reputation_after - result.reputation_before,
			"total": result.reputation_after,
		})
	var cash_earned: int = _contract.cash_reward if outcome == Outcome.WON else 0
	profile.set_cash(profile.get_cash() + cash_earned)
	_log.log_world("cash", {"earned": cash_earned, "total": profile.get_cash()})
	profile.save()

	# Freeze the world behind the summary. The intent keeps listening so the next fight can be started.
	var frozen: Array[Node] = [_spawner, _sponsors, _pod_dropper, _player]
	for node: Node in frozen:
		node.process_mode = Node.PROCESS_MODE_DISABLED
	_intent.process_mode = Node.PROCESS_MODE_ALWAYS
	_hud.visible = false
	_summary_wait = run.summary_input_delay
	_summary.show_summary(
			_get_outcome_title(outcome), _contract, cash_earned, profile.get_cash(), _stats, results)
	if outcome == Outcome.WON:
		_sfx.play_contract_won()
	else:
		_sfx.play_contract_lost()


func _get_outcome_title(outcome: Outcome) -> String:
	match outcome:
		Outcome.WON:
			return "CONTRACT COMPLETE"
		Outcome.DIED:
			return "YOU DIED"
	return "OUT OF TIME"


func _get_reputation_gain(drops: int) -> int:
	if drops <= 0 or run.drops_per_reputation <= 0:
		return 0
	return mini(ceili(float(drops) / float(run.drops_per_reputation)), run.max_reputation_gain)


func _get_next_contract_index() -> int:
	return (_contract_index + 1) % maxi(contracts.size(), 1)


func _tick_summary(delta: float) -> void:
	var was_waiting: bool = _summary_wait > 0.0
	_summary_wait -= delta
	# Read both every frame so neither press is left queued.
	var again: bool = _intent.consume_fire()
	var next: bool = _intent.consume_reload()
	if _summary_wait > 0.0:
		return
	if was_waiting:
		_summary.show_prompt(contracts[_get_next_contract_index()])
		return
	if next:
		var profile: ProfileStore = ProfileStore.new(profile_path)
		profile.set_contract_index(_get_next_contract_index())
		profile.save()
	if again or next:
		_log.log_world("summary_choice", {"choice": "next" if next else "again"})
		get_tree().reload_current_scene()


func _tick_pity(delta: float) -> void:
	var out_of_ammo: bool = _weapon.get_mag() + _weapon.get_reserve() <= 0 and not _weapon.infinite_reserve
	if not out_of_ammo or pity_pod == null or _pod_dropper.has_active_effect(PodData.Effect.AMMO):
		_empty_time = 0.0
		return
	_empty_time += delta
	if _empty_time >= pity_delay:
		_empty_time = 0.0
		_pod_dropper.drop(pity_pod, null)
		_log.log_world("pod_drop", {"pod": pity_pod.display_name, "sponsor": "PITY"})
		_hud.show_pickup("OUT OF AMMO - SCRAPS INCOMING", Color.WHITE)
		_sfx.play_pod_alarm()


## Only one hold zone is live at a time.
func _activate_zone(index: int) -> void:
	if _hold_zones.is_empty():
		return
	_active_zone = index % _hold_zones.size()
	for zone_index: int in _hold_zones.size():
		_hold_zones[zone_index].set_active(zone_index == _active_zone)
	_was_holding = false
	var zone_position: Vector3 = _hold_zones[_active_zone].global_position
	_log.log_world("zone_active", {
		"zone": _active_zone,
		"zone_pos": [roundi(zone_position.x), roundi(zone_position.y), roundi(zone_position.z)],
	})


func _on_weapon_shot_fired(hit: HitInfo) -> void:
	_stats.record_shot(hit)
	_log.log_shot(hit, _weapon.get_mag(), _weapon.get_reserve())
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
	_log.log_player_hit(hit, false)
	_player.add_trauma(hit.damage * feel.trauma_per_damage_taken)
	_sponsors.on_player_damaged(hit)


func _on_player_dashed(direction: Vector3) -> void:
	_log.log_player("dash", {"dir": [snappedf(direction.x, 0.01), snappedf(direction.z, 0.01)]})


func _on_player_died() -> void:
	# Deferred: this arrives mid-physics, from inside an enemy's attack.
	_end_run.call_deferred(Outcome.DIED)


func _on_enemy_acted(enemy: Enemy, action: StringName) -> void:
	var extra: Dictionary = {}
	if action != &"spawn":
		extra["attack"] = enemy.get_attack_name()
	_log.log_enemy("enemy_%s" % action, enemy, extra)


func _on_enemy_died(enemy: Enemy, hit: HitInfo) -> void:
	_stats.kills += 1
	_log.log_enemy("enemy_killed", enemy, {"headshot": hit.is_headshot})
	_player.add_trauma(feel.trauma_per_kill)
	var freeze: float = feel.hitstop_headshot_kill if hit.is_headshot else feel.hitstop_kill
	_hitstop.trigger(freeze, feel.hitstop_time_scale)
	_sponsors.on_kill(hit)


func _on_sponsor_drop_earned(sponsor: SponsorData, pod: PodData) -> void:
	_pod_dropper.drop(pod, sponsor)
	_log.log_world("pod_drop", {"pod": pod.display_name, "sponsor": sponsor.display_name})
	_hud.show_approval(sponsor, pod)
	_sfx.play_pod_alarm()
	if sponsor.trigger == SponsorData.Trigger.HOLD_ZONE:
		# A paid-out zone is spent; the next one is somewhere else, so holding ground means crossing it.
		_activate_zone(_active_zone + 1)
		_hud.show_pickup("HOLD ZONE MOVED", sponsor.color)


func _on_pod_landed(pod: Pod) -> void:
	_log.log_world("pod_landed", {
		"pod": pod.pod_data.display_name,
		"pod_pos": [roundi(pod.global_position.x), roundi(pod.global_position.y), roundi(pod.global_position.z)],
	})
	var distance: float = pod.global_position.distance_to(_player.global_position)
	var closeness: float = clampf(1.0 - distance / feel.pod_landing_falloff, 0.0, 1.0)
	_player.add_trauma(feel.trauma_pod_landing * closeness)


func _on_pod_collected(pod_data: PodData, sponsor: SponsorData) -> void:
	_stats.pods_collected += 1
	_log.log_player("pod_collected", {
		"pod": pod_data.display_name,
		"sponsor": "PITY" if sponsor == null else sponsor.display_name,
	})
	if sponsor != null and sponsor == _contract.target_sponsor:
		_target_pods += 1
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
		PodData.Effect.DAMAGE:
			_weapon.boost_damage(pod_data.amount)
	_hud.show_pickup(pod_data.display_name, Color.WHITE if sponsor == null else sponsor.color)


func _on_ammo_station_collected(station: AmmoStation) -> void:
	_weapon.add_reserve(station.get_ammo())
	_log.log_player("ammo_station", {"ammo": station.get_ammo()})
	_hud.show_pickup("AMMO +%d" % station.get_ammo(), station.data.stocked_color)
