class_name MailData
extends Resource
## One message waiting at the agent's terminal. It arrives once, when its trigger comes true,
## and can put something in the shop or money in the wallet as it lands.

enum Trigger {
	## Waiting from the first visit to the base.
	ALWAYS,
	## Favour with `sender` is at `amount` or more.
	FAVOUR_REACHED,
	## Favour with `sender` fell by `amount` or more in one fight.
	FAVOUR_LOST,
	## A contract `sender` asked for was won.
	REQUEST_WON,
	## A contract some other sponsor asked for was won.
	RIVAL_REQUEST_WON,
}

## Written to the save file. Never change it once people have saves.
@export var id: StringName = &""
## Who wrote it. Empty means the agent.
@export var sender: SponsorData
@export var subject: String = ""
@export_multiline var body: String = ""

@export_group("Arrives")
@export var trigger: Trigger = Trigger.ALWAYS
@export var amount: int = 0

@export_group("Brings")
## Goes on sale in the shop when this arrives.
@export var unlocks: ItemData
## Added to the wallet when this arrives.
@export var gift_cash: int = 0


func get_sender_name() -> String:
	return "YOUR AGENT" if sender == null else sender.display_name
