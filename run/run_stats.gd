class_name RunStats
extends RefCounted
## Tallies for the run summary.

var time_survived: float = 0.0
var kills: int = 0
var shots: int = 0
var hits: int = 0
var headshots: int = 0
var pods_collected: int = 0


func record_shot(hit: HitInfo) -> void:
	shots += 1
	if hit != null and hit.landed():
		hits += 1
		if hit.is_headshot:
			headshots += 1


## Share of shots fired that hit an enemy, 0.0 to 1.0.
func get_hit_rate() -> float:
	return 0.0 if shots == 0 else float(hits) / float(shots)


## Share of hits that were headshots, 0.0 to 1.0.
func get_headshot_rate() -> float:
	return 0.0 if hits == 0 else float(headshots) / float(hits)
