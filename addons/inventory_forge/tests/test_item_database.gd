extends GutTest
## Unit tests for ItemDatabase resource
##
## HOW TO RUN:
## 1. Install GUT addon from AssetLib: https://godotengine.org/asset-library/asset/1709
## 2. Delete or rename the .gdignore file in this folder
## 3. Run tests via GUT panel or: godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://addons/inventory_forge/tests
##
## Inventory Forge Plugin by Menkos
## License: MIT


var database: ItemDatabase


func before_each() -> void:
	database = ItemDatabase.new()


func after_each() -> void:
	database = null


# === Helper Functions ===

func create_test_item(id: int, name_key: String, category: ItemEnums.Category = ItemEnums.Category.MISC) -> ItemDefinition:
	var item := ItemDefinition.new()
	item.id = id
	item.name_key = name_key
	item.description_key = name_key + "_DESC"
	item.category = category
	return item


# === Basic Operations Tests ===

func test_empty_database() -> void:
	assert_eq(database.items.size(), 0, "New database should be empty")


func test_add_item() -> void:
	var item := create_test_item(1, "ITEM_TEST")
	
	database.add_item(item)
	
	assert_eq(database.items.size(), 1)
	assert_eq(database.items[0], item)


func test_add_item_assigns_id_if_negative() -> void:
	var item := ItemDefinition.new()
	item.id = -1
	item.name_key = "TEST"
	
	database.add_item(item)
	
	assert_eq(item.id, 0, "Should assign ID 0 to first item")


func test_add_multiple_items() -> void:
	database.add_item(create_test_item(1, "ITEM_1"))
	database.add_item(create_test_item(2, "ITEM_2"))
	database.add_item(create_test_item(3, "ITEM_3"))
	
	assert_eq(database.items.size(), 3)


func test_remove_item() -> void:
	var item := create_test_item(1, "ITEM_TEST")
	database.add_item(item)
	
	var result := database.remove_item(item)
	
	assert_true(result)
	assert_eq(database.items.size(), 0)


func test_remove_item_not_found() -> void:
	var item := create_test_item(1, "ITEM_TEST")
	
	var result := database.remove_item(item)
	
	assert_false(result)


func test_remove_item_by_id() -> void:
	database.add_item(create_test_item(1, "ITEM_1"))
	database.add_item(create_test_item(2, "ITEM_2"))
	
	var result := database.remove_item_by_id(1)
	
	assert_true(result)
	assert_eq(database.items.size(), 1)
	assert_eq(database.items[0].id, 2)


func test_create_new_item() -> void:
	var item := database.create_new_item()
	
	assert_not_null(item)
	assert_eq(item.id, 0)
	assert_eq(database.items.size(), 1)


func test_create_new_item_increments_id() -> void:
	database.add_item(create_test_item(5, "ITEM_5"))
	
	var new_item := database.create_new_item()
	
	assert_eq(new_item.id, 6, "New item should have next available ID")


# === Search Tests ===

func test_get_item_by_id() -> void:
	var item := create_test_item(42, "ITEM_42")
	database.add_item(item)
	
	var found := database.get_item_by_id(42)
	
	assert_eq(found, item)


func test_get_item_by_id_not_found() -> void:
	database.add_item(create_test_item(1, "ITEM_1"))
	
	var found := database.get_item_by_id(999)
	
	assert_null(found)


func test_has_item() -> void:
	database.add_item(create_test_item(1, "ITEM_1"))
	
	assert_true(database.has_item(1))
	assert_false(database.has_item(999))


func test_get_item_index_by_id() -> void:
	database.add_item(create_test_item(10, "ITEM_10"))
	database.add_item(create_test_item(20, "ITEM_20"))
	database.add_item(create_test_item(30, "ITEM_30"))
	
	assert_eq(database.get_item_index_by_id(20), 1)
	assert_eq(database.get_item_index_by_id(999), -1)


func test_get_items_by_category() -> void:
	database.add_item(create_test_item(1, "WEAPON_1", ItemEnums.Category.WEAPON))
	database.add_item(create_test_item(2, "ARMOR_1", ItemEnums.Category.ARMOR))
	database.add_item(create_test_item(3, "WEAPON_2", ItemEnums.Category.WEAPON))
	
	var weapons := database.get_items_by_category(ItemEnums.Category.WEAPON)
	
	assert_eq(weapons.size(), 2)


func test_get_items_by_rarity() -> void:
	var common := create_test_item(1, "COMMON")
	common.rarity = ItemEnums.Rarity.COMMON
	var rare := create_test_item(2, "RARE")
	rare.rarity = ItemEnums.Rarity.RARE
	var rare2 := create_test_item(3, "RARE2")
	rare2.rarity = ItemEnums.Rarity.RARE
	
	database.add_item(common)
	database.add_item(rare)
	database.add_item(rare2)
	
	var rare_items := database.get_items_by_rarity(ItemEnums.Rarity.RARE)
	
	assert_eq(rare_items.size(), 2)


