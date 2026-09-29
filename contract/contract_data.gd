class_name ContractData
extends Resource
## One bookable fight: what you face, how long you have, what it pays.

enum Type {
	## Kill every enemy on the roster.
	EXTERMINATION,
	## Stay alive until the clock runs out while the arena fills.
	SURVIVAL,
	## Collect a number of pods from one sponsor.
	SCAVENGER,
}

@export var display_name: String = "CONTRACT"
@export_multiline var briefing: String = ""
@export var type: Type = Type.EXTERMINATION
## EXTERMINATION and SCAVENGER fail at this time. SURVIVAL is won at this time.
@export var time_limit: float = 300.0
@export var cash_reward: int = 300

@export_group("Enemies")
@export var enemy_health_scale: float = 1.0
@export var enemy_damage_scale: float = 1.0
## EXTERMINATION: the named enemies, in the order they arrive.
@export var roster: Array[RosterWave] = []
## SURVIVAL and SCAVENGER: the density ramp.
@export var ramp: Array[SpawnWave] = []

@export_group("Scavenger")
@export var target_sponsor: SponsorData
@export var target_count: int = 3


func get_type_name() -> String:
	return Type.keys()[type]


func get_roster_total() -> int:
	var total: int = 0
	for wave: RosterWave in roster:
		total += wave.get_total()
	return total


## "9 grunts, 5 shooters, 1 heavy", or a description of the ramp.
func get_enemy_summary() -> String:
	if type != Type.EXTERMINATION:
		if ramp.is_empty():
			return "none"
		return "a growing crowd, up to %d at once" % ramp[-1].alive_at_end
	var grunts: int = 0
	var shooters: int = 0
	var heavies: int = 0
	for wave: RosterWave in roster:
		grunts += wave.grunts
		shooters += wave.shooters
		heavies += wave.heavies
	var parts: PackedStringArray = []
	if grunts > 0:
		parts.append("%d grunt%s" % [grunts, "" if grunts == 1 else "s"])
	if shooters > 0:
		parts.append("%d shooter%s" % [shooters, "" if shooters == 1 else "s"])
	if heavies > 0:
		parts.append("%d heav%s" % [heavies, "y" if heavies == 1 else "ies"])
	return ", ".join(parts) + " in %d wave%s" % [roster.size(), "" if roster.size() == 1 else "s"]


func get_goal() -> String:
	match type:
		Type.EXTERMINATION:
			return "Kill everything before the clock runs out"
		Type.SURVIVAL:
			return "Stay alive until the clock runs out"
		Type.SCAVENGER:
			return "Collect %d pods from %s before the clock runs out" % [
					target_count, target_sponsor.display_name]
	return ""
