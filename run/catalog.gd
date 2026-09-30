class_name Catalog
extends Resource
## Everything the game offers: what can be bought, what can be fought, and who is watching.

@export var items: Array[ItemData] = []
## In the order the contract board lists them.
@export var contracts: Array[ContractData] = []
@export var sponsors: Array[SponsorData] = []
## What a new profile has in its wallet.
@export var starting_cash: int = 100


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


func get_items_sold_by(sponsor: SponsorData) -> Array[ItemData]:
	var found: Array[ItemData] = []
	for item: ItemData in items:
		if item.sponsor == sponsor and item.price_favour > 0:
			found.append(item)
	return found