func test_search_items_by_name_key() -> void:
	database.add_item(create_test_item(1, "ITEM_SWORD"))
	database.add_item(create_test_item(2, "ITEM_SHIELD"))
	database.add_item(create_test_item(3, "ITEM_SWORD_FIRE"))
	
	var results := database.search_items("SWORD")
	
	assert_eq(results.size(), 2)


func test_search_items_by_id() -> void:
	database.add_item(create_test_item(123, "ITEM_A"))
	database.add_item(create_test_item(456, "ITEM_B"))
	
	var results := database.search_items("123")
	
	assert_eq(results.size(), 1)
	assert_eq(results[0].id, 123)


func test_search_items_empty_query() -> void:
	database.add_item(create_test_item(1, "ITEM_1"))
	database.add_item(create_test_item(2, "ITEM_2"))
	
	var results := database.search_items("")
	
	assert_eq(results.size(), 2)


func test_filter_items_by_category() -> void:
	database.add_item(create_test_item(1, "W1", ItemEnums.Category.WEAPON))
	database.add_item(create_test_item(2, "A1", ItemEnums.Category.ARMOR))
	database.add_item(create_test_item(3, "W2", ItemEnums.Category.WEAPON))
	
	var filtered := database.filter_items(ItemEnums.Category.WEAPON, "")
	
	assert_eq(filtered.size(), 2)


func test_filter_items_combined() -> void:
	database.add_item(create_test_item(1, "SWORD_IRON", ItemEnums.Category.WEAPON))
	database.add_item(create_test_item(2, "SWORD_STEEL", ItemEnums.Category.WEAPON))
	database.add_item(create_test_item(3, "ARMOR_IRON", ItemEnums.Category.ARMOR))
	
	var filtered := database.filter_items(ItemEnums.Category.WEAPON, "IRON")
	
	assert_eq(filtered.size(), 1)
	assert_eq(filtered[0].name_key, "SWORD_IRON")


# === Ingredient Tests ===

func test_get_ingredients() -> void:
	var ing1 := create_test_item(1, "IRON_ORE")
	ing1.is_ingredient = true
	var ing2 := create_test_item(2, "WOOD")
	ing2.is_ingredient = true
	var weapon := create_test_item(3, "SWORD")
	weapon.is_ingredient = false
	
	database.add_item(ing1)
	database.add_item(ing2)
	database.add_item(weapon)
	
	var ingredients := database.get_ingredients()
	
	assert_eq(ingredients.size(), 2)


# === Duplicate Detection Tests ===

func test_has_duplicate_id() -> void:
	database.add_item(create_test_item(1, "ITEM_1"))
	database.add_item(create_test_item(1, "ITEM_1_DUP"))  # Same ID
	
	assert_true(database.has_duplicate_id(1))
	assert_false(database.has_duplicate_id(999))


func test_get_duplicate_ids() -> void:
	database.add_item(create_test_item(1, "ITEM_1"))
	database.add_item(create_test_item(2, "ITEM_2"))
	database.add_item(create_test_item(1, "ITEM_1_DUP"))  # Duplicate
	database.add_item(create_test_item(3, "ITEM_3"))
	database.add_item(create_test_item(2, "ITEM_2_DUP"))  # Duplicate
	
	var duplicates := database.get_duplicate_ids()
	
	assert_eq(duplicates.size(), 2)
	assert_true(1 in duplicates)
	assert_true(2 in duplicates)


# === Sorting Tests ===

func test_sort_by_id() -> void:
	database.add_item(create_test_item(30, "C"))
	database.add_item(create_test_item(10, "A"))
	database.add_item(create_test_item(20, "B"))
	
	database.sort_by_id()
	
	assert_eq(database.items[0].id, 10)
	assert_eq(database.items[1].id, 20)
	assert_eq(database.items[2].id, 30)


func test_sort_by_name() -> void:
	database.add_item(create_test_item(1, "ITEM_C"))
	database.add_item(create_test_item(2, "ITEM_A"))
	database.add_item(create_test_item(3, "ITEM_B"))
	
	database.sort_by_name()
	
	assert_eq(database.items[0].name_key, "ITEM_A")
	assert_eq(database.items[1].name_key, "ITEM_B")
	assert_eq(database.items[2].name_key, "ITEM_C")


# === Duplicate Item Tests ===

func test_duplicate_item() -> void:
	var original := create_test_item(1, "ORIGINAL")
	original.buy_price = 100
	database.add_item(original)
	
	var duplicated := database.duplicate_item(original)
	
	assert_not_null(duplicated)
	assert_eq(database.items.size(), 2)
	assert_eq(duplicated.id, 2, "Duplicated should have next ID")
	assert_eq(duplicated.name_key, "ORIGINAL_COPY")
	assert_eq(duplicated.buy_price, 100)


# === Validation Tests ===

func test_validate_empty_database() -> void:
	var errors := database.validate()
	
	assert_eq(errors.size(), 0)


