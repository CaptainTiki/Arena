class_name KioskPanel
extends CanvasLayer
## A kiosk menu: a list down the left, and beside it what the picked-out line is about.
## The owner says what to list and passes on what the player pressed; clicks come up from the rows.

## A line was clicked. The owner decides what choosing it means.
signal entry_clicked(entry: MenuEntry)

var _rows: Array[MenuRow] = []
var _entries: Array[MenuEntry] = []
## The entry picked out, as an index into `_entries`, or -1.
var _picked: int = -1

@onready var _title: Label = $Back/Title
@onready var _wallet: Label = $Back/Wallet
@onready var _rows_root: Control = $Back/Rows
@onready var _detail: Label = $Back/Detail
@onready var _message: Label = $Back/Message


func _ready() -> void:
	visible = false
	for child: Node in _rows_root.get_children():
		var row: MenuRow = child as MenuRow
		_rows.append(row)
		row.clicked.connect(_on_row_clicked)
		row.hovered.connect(_on_row_hovered)


## Lists `entries`, keeping the same line picked out if there is still one there.
func show_menu(title: String, wallet: String, entries: Array[MenuEntry], message: String) -> void:
	visible = true
	_title.text = title
	_wallet.text = wallet
	_message.text = message
	_entries = entries
	if _entries.size() > _rows.size():
		push_warning("KioskPanel: %d lines, room for %d" % [_entries.size(), _rows.size()])
	for index: int in _rows.size():
		if index < _entries.size():
			_rows[index].show_entry(_entries[index])
		else:
			_rows[index].visible = false
	if _picked < 0 or _picked >= _entries.size() or not _entries[_picked].selectable:
		_picked = -1
		move(1)
	_refresh()


func close() -> void:
	visible = false
	_picked = -1


## Forgets which line was picked out, so the next list starts from its top.
func reset_pick() -> void:
	_picked = -1


## Moves the pick up (-1) or down (1), over headings, round the ends.
func move(step: int) -> void:
	var count: int = mini(_entries.size(), _rows.size())
	if count == 0 or step == 0:
		return
	var index: int = _picked
	for attempt: int in count:
		index = posmod(index + step, count)
		if _entries[index].selectable:
			_picked = index
			break
	_refresh()


func get_picked() -> MenuEntry:
	if _picked < 0 or _picked >= _entries.size():
		return null
	return _entries[_picked]


func get_entries() -> Array[MenuEntry]:
	return _entries


func _refresh() -> void:
	for index: int in _rows.size():
		_rows[index].set_picked(index == _picked)
	var entry: MenuEntry = get_picked()
	_detail.text = "" if entry == null else entry.detail


func _on_row_hovered(row: MenuRow) -> void:
	var index: int = _rows.find(row)
	if index >= 0 and index < _entries.size() and _entries[index].selectable:
		_picked = index
		_refresh()


func _on_row_clicked(row: MenuRow) -> void:
	_on_row_hovered(row)
	var entry: MenuEntry = get_picked()
	if entry != null:
		entry_clicked.emit(entry)
