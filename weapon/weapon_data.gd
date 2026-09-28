class_name WeaponData
extends Resource

@export_group("Damage")
@export var damage: float = 10.0
@export var headshot_multiplier: float = 2.0
@export var max_range: float = 200.0

@export_group("Ammo")
@export var mag_size: int = 6
@export var starting_reserve: int = 12
@export var reload_time: float = 1.4
## Pulling the trigger on an empty mag starts a reload if there is reserve.
@export var reload_on_dry_fire: bool = true

@export_group("Trigger")
## Minimum seconds between shots. Semi-auto: one shot per click.
@export var fire_interval: float = 0.16

@export_group("Recoil")
## Upward aim kick per shot.
@export var recoil_pitch_degrees: float = 2.2
## Sideways aim kick per shot, rolled randomly between minus and plus this.
@export var recoil_yaw_degrees: float = 0.9
## How fast the view snaps to the kicked position.
@export var recoil_snap_speed: float = 45.0
## How fast the aim settles back. Lower means rapid fire climbs more.
@export var recoil_recover_speed: float = 7.0

@export_group("View")
@export var kick_distance: float = 0.12
@export var kick_recover_speed: float = 14.0
@export var reload_dip: float = 0.3
