class_name AmmoStationData
extends Resource

## Rounds added to reserve per pickup.
@export var ammo: int = 12
## Health restored per pickup.
@export var health: float = 30.0
## What each costs. Paid in cash, or in favour with whichever sponsor has the most to spare.
@export var ammo_cash: int = 20
@export var ammo_favour: int = 2
@export var health_cash: int = 40
@export var health_favour: int = 4
## Chance that a restock brings health instead of ammo.
@export_range(0.0, 1.0) var health_chance: float = 0.4
## Seconds from being emptied to being stocked again.
@export var restock_time: float = 120.0
## The light flashes for this long before the restock lands.
@export var warning_time: float = 15.0
@export var flash_rate: float = 3.0

@export_group("Lights")
@export var ammo_color: Color = Color(0.15, 0.45, 1.0)
@export var health_color: Color = Color(1.0, 0.1, 0.1)
## The off beat of a flashing light.
@export var dark_color: Color = Color(0.12, 0.12, 0.12)
