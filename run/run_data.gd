class_name RunData
extends Resource

## Seconds the contract card stays up at the start of a fight.
@export var briefing_time: float = 6.0
## Seconds the summary ignores input after it appears, so a panic click doesn't skip it.
@export var summary_input_delay: float = 1.0

@export_group("Favour")
## The sponsor who asked for a contract pays this many times its usual favour for it.
@export var request_multiplier: float = 2.0

@export_group("Hold Zone Noise")
## Standing in the active hold zone is heard this far from the zone.
@export var zone_noise_radius: float = 45.0
## Seconds between one call from a held zone and the next.
@export var zone_noise_interval: float = 1.0
