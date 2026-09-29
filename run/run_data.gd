class_name RunData
extends Resource

## The run ends here if the player is still alive.
@export var run_length: float = 900.0
## Seconds the summary ignores input after it appears, so a panic click doesn't skip it.
@export var summary_input_delay: float = 1.0

@export_group("Reputation")
## A sponsor's reputation rises by one for every this many pods it dropped during the run.
@export var drops_per_reputation: int = 2
@export var max_reputation_gain: int = 3
