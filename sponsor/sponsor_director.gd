class_name SponsorDirector
extends Node
## Scores the player's behaviour for each sponsor and announces when one has seen enough to pay out.

signal drop_earned(sponsor: SponsorData, pod: PodData)
## Progress runs 0.0 to 1.0 toward the sponsor's next drop.
signal standing_changed(index: int, progress: float)
## A discrete thing the sponsor liked or disliked, worded for the player. `minor` is small change.
signal sponsor_reacted(index: int, reason: String, positive: bool, minor: bool)

@export var sponsors: Array[SponsorData] = []

var _scores: Array[float] = []
var _thresholds: Array[float] = []
var _drops: Array[int] = []
## Score over the whole fight, which drops don't spend. This is what favour is paid on.
var _earned: Array[float] = []
var _chains: Array[int] = []
var _chain_left: Array[float] = []
var _holding: bool = false


func _ready() -> void:
	for sponsor: SponsorData in sponsors:
		_scores.append(0.0)
		_thresholds.append(sponsor.threshold)
		_drops.append(0)
		_earned.append(0.0)
		_chains.append(0)
		_chain_left.append(0.0)


func _physics_process(delta: float) -> void:
	for index: int in sponsors.size():
		var sponsor: SponsorData = sponsors[index]
		match sponsor.trigger:
			SponsorData.Trigger.UNTOUCHED_STREAK:
				_add(index, sponsor.score_per_event * delta, "")
			SponsorData.Trigger.MULTIKILL:
				_chain_left[index] = maxf(_chain_left[index] - delta, 0.0)
			SponsorData.Trigger.HOLD_ZONE:
				if _holding:
					_add(index, sponsor.score_per_event * delta, "")


## Call every tick with whether the player is standing in the active hold zone.
func set_holding(holding: bool) -> void:
	if holding == _holding:
		return
	_holding = holding
	for index: int in sponsors.size():
		if sponsors[index].trigger == SponsorData.Trigger.HOLD_ZONE:
			sponsor_reacted.emit(index, "HOLDING" if holding else "LEFT THE ZONE", holding, false)


## Call for every shot fired. `hit` is null or not landed for a miss.
func on_shot(hit: HitInfo) -> void:
	for index: int in sponsors.size():
		var sponsor: SponsorData = sponsors[index]
		if sponsor.trigger != SponsorData.Trigger.HEADSHOTS:
			continue
		if hit == null or not hit.landed():
			if sponsor.penalty > 0.0:
				_add(index, -sponsor.penalty, "MISS")
		elif hit.is_headshot:
			_add(index, sponsor.score_per_event, "HEADSHOT")
		else:
			_add(index, sponsor.minor_score, "HIT", true)


func on_kill(_hit: HitInfo) -> void:
	for index: int in sponsors.size():
		var sponsor: SponsorData = sponsors[index]
		if sponsor.trigger != SponsorData.Trigger.MULTIKILL:
			continue
		_chains[index] = _chains[index] + 1 if _chain_left[index] > 0.0 else 1
		_chain_left[index] = sponsor.window
		if _chains[index] >= 2:
			var links: int = _chains[index] - 1
			_add(index, sponsor.score_per_event * links, "%d KILL CHAIN" % _chains[index])


func on_player_damaged(_hit: HitInfo) -> void:
	for index: int in sponsors.size():
		var sponsor: SponsorData = sponsors[index]
		if sponsor.trigger == SponsorData.Trigger.UNTOUCHED_STREAK and sponsor.penalty > 0.0:
			_add(index, -sponsor.penalty, "HIT TAKEN")


func get_progress(index: int) -> float:
	return clampf(_scores[index] / _thresholds[index], 0.0, 1.0)


func get_drop_count(index: int) -> int:
	return _drops[index]


func get_drop_counts() -> Array[int]:
	return _drops


## What each sponsor made of the fight so far, in sponsor order.
func get_earned() -> Array[float]:
	return _earned


func _add(index: int, amount: float, reason: String, minor: bool = false) -> void:
	var sponsor: SponsorData = sponsors[index]
	_scores[index] = maxf(_scores[index] + amount, 0.0)
	_earned[index] = maxf(_earned[index] + amount, 0.0)
	if not reason.is_empty():
		sponsor_reacted.emit(index, reason, amount > 0.0, minor)
	while _scores[index] >= _thresholds[index]:
		_scores[index] -= _thresholds[index]
		_thresholds[index] *= sponsor.threshold_growth
		if not sponsor.pods.is_empty():
			var pod: PodData = sponsor.pods[_drops[index] % sponsor.pods.size()]
			drop_earned.emit(sponsor, pod)
		_drops[index] += 1
	standing_changed.emit(index, get_progress(index))
