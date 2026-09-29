class_name SummaryRow
extends Control
## One sponsor's line on the run summary.

@onready var _headline: Label = $Headline
@onready var _detail: Label = $Detail


func setup(result: SponsorResult) -> void:
	var sponsor: SponsorData = result.sponsor
	_headline.modulate = sponsor.color
	_headline.text = "%s   Reputation: %d -> %d" % [
			sponsor.display_name, result.reputation_before, result.reputation_after]
	_detail.text = "Wants: %s.   Pods dropped: %d.   Standing at the end: %d%%.   Reputation buys: %s." % [
			sponsor.wants, result.drops, roundi(result.standing * 100.0), sponsor.perk_teaser]
