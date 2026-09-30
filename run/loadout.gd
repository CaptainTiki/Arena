class_name Loadout
extends RefCounted
## What the player carries into one fight. Set in the base, fixed once the fight starts.

## In slot order.
var weapons: Array[WeaponData] = []
## Null for none.
var vest: ItemData
## What is in the pocket, or null.
var consumable: ItemData
var mods: Array[ItemData] = []
