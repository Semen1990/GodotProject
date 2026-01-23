@tool
class_name LootTable
extends Resource
## A loot table containing multiple weighted drop entries.
## Can roll for random items with configurable drop chances.
## Supports rarity presets and sub-table chaining for modular loot design.
##
## Inventory Forge Plugin by Menkos
## License: MIT

# === Enums ===

## Rarity tier presets with predefined drop settings
enum RarityTier {
	CUSTOM = 0,      ## Manual configuration (no preset)
	COMMON = 1,      ## Always drops, 1-2 items
	UNCOMMON = 2,    ## 80% drop chance, 1-2 items
	RARE = 3,        ## 30% drop chance, 1-1 items
	EPIC = 4,        ## 10% drop chance, 1-1 items
	LEGENDARY = 5,   ## 2% drop chance, 1-1 items
}

# === Preset Configurations ===
const RARITY_PRESETS := {
	RarityTier.COMMON: {
		"empty_chance": 0.0,
		"min_drops": 1,
		"max_drops": 2,
		"description": "Always drops 1-2 items"
	},
	RarityTier.UNCOMMON: {
		"empty_chance": 0.2,
		"min_drops": 1,
		"max_drops": 2,
		"description": "80% chance, 1-2 items"
	},
	RarityTier.RARE: {
		"empty_chance": 0.7,
		"min_drops": 1,
		"max_drops": 1,
		"description": "30% chance, 1 item"
	},
	RarityTier.EPIC: {
		"empty_chance": 0.9,
		"min_drops": 1,
		"max_drops": 1,
		"description": "10% chance, 1 item"
	},
	RarityTier.LEGENDARY: {
		"empty_chance": 0.98,
		"min_drops": 1,
		"max_drops": 1,
		"description": "2% chance, 1 item"
	},
}

# === Signals ===
signal entry_added(entry: LootEntry)
signal entry_removed(entry: LootEntry)
signal table_changed()

# === Data ===

## Unique identifier for this loot table
@export var id: String = "":
	set(value):
		id = value
		emit_changed()
		table_changed.emit()

## Display name for the loot table
@export var name: String = "":
	set(value):
		name = value
		emit_changed()
		table_changed.emit()

## Description of when this loot table is used
@export_multiline var description: String = "":
	set(value):
		description = value
		emit_changed()
		table_changed.emit()

@export_group("Rarity Preset")

## Rarity tier - select CUSTOM for manual configuration
@export var rarity_tier: RarityTier = RarityTier.CUSTOM:
	set(value):
		rarity_tier = value
		if value != RarityTier.CUSTOM:
			_apply_rarity_preset(value)
		emit_changed()
		table_changed.emit()

@export_group("Drop Settings")

## List of loot entries
@export var entries: Array[LootEntry] = []:
	set(value):
		entries = value
		emit_changed()
		table_changed.emit()

## Minimum number of items to drop per roll
@export_range(0, 10) var min_drops: int = 1:
	set(value):
		min_drops = clampi(value, 0, max_drops)
		emit_changed()
		table_changed.emit()

## Maximum number of items to drop per roll
@export_range(0, 10) var max_drops: int = 1:
	set(value):
		max_drops = clampi(value, min_drops, 10)
		emit_changed()
		table_changed.emit()

## Chance that nothing drops at all (0.0 = always drops, 1.0 = never drops)
@export_range(0.0, 1.0, 0.01) var empty_chance: float = 0.0:
	set(value):
		empty_chance = clampf(value, 0.0, 1.0)
		emit_changed()
		table_changed.emit()

## Whether duplicates are allowed in a single roll
@export var allow_duplicates: bool = true:
	set(value):
		allow_duplicates = value
		emit_changed()
		table_changed.emit()

@export_group("Sub-Tables")

## IDs of other loot tables to roll together with this one
@export var sub_table_ids: Array[String] = []:
	set(value):
		sub_table_ids = value
		emit_changed()
		table_changed.emit()

## Reference to the database (set at runtime for sub-table lookups)
var _database: Resource = null


# === Rarity Preset Methods ===

