class_name Weapon
extends Node3D
## Semi-auto hitscan weapon.

## `hit` is null when the shot struck nothing at all.
signal shot_fired(hit: HitInfo)
## Aim kick in radians: x is yaw, y is pitch (up positive).
signal recoiled(kick: Vector2)
signal dry_fired
signal ammo_changed(mag: int, reserve: int)
signal reload_started
signal reload_finished

@export var data: WeaponData
@export var wielder: CollisionObject3D
## Shots travel down this node's -Z, so camera shake never moves the aim.
@export var aim_origin: Node3D
@export_flags_3d_physics var hit_mask: int = 21

## Debug aid: reloads never drain the reserve.
var infinite_reserve: bool = false

var _stats: WeaponData
var _mag: int = 0
var _reserve: int = 0
var _cooldown_left: float = 0.0
var _reload_left: float = 0.0
var _kick: float = 0.0
var _gun_rest: Vector3

@onready var _gun: Node3D = $Gun


func _ready() -> void:
	# Runtime copy so pod upgrades never write back to the authored resource.
	_stats = data.duplicate() as WeaponData
	_mag = _stats.mag_size
	_reserve = _stats.starting_reserve
	_gun_rest = _gun.position


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if is_reloading():
		_reload_left -= delta
		if _reload_left <= 0.0:
			_finish_reload()


func _process(delta: float) -> void:
	_kick = lerpf(_kick, 0.0, 1.0 - exp(-_stats.kick_recover_speed * delta))
	var dip: float = sin(get_reload_progress() * PI) * _stats.reload_dip if is_reloading() else 0.0
	_gun.position = _gun_rest + Vector3(0.0, -dip, _kick * _stats.kick_distance)


func try_fire() -> void:
	if is_reloading() or _cooldown_left > 0.0:
		return
	if _mag <= 0:
		dry_fired.emit()
		if _stats.reload_on_dry_fire:
			try_reload()
		return
	_mag -= 1
	_cooldown_left = _stats.fire_interval
	_kick = 1.0
	ammo_changed.emit(_mag, _reserve)
	shot_fired.emit(_resolve_shot())
	recoiled.emit(Vector2(
			deg_to_rad(randf_range(-_stats.recoil_yaw_degrees, _stats.recoil_yaw_degrees)),
			deg_to_rad(_stats.recoil_pitch_degrees)))


func try_reload() -> void:
	if is_reloading() or _mag >= _stats.mag_size:
		return
	if _reserve <= 0 and not infinite_reserve:
		return
	_reload_left = _stats.reload_time
	reload_started.emit()


func add_reserve(amount: int) -> void:
	_reserve += amount
	ammo_changed.emit(_mag, _reserve)


func add_mag_size(amount: int) -> void:
	_stats.mag_size += amount
	_mag += amount
	ammo_changed.emit(_mag, _reserve)


## 0.1 makes the weapon fire 10% faster.
func quicken_fire(fraction: float) -> void:
	_stats.fire_interval *= 1.0 - fraction


## 0.15 makes every shot hit 15% harder.
func boost_damage(fraction: float) -> void:
	_stats.damage *= 1.0 + fraction


func is_reloading() -> bool:
	return _reload_left > 0.0


## 0.0 at the start of a reload, 1.0 when done or not reloading.
func get_reload_progress() -> float:
	if not is_reloading() or _stats.reload_time <= 0.0:
		return 1.0
	return 1.0 - _reload_left / _stats.reload_time


func get_stats() -> WeaponData:
	return _stats


func get_mag() -> int:
	return _mag


func get_mag_size() -> int:
	return _stats.mag_size


func get_reserve() -> int:
	return _reserve


func _finish_reload() -> void:
	_reload_left = 0.0
	if infinite_reserve:
		_mag = _stats.mag_size
	else:
		var loaded: int = mini(_stats.mag_size - _mag, _reserve)
		_mag += loaded
		_reserve -= loaded
	ammo_changed.emit(_mag, _reserve)
	reload_finished.emit()


func _resolve_shot() -> HitInfo:
	var origin: Vector3 = aim_origin.global_position
	var direction: Vector3 = -aim_origin.global_basis.z
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			origin, origin + direction * _stats.max_range, hit_mask, [wielder.get_rid()])
	query.collide_with_areas = true
	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return null

	var hit: HitInfo = HitInfo.new()
	hit.position = result[&"position"]
	hit.normal = result[&"normal"]
	hit.direction = direction
	hit.source = wielder

	var collider: Object = result[&"collider"]
	if collider is Hitbox:
		var hitbox: Hitbox = collider as Hitbox
		hit.is_headshot = hitbox.is_head
		hit.target = hitbox.target
	elif collider.has_method(&"take_hit"):
		hit.target = collider as Node

	hit.damage = _stats.damage
	hit.knockback = _stats.knockback
	if hit.is_headshot:
		hit.damage *= _stats.headshot_multiplier
		hit.knockback *= _stats.headshot_knockback_multiplier
	if hit.landed():
		hit.target.call(&"take_hit", hit)
	return hit
