class_name EnemyData
extends Resource

@export_group("Body")
@export var max_health: float = 40.0
@export var move_speed: float = 5.0
## Each enemy rolls its own speed within plus or minus this fraction, so the pack strings out.
@export_range(0.0, 0.5) var speed_variance: float = 0.15
@export var acceleration: float = 30.0
## How quickly knockback speed bleeds off, metres per second squared.
@export var knockback_friction: float = 22.0

@export_group("Pursuit")
## Each enemy rolls a lead time up to this and runs at where the target will be, to cut it off.
@export var lead_time_max: float = 1.0
## Inside this distance the enemy stops leading and runs straight at the target.
@export var lead_falloff_distance: float = 8.0
## Each enemy replans its route at a random interval in this range, so the pack never replans on one frame.
@export var repath_interval_min: float = 0.25
@export var repath_interval_max: float = 0.5
## A route corner counts as reached inside this distance.
@export var waypoint_reach: float = 0.7

@export_group("Melee")
## Distance to the target at which the windup starts.
@export var attack_range: float = 2.5
@export var attack_windup: float = 0.35
## After the windup the enemy lunges in a straight line at this speed.
@export var lunge_speed: float = 16.0
@export var lunge_duration: float = 0.3
## The lunge connects if it gets this close to the target.
@export var attack_reach: float = 1.3
## No windup or strike when the target is further above or below than this.
@export var attack_height_tolerance: float = 1.5
@export var attack_recover: float = 0.6
@export var attack_damage: float = 10.0

@export_group("Feedback")
@export var body_color: Color = Color(0.7, 0.15, 0.15)
@export var hit_flash_color: Color = Color(1.0, 1.0, 1.0)
@export var windup_color: Color = Color(1.0, 0.55, 0.0)
@export var flash_fade_speed: float = 10.0
## The body squashes to this height during the windup.
@export var windup_squash: float = 0.75
@export var pop_scale: float = 1.7
@export var pop_time: float = 0.12
