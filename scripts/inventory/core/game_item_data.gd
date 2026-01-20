@tool
@icon("res://addons/inventory_forge/icons/inventory_forge_icon.svg")
class_name GameItemData
extends Resource
## Определение игрового предмета.
##
## Путь: res://scripts/inventory/core/game_item_data.gd

# ===========================================
# СИГНАЛЫ
# ===========================================

signal data_changed()

# ===========================================
# БАЗОВЫЕ ДАННЫЕ
# ===========================================

@export_group("Основное")

@export var id: int = -1:
	set(value):
		id = value
		data_changed.emit()

@export var internal_name: String = "":
	set(value):
		internal_name = value
		data_changed.emit()

@export var display_name: String = "":
	set(value):
		display_name = value
		data_changed.emit()

@export_multiline var description: String = "":
	set(value):
		description = value
		data_changed.emit()

@export var icon: Texture2D:
	set(value):
		icon = value
		data_changed.emit()

# ===========================================
# КАТЕГОРИЯ И ТИП
# ===========================================

@export_group("Категория")

@export var category: InventoryEnums.ItemCategory = InventoryEnums.ItemCategory.MISC:
	set(value):
		category = value
		data_changed.emit()

@export var equipment_type: InventoryEnums.EquipmentType = InventoryEnums.EquipmentType.NONE:
	set(value):
		equipment_type = value
		data_changed.emit()

@export var consumable_type: InventoryEnums.ConsumableType = InventoryEnums.ConsumableType.NONE:
	set(value):
		consumable_type = value
		data_changed.emit()

@export var equip_slot: InventoryEnums.EquipSlot = InventoryEnums.EquipSlot.NONE:
	set(value):
		equip_slot = value
		data_changed.emit()

# ===========================================
# РЕДКОСТЬ И УРОВЕНЬ
# ===========================================

@export_group("Редкость")

@export var rarity: InventoryEnums.ItemRarity = InventoryEnums.ItemRarity.COMMON:
	set(value):
		rarity = value
		data_changed.emit()

@export_range(0, 100) var required_level: int = 0:
	set(value):
		required_level = value
		data_changed.emit()

@export var required_class: InventoryEnums.CharacterClass = InventoryEnums.CharacterClass.ANY:
	set(value):
		required_class = value
		data_changed.emit()

# ===========================================
# СТАК И ЭКОНОМИКА
# ===========================================

@export_group("Стак и цена")

@export var stackable: bool = false:
	set(value):
		stackable = value
		data_changed.emit()

@export_range(1, 999) var max_stack: int = 1:
	set(value):
		max_stack = value
		data_changed.emit()

@export_range(0, 999999) var buy_price: int = 0:
	set(value):
		buy_price = value
		data_changed.emit()

@export_range(0, 999999) var sell_price: int = 0:
	set(value):
		sell_price = value
		data_changed.emit()

@export var sellable: bool = true:
	set(value):
		sellable = value
		data_changed.emit()

@export var droppable: bool = true:
	set(value):
		droppable = value
		data_changed.emit()

# ===========================================
# СТАТЫ (ДЛЯ ЭКИПИРОВКИ)
# ===========================================

@export_group("Характеристики")

@export_range(-999, 999) var stat_max_hp: int = 0:
	set(value):
		stat_max_hp = value
		data_changed.emit()

@export_range(-999, 999) var stat_max_mana: int = 0:
	set(value):
		stat_max_mana = value
		data_changed.emit()

@export_range(-99, 99) var stat_armor: int = 0:
	set(value):
		stat_armor = value
		data_changed.emit()

@export_range(-999, 999) var stat_damage: int = 0:
	set(value):
		stat_damage = value
		data_changed.emit()

@export_range(-100, 100) var stat_speed_percent: int = 0:
	set(value):
		stat_speed_percent = value
		data_changed.emit()

@export_range(0, 100) var stat_crit_chance: int = 0:
	set(value):
		stat_crit_chance = value
		data_changed.emit()

@export_range(0, 500) var stat_crit_damage: int = 0:
	set(value):
		stat_crit_damage = value
		data_changed.emit()

@export_range(-50, 100) var stat_attack_speed: int = 0:
	set(value):
		stat_attack_speed = value
		data_changed.emit()

@export_range(0, 100) var stat_block_chance: int = 0:
	set(value):
		stat_block_chance = value
		data_changed.emit()

@export_range(0, 100) var stat_dodge_chance: int = 0:
	set(value):
		stat_dodge_chance = value
		data_changed.emit()

# ===========================================
# ЭФФЕКТЫ (ДЛЯ РАСХОДНИКОВ И АРТЕФАКТОВ)
# ===========================================

@export_group("Эффекты")

@export var effects: Array[Dictionary] = []:
	set(value):
		effects = value
		data_changed.emit()

# ===========================================
# СПЕЦИАЛЬНЫЕ ФЛАГИ
# ===========================================

