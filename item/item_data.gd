class_name ItemData
extends Resource
## One thing that can be owned: a weapon, a vest, something for the pocket, or a permanent mod.

enum Category { WEAPON, VEST, CONSUMABLE, MOD }
enum Effect {
	NONE,
	## CONSUMABLE: restores `amount` health over `duration` seconds.
	HEAL_OVER_TIME,
	## MOD: adds `amount` rounds to the starting weapon's magazine.
	STARTER_MAG,
}

## Written to the save file. Never change it once people have saves.
@export var id: StringName = &""
@export var display_name: String = "ITEM"
@export_multiline var description: String = ""
@export var category: Category = Category.WEAPON

@export_group("Price")
@export var price_cash: int = 0
## Owned by every profile from the start.
@export var starter: bool = false
## How many can be owned at once. Everything but a consumable is owned once.
@export var stack_limit: int = 1

@export_group("Weapon")
@export var weapon: WeaponData

@export_group("Vest")
## Multiplies every hit taken. 0.7 takes 30% off.
@export var damage_taken_scale: float = 1.0
## Multiplies the ammo each weapon starts with and the most it can carry.
@export var ammo_scale: float = 1.0
## Multiplies sprint speed.
@export var sprint_scale: float = 1.0

@export_group("Effect")
@export var effect: Effect = Effect.NONE
@export var amount: float = 0.0
@export var duration: float = 0.0


func get_price_text() -> String:
	return "$%d" % price_cash if price_cash > 0 else "free"
