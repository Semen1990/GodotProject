extends Node
## Скрипт для создания демонстрационных предметов.
## Запустите один раз для генерации базы данных.
##
## Путь: res://scripts/inventory/demo/create_demo_items.gd

const SAVE_PATH = "res://data/items/demo_database.tres"

func _ready():
	create_demo_database()
	print("✅ Демо база данных создана!")
	# После создания этот скрипт можно удалить


func create_demo_database():
	var db = GameItemDatabase.new()
	db.database_name = "Demo Items"
	
	# === ЗЕЛЬЯ ===
	db.add_item(_create_health_potion())
	db.add_item(_create_mana_potion())
	db.add_item(_create_stone_skin_potion())
	db.add_item(_create_rage_potion())
	
	# === ЭКИПИРОВКА ===
	db.add_item(_create_iron_sword())
	db.add_item(_create_steel_helmet())
	db.add_item(_create_leather_armor())
	db.add_item(_create_wooden_shield())
	db.add_item(_create_warrior_gloves())
	
	# === АРТЕФАКТЫ ===
	db.add_item(_create_hermes_wings())
	db.add_item(_create_phoenix_feather())
	db.add_item(_create_vampire_ring())
	db.add_item(_create_berserker_amulet())
	
	# Сохраняем
	var error = ResourceSaver.save(db, SAVE_PATH)
	if error != OK:
		push_error("Ошибка сохранения базы данных: %d" % error)
	else:
		print("💾 База сохранена в: %s" % SAVE_PATH)


# ===========================================
# ЗЕЛЬЯ
# ===========================================

func _create_health_potion() -> GameItemData:
	var item = GameItemData.new()
	item.id = 1
	item.internal_name = "health_potion"
	item.display_name = "Зелье здоровья"
	item.description = "Восстанавливает 50 единиц здоровья."
	item.category = InventoryEnums.ItemCategory.CONSUMABLE
	item.consumable_type = InventoryEnums.ConsumableType.POTION_HP
	item.rarity = InventoryEnums.ItemRarity.COMMON
	item.stackable = true
	item.max_stack = 20
	item.buy_price = 50
	item.sell_price = 25
	
	item.add_effect(
		InventoryEnums.EffectType.INSTANT_HEAL_HP,
		50.0,
		0.0,
		InventoryEnums.EffectApplication.ON_USE
	)
	
	return item


func _create_mana_potion() -> GameItemData:
	var item = GameItemData.new()
	item.id = 2
	item.internal_name = "mana_potion"
	item.display_name = "Зелье маны"
	item.description = "Восстанавливает 30 единиц маны."
	item.category = InventoryEnums.ItemCategory.CONSUMABLE
	item.consumable_type = InventoryEnums.ConsumableType.POTION_MANA
	item.rarity = InventoryEnums.ItemRarity.COMMON
	item.stackable = true
	item.max_stack = 20
	item.buy_price = 40
	item.sell_price = 20
	
	item.add_effect(
		InventoryEnums.EffectType.INSTANT_HEAL_MANA,
		30.0,
		0.0,
		InventoryEnums.EffectApplication.ON_USE
	)
	
	return item


func _create_stone_skin_potion() -> GameItemData:
	var item = GameItemData.new()
	item.id = 3
	item.internal_name = "stone_skin_potion"
	item.display_name = "Зелье каменной кожи"
	item.description = "Увеличивает броню на 4 единицы на 6 секунд."
	item.category = InventoryEnums.ItemCategory.CONSUMABLE
	item.consumable_type = InventoryEnums.ConsumableType.POTION_BUFF
	item.rarity = InventoryEnums.ItemRarity.UNCOMMON
	item.stackable = true
	item.max_stack = 10
	item.buy_price = 100
	item.sell_price = 50
	
	item.add_effect(
		InventoryEnums.EffectType.BUFF_ARMOR,
		4.0,
		6.0,
		InventoryEnums.EffectApplication.ON_USE
	)
	
	return item