## Applies preset values based on rarity tier
func _apply_rarity_preset(tier: RarityTier) -> void:
	if not RARITY_PRESETS.has(tier):
		return
	
	var preset: Dictionary = RARITY_PRESETS[tier]
	empty_chance = preset.empty_chance
	min_drops = preset.min_drops
	max_drops = preset.max_drops


## Gets the description for a rarity tier
static func get_rarity_description(tier: RarityTier) -> String:
	if tier == RarityTier.CUSTOM:
		return "Manual configuration"
	if RARITY_PRESETS.has(tier):
		return RARITY_PRESETS[tier].description
	return ""


## Gets the rarity tier name as string
static func get_rarity_name(tier: RarityTier) -> String:
	match tier:
		RarityTier.CUSTOM: return "Custom"
		RarityTier.COMMON: return "Common"
		RarityTier.UNCOMMON: return "Uncommon"
		RarityTier.RARE: return "Rare"
		RarityTier.EPIC: return "Epic"
		RarityTier.LEGENDARY: return "Legendary"
		_: return "Unknown"


# === Roll Methods ===

## Result of a loot roll
class LootResult:
	var items: Array[Dictionary] = []  # [{item: ItemDefinition, quantity: int}]
	
	func add(item: ItemDefinition, quantity: int) -> void:
		# Check if item already exists in results
		for entry in items:
			if entry.item == item:
				entry.quantity += quantity
				return
		items.append({"item": item, "quantity": quantity})
	
	func is_empty() -> bool:
		return items.is_empty()
	
	func get_total_items() -> int:
		var total := 0
		for entry in items:
			total += entry.quantity
		return total


## Performs a single roll on the loot table
func roll() -> LootResult:
	var result := LootResult.new()
	
	# Check empty chance
	if randf() < empty_chance:
		return result
	
	# Get valid entries
	var valid_entries := get_valid_entries()
	if valid_entries.is_empty():
		return result
	
	# Determine number of drops
	var num_drops := randi_range(min_drops, max_drops)
	if num_drops == 0:
		return result
	
	# Calculate total weight
	var total_weight := get_total_weight()
	if total_weight <= 0.0:
		return result
	
	# Roll for each drop
	var used_entries: Array[LootEntry] = []
	
	for i in range(num_drops):
		var available_entries := valid_entries.duplicate()
		
		# Remove used entries if duplicates not allowed
		if not allow_duplicates:
			for used in used_entries:
				available_entries.erase(used)
		
		if available_entries.is_empty():
			break
		
		# Recalculate weight for available entries
		var available_weight := 0.0
		for entry in available_entries:
			available_weight += entry.weight
		
		# Roll weighted random
		var roll_value := randf() * available_weight
		var cumulative := 0.0
		
		for entry in available_entries:
			cumulative += entry.weight
			if roll_value <= cumulative:
				var quantity: int = entry.get_random_quantity()
				result.add(entry.item, quantity)
				used_entries.append(entry)
				break
	
	return result


## Performs multiple rolls and returns combined results
func roll_multiple(count: int) -> LootResult:
	var combined := LootResult.new()
	
	for i in range(count):
		var single_result := roll()
		for entry in single_result.items:
			combined.add(entry.item, entry.quantity)
	
	return combined


## Rolls and returns a flat array of item instances (for direct use)
func roll_items() -> Array[Dictionary]:
	return roll().items


## Performs a roll including all sub-tables (requires database reference)
func roll_with_sub_tables(database: Resource = null) -> LootResult:
	var result := roll()
	
	# Use provided database or cached reference
	var db: Resource = database if database else _database
	if db == null or sub_table_ids.is_empty():
		return result
	
	# Roll each sub-table and combine results
	for sub_id in sub_table_ids:
		if sub_id.is_empty() or sub_id == id:  # Prevent self-reference
			continue
		
		var sub_table: LootTable = db.get_table_by_id(sub_id)
		if sub_table:
			var sub_result := sub_table.roll()
			for entry in sub_result.items:
				result.add(entry.item, entry.quantity)
	
	return result


## Sets the database reference for sub-table lookups
func set_database(database: Resource) -> void:
	_database = database


## Checks if this table has sub-tables configured
func has_sub_tables() -> bool:
	return not sub_table_ids.is_empty()


