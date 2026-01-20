class_name DemoItems
extends RefCounted
## Создаёт демо-предметы для тестирования системы инвентаря.
##
## Путь: res://scripts/inventory/demo/demo_items.gd
##
## ЗНАЧЕНИЯ ЗЕЛИЙ:
## - Малое зелье здоровья: +2 HP
## - Малое зелье маны: +2 MP
## - Малое зелье каменной кожи: +1 броня (до конца комнаты)
## - Зелье ярости: +1 урон (до конца комнаты)

static func create_demo_database() -> GameItemDatabase:
	var db = GameItemDatabase.new()
	
	# === ЗЕЛЬЯ ===
	db.items.append(_create_health_potion())      # ID: 1
	db.items.append(_create_mana_potion())        # ID: 2
	db.items.append(_create_armor_potion())       # ID: 3
	db.items.append(_create_rage_potion())        # ID: 4
	
	# === ЭКИПИРОВКА ===
	db.items.append(_create_iron_sword())         # ID: 101
	db.items.append(_create_steel_helmet())       # ID: 102
	db.items.append(_create_leather_armor())      # ID: 103
	db.items.append(_create_wooden_shield())      # ID: 104
	db.items.append(_create_combat_gloves())      # ID: 105
	
	# === АРТЕФАКТЫ ===
	db.items.append(_create_hermes_wings())       # ID: 201
	db.items.append(_create_phoenix_feather())    # ID: 202
	db.items.append(_create_vampire_ring())       # ID: 203
	db.items.append(_create_berserker_amulet())   # ID: 204
	
	return db


# ===========================================
# ЗЕЛЬЯ
# ===========================================

static func _create_health_potion() -> GameItemData:
	"""Малое зелье здоровья - восстанавливает 2 HP"""
	var item = GameItemData.new()
	item.id = 1
	item.internal_name = "health_potion"
	item.display_name = "Малое зелье здоровья"
	item.description = "Восстанавливает 2 единицы здоровья."
	item.category = InventoryEnums.ItemCategory.CONSUMABLE
	item.consumable_type = InventoryEnums.ConsumableType.POTION_HP
	item.rarity = InventoryEnums.ItemRarity.COMMON
	item.stackable = true
	item.max_stack = 20
	item.buy_price = 10
	item.sell_price = 5
	
	# Эффект: +2 HP мгновенно
	item.effects.append({
		"type": InventoryEnums.EffectType.INSTANT_HEAL_HP,
		"value": 2.0,
		"duration": 0.0,
		"application": InventoryEnums.EffectApplication.ON_USE,
	})
	
	return item


static func _create_mana_potion() -> GameItemData:
	"""Малое зелье маны - восстанавливает 2 маны"""
	var item = GameItemData.new()
	item.id = 2
	item.internal_name = "mana_potion"
	item.display_name = "Малое зелье маны"
	item.description = "Восстанавливает 2 единицы маны."
	item.category = InventoryEnums.ItemCategory.CONSUMABLE
	item.consumable_type = InventoryEnums.ConsumableType.POTION_MANA
	item.rarity = InventoryEnums.ItemRarity.COMMON
	item.stackable = true
	item.max_stack = 20
	item.buy_price = 15
	item.sell_price = 7
	
	# Эффект: +2 маны мгновенно
	item.effects.append({
		"type": InventoryEnums.EffectType.INSTANT_HEAL_MANA,
		"value": 2.0,
		"duration": 0.0,
		"application": InventoryEnums.EffectApplication.ON_USE,
	})
	
	return item


static func _create_armor_potion() -> GameItemData:
	"""Малое зелье каменной кожи - +1 броня до конца комнаты"""
	var item = GameItemData.new()
	item.id = 3
	item.internal_name = "stoneskin_potion"
	item.display_name = "Малое зелье каменной кожи"
	item.description = "Увеличивает броню на 1 до конца комнаты."
	item.category = InventoryEnums.ItemCategory.CONSUMABLE
	item.consumable_type = InventoryEnums.ConsumableType.POTION_BUFF
	item.rarity = InventoryEnums.ItemRarity.UNCOMMON
	item.stackable = true
	item.max_stack = 10
	item.buy_price = 25
	item.sell_price = 12
	
	# Эффект: +1 броня (до конца комнаты, duration = 0 означает постоянный)
	item.effects.append({
		"type": InventoryEnums.EffectType.BUFF_ARMOR,
		"value": 1.0,
		"duration": 0.0,  # 0 = до конца комнаты
		"application": InventoryEnums.EffectApplication.ON_USE,
	})
	
	return item


