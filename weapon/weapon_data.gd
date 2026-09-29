class_name WeaponData
extends Resource

@export var display_name: String = "WEAPON"

@export_group("Damage")
@export var damage: float = 20.0
@export var headshot_multiplier: float = 2.0
@export var max_range: float = 200.0
## Speed the target is shoved back at, metres per second.
@export var knockback: float = 4.0
@export var headshot_knockback_multiplier: float = 2.0
## Rays per shot. Damage and knockback are per pellet.
@export var pellets: int = 1
## Pellets scatter inside a cone this many degrees off the aim.
@export var spread_degrees: float = 0.0

@export_group("Ammo")
@export var mag_size: int = 12
@export var starting_reserve: int = 24
@export var reload_time: float = 1.4
## Pulling the trigger on an empty mag starts a reload if there is reserve.
@export var reload_on_dry_fire: bool = true
## Ammo pickups and mag upgrades are counted in pistol rounds; this weapon gets this share of them.
@export var pickup_scale: float = 1.0

@export_group("Trigger")
## Minimum seconds between shots. Semi-auto: one shot per click.
@export var fire_interval: float = 0.16
## Seconds after drawing the weapon before it can fire.
@export var draw_time: float = 0.3

@export_group("Recoil")
## Upward aim kick per shot.
@export var recoil_pitch_degrees: float = 3.4
## Sideways aim kick per shot, rolled randomly between minus and plus this.
@export var recoil_yaw_degrees: float = 1.5
## How fast the view snaps to the kicked position.
@export var recoil_snap_speed: float = 45.0
## How fast the aim settles back. Lower means rapid fire climbs more.
@export var recoil_recover_speed: float = 5.5

@export_group("View")
@export var kick_distance: float = 0.12
@export var kick_recover_speed: float = 14.0
@export var reload_dip: float = 0.3

@export_group("Noise")
## Enemies within this distance hear the shot and come to look.
@export var noise_radius: float = 40.0
