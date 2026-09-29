class_name RosterWave
extends Resource
## One group of named enemies in an extermination contract.

## This wave arrives at this time at the latest. It arrives early if the floor is cleared first.
@export var start_time: float = 0.0
@export var grunts: int = 0
@export var shooters: int = 0
@export var heavies: int = 0


func get_total() -> int:
	return grunts + shooters + heavies