static func _create_rage_potion() -> GameItemData:
	"""Зелье ярости - +1 урон до конца комнаты"""
	var item = GameItemData.new()
	item.id = 4
	item.internal_name = "rage_potion"
	item.display_name = "Зелье ярости"
	item.description = "Увеличивает урон на 1 до конца комнаты."
	item.category = InventoryEnums.ItemCategory.CONSUMABLE
	item.consumable_type = InventoryEnums.ConsumableType.POTION_BUFF
	item.rarity = InventoryEnums.ItemRarity.UNCOMMON
	item.stackable = true
	item.max_stack = 10
	item.buy_price = 30
	item.sell_price = 15
	
	# Эффект: +1 урон (до конца комнаты)
	item.effects.append({
		"type": InventoryEnums.EffectType.BUFF_DAMAGE,
		"value": 1.0,
		"duration": 0.0,  # 0 = до конца комнаты
		"application": InventoryEnums.EffectApplication.ON_USE,
	})
	
	return item


# ===========================================
# ЭКИПИРОВКА
# ===========================================

static func _create_iron_sword() -> GameItemData:
	"""Железный меч - +2 урона"""
	var item = GameItemData.new()
	item.id = 101
	item.internal_name = "iron_sword"
	item.display_name = "Железный меч"
	item.description = "Простой, но надёжный клинок."
	item.category = InventoryEnums.ItemCategory.EQUIPMENT
	item.equipment_type = InventoryEnums.EquipmentType.SWORD
	item.equip_slot = InventoryEnums.EquipSlot.MAIN_HAND
	item.rarity = InventoryEnums.ItemRarity.COMMON
	item.stat_damage = 2
	item.buy_price = 50
	item.sell_price = 25
	return item


static func _create_steel_helmet() -> GameItemData:
	"""Стальной шлем - +1 броня"""
	var item = GameItemData.new()
	item.id = 102
	item.internal_name = "steel_helmet"
	item.display_name = "Стальной шлем"
	item.description = "Защищает голову от ударов."
	item.category = InventoryEnums.ItemCategory.EQUIPMENT
	item.equipment_type = InventoryEnums.EquipmentType.HELMET
	item.equip_slot = InventoryEnums.EquipSlot.HEAD
	item.rarity = InventoryEnums.ItemRarity.COMMON
	item.stat_armor = 1
	item.buy_price = 40
	item.sell_price = 20
	return item


static func _create_leather_armor() -> GameItemData:
	"""Кожаный доспех - +1 броня, +5 HP"""
	var item = GameItemData.new()
	item.id = 103
	item.internal_name = "leather_armor"
	item.display_name = "Кожаный доспех"
	item.description = "Лёгкий, но достаточно прочный."
	item.category = InventoryEnums.ItemCategory.EQUIPMENT
	item.equipment_type = InventoryEnums.EquipmentType.ARMOR
	item.equip_slot = InventoryEnums.EquipSlot.BODY
	item.rarity = InventoryEnums.ItemRarity.COMMON
	item.stat_armor = 1
	item.stat_max_hp = 5
	item.buy_price = 60
	item.sell_price = 30
	return item


static func _create_wooden_shield() -> GameItemData:
	"""Деревянный щит - +2 броня, +5% блока"""
	var item = GameItemData.new()
	item.id = 104
	item.internal_name = "wooden_shield"
	item.display_name = "Деревянный щит"
	item.description = "Простой щит из дуба."
	item.category = InventoryEnums.ItemCategory.EQUIPMENT
	item.equipment_type = InventoryEnums.EquipmentType.SHIELD
	item.equip_slot = InventoryEnums.EquipSlot.OFF_HAND
	item.rarity = InventoryEnums.ItemRarity.COMMON
	item.stat_armor = 2
	item.stat_block_chance = 5
	item.buy_price = 35
	item.sell_price = 17
	return item


