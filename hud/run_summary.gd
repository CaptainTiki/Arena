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

	var earned: int = 0
	for index: int in _rows.size():
		_rows[index].visible = index < results.size()
		if index >= results.size():
			continue
		_rows[index].setup(results[index])
		earned += results[index].favour_after - results[index].favour_before

	if cash_earned > 0:
		_teaser.text = "Favour earned: %d, at x%s for this contract." % [
				earned, String.num(contract.favour_multiplier, 1)]
	else:
		_teaser.text = "Nothing is paid for a loss. What you bought is still yours."


func show_prompt() -> void:
	_prompt.text = "Click or [E]: back to the base"
	_prompt.visible = true
