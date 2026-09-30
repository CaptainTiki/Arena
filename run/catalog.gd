class_name Catalog
extends Resource
## Everything the game offers: what can be bought, what can be fought, and who is watching.

@export var items: Array[ItemData] = []
## In the order the contract board lists them.
@export var contracts: Array[ContractData] = []
@export var sponsors: Array[SponsorData] = []
## What a new profile has in its wallet.
@export var starting_cash: int = 100
## Every message that can arrive at the terminal.
@export var mail: Array[MailData] = []
## Favour lost with a sponsor when a contract they asked for is lost.
@export var request_loss_favour: int = 15


func find_item(id: StringName) -> ItemData:
	for item: ItemData in items:
		if item.id == id:
			return item
	return null


func find_sponsor(display_name: String) -> SponsorData:
	for sponsor: SponsorData in sponsors:
		if sponsor.display_name == display_name:
			return sponsor
	return null


func get_items_in(category: ItemData.Category) -> Array[ItemData]:
	var found: Array[ItemData] = []
	for item: ItemData in items:
		if item.category == category:
			found.append(item)
	return found


func find_mail(id: StringName) -> MailData:
	for message: MailData in mail:
		if message.id == id:
			return message
	return null


## The mail that puts `item` in the shop, or null when it is on sale from the start.
func find_offer(item: ItemData) -> MailData:
	for message: MailData in mail:
		if message.unlocks == item:
			return message
	return null
