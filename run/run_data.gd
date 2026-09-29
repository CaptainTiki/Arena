class_name RunData
extends Resource

## Seconds the contract card stays up at the start of a fight.
@export var briefing_time: float = 6.0
## Seconds the summary ignores input after it appears, so a panic click doesn't skip it.
@export var summary_input_delay: float = 1.0

@export_group("Reputation")
## A sponsor's reputation rises by one for every this many pods it dropped during the fight.
@export var drops_per_reputation: int = 2
@export var max_reputation_gain: int = 3
