class_name AmmoStationData
extends Resource

## Rounds added to reserve per pickup.
@export var ammo: int = 12
## Seconds from being emptied to being stocked again.
@export var restock_time: float = 120.0
## The light flashes for this long before the restock lands.
@export var warning_time: float = 15.0
@export var flash_rate: float = 3.0

@export_group("Lights")
@export var empty_color: Color = Color(0.8, 0.1, 0.1)
@export var warning_color: Color = Color(1.0, 0.7, 0.1)
@export var stocked_color: Color = Color(0.2, 1.0, 0.3)
@export var dark_color: Color = Color(0.12, 0.12, 0.12)
