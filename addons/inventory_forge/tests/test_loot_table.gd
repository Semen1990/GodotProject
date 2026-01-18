extends GutTest
## Unit tests for LootTable and LootEntry resources
##
## HOW TO RUN:
## 1. Install GUT addon from AssetLib: https://godotengine.org/asset-library/asset/1709
## 2. Delete or rename the .gdignore file in this folder
## 3. Run tests via GUT panel or: godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://addons/inventory_forge/tests
##
## Inventory Forge Plugin by Menkos
## License: MIT


var loot_table: LootTable
var item_database: ItemDatabase


func before_each() -> void:
	loot_table = LootTable.new()
	item_database = ItemDatabase.new()
	
	# Create some test items
	for i in range(5):
		var item := ItemDefinition.new()
		item.id = i + 1
		item.name_key = "ITEM_%d" % (i + 1)
		item_database.add_item(item)


func after_each() -> void:
	loot_table = null
	item_database = null


# === Helper Functions ===

func create_entry(item_id: int, weight: float = 1.0, min_qty: int = 1, max_qty: int = 1) -> LootEntry:
	var entry := LootEntry.new()
	entry.item = item_database.get_item_by_id(item_id)
	entry.weight = weight
	entry.min_quantity = min_qty
	entry.max_quantity = max_qty
	return entry


# === LootEntry Tests ===

func test_loot_entry_default_values() -> void:
	var entry := LootEntry.new()
	
	assert_null(entry.item)
	assert_eq(entry.weight, 1.0)
	assert_eq(entry.min_quantity, 1)
	assert_eq(entry.max_quantity, 1)
	assert_true(entry.enabled)


func test_loot_entry_is_valid() -> void:
	var entry := create_entry(1)
	
	assert_true(entry.is_valid())


func test_loot_entry_invalid_no_item() -> void:
	var entry := LootEntry.new()
	entry.weight = 1.0
	
	assert_false(entry.is_valid())


func test_loot_entry_invalid_zero_weight() -> void:
	var entry := create_entry(1, 0.0)
	
	assert_false(entry.is_valid())


func test_loot_entry_invalid_disabled() -> void:
	var entry := create_entry(1)
	entry.enabled = false
	
	assert_false(entry.is_valid())


func test_loot_entry_get_random_quantity_fixed() -> void:
	var entry := create_entry(1, 1.0, 5, 5)
	
	for i in range(10):
		assert_eq(entry.get_random_quantity(), 5)


func test_loot_entry_get_random_quantity_range() -> void:
	var entry := create_entry(1, 1.0, 1, 10)
	
	for i in range(20):
		var qty := entry.get_random_quantity()
		assert_true(qty >= 1 and qty <= 10, "Quantity should be in range")


func test_loot_entry_validation_warnings() -> void:
	var entry := LootEntry.new()
	# No item, zero weight
	entry.weight = 0.0
	
	var warnings := entry.get_validation_warnings()
	
	assert_true(warnings.size() >= 2)


func test_loot_entry_duplicate() -> void:
	var entry := create_entry(1, 2.5, 3, 7)
	entry.enabled = false
	
	var duplicated := entry.duplicate_entry()
	
	assert_eq(duplicated.item, entry.item)
	assert_eq(duplicated.weight, 2.5)
	assert_eq(duplicated.min_quantity, 3)
	assert_eq(duplicated.max_quantity, 7)
	assert_false(duplicated.enabled)


# === LootTable Basic Tests ===

func test_loot_table_default_values() -> void:
	assert_eq(loot_table.id, "")
	assert_eq(loot_table.name, "")
	assert_eq(loot_table.entries.size(), 0)
	assert_eq(loot_table.min_drops, 1)
	assert_eq(loot_table.max_drops, 1)
	assert_eq(loot_table.empty_chance, 0.0)
	assert_true(loot_table.allow_duplicates)


func test_loot_table_set_properties() -> void:
	loot_table.id = "chest_common"
	loot_table.name = "Common Chest"
	loot_table.description = "A basic chest"
	loot_table.min_drops = 2
	loot_table.max_drops = 5
	loot_table.empty_chance = 0.1
	loot_table.allow_duplicates = false
	
	assert_eq(loot_table.id, "chest_common")
	assert_eq(loot_table.name, "Common Chest")
	assert_eq(loot_table.min_drops, 2)
	assert_eq(loot_table.max_drops, 5)
	assert_almost_eq(loot_table.empty_chance, 0.1, 0.001)
	assert_false(loot_table.allow_duplicates)


# === Entry Management Tests ===

func test_add_entry() -> void:
	var entry := create_entry(1)
	
	loot_table.add_entry(entry)
	
	assert_eq(loot_table.entries.size(), 1)


