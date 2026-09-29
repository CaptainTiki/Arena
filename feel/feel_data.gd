class_name FeelData
extends Resource
## How hard the game reacts to combat events.

@export_group("Hitstop")
## Game speed while frozen.
@export_range(0.0, 1.0) var hitstop_time_scale: float = 0.05
## Real seconds frozen on a kill.
@export var hitstop_kill: float = 0.05
@export var hitstop_headshot_kill: float = 0.09

@export_group("Screenshake")
## Trauma added per point of damage. Trauma runs 0.0 to 1.0; shake strength is trauma squared.
@export var trauma_per_damage_dealt: float = 0.012
@export var trauma_per_kill: float = 0.15
@export var trauma_per_damage_taken: float = 0.06
## Thump when a pod lands right next to the player; fades to nothing at the falloff distance.
@export var trauma_pod_landing: float = 0.5
@export var pod_landing_falloff: float = 30.0
