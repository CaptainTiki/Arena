class_name Player
extends CharacterBody3D

signal health_changed(health: float, max_health: float)
signal damaged(hit: HitInfo)
signal died
signal dashed(direction: Vector3)
## A hit the dash carried the player through.
signal dodged(hit: HitInfo)
signal weapon_changed(weapon: Weapon)
## The thing in the pocket was used.
signal item_used(item: ItemData)

@export var data: PlayerData
## Off in the base: no firing, reloading or swapping, and the weapons are out of sight.
@export var armed: bool = true

var _health: float = 0.0
var _base_mask: int = 0
var _pitch: float = 0.0
var _dash_time_left: float = 0.0
var _dash_cooldown_left: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO
## Aim offset from recoil, radians: x is yaw, y is pitch.
var _recoil: Vector2 = Vector2.ZERO
var _recoil_target: Vector2 = Vector2.ZERO
var _trauma: float = 0.0
var _shake_time: float = 0.0
var _shake_noise: FastNoiseLite = FastNoiseLite.new()
## Every weapon carried, in slot order. `_weapon` is the one in hand.
var _weapons: Array[Weapon] = []
var _damage_taken_scale: float = 1.0
var _sprint_scale: float = 1.0
## What is in the pocket, or null once it has been used.
var _pocket: ItemData
var _heal_left: float = 0.0
var _heal_rate: float = 0.0

@onready var _intent: PlayerIntent = $Intent
@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera3D
@onready var _weapon: Weapon = $Head/Camera3D/Weapon


func _ready() -> void:
	# Runtime copy so pod upgrades never write back to the authored resource.
	data = data.duplicate() as PlayerData
	_camera.fov = data.base_fov
	_health = data.max_health
	_base_mask = collision_mask
	_intent.menu_repeat_delay = data.menu_repeat_delay
	_intent.menu_repeat_interval = data.menu_repeat_interval
	for child: Node in _camera.get_children():
		if child is Weapon:
			var weapon: Weapon = child as Weapon
			_weapons.append(weapon)
			weapon.recoiled.connect(_on_weapon_recoiled)
			weapon.visible = armed and weapon == _weapon


## What to carry into the fight. Without this call the player carries every weapon there is, for testing.
func equip(loadout: Loadout) -> void:
	var carried: Array[Weapon] = []
	for weapon_data: WeaponData in loadout.weapons:
		for weapon: Weapon in _weapons:
			if weapon.data == weapon_data:
				carried.append(weapon)
	if carried.is_empty():
		return
	for weapon: Weapon in _weapons:
		weapon.visible = false
	_weapons = carried
	_weapon = _weapons[0]
	_weapon.visible = armed

	var ammo_scale: float = 1.0
	if loadout.vest != null:
		_damage_taken_scale = loadout.vest.damage_taken_scale
		_sprint_scale = loadout.vest.sprint_scale
		ammo_scale = loadout.vest.ammo_scale
	for weapon: Weapon in _weapons:
		weapon.scale_ammo(ammo_scale)
	for mod: ItemData in loadout.mods:
		if mod.effect == ItemData.Effect.STARTER_MAG:
			# The starting weapon is the first one in the scene.
			for weapon: Weapon in _weapons:
				if weapon == $Head/Camera3D/Weapon:
					weapon.add_mag_size(roundi(mod.amount))
	_pocket = loadout.consumable


func _process(delta: float) -> void:
	_weapon.aiming = is_aiming()
	_apply_look(delta)
	_update_recoil(delta)
	_update_shake(delta)
	_update_fov(delta)


func _physics_process(delta: float) -> void:
	_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)

	var wish_direction: Vector3 = _get_wish_direction()
	if _intent.consume_dash() and _dash_cooldown_left <= 0.0:
		_start_dash(wish_direction)

	if is_dashing():
		_dash_time_left = maxf(_dash_time_left - delta, 0.0)
		velocity.x = _dash_direction.x * data.dash_speed
		velocity.z = _dash_direction.z * data.dash_speed
	else:
		_apply_ground_movement(wish_direction, delta)
	collision_mask = _base_mask & ~data.dash_ignore_mask if is_dashing() else _base_mask

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity += get_gravity() * delta

	move_and_slide()
	_tick_heal(delta)

	if not armed:
		return
	if _intent.consume_use_item():
		_use_pocket()

	var slot: int = _intent.consume_weapon_slot()
	if _intent.consume_weapon_cycle():
		slot = (_weapons.find(_weapon) + 1) % _weapons.size()
	if slot >= 0:
		_equip(slot)

	if _intent.consume_reload():
		_weapon.try_reload()
	if _intent.consume_fire():
		_weapon.try_fire()


func take_hit(hit: HitInfo) -> void:
	if _health <= 0.0:
		return
	if is_invulnerable():
		dodged.emit(hit)
		return
	hit.damage *= _damage_taken_scale
	_health = maxf(_health - hit.damage, 0.0)
	damaged.emit(hit)
	health_changed.emit(_health, data.max_health)
	if _health <= 0.0:
		died.emit()


func heal(amount: float) -> void:
	_health = minf(_health + amount, data.max_health)
	health_changed.emit(_health, data.max_health)


## What is in the pocket, or null.
func get_pocket() -> ItemData:
	return _pocket


func is_healing() -> bool:
	return _heal_left > 0.0


func _use_pocket() -> void:
	if _pocket == null or _health <= 0.0 or _health >= data.max_health:
		return
	var item: ItemData = _pocket
	_pocket = null
	if item.effect == ItemData.Effect.HEAL_OVER_TIME:
		_heal_left = maxf(item.duration, 0.01)
		_heal_rate = item.amount / _heal_left
	item_used.emit(item)


