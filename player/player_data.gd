class_name PlayerData
extends Resource

@export_group("Health")
@export var max_health: float = 100.0

@export_group("Movement")
@export var walk_speed: float = 7.0
## Forward only.
@export var sprint_speed: float = 11.0
## Speed scale when moving straight backward. Blends in with the backward part of the input.
@export_range(0.0, 1.0) var backpedal_multiplier: float = 0.6
@export var acceleration: float = 70.0
@export var deceleration: float = 55.0

@export_group("Dash")
@export var dash_speed: float = 14.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 1.2
## Physics layers the player passes through while dashing.
@export_flags_3d_physics var dash_ignore_mask: int = 4

@export_group("Look")
## Radians of rotation per pixel of mouse travel.
@export var mouse_sensitivity: float = 0.0022
@export_range(0.0, 89.0) var max_pitch_degrees: float = 89.0

@export_group("Camera")
@export var base_fov: float = 90.0
@export var sprint_fov_bonus: float = 5.0
@export var dash_fov_bonus: float = 14.0
@export var fov_lerp_speed: float = 12.0

@export_group("Screenshake")
## Camera rotation at full trauma.
@export var shake_max_degrees: float = 5.0
## Trauma lost per second.
@export var shake_decay: float = 2.2
@export var shake_frequency: float = 120.0