func _create_rage_potion() -> GameItemData:
	var item = GameItemData.new()
	item.id = 4
	item.internal_name = "rage_potion"
	item.display_name = "Зелье ярости"
	item.description = "Увеличивает урон на 30% на 10 секунд."
	item.category = InventoryEnums.ItemCategory.CONSUMABLE
	item.consumable_type = InventoryEnums.ConsumableType.POTION_BUFF
	item.rarity = InventoryEnums.ItemRarity.RARE
	item.stackable = true
	item.max_stack = 5
	item.buy_price = 200
	item.sell_price = 100
	
	item.add_effect(
		InventoryEnums.EffectType.BUFF_DAMAGE,
		30.0,
		10.0,
		InventoryEnums.EffectApplication.ON_USE
	)
	
	return item


# ===========================================
# ЭКИПИРОВКА
# ===========================================

func _create_iron_sword() -> GameItemData:
	var item = GameItemData.new()
	item.id = 101
	item.internal_name = "iron_sword"
	item.display_name = "Железный меч"
	item.description = "Надёжный железный меч. Ничего особенного, но свою работу делает."
	item.category = InventoryEnums.ItemCategory.EQUIPMENT
	item.equipment_type = InventoryEnums.EquipmentType.SWORD
	item.equip_slot = InventoryEnums.EquipSlot.MAIN_HAND
	item.rarity = InventoryEnums.ItemRarity.COMMON
	item.stackable = false
	item.buy_price = 150
	item.sell_price = 75
	
	item.stat_damage = 5
	
	return item


func _create_steel_helmet() -> GameItemData:
	var item = GameItemData.new()
	item.id = 102
	item.internal_name = "steel_helmet"
	item.display_name = "Стальной шлем"
	item.description = "Прочный шлем из закалённой стали."
	item.category = InventoryEnums.ItemCategory.EQUIPMENT
	item.equipment_type = InventoryEnums.EquipmentType.HELMET
	item.equip_slot = InventoryEnums.EquipSlot.HEAD
	item.rarity = InventoryEnums.ItemRarity.UNCOMMON
	item.stackable = false
	item.buy_price = 200
	item.sell_price = 100
	
	item.stat_armor = 3
	item.stat_max_hp = 10
	
	return item


func _create_leather_armor() -> GameItemData:
	var item = GameItemData.new()
	item.id = 103
	item.internal_name = "leather_armor"
	item.display_name = "Кожаный доспех"
	item.description = "Лёгкий доспех из выделанной кожи. Не стесняет движений."
	item.category = InventoryEnums.ItemCategory.EQUIPMENT
	item.equipment_type = InventoryEnums.EquipmentType.ARMOR
	item.equip_slot = InventoryEnums.EquipSlot.BODY
	item.rarity = InventoryEnums.ItemRarity.COMMON
	item.stackable = false
	item.buy_price = 180
	item.sell_price = 90
	
	item.stat_armor = 2
	item.stat_speed_percent = 5
	
	return item


func _create_wooden_shield() -> GameItemData:
	var item = GameItemData.new()
	item.id = 104
	item.internal_name = "wooden_shield"
	item.display_name = "Деревянный щит"
	item.description = "Простой деревянный щит с металлической оковкой."
	item.category = InventoryEnums.ItemCategory.EQUIPMENT
	item.equipment_type = InventoryEnums.EquipmentType.SHIELD
	item.equip_slot = InventoryEnums.EquipSlot.OFF_HAND
	item.rarity = InventoryEnums.ItemRarity.COMMON
	item.stackable = false
	item.buy_price = 120
	item.sell_price = 60
	
	item.stat_armor = 2
	item.stat_block_chance = 10
	
	return item


func _create_warrior_gloves() -> GameItemData:
	var item = GameItemData.new()
	item.id = 105
	item.internal_name = "warrior_gloves"
	item.display_name = "Боевые перчатки"
	item.description = "Укреплённые перчатки воина. Усиливают хватку оружия."
	item.category = InventoryEnums.ItemCategory.EQUIPMENT
	item.equipment_type = InventoryEnums.EquipmentType.GLOVES
	item.equip_slot = InventoryEnums.EquipSlot.HANDS
	item.rarity = InventoryEnums.ItemRarity.UNCOMMON
	item.required_class = InventoryEnums.CharacterClass.WARRIOR
	item.stackable = false
	item.buy_price = 160
	item.sell_price = 80
	
	item.stat_damage = 2
	item.stat_crit_chance = 5
	
	return item