func test_add_item_convenience() -> void:
	var item := item_database.get_item_by_id(1)
	
	var entry := loot_table.add_item(item, 2.0, 1, 5)
	
	assert_not_null(entry)
	assert_eq(loot_table.entries.size(), 1)
	assert_eq(entry.item, item)
	assert_eq(entry.weight, 2.0)
	assert_eq(entry.max_quantity, 5)


func test_remove_entry() -> void:
	var entry := create_entry(1)
	loot_table.add_entry(entry)
	
	var result := loot_table.remove_entry(entry)
	
	assert_true(result)
	assert_eq(loot_table.entries.size(), 0)


func test_remove_entry_at() -> void:
	loot_table.add_entry(create_entry(1))
	loot_table.add_entry(create_entry(2))
	loot_table.add_entry(create_entry(3))
	
	var result := loot_table.remove_entry_at(1)
	
	assert_true(result)
	assert_eq(loot_table.entries.size(), 2)
	assert_eq(loot_table.entries[0].item.id, 1)
	assert_eq(loot_table.entries[1].item.id, 3)


func test_get_entry() -> void:
	loot_table.add_entry(create_entry(1))
	loot_table.add_entry(create_entry(2))
	
	var entry := loot_table.get_entry(1)
	
	assert_not_null(entry)
	assert_eq(entry.item.id, 2)


func test_get_entry_out_of_bounds() -> void:
	loot_table.add_entry(create_entry(1))
	
	assert_null(loot_table.get_entry(999))
	assert_null(loot_table.get_entry(-1))


func test_clear_entries() -> void:
	loot_table.add_entry(create_entry(1))
	loot_table.add_entry(create_entry(2))
	
	loot_table.clear_entries()
	
	assert_eq(loot_table.entries.size(), 0)


# === Weight and Probability Tests ===

func test_get_valid_entries() -> void:
	loot_table.add_entry(create_entry(1))
	
	var disabled_entry := create_entry(2)
	disabled_entry.enabled = false
	loot_table.add_entry(disabled_entry)
	
	var no_item_entry := LootEntry.new()
	loot_table.add_entry(no_item_entry)
	
	var valid := loot_table.get_valid_entries()
	
	assert_eq(valid.size(), 1)


func test_get_total_weight() -> void:
	loot_table.add_entry(create_entry(1, 2.0))
	loot_table.add_entry(create_entry(2, 3.0))
	loot_table.add_entry(create_entry(3, 5.0))
	
	var total := loot_table.get_total_weight()
	
	assert_almost_eq(total, 10.0, 0.001)


func test_get_total_weight_excludes_invalid() -> void:
	loot_table.add_entry(create_entry(1, 5.0))
	
	var disabled := create_entry(2, 10.0)
	disabled.enabled = false
	loot_table.add_entry(disabled)
	
	var total := loot_table.get_total_weight()
	
	assert_almost_eq(total, 5.0, 0.001)


func test_get_entry_probability() -> void:
	loot_table.add_entry(create_entry(1, 1.0))
	loot_table.add_entry(create_entry(2, 1.0))
	loot_table.add_entry(create_entry(3, 2.0))
	
	var prob1 := loot_table.get_entry_probability(loot_table.entries[0])
	var prob3 := loot_table.get_entry_probability(loot_table.entries[2])
	
	assert_almost_eq(prob1, 25.0, 0.1)  # 1/4 = 25%
	assert_almost_eq(prob3, 50.0, 0.1)  # 2/4 = 50%


# === Roll Tests ===

func test_roll_empty_table() -> void:
	var result := loot_table.roll()
	
	assert_true(result.is_empty())


func test_roll_single_entry() -> void:
	loot_table.add_entry(create_entry(1, 1.0, 1, 1))
	
	var result := loot_table.roll()
	
	assert_false(result.is_empty())
	assert_eq(result.items.size(), 1)
	assert_eq(result.items[0].item.id, 1)
	assert_eq(result.items[0].quantity, 1)


func test_roll_respects_quantity_range() -> void:
	loot_table.add_entry(create_entry(1, 1.0, 5, 10))
	
	for i in range(20):
		var result := loot_table.roll()
		var qty: int = result.items[0].quantity
		assert_true(qty >= 5 and qty <= 10, "Quantity should be in range")


func test_roll_multiple_drops() -> void:
	loot_table.min_drops = 3
	loot_table.max_drops = 3
	loot_table.add_entry(create_entry(1, 1.0))
	loot_table.add_entry(create_entry(2, 1.0))
	loot_table.add_entry(create_entry(3, 1.0))
	
	var result := loot_table.roll()
	
	# With duplicates allowed, we should have 3 drops (may be same item multiple times)
	assert_eq(result.get_total_items(), 3)