@export_group("Особенности")

@export var is_quest_item: bool = false:
	set(value):
		is_quest_item = value
		data_changed.emit()

@export var quest_id: String = "":
	set(value):
		quest_id = value
		data_changed.emit()

@export var is_unique: bool = false:
	set(value):
		is_unique = value
		data_changed.emit()

@export var binds_on_pickup: bool = false:
	set(value):
		binds_on_pickup = value
		data_changed.emit()

@export var binds_on_equip: bool = false:
	set(value):
		binds_on_equip = value
		data_changed.emit()

# ===========================================
# ВИЗУАЛЬНЫЕ ЭФФЕКТЫ
# ===========================================

@export_group("Визуал")

@export var glow_color: Color = Color.WHITE:
	set(value):
		glow_color = value
		data_changed.emit()

@export var pickup_sound: AudioStream:
	set(value):
		pickup_sound = value
		data_changed.emit()

@export var use_sound: AudioStream:
	set(value):
		use_sound = value
		data_changed.emit()

# ===========================================
# КАСТОМНЫЕ ПОЛЯ
# ===========================================

@export_group("Дополнительно")

@export var custom_data: Dictionary = {}:
	set(value):
		custom_data = value
		data_changed.emit()

# ===========================================
# МЕТОДЫ
# ===========================================

func is_valid() -> bool:
	return id >= 0 and not display_name.is_empty()


func get_rarity_color() -> Color:
	return InventoryEnums.get_rarity_color(rarity)


func get_rarity_name() -> String:
	return InventoryEnums.get_rarity_name(rarity)


func get_slot_name() -> String:
	return InventoryEnums.get_slot_name(equip_slot)


func is_equippable() -> bool:
	return equip_slot != InventoryEnums.EquipSlot.NONE


func is_usable() -> bool:
	return category == InventoryEnums.ItemCategory.CONSUMABLE


func is_artifact() -> bool:
	return category == InventoryEnums.ItemCategory.ARTIFACT


func get_valid_equip_slots() -> Array[InventoryEnums.EquipSlot]:
	"""Возвращает список допустимых слотов для экипировки"""
	if category == InventoryEnums.ItemCategory.ARTIFACT:
		return [
			InventoryEnums.EquipSlot.ARTIFACT_1,
			InventoryEnums.EquipSlot.ARTIFACT_2,
			InventoryEnums.EquipSlot.ARTIFACT_3,
			InventoryEnums.EquipSlot.ARTIFACT_4,
		]
	
	# Если указан конкретный слот
	if equip_slot != InventoryEnums.EquipSlot.NONE:
		return [equip_slot]
	
	return InventoryEnums.get_valid_slots_for_equipment(equipment_type)


func can_equip_in_slot(slot: InventoryEnums.EquipSlot) -> bool:
	"""Проверяет, можно ли экипировать предмет в указанный слот"""
	if slot == InventoryEnums.EquipSlot.NONE:
		return false
	
	# Артефакты - в слоты артефактов
	if category == InventoryEnums.ItemCategory.ARTIFACT:
		return slot in [
			InventoryEnums.EquipSlot.ARTIFACT_1,
			InventoryEnums.EquipSlot.ARTIFACT_2,
			InventoryEnums.EquipSlot.ARTIFACT_3,
			InventoryEnums.EquipSlot.ARTIFACT_4,
		]
	
	# Экипировка - в соответствующий слот
	if equip_slot != InventoryEnums.EquipSlot.NONE:
		return slot == equip_slot
	
	# Проверяем по типу экипировки
	var valid_slots = InventoryEnums.get_valid_slots_for_equipment(equipment_type)
	return slot in valid_slots


func can_class_use(char_class: InventoryEnums.CharacterClass) -> bool:
	if required_class == InventoryEnums.CharacterClass.ANY:
		return true
	return required_class == char_class


func meets_level_requirement(level: int) -> bool:
	return level >= required_level


func get_stats_dict() -> Dictionary:
	return {
		"max_hp": stat_max_hp,
		"max_mana": stat_max_mana,
		"armor": stat_armor,
		"damage": stat_damage,
		"speed_percent": stat_speed_percent,
		"crit_chance": stat_crit_chance,
		"crit_damage": stat_crit_damage,
		"attack_speed": stat_attack_speed,
		"block_chance": stat_block_chance,
		"dodge_chance": stat_dodge_chance,
	}


func add_effect(type: InventoryEnums.EffectType, value: float, 
				duration: float = 0.0, 
				application: InventoryEnums.EffectApplication = InventoryEnums.EffectApplication.PASSIVE,
				condition_value: float = 0.0) -> void:
	effects.append({
		"type": type,
		"value": value,
		"duration": duration,
		"application": application,
		"condition_value": condition_value,
	})
	data_changed.emit()


