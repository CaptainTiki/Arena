class_name PlayerData
extends Resource

@export_group("Movement")
@export var walk_speed: float = 7.0
@export var sprint_speed: float = 11.0
@export var acceleration: float = 70.0
@export var deceleration: float = 55.0

@export_group("Dash")
@export var dash_speed: float = 28.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 1.2

@export_group("Look")
## Radians of rotation per pixel of mouse travel.
@export var mouse_sensitivity: float = 0.0022
@export_range(0.0, 89.0) var max_pitch_degrees: float = 89.0

@export_group("Camera")
@export var base_fov: float = 90.0
@export var sprint_fov_bonus: float = 5.0
@export var dash_fov_bonus: float = 14.0
@export var fov_lerp_speed: float = 12.0
