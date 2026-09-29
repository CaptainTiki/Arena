class_name PodData
extends Resource

enum Effect { AMMO, HEALTH, MAG_SIZE, FIRE_RATE, DASH_COOLDOWN }

## Shown on the pod and in the pickup pop.
@export var display_name: String = "POD"
@export var effect: Effect = Effect.AMMO
## AMMO: rounds added to reserve. HEALTH: health restored. MAG_SIZE: rounds added to the mag.
## FIRE_RATE and DASH_COOLDOWN: fraction shaved off the interval or cooldown (0.1 is 10% faster).
@export var amount: float = 12.0
## Seconds the pod waits on the floor before it despawns.
@export var lifetime: float = 25.0