## Gets the list of sub-table IDs
func get_sub_table_ids() -> Array[String]:
	return sub_table_ids.duplicate()


# === Entry Management ===

## Adds a new entry to the table
func add_entry(entry: LootEntry) -> void:
	if entry == null:
		return
	
	entries.append(entry)
	emit_changed()
	entry_added.emit(entry)
	table_changed.emit()


## Creates and adds a new entry for the given item
func add_item(item: ItemDefinition, weight: float = 1.0, min_qty: int = 1, max_qty: int = 1) -> LootEntry:
	var entry := LootEntry.new()
	entry.item = item
	entry.weight = weight
	entry.min_quantity = min_qty
	entry.max_quantity = max_qty
	add_entry(entry)
	return entry


## Removes an entry from the table
func remove_entry(entry: LootEntry) -> bool:
	var index := entries.find(entry)
	if index >= 0:
		entries.remove_at(index)
		emit_changed()
		entry_removed.emit(entry)
		table_changed.emit()
		return true
	return false


## Removes an entry by index
func remove_entry_at(index: int) -> bool:
	if index >= 0 and index < entries.size():
		var entry := entries[index]
		entries.remove_at(index)
		emit_changed()
		entry_removed.emit(entry)
		table_changed.emit()
		return true
	return false


## Gets entry at index
func get_entry(index: int) -> LootEntry:
	if index >= 0 and index < entries.size():
		return entries[index]
	return null


## Clears all entries
func clear_entries() -> void:
	entries.clear()
	emit_changed()
	table_changed.emit()


# === Utility Methods ===

## Gets all valid (enabled, with item) entries
func get_valid_entries() -> Array[LootEntry]:
	var valid: Array[LootEntry] = []
	for entry in entries:
		if entry and entry.is_valid():
			valid.append(entry)
	return valid


## Gets the total weight of all valid entries
func get_total_weight() -> float:
	var total := 0.0
	for entry in entries:
		if entry and entry.is_valid():
			total += entry.weight
	return total


## Gets the drop probability for a specific entry (as percentage)
func get_entry_probability(entry: LootEntry) -> float:
	var total_weight := get_total_weight()
	if total_weight <= 0.0 or entry == null or not entry.is_valid():
		return 0.0
	return (entry.weight / total_weight) * 100.0


## Checks if the loot table is valid
func is_valid() -> bool:
	return not id.is_empty() and not entries.is_empty() and get_valid_entries().size() > 0


## Gets validation warnings
func get_validation_warnings() -> Array[String]:
	var warnings: Array[String] = []
	
	if id.is_empty():
		warnings.append("Loot table has no ID")
	
	if entries.is_empty():
		warnings.append("Loot table has no entries")
	else:
		var valid_count := get_valid_entries().size()
		if valid_count == 0:
			warnings.append("No valid entries (all disabled or missing items)")
		
		# Check individual entries
		for i in range(entries.size()):
			var entry := entries[i]
			if entry:
				var entry_warnings := entry.get_validation_warnings()
				for w in entry_warnings:
					warnings.append("Entry %d: %s" % [i + 1, w])
	
	if min_drops > max_drops:
		warnings.append("Min drops cannot be greater than max drops")
	
	# Check for self-reference in sub-tables
	if id in sub_table_ids:
		warnings.append("Sub-tables contains self-reference (will be ignored)")
	
	# Check for empty sub-table IDs
	for i in range(sub_table_ids.size()):
		if sub_table_ids[i].is_empty():
			warnings.append("Sub-table %d has empty ID" % [i + 1])
	
	return warnings


## Creates a duplicate of this loot table
func duplicate_table() -> LootTable:
	var new_table := LootTable.new()
	new_table.id = id + "_copy"
	new_table.name = name + " (Copy)"
	new_table.description = description
	new_table.rarity_tier = rarity_tier
	new_table.min_drops = min_drops
	new_table.max_drops = max_drops
	new_table.empty_chance = empty_chance
	new_table.allow_duplicates = allow_duplicates
	new_table.sub_table_ids = sub_table_ids.duplicate()
	
	for entry in entries:
		if entry:
			new_table.entries.append(entry.duplicate_entry())
	
	return new_table
