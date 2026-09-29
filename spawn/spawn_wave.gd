class_name SpawnWave
extends Resource
## One segment of the density ramp. The spawner plays waves back to back and
## holds the last wave's end count once the sequence runs out.

@export var duration: float = 60.0
## Target number of enemies alive at the start and end of this wave; ramps linearly between.
@export var alive_at_start: int = 3
@export var alive_at_end: int = 8
## Seconds between spawn attempts.
@export var spawn_interval: float = 1.5
## Most enemies added per attempt.
@export var batch_size: int = 1
## Relative odds of each enemy type, in the order of the spawner's pools (grunt, heavy, shooter).
@export var weights: PackedFloat32Array = PackedFloat32Array([1.0])
