class_name MenuEntry
extends RefCounted
## One line of a kiosk menu: a heading, or something that can be chosen.

var label: String = ""
## Shown at the right of the line: a price, or where things stand.
var note: String = ""
## Shown beside the list while this line is picked out.
var detail: String = ""
## False for a heading, which is skipped over.
var selectable: bool = true
## False greys the line. It can still be picked out and read, and choosing it says why not.
var available: bool = true
var color: Color = Color.WHITE
## Called when the line is chosen.
var action: Callable
## Called with -1 or 1 when the line is nudged left or right. Most lines have none.
var nudge: Callable


static func heading(text: String, tint: Color = Color(1.0, 1.0, 1.0, 0.6), side: String = "") -> MenuEntry:
	var entry: MenuEntry = MenuEntry.new()
	entry.label = text
	entry.note = side
	entry.selectable = false
	entry.color = tint
	return entry


static func option(text: String, side: String, about: String, chosen: Callable, can: bool = true) -> MenuEntry:
	var entry: MenuEntry = MenuEntry.new()
	entry.label = text
	entry.note = side
	entry.detail = about
	entry.action = chosen
	entry.available = can
	return entry