# ===========================================
# АРТЕФАКТЫ
# ===========================================

func _create_hermes_wings() -> GameItemData:
	var item = GameItemData.new()
	item.id = 201
	item.internal_name = "hermes_wings"
	item.display_name = "Крылья Гермеса"
	item.description = "Легендарные крылатые сандалии бога-посланника. Дарует способность совершить второй прыжок в воздухе."
	item.category = InventoryEnums.ItemCategory.ARTIFACT
	item.equip_slot = InventoryEnums.EquipSlot.ARTIFACT_1
	item.rarity = InventoryEnums.ItemRarity.RARE
	item.stackable = false
	item.is_unique = true
	item.buy_price = 0
	item.sell_price = 500
	item.sellable = false
	
	item.add_effect(
		InventoryEnums.EffectType.SPECIAL_DOUBLE_JUMP,
		1.0,
		0.0,
		InventoryEnums.EffectApplication.PASSIVE
	)
	
	return item


func _create_phoenix_feather() -> GameItemData:
	var item = GameItemData.new()
	item.id = 202
	item.internal_name = "phoenix_feather"
	item.display_name = "Перо Феникса"
	item.description = "Магическое перо возрождения. Возвращает к жизни после смертельного удара."
	item.category = InventoryEnums.ItemCategory.ARTIFACT
	item.equip_slot = InventoryEnums.EquipSlot.ARTIFACT_1
	item.rarity = InventoryEnums.ItemRarity.LEGENDARY
	item.stackable = false
	item.is_unique = true
	item.buy_price = 0
	item.sell_price = 1000
	item.sellable = false
	
	item.add_effect(
		InventoryEnums.EffectType.SPECIAL_REVIVAL,
		50.0,  # 50% HP при возрождении
		0.0,
		InventoryEnums.EffectApplication.PASSIVE
	)
	
	return item


func _create_vampire_ring() -> GameItemData:
	var item = GameItemData.new()
	item.id = 203
	item.internal_name = "vampire_ring"
	item.display_name = "Кольцо вампира"
	item.description = "Проклятое кольцо, питающееся кровью врагов. Часть нанесённого урона возвращается как здоровье."
	item.category = InventoryEnums.ItemCategory.ARTIFACT
	item.equip_slot = InventoryEnums.EquipSlot.ARTIFACT_1
	item.rarity = InventoryEnums.ItemRarity.EPIC
	item.stackable = false
	item.is_unique = true
	item.buy_price = 0
	item.sell_price = 750
	item.sellable = false
	
	item.add_effect(
		InventoryEnums.EffectType.SPECIAL_LIFESTEAL,
		10.0,  # 10% вампиризма
		0.0,
		InventoryEnums.EffectApplication.ON_HIT
	)
	
	return item


func _create_berserker_amulet() -> GameItemData:
	var item = GameItemData.new()
	item.id = 204
	item.internal_name = "berserker_amulet"
	item.display_name = "Амулет берсерка"
	item.description = "Амулет, пробуждающий первобытную ярость. Чем ближе к смерти — тем сильнее удар."
	item.category = InventoryEnums.ItemCategory.ARTIFACT
	item.equip_slot = InventoryEnums.EquipSlot.ARTIFACT_1
	item.rarity = InventoryEnums.ItemRarity.EPIC
	item.stackable = false
	item.is_unique = true
	item.buy_price = 0
	item.sell_price = 750
	item.sellable = false
	
	# +50% урона когда HP < 30%
	item.add_effect(
		InventoryEnums.EffectType.BUFF_DAMAGE,
		50.0,
		0.0,
		InventoryEnums.EffectApplication.ON_LOW_HP,
		30.0  # condition_value: HP < 30%
	)
	
	return item
