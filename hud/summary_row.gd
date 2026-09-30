class_name SummaryRow
extends Control
## One sponsor's line on the run summary.

@onready var _headline: Label = $Headline
@onready var _detail: Label = $Detail


func setup(result: SponsorResult) -> void:
	var sponsor: SponsorData = result.sponsor
	_headline.modulate = sponsor.color
	_headline.text = "%s   Favour: %d -> %d%s" % [
			sponsor.display_name, result.favour_before, result.favour_after,
			"   (asked for this fight: double)" if result.requested else ""]
	_detail.text = "Wants: %s.   Score: %d.   Pods dropped: %d." % [
			sponsor.wants, roundi(result.score), result.drops]