static func _create_combat_gloves() -> GameItemData:
	"""Боевые перчатки - +1 урон, +1 броня"""
	var item = GameItemData.new()
	item.id = 105
	item.internal_name = "combat_gloves"
	item.display_name = "Боевые перчатки"
	item.description = "Укреплённые металлическими пластинами."
	item.category = InventoryEnums.ItemCategory.EQUIPMENT
	item.equipment_type = InventoryEnums.EquipmentType.GLOVES
	item.equip_slot = InventoryEnums.EquipSlot.HANDS
	item.rarity = InventoryEnums.ItemRarity.UNCOMMON
	item.stat_damage = 1
	item.stat_armor = 1
	item.buy_price = 45
	item.sell_price = 22
	return item


# ===========================================
# АРТЕФАКТЫ
# ===========================================

static func _create_hermes_wings() -> GameItemData:
	"""Крылья Гермеса - двойной прыжок"""
	var item = GameItemData.new()
	item.id = 201
	item.internal_name = "hermes_wings"
	item.display_name = "Крылья Гермеса"
	item.description = "Древний артефакт, дарующий способность к двойному прыжку."
	item.category = InventoryEnums.ItemCategory.ARTIFACT
	item.rarity = InventoryEnums.ItemRarity.EPIC
	item.is_unique = true
	item.buy_price = 500
	item.sell_price = 250
	
	item.effects.append({
		"type": InventoryEnums.EffectType.SPECIAL_DOUBLE_JUMP,
		"value": 1.0,
		"duration": 0.0,
		"application": InventoryEnums.EffectApplication.PASSIVE,
	})
	
	return item


static func _create_phoenix_feather() -> GameItemData:
	"""Перо Феникса - возрождение с 50% HP"""
	var item = GameItemData.new()
	item.id = 202
	item.internal_name = "phoenix_feather"
	item.display_name = "Перо Феникса"
	item.description = "Один раз спасёт вас от смерти, возродив с 50% здоровья."
	item.category = InventoryEnums.ItemCategory.ARTIFACT
	item.rarity = InventoryEnums.ItemRarity.LEGENDARY
	item.is_unique = true
	item.buy_price = 1000
	item.sell_price = 500
	
	item.effects.append({
		"type": InventoryEnums.EffectType.SPECIAL_REVIVAL,
		"value": 50.0,  # 50% HP при возрождении
		"duration": 0.0,
		"application": InventoryEnums.EffectApplication.PASSIVE,
	})
	
	return item


static func _create_vampire_ring() -> GameItemData:
	"""Кольцо вампира - 10% вампиризма"""
	var item = GameItemData.new()
	item.id = 203
	item.internal_name = "vampire_ring"
	item.display_name = "Кольцо вампира"
	item.description = "Восстанавливает 10% от нанесённого урона в виде здоровья."
	item.category = InventoryEnums.ItemCategory.ARTIFACT
	item.rarity = InventoryEnums.ItemRarity.RARE
	item.is_unique = true
	item.buy_price = 300
	item.sell_price = 150
	
	item.effects.append({
		"type": InventoryEnums.EffectType.SPECIAL_LIFESTEAL,
		"value": 10.0,  # 10% вампиризма
		"duration": 0.0,
		"application": InventoryEnums.EffectApplication.PASSIVE,
	})
	
	return item


static func _create_berserker_amulet() -> GameItemData:
	"""Амулет берсерка - +30% урона при HP < 30%"""
	var item = GameItemData.new()
	item.id = 204
	item.internal_name = "berserker_amulet"
	item.display_name = "Амулет берсерка"
	item.description = "Увеличивает урон на 30% когда здоровье ниже 30%."
	item.category = InventoryEnums.ItemCategory.ARTIFACT
	item.rarity = InventoryEnums.ItemRarity.EPIC
	item.is_unique = true
	item.buy_price = 400
	item.sell_price = 200
	
	item.effects.append({
		"type": InventoryEnums.EffectType.BUFF_DAMAGE,
		"value": 30.0,  # +30% урона
		"duration": 0.0,
		"application": InventoryEnums.EffectApplication.ON_LOW_HP,
		"condition_value": 30.0,  # При HP < 30%
	})
	
	return item
