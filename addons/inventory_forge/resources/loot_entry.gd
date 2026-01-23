@tool
class_name LootEntry
extends Resource
## A single entry in a loot table.
## Defines an item that can drop, its probability, and quantity range.
##
## Inventory Forge Plugin by Menkos
## License: MIT

# === Signals ===
signal changed_entry()

# === Data ===

## The item that can drop
@export var item: ItemDefinition = null:
	set(value):
		item = value
		emit_changed()
		changed_entry.emit()

## Drop weight (higher = more likely relative to other entries)
@export_range(0.0, 1000.0, 0.1) var weight: float = 1.0:
	set(value):
		weight = value
		emit_changed()
		changed_entry.emit()

## Minimum quantity when this item drops
@export_range(1, 999) var min_quantity: int = 1:
	set(value):
		min_quantity = clampi(value, 1, max_quantity)
		emit_changed()
		changed_entry.emit()

## Maximum quantity when this item drops
@export_range(1, 999) var max_quantity: int = 1:
	set(value):
		max_quantity = clampi(value, min_quantity, 999)
		emit_changed()
		changed_entry.emit()

## Whether this entry is enabled
@export var enabled: bool = true:
	set(value):
		enabled = value
		emit_changed()
		changed_entry.emit()


# === Methods ===

## Gets a random quantity within the defined range
func get_random_quantity() -> int:
	if min_quantity == max_quantity:
		return min_quantity
	return randi_range(min_quantity, max_quantity)


## Checks if the entry is valid
func is_valid() -> bool:
	return item != null and weight > 0.0 and enabled


## Gets validation warnings
func get_validation_warnings() -> Array[String]:
	var warnings: Array[String] = []
	
	if item == null:
		warnings.append("No item assigned")
	
	if weight <= 0.0:
		warnings.append("Weight must be greater than 0")
	
	if min_quantity > max_quantity:
		warnings.append("Min quantity cannot be greater than max quantity")
	
	return warnings


## Creates a duplicate of this entry
func duplicate_entry() -> LootEntry:
	var new_entry := LootEntry.new()
	new_entry.item = item
	new_entry.weight = weight
	new_entry.min_quantity = min_quantity
	new_entry.max_quantity = max_quantity
	new_entry.enabled = enabled
	return new_entry