func has_effect(effect_type: InventoryEnums.EffectType) -> bool:
	for effect in effects:
		if effect.get("type") == effect_type:
			return true
	return false


func get_effect_value(effect_type: InventoryEnums.EffectType) -> float:
	for effect in effects:
		if effect.get("type") == effect_type:
			return effect.get("value", 0.0)
	return 0.0


func generate_tooltip() -> String:
	var text = ""
	
	text += "[color=%s]%s[/color]\n" % [get_rarity_color().to_html(), display_name]
	text += "[color=gray]%s[/color]\n" % get_rarity_name()
	
	if is_equippable():
		text += "[color=yellow]%s[/color]\n" % get_slot_name()
	
	text += "\n"
	
	var stats = get_stats_dict()
	for stat_name in stats:
		var value = stats[stat_name]
		if value != 0:
			var sign_str = "+" if value > 0 else ""
			var suffix = "%" if "percent" in stat_name or "chance" in stat_name else ""
			var display = stat_name.replace("_", " ").capitalize()
			text += "[color=green]%s%d%s %s[/color]\n" % [sign_str, value, suffix, display]
	
	if not effects.is_empty():
		text += "\n[color=cyan]Эффекты:[/color]\n"
		for effect in effects:
			var eff_type = effect.get("type", 0)
			var eff_value = effect.get("value", 0)
			var eff_duration = effect.get("duration", 0)
			text += "• %s\n" % _get_effect_description(eff_type, eff_value, eff_duration)
	
	if not description.is_empty():
		text += "\n[color=gray][i]%s[/i][/color]\n" % description
	
	if required_level > 0:
		text += "\n[color=red]Требуется уровень: %d[/color]" % required_level
	
	if required_class != InventoryEnums.CharacterClass.ANY:
		text += "\n[color=red]Только для: %s[/color]" % InventoryEnums.CharacterClass.keys()[required_class]
	
	return text


func _get_effect_description(type: InventoryEnums.EffectType, value: float, duration: float) -> String:
	var dur_text = " на %.1f сек" % duration if duration > 0 else ""
	
	match type:
		InventoryEnums.EffectType.INSTANT_HEAL_HP:
			return "Восстанавливает %d HP" % int(value)
		InventoryEnums.EffectType.INSTANT_HEAL_MANA:
			return "Восстанавливает %d маны" % int(value)
		InventoryEnums.EffectType.BUFF_ARMOR:
			return "+%d брони%s" % [int(value), dur_text]
		InventoryEnums.EffectType.BUFF_DAMAGE:
			return "+%d урона%s" % [int(value), dur_text]
		InventoryEnums.EffectType.BUFF_SPEED:
			return "+%d%% скорости%s" % [int(value), dur_text]
		InventoryEnums.EffectType.SPECIAL_DOUBLE_JUMP:
			return "Двойной прыжок"
		InventoryEnums.EffectType.SPECIAL_LIFESTEAL:
			return "%d%% вампиризма" % int(value)
		InventoryEnums.EffectType.SPECIAL_REVIVAL:
			return "Возрождение с %d%% HP" % int(value)
		InventoryEnums.EffectType.SPECIAL_DAMAGE_REFLECT:
			return "Отражает %d%% урона" % int(value)
		_:
			return "Эффект %d: %.1f" % [type, value]


func duplicate_item() -> GameItemData:
	var copy = GameItemData.new()
	
	copy.id = -1
	copy.internal_name = internal_name + "_copy"
	copy.display_name = display_name
	copy.description = description
	copy.icon = icon
	copy.category = category
	copy.equipment_type = equipment_type
	copy.consumable_type = consumable_type
	copy.equip_slot = equip_slot
	copy.rarity = rarity
	copy.required_level = required_level
	copy.required_class = required_class
	copy.stackable = stackable
	copy.max_stack = max_stack
	copy.buy_price = buy_price
	copy.sell_price = sell_price
	copy.sellable = sellable
	copy.droppable = droppable
	copy.stat_max_hp = stat_max_hp
	copy.stat_max_mana = stat_max_mana
	copy.stat_armor = stat_armor
	copy.stat_damage = stat_damage
	copy.stat_speed_percent = stat_speed_percent
	copy.stat_crit_chance = stat_crit_chance
	copy.stat_crit_damage = stat_crit_damage
	copy.stat_attack_speed = stat_attack_speed
	copy.stat_block_chance = stat_block_chance
	copy.stat_dodge_chance = stat_dodge_chance
	copy.effects = effects.duplicate(true)
	copy.is_quest_item = is_quest_item
	copy.quest_id = quest_id
	copy.is_unique = is_unique
	copy.binds_on_pickup = binds_on_pickup
	copy.binds_on_equip = binds_on_equip
	copy.glow_color = glow_color
	copy.pickup_sound = pickup_sound
	copy.use_sound = use_sound
	copy.custom_data = custom_data.duplicate(true)
	
	return copy