func _tick_heal(delta: float) -> void:
	if _heal_left <= 0.0 or _health <= 0.0:
		return
	var step: float = minf(delta, _heal_left)
	_heal_left -= step
	heal(_heal_rate * step)


## 0.1 makes the dash come back 10% sooner.
func quicken_dash(fraction: float) -> void:
	data.dash_cooldown *= 1.0 - fraction


## Screenshake input, 0.0 to 1.0. Shake strength is trauma squared.
func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


## The weapon in hand.
func get_weapon() -> Weapon:
	return _weapon


func get_weapons() -> Array[Weapon]:
	return _weapons


func get_intent() -> PlayerIntent:
	return _intent


func get_health() -> float:
	return _health


## Where the player is aiming, radians up from level. Recoil and shake not included.
func get_pitch() -> float:
	return _pitch


## True while the sights are up. Only some weapons have them, and a reload or a dash brings them down.
func is_aiming() -> bool:
	return armed and _weapon.get_stats().aim_fov > 0.0 and _intent.is_aiming() \
			and not _weapon.is_reloading() and not is_dashing()


func is_dashing() -> bool:
	return _dash_time_left > 0.0


## Dash grants i-frames for its whole duration.
func is_invulnerable() -> bool:
	return is_dashing()


## 0.0 just after dashing, 1.0 when the dash is ready.
func get_dash_charge() -> float:
	if data.dash_cooldown <= 0.0:
		return 1.0
	return 1.0 - _dash_cooldown_left / data.dash_cooldown


func _get_wish_direction() -> Vector3:
	var move: Vector2 = _intent.get_move()
	var direction: Vector3 = global_basis * Vector3(move.x, 0.0, move.y)
	direction.y = 0.0
	return direction.limit_length(1.0)


func _equip(slot: int) -> void:
	if slot >= _weapons.size() or _weapons[slot] == _weapon:
		return
	_weapon.holster()
	_weapon = _weapons[slot]
	_weapon.draw()
	weapon_changed.emit(_weapon)


func _start_dash(wish_direction: Vector3) -> void:
	_dash_direction = wish_direction.normalized()
	if _dash_direction.is_zero_approx():
		_dash_direction = -global_basis.z
	_dash_time_left = data.dash_duration
	_dash_cooldown_left = data.dash_cooldown
	dashed.emit(_dash_direction)


func _apply_ground_movement(wish_direction: Vector3, delta: float) -> void:
	var top_speed: float = data.sprint_speed * _sprint_scale if _is_sprinting() else data.walk_speed
	var backward: float = maxf(_intent.get_move().y, 0.0)
	top_speed *= lerpf(1.0, data.backpedal_multiplier, backward)
	if is_aiming():
		top_speed *= _weapon.get_stats().aim_move_scale
	var target: Vector3 = wish_direction * top_speed
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var rate: float = data.deceleration if wish_direction.is_zero_approx() else data.acceleration
	horizontal = horizontal.move_toward(target, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


## Sprint only counts while moving forward.
func _is_sprinting() -> bool:
	return _intent.is_sprinting() and _intent.get_move().y < 0.0 and not is_aiming()


func _apply_look(delta: float) -> void:
	var look: Vector2 = _intent.consume_look() * data.mouse_sensitivity
	# The mouse says how far it moved; the stick says how fast to turn.
	var stick: Vector2 = _intent.get_look_stick()
	stick *= pow(stick.length(), data.stick_curve - 1.0)
	look.x += stick.x * deg_to_rad(data.stick_yaw_speed) * delta
	look.y += stick.y * deg_to_rad(data.stick_pitch_speed) * delta
	# Zoomed in, the same hand movement covers the same distance on screen.
	if is_aiming():
		look *= _weapon.get_stats().aim_fov / data.base_fov
	if look.is_zero_approx():
		return
	rotate_y(-look.x)
	var max_pitch: float = deg_to_rad(data.max_pitch_degrees)
	_pitch = clampf(_pitch - look.y, -max_pitch, max_pitch)


func _update_recoil(delta: float) -> void:
	var stats: WeaponData = _weapon.get_stats()
	_recoil_target = _recoil_target.lerp(Vector2.ZERO, 1.0 - exp(-stats.recoil_recover_speed * delta))
	_recoil = _recoil.lerp(_recoil_target, 1.0 - exp(-stats.recoil_snap_speed * delta))
	var max_pitch: float = deg_to_rad(data.max_pitch_degrees)
	_head.rotation.x = clampf(_pitch + _recoil.y, -max_pitch, max_pitch)
	_head.rotation.y = _recoil.x


func _on_weapon_recoiled(kick: Vector2) -> void:
	_recoil_target += kick


func _update_shake(delta: float) -> void:
	_trauma = maxf(_trauma - data.shake_decay * delta, 0.0)
	_shake_time += delta * data.shake_frequency
	var strength: float = _trauma * _trauma * deg_to_rad(data.shake_max_degrees)
	# Shake lives on the camera only, so it never moves the aim.
	_camera.rotation = Vector3(
			_shake_noise.get_noise_2d(_shake_time, 0.0),
			_shake_noise.get_noise_2d(_shake_time, 100.0),
			_shake_noise.get_noise_2d(_shake_time, 200.0)) * strength


func _update_fov(delta: float) -> void:
	var target_fov: float = data.base_fov
	if is_aiming():
		target_fov = _weapon.get_stats().aim_fov
	elif is_dashing():
		target_fov += data.dash_fov_bonus
	elif _is_sprinting():
		target_fov += data.sprint_fov_bonus
	var weight: float = 1.0 - exp(-data.fov_lerp_speed * delta)
	_camera.fov = lerpf(_camera.fov, target_fov, weight)
