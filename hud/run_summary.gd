class_name RunSummary
extends CanvasLayer
## End-of-run screen: what happened, what each sponsor thought, what reputation will buy.

var _rows: Array[SummaryRow] = []

@onready var _title: Label = $Panel/Content/Title
@onready var _stats: Label = $Panel/Content/Stats
@onready var _rows_root: Control = $Panel/Content/Rows
@onready var _teaser: Label = $Panel/Content/Teaser
@onready var _prompt: Label = $Panel/Content/Prompt


func _ready() -> void:
	visible = false
	for child: Node in _rows_root.get_children():
		_rows.append(child as SummaryRow)


func show_summary(survived: bool, stats: RunStats, results: Array[SponsorResult]) -> void:
	visible = true
	_prompt.visible = false
	_title.text = "RUN COMPLETE" if survived else "YOU DIED"
	var seconds: int = int(stats.time_survived)
	@warning_ignore("integer_division")
	var minutes: int = seconds / 60
	_stats.text = "Time survived  %02d:%02d\nKills  %d\nHeadshots  %d%% of hits\nHit rate  %d%% of %d shots\nPods collected  %d" % [
			minutes, seconds % 60, stats.kills, roundi(stats.get_headshot_rate() * 100.0),
			roundi(stats.get_hit_rate() * 100.0), stats.shots, stats.pods_collected]

	var favourite: SponsorResult = null
	for index: int in _rows.size():
		_rows[index].visible = index < results.size()
		if index >= results.size():
			continue
		_rows[index].setup(results[index])
		if favourite == null or results[index].reputation_after > favourite.reputation_after:
			favourite = results[index]

	if favourite == null or favourite.reputation_after <= 0:
		_teaser.text = "No sponsor knows your name yet."
		_teaser.modulate = Color.WHITE
	else:
		_teaser.text = "Next run, courtesy of %s: %s" % [
				favourite.sponsor.display_name, favourite.sponsor.perk_teaser]
		_teaser.modulate = favourite.sponsor.color


func show_prompt() -> void:
	_prompt.visible = true
