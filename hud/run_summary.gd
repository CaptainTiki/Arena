class_name RunSummary
extends CanvasLayer
## End-of-fight screen: what happened, what it paid, what each sponsor thought.

var _rows: Array[SummaryRow] = []

@onready var _title: Label = $Panel/Content/Title
@onready var _pay: Label = $Panel/Content/Pay
@onready var _stats: Label = $Panel/Content/Stats
@onready var _rows_root: Control = $Panel/Content/Rows
@onready var _teaser: Label = $Panel/Content/Teaser
@onready var _prompt: Label = $Panel/Content/Prompt


func _ready() -> void:
	visible = false
	for child: Node in _rows_root.get_children():
		_rows.append(child as SummaryRow)


func show_summary(
		title: String, contract: ContractData, cash_earned: int, cash_total: int,
		stats: RunStats, results: Array[SponsorResult]) -> void:
	visible = true
	_prompt.visible = false
	_title.text = title
	_pay.text = "%s   paid $%d of $%d      Wallet: $%d" % [
			contract.display_name, cash_earned, contract.cash_reward, cash_total]
	_stats.text = "Time  %s      Kills  %d      Pods  %d\nHeadshots  %d%% of hits      Hit rate  %d%% of %d shots" % [
			Hud.format_clock(stats.time_survived), stats.kills, stats.pods_collected,
			roundi(stats.get_headshot_rate() * 100.0), roundi(stats.get_hit_rate() * 100.0),
			stats.shots]

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
		_teaser.text = "Next fight, courtesy of %s: %s" % [
				favourite.sponsor.display_name, favourite.sponsor.perk_teaser]
		_teaser.modulate = favourite.sponsor.color


func show_prompt(next_contract: ContractData) -> void:
	_prompt.text = "Click: fight this contract again      R: next contract (%s)" % next_contract.display_name
	_prompt.visible = true