func test_roll_no_duplicates() -> void:
	loot_table.min_drops = 3
	loot_table.max_drops = 3
	loot_table.allow_duplicates = false
	loot_table.add_entry(create_entry(1, 1.0))
	loot_table.add_entry(create_entry(2, 1.0))
	loot_table.add_entry(create_entry(3, 1.0))
	
	var result := loot_table.roll()
	
	# Each item should appear exactly once
	assert_eq(result.items.size(), 3)
	
	var seen_ids: Array[int] = []
	for item_data in result.items:
		assert_false(item_data.item.id in seen_ids, "Should not have duplicates")
		seen_ids.append(item_data.item.id)


func test_roll_no_duplicates_limited_entries() -> void:
	loot_table.min_drops = 5
	loot_table.max_drops = 5
	loot_table.allow_duplicates = false
	loot_table.add_entry(create_entry(1, 1.0))
	loot_table.add_entry(create_entry(2, 1.0))
	# Only 2 entries but asking for 5 drops
	
	var result := loot_table.roll()
	
	# Should only get 2 items (limited by available entries)
	assert_eq(result.items.size(), 2)


func test_roll_empty_chance_always_empty() -> void:
	loot_table.empty_chance = 1.0  # 100% empty chance
	loot_table.add_entry(create_entry(1))
	
	for i in range(20):
		var result := loot_table.roll()
		assert_true(result.is_empty(), "Should always be empty")


func test_roll_empty_chance_never_empty() -> void:
	loot_table.empty_chance = 0.0  # 0% empty chance
	loot_table.add_entry(create_entry(1))
	
	for i in range(20):
		var result := loot_table.roll()
		assert_false(result.is_empty(), "Should never be empty")


func test_roll_multiple() -> void:
	loot_table.add_entry(create_entry(1, 1.0, 1, 1))
	
	var result := loot_table.roll_multiple(5)
	
	assert_eq(result.get_total_items(), 5)


func test_roll_items_returns_array() -> void:
	loot_table.add_entry(create_entry(1))
	
	var items := loot_table.roll_items()
	
	assert_true(items is Array)
	assert_eq(items.size(), 1)


# === LootResult Tests ===

func test_loot_result_add_combines_same_item() -> void:
	var result := LootTable.LootResult.new()
	var item := item_database.get_item_by_id(1)
	
	result.add(item, 3)
	result.add(item, 2)
	
	assert_eq(result.items.size(), 1)
	assert_eq(result.items[0].quantity, 5)


func test_loot_result_get_total_items() -> void:
	var result := LootTable.LootResult.new()
	result.add(item_database.get_item_by_id(1), 3)
	result.add(item_database.get_item_by_id(2), 2)
	
	assert_eq(result.get_total_items(), 5)


# === Validation Tests ===

func test_is_valid() -> void:
	loot_table.id = "test_table"
	loot_table.add_entry(create_entry(1))
	
	assert_true(loot_table.is_valid())


func test_is_valid_no_id() -> void:
	loot_table.add_entry(create_entry(1))
	
	assert_false(loot_table.is_valid())


func test_is_valid_no_entries() -> void:
	loot_table.id = "test_table"
	
	assert_false(loot_table.is_valid())


func test_is_valid_all_entries_invalid() -> void:
	loot_table.id = "test_table"
	
	var disabled := create_entry(1)
	disabled.enabled = false
	loot_table.add_entry(disabled)
	
	assert_false(loot_table.is_valid())


func test_validation_warnings() -> void:
	# Empty ID, no entries
	var warnings := loot_table.get_validation_warnings()
	
	assert_true("no ID" in str(warnings))
	assert_true("no entries" in str(warnings))


func test_validation_warnings_entry_issues() -> void:
	loot_table.id = "test"
	
	var no_item := LootEntry.new()
	loot_table.add_entry(no_item)
	
	var warnings := loot_table.get_validation_warnings()
	
	assert_true("Entry 1" in str(warnings))


# === Duplicate Tests ===

func test_duplicate_table() -> void:
	loot_table.id = "original"
	loot_table.name = "Original Table"
	loot_table.min_drops = 2
	loot_table.max_drops = 4
	loot_table.add_entry(create_entry(1, 2.0))
	
	var duplicated := loot_table.duplicate_table()
	
	assert_eq(duplicated.id, "original_copy")
	assert_eq(duplicated.name, "Original Table (Copy)")
	assert_eq(duplicated.min_drops, 2)
	assert_eq(duplicated.max_drops, 4)
	assert_eq(duplicated.entries.size(), 1)


func test_duplicate_table_independent() -> void:
	loot_table.id = "original"
	loot_table.add_entry(create_entry(1))
	
	var duplicated := loot_table.duplicate_table()
	duplicated.clear_entries()
	
	assert_eq(loot_table.entries.size(), 1, "Original should be unchanged")
