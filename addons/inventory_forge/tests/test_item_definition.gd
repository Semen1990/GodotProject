extends GutTest
## Unit tests for ItemDefinition resource
##
## HOW TO RUN:
## 1. Install GUT addon from AssetLib: https://godotengine.org/asset-library/asset/1709
## 2. Delete or rename the .gdignore file in this folder
## 3. Run tests via GUT panel or: godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://addons/inventory_forge/tests
##
## Inventory Forge Plugin by Menkos
## License: MIT


var item: ItemDefinition


func before_each() -> void:
	item = ItemDefinition.new()


func after_each() -> void:
	item = null


# === Basic Properties Tests ===

func test_default_values() -> void:
	assert_eq(item.id, -1, "Default ID should be -1")
	assert_eq(item.name_key, "", "Default name_key should be empty")
	assert_eq(item.description_key, "", "Default description_key should be empty")
	assert_null(item.icon, "Default icon should be null")
	assert_eq(item.category, ItemEnums.Category.MISC, "Default category should be MISC")
	assert_eq(item.rarity, ItemEnums.Rarity.COMMON, "Default rarity should be COMMON")


func test_set_basic_properties() -> void:
	item.id = 42
	item.name_key = "ITEM_SWORD_NAME"
	item.description_key = "ITEM_SWORD_DESC"
	
	assert_eq(item.id, 42)
	assert_eq(item.name_key, "ITEM_SWORD_NAME")
	assert_eq(item.description_key, "ITEM_SWORD_DESC")


func test_stack_properties() -> void:
	item.stack_capacity = 50
	item.stack_count_limit = 100
	
	assert_eq(item.stack_capacity, 50)
	assert_eq(item.stack_count_limit, 100)


func test_economy_properties() -> void:
	item.buy_price = 100
	item.sell_price = 50
	item.tradeable = false
	
	assert_eq(item.buy_price, 100)
	assert_eq(item.sell_price, 50)
	assert_false(item.tradeable)


func test_equipment_properties() -> void:
	item.equippable = true
	item.equip_slot = ItemEnums.EquipSlot.WEAPON
	item.stat_atk = 10
	item.stat_def = 5
	item.stat_hp = 100
	item.stat_mp = 50
	item.stat_spd = 3
	
	assert_true(item.equippable)
	assert_eq(item.equip_slot, ItemEnums.EquipSlot.WEAPON)
	assert_eq(item.stat_atk, 10)
	assert_eq(item.stat_def, 5)
	assert_eq(item.stat_hp, 100)
	assert_eq(item.stat_mp, 50)
	assert_eq(item.stat_spd, 3)


func test_consumable_properties() -> void:
	item.consumable = true
	item.effect_type = ItemEnums.EffectType.HEAL_HP
	item.effect_value = 50
	item.effect_duration = 10.0
	
	assert_true(item.consumable)
	assert_eq(item.effect_type, ItemEnums.EffectType.HEAL_HP)
	assert_eq(item.effect_value, 50)
	assert_eq(item.effect_duration, 10.0)


func test_crafting_properties() -> void:
	item.is_ingredient = true
	item.material_type = ItemEnums.MaterialType.ORE
	item.craftable = true
	
	assert_true(item.is_ingredient)
	assert_eq(item.material_type, ItemEnums.MaterialType.ORE)
	assert_true(item.craftable)


# === Validation Tests ===

func test_is_valid_with_valid_item() -> void:
	item.id = 1
	item.name_key = "ITEM_TEST"
	
	assert_true(item.is_valid())


func test_is_valid_with_invalid_id() -> void:
	item.id = -1
	item.name_key = "ITEM_TEST"
	
	assert_false(item.is_valid())


func test_is_valid_with_empty_name() -> void:
	item.id = 1
	item.name_key = ""
	
	assert_false(item.is_valid())


func test_validation_warnings_missing_fields() -> void:
	item.id = -1
	item.name_key = ""
	item.description_key = ""
	
	var warnings := item.get_validation_warnings()
	
	assert_true(warnings.size() >= 3, "Should have at least 3 warnings")
	assert_true("Invalid ID" in str(warnings), "Should warn about invalid ID")
	assert_true("Missing name key" in str(warnings), "Should warn about missing name key")


