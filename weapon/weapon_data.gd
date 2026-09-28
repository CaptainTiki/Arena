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

@export_group("View")
@export var kick_distance: float = 0.12
@export var kick_recover_speed: float = 14.0
@export var reload_dip: float = 0.3