func test_validate_with_duplicate_ids() -> void:
	database.add_item(create_test_item(1, "A"))
	database.add_item(create_test_item(1, "B"))  # Duplicate ID
	
	var errors := database.validate()
	
	assert_true(errors.size() > 0)
	assert_true("Duplicate ID" in str(errors))


func test_get_items_with_warnings() -> void:
	var valid := create_test_item(1, "VALID")
	valid.description_key = "VALID_DESC"
	
	var invalid := ItemDefinition.new()
	invalid.id = -1  # Invalid ID triggers warning
	
	database.add_item(valid)
	database.add_item(invalid)
	
	var items_with_warnings := database.get_items_with_warnings()
	
	assert_true(items_with_warnings.size() >= 1)


# === Statistics Tests ===

func test_get_next_available_id_empty() -> void:
	assert_eq(database.get_next_available_id(), 0)


func test_get_next_available_id_with_items() -> void:
	database.add_item(create_test_item(5, "A"))
	database.add_item(create_test_item(10, "B"))
	database.add_item(create_test_item(3, "C"))
	
	assert_eq(database.get_next_available_id(), 11)


func test_get_category_counts() -> void:
	database.add_item(create_test_item(1, "W1", ItemEnums.Category.WEAPON))
	database.add_item(create_test_item(2, "W2", ItemEnums.Category.WEAPON))
	database.add_item(create_test_item(3, "A1", ItemEnums.Category.ARMOR))
	
	var counts := database.get_category_counts()
	
	assert_eq(counts[ItemEnums.Category.WEAPON], 2)
	assert_eq(counts[ItemEnums.Category.ARMOR], 1)


func test_get_stats() -> void:
	database.add_item(create_test_item(1, "ITEM_1"))
	database.add_item(create_test_item(2, "ITEM_2"))
	
	var stats := database.get_stats()
	
	assert_eq(stats.total_items, 2)
	assert_true(stats.has("category_counts"))
	assert_true(stats.has("rarity_counts"))


# === Export Tests ===

func test_export_to_json() -> void:
	var item := create_test_item(1, "TEST_ITEM")
	item.buy_price = 100
	database.add_item(item)
	
	var json_string := database.export_to_json()
	
	assert_true(json_string.length() > 0)
	assert_true("TEST_ITEM" in json_string)
	assert_true("buy_price" in json_string)


func test_export_to_csv() -> void:
	var item := create_test_item(1, "TEST_ITEM")
	database.add_item(item)
	
	var csv_string := database.export_to_csv()
	
	assert_true(csv_string.length() > 0)
	assert_true("id" in csv_string)  # Header
	assert_true("TEST_ITEM" in csv_string)


# === Import Tests ===

func test_import_from_json_replace_all() -> void:
	database.add_item(create_test_item(999, "EXISTING"))
	
	var json := '{"version": "1.0", "items": [{"id": 1, "name_key": "IMPORTED"}]}'
	var result := database.import_from_json(json, ItemDatabase.ImportMode.REPLACE_ALL)
	
	assert_true(result.success)
	assert_eq(result.imported, 1)
	assert_eq(database.items.size(), 1)
	assert_eq(database.items[0].name_key, "IMPORTED")


func test_import_from_json_merge_skip() -> void:
	database.add_item(create_test_item(1, "EXISTING"))
	
	var json := '{"version": "1.0", "items": [{"id": 1, "name_key": "IMPORTED"}, {"id": 2, "name_key": "NEW"}]}'
	var result := database.import_from_json(json, ItemDatabase.ImportMode.MERGE_SKIP)
	
	assert_eq(result.imported, 1, "Only new item should be imported")
	assert_eq(result.skipped, 1, "Existing item should be skipped")
	assert_eq(database.items.size(), 2)
	assert_eq(database.get_item_by_id(1).name_key, "EXISTING")  # Unchanged


func test_import_from_json_merge_overwrite() -> void:
	database.add_item(create_test_item(1, "EXISTING"))
	
	var json := '{"version": "1.0", "items": [{"id": 1, "name_key": "UPDATED"}]}'
	var result := database.import_from_json(json, ItemDatabase.ImportMode.MERGE_OVERWRITE)
	
	assert_eq(result.imported, 1)
	assert_eq(database.get_item_by_id(1).name_key, "UPDATED")


func test_import_from_json_invalid() -> void:
	var result := database.import_from_json("not valid json {{{")
	
	assert_false(result.success)
	assert_true(result.errors.size() > 0)


func test_import_custom_fields() -> void:
	var json := '{"version": "1.0", "items": [{"id": 1, "name_key": "TEST", "custom_fields": {"damage": 10, "element": "fire"}}]}'
	var result := database.import_from_json(json)
	
	assert_true(result.success)
	var item := database.get_item_by_id(1)
	assert_eq(item.get_custom("damage"), 10)
	assert_eq(item.get_custom("element"), "fire")