func test_validation_warning_equippable_no_slot() -> void:
	item.id = 1
	item.name_key = "TEST"
	item.description_key = "TEST"
	item.equippable = true
	item.equip_slot = ItemEnums.EquipSlot.NONE
	
	var warnings := item.get_validation_warnings()
	
	assert_true("slot not specified" in str(warnings), "Should warn about missing equip slot")


func test_validation_warning_consumable_no_effect() -> void:
	item.id = 1
	item.name_key = "TEST"
	item.description_key = "TEST"
	item.consumable = true
	item.effect_type = ItemEnums.EffectType.NONE
	
	var warnings := item.get_validation_warnings()
	
	assert_true("effect not specified" in str(warnings), "Should warn about missing effect")


func test_validation_warning_sell_higher_than_buy() -> void:
	item.id = 1
	item.name_key = "TEST"
	item.description_key = "TEST"
	item.buy_price = 100
	item.sell_price = 200
	
	var warnings := item.get_validation_warnings()
	
	assert_true("Sell price higher" in str(warnings), "Should warn about sell > buy")


func test_validation_warning_craftable_no_ingredients() -> void:
	item.id = 1
	item.name_key = "TEST"
	item.description_key = "TEST"
	item.craftable = true
	item.ingredients = []
	
	var warnings := item.get_validation_warnings()
	
	assert_true("no ingredients" in str(warnings), "Should warn about missing ingredients")


func test_validation_warning_ingredient_no_material_type() -> void:
	item.id = 1
	item.name_key = "TEST"
	item.description_key = "TEST"
	item.is_ingredient = true
	item.material_type = ItemEnums.MaterialType.NONE
	
	var warnings := item.get_validation_warnings()
	
	assert_true("material type not set" in str(warnings), "Should warn about missing material type")


# === Custom Fields Tests ===

func test_custom_fields_set_and_get() -> void:
	item.set_custom("damage_type", "fire")
	item.set_custom("cooldown", 2.5)
	item.set_custom("is_legendary", true)
	item.set_custom("bonus_damage", 10)
	
	assert_eq(item.get_custom("damage_type"), "fire")
	assert_eq(item.get_custom("cooldown"), 2.5)
	assert_eq(item.get_custom("is_legendary"), true)
	assert_eq(item.get_custom("bonus_damage"), 10)


func test_custom_fields_default_value() -> void:
	assert_eq(item.get_custom("nonexistent", "default"), "default")
	assert_eq(item.get_custom("missing", 42), 42)


func test_custom_fields_has_custom() -> void:
	item.set_custom("exists", true)
	
	assert_true(item.has_custom("exists"))
	assert_false(item.has_custom("not_exists"))


func test_custom_fields_remove() -> void:
	item.set_custom("to_remove", "value")
	assert_true(item.has_custom("to_remove"))
	
	var result := item.remove_custom("to_remove")
	
	assert_true(result)
	assert_false(item.has_custom("to_remove"))


func test_custom_fields_remove_nonexistent() -> void:
	var result := item.remove_custom("nonexistent")
	
	assert_false(result)


func test_custom_fields_get_keys() -> void:
	item.set_custom("key1", "value1")
	item.set_custom("key2", "value2")
	item.set_custom("key3", "value3")
	
	var keys := item.get_custom_keys()
	
	assert_eq(keys.size(), 3)
	assert_true("key1" in keys)
	assert_true("key2" in keys)
	assert_true("key3" in keys)


func test_custom_fields_typed_getters() -> void:
	item.set_custom("str_val", "hello")
	item.set_custom("int_val", 42)
	item.set_custom("float_val", 3.14)
	item.set_custom("bool_val", true)
	
	assert_eq(item.get_custom_string("str_val"), "hello")
	assert_eq(item.get_custom_int("int_val"), 42)
	assert_almost_eq(item.get_custom_float("float_val"), 3.14, 0.001)
	assert_true(item.get_custom_bool("bool_val"))


