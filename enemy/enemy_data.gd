class_name EnemyData
extends Resource

@export_group("Body")
@export var max_health: float = 30.0
@export var move_speed: float = 4.5
@export var acceleration: float = 30.0

@export_group("Melee")
## Distance to the target at which the windup starts.
@export var attack_range: float = 1.5
## Distance at which the blow still connects once the windup ends.
@export var attack_reach: float = 2.0
@export var attack_windup: float = 0.45
@export var attack_recover: float = 0.7
@export var attack_damage: float = 10.0

@export_group("Feedback")
@export var body_color: Color = Color(0.7, 0.15, 0.15)
@export var hit_flash_color: Color = Color(1.0, 1.0, 1.0)
@export var windup_color: Color = Color(1.0, 0.55, 0.0)
@export var flash_fade_speed: float = 10.0
@export var pop_scale: float = 1.7
@export var pop_time: float = 0.12
