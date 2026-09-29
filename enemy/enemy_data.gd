class_name EnemyData
extends Resource

enum AttackStyle {
	## Winds up, then lunges in a straight line.
	LUNGE,
	## Raises its arms and slams the ground around it. Can also charge from range.
	SLAM,
	## Keeps its distance and fires aimed projectiles when it can see the target.
	RANGED,
}

@export var attack_style: AttackStyle = AttackStyle.LUNGE

@export_group("Body")
@export var max_health: float = 40.0
@export var move_speed: float = 5.0
## Each enemy rolls its own speed within plus or minus this fraction, so the pack strings out.
@export_range(0.0, 0.5) var speed_variance: float = 0.15
@export var acceleration: float = 30.0
## How quickly knockback speed bleeds off, metres per second squared.
@export var knockback_friction: float = 22.0
## Multiplies incoming knockback. Heavy things barely move.
@export var knockback_scale: float = 1.0

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

@export_group("Attack")
## LUNGE: distance at which the windup starts. SLAM: distance at which it stops walking.
@export var attack_range: float = 2.5
## Seconds of telegraph before a lunge, a charge or a shot.
@export var attack_windup: float = 0.35
@export var attack_recover: float = 0.6
## Damage of one lunge or one projectile.
@export var attack_damage: float = 10.0
## No strike when the target is further above or below than this.
@export var attack_height_tolerance: float = 1.5

@export_group("Lunge")
## Also the speed and length of a slam enemy's charge.
@export var lunge_speed: float = 16.0
@export var lunge_duration: float = 0.3
## The lunge or charge connects if it gets this close to the target.
@export var attack_reach: float = 1.3

@export_group("Slam")
## Starts raising its arms when the target is this close.
@export var slam_trigger_distance: float = 3.0
## Everything inside this distance is hit when the arms come down.
@export var slam_radius: float = 4.5
## Seconds the arms are raised before they come down.
@export var slam_windup: float = 0.7
@export var slam_recover: float = 1.3
@export var slam_damage: float = 22.0

@export_group("Charge")
## Slam enemies only. Seconds between charges; zero means it never charges.
@export var charge_cooldown: float = 0.0
## Charges only when the target is between these distances with clear ground between.
@export var charge_min_distance: float = 10.0
@export var charge_max_distance: float = 30.0
@export var charge_damage: float = 25.0

@export_group("Ranged")
## Stops advancing and starts shooting inside this distance, if it can see the target.
@export var preferred_range: float = 24.0
## Backs away when the target gets closer than this.
@export var retreat_range: float = 9.0
@export var projectile_speed: float = 24.0
## Height the shot leaves from.
@export var muzzle_height: float = 1.4
## Each enemy rolls how well it leads a moving target: 0.0 aims where you are, 1.0 where you will be.
@export_range(0.0, 1.0) var lead_accuracy_min: float = 0.6
@export_range(0.0, 1.0) var lead_accuracy_max: float = 1.0

@export_group("Feedback")
@export var body_color: Color = Color(0.7, 0.15, 0.15)
@export var hit_flash_color: Color = Color(1.0, 1.0, 1.0)
@export var windup_color: Color = Color(1.0, 0.55, 0.0)
@export var flash_fade_speed: float = 10.0
## The body squashes to this height during a lunge, charge or shot windup.
@export var windup_squash: float = 0.75
@export var pop_scale: float = 1.7
@export var pop_time: float = 0.12
## How far the arms swing up for a slam, in degrees from hanging straight down.
@export var arm_raise_degrees: float = 165.0
@export var arm_raise_speed: float = 8.0
@export var arm_slam_speed: float = 30.0
@export var turn_speed: float = 10.0
## False leaves it facing the way it struck until it has recovered, so its back can be reached.
@export var turn_while_recovering: bool = true