func test_custom_fields_type_conversion() -> void:
	item.set_custom("number", 42)
	
	# Int to String
	assert_eq(item.get_custom_string("number"), "42")
	
	# Int to Float
	assert_eq(item.get_custom_float("number"), 42.0)
	
	# Int to Bool (non-zero = true)
	assert_true(item.get_custom_bool("number"))


func test_custom_fields_clear() -> void:
	item.set_custom("key1", "value1")
	item.set_custom("key2", "value2")
	
	item.clear_custom_fields()
	
	assert_eq(item.get_custom_keys().size(), 0)


func test_custom_fields_merge() -> void:
	item.set_custom("existing", "old_value")
	item.set_custom("keep", "keep_value")
	
	var new_fields := {"existing": "new_value", "added": "added_value"}
	item.merge_custom_fields(new_fields, true)
	
	assert_eq(item.get_custom("existing"), "new_value")  # Overwritten
	assert_eq(item.get_custom("keep"), "keep_value")      # Kept
	assert_eq(item.get_custom("added"), "added_value")    # Added


func test_custom_fields_merge_no_overwrite() -> void:
	item.set_custom("existing", "old_value")
	
	var new_fields := {"existing": "new_value", "added": "added_value"}
	item.merge_custom_fields(new_fields, false)
	
	assert_eq(item.get_custom("existing"), "old_value")   # Not overwritten
	assert_eq(item.get_custom("added"), "added_value")    # Added


# === Duplicate Tests ===

func test_duplicate_item() -> void:
	item.id = 1
	item.name_key = "ITEM_ORIGINAL"
	item.description_key = "ITEM_ORIGINAL_DESC"
	item.category = ItemEnums.Category.WEAPON
	item.rarity = ItemEnums.Rarity.RARE
	item.buy_price = 1000
	item.set_custom("custom_prop", "custom_value")
	
	var duplicated := item.duplicate_item()
	
	assert_eq(duplicated.id, -1, "Duplicated item should have ID -1")
	assert_eq(duplicated.name_key, "ITEM_ORIGINAL")
	assert_eq(duplicated.category, ItemEnums.Category.WEAPON)
	assert_eq(duplicated.rarity, ItemEnums.Rarity.RARE)
	assert_eq(duplicated.buy_price, 1000)
	assert_eq(duplicated.get_custom("custom_prop"), "custom_value")


func test_duplicate_item_is_independent() -> void:
	item.id = 1
	item.name_key = "ORIGINAL"
	item.set_custom("key", "original")
	
	var duplicated := item.duplicate_item()
	duplicated.name_key = "DUPLICATED"
	duplicated.set_custom("key", "duplicated")
	
	assert_eq(item.name_key, "ORIGINAL", "Original should be unchanged")
	assert_eq(item.get_custom("key"), "original", "Original custom field unchanged")


# === Translation Key Generation Tests ===

func test_generate_translation_keys() -> void:
	item.id = 1
	item.generate_translation_keys("Iron Sword")
	
	assert_eq(item.name_key, "ITEM_IRON_SWORD_NAME")
	assert_eq(item.description_key, "ITEM_IRON_SWORD_DESC")


func test_generate_translation_keys_special_chars() -> void:
	item.id = 1
	item.generate_translation_keys("Magic Staff +5")
	
	assert_true(item.name_key.begins_with("ITEM_"))
	assert_true(item.name_key.ends_with("_NAME"))


func test_generate_translation_keys_empty_name() -> void:
	item.id = 42
	item.generate_translation_keys("")
	
	assert_eq(item.name_key, "ITEM_ITEM_42_NAME")


# === to_dictionary Tests ===

func test_to_dictionary() -> void:
	item.id = 1
	item.name_key = "TEST"
	item.category = ItemEnums.Category.WEAPON
	item.set_custom("custom", "value")
	
	var dict := item.to_dictionary()
	
	assert_eq(dict.id, 1)
	assert_eq(dict.name_key, "TEST")
	assert_eq(dict.category, ItemEnums.Category.WEAPON)
	assert_true(dict.has("custom_fields"))
	assert_eq(dict.custom_fields.custom, "value")
