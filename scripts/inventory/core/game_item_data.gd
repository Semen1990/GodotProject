@tool
@icon("res://addons/inventory_forge/icons/inventory_forge_icon.svg")
class_name GameItemData
extends Resource
## Определение игрового предмета.
## Расширяет функционал Inventory Forge для нужд проекта.
##
## Путь: res://scripts/inventory/core/game_item_data.gd
##
## Использование:
## 1. Создайте новый Resource в редакторе Godot
## 2. Выберите тип GameItemData
## 3. Заполните поля в Inspector
## 4. Сохраните как .tres файл в res://data/items/

# ===========================================
# СИГНАЛЫ
# ===========================================

signal data_changed()

# ===========================================
# БАЗОВЫЕ ДАННЫЕ
# ===========================================

@export_group("Основное")

## Уникальный ID предмета
@export var id: int = -1:
	set(value):
		id = value
		data_changed.emit()

## Внутреннее имя (для кода)
@export var internal_name: String = "":
	set(value):
		internal_name = value
		data_changed.emit()

## Отображаемое название
@export var display_name: String = "":
	set(value):
		display_name = value
		data_changed.emit()

## Описание предмета
@export_multiline var description: String = "":
	set(value):
		description = value
		data_changed.emit()

## Иконка предмета
@export var icon: Texture2D:
	set(value):
		icon = value
		data_changed.emit()

# ===========================================
# КАТЕГОРИЯ И ТИП
# ===========================================

@export_group("Категория")

## Основная категория
@export var category: InventoryEnums.ItemCategory = InventoryEnums.ItemCategory.MISC:
	set(value):
		category = value
		data_changed.emit()

## Тип экипировки (если категория = EQUIPMENT)
@export var equipment_type: InventoryEnums.EquipmentType = InventoryEnums.EquipmentType.NONE:
	set(value):
		equipment_type = value
		data_changed.emit()

## Тип расходника (если категория = CONSUMABLE)
@export var consumable_type: InventoryEnums.ConsumableType = InventoryEnums.ConsumableType.NONE:
	set(value):
		consumable_type = value
		data_changed.emit()

## Слот экипировки (куда можно надеть)
@export var equip_slot: InventoryEnums.EquipSlot = InventoryEnums.EquipSlot.NONE:
	set(value):
		equip_slot = value
		data_changed.emit()

# ===========================================
# РЕДКОСТЬ И УРОВЕНЬ
# ===========================================

@export_group("Редкость")

## Редкость предмета
@export var rarity: InventoryEnums.ItemRarity = InventoryEnums.ItemRarity.COMMON:
	set(value):
		rarity = value
		data_changed.emit()

## Требуемый уровень персонажа (0 = без требований)
@export_range(0, 100) var required_level: int = 0:
	set(value):
		required_level = value
		data_changed.emit()

## Ограничение по классу (ANY = для всех)
@export var required_class: InventoryEnums.CharacterClass = InventoryEnums.CharacterClass.ANY:
	set(value):
		required_class = value
		data_changed.emit()

# ===========================================
# СТАК И ЭКОНОМИКА
# ===========================================

@export_group("Стак и цена")

## Можно ли стакать (для зелий и материалов)
@export var stackable: bool = false:
	set(value):
		stackable = value
		data_changed.emit()

## Максимальный размер стака
@export_range(1, 999) var max_stack: int = 1:
	set(value):
		max_stack = value
		data_changed.emit()

## Цена покупки
@export_range(0, 999999) var buy_price: int = 0:
	set(value):
		buy_price = value
		data_changed.emit()

## Цена продажи
@export_range(0, 999999) var sell_price: int = 0:
	set(value):
		sell_price = value
		data_changed.emit()

## Можно ли продать
@export var sellable: bool = true:
	set(value):
		sellable = value
		data_changed.emit()

## Можно ли выбросить
@export var droppable: bool = true:
	set(value):
		droppable = value
		data_changed.emit()

# ===========================================
# СТАТЫ (ДЛЯ ЭКИПИРОВКИ)
# ===========================================

@export_group("Характеристики")

## +Максимальное здоровье
@export_range(-999, 999) var stat_max_hp: int = 0:
	set(value):
		stat_max_hp = value
		data_changed.emit()

## +Максимальная мана
@export_range(-999, 999) var stat_max_mana: int = 0:
	set(value):
		stat_max_mana = value
		data_changed.emit()

## +Броня
@export_range(-99, 99) var stat_armor: int = 0:
	set(value):
		stat_armor = value
		data_changed.emit()

## +Урон
@export_range(-999, 999) var stat_damage: int = 0:
	set(value):
		stat_damage = value
		data_changed.emit()

## +Скорость передвижения (%)
@export_range(-100, 100) var stat_speed_percent: int = 0:
	set(value):
		stat_speed_percent = value
		data_changed.emit()

## +Шанс крита (%)
@export_range(0, 100) var stat_crit_chance: int = 0:
	set(value):
		stat_crit_chance = value
		data_changed.emit()

## +Урон крита (%)
@export_range(0, 500) var stat_crit_damage: int = 0:
	set(value):
		stat_crit_damage = value
		data_changed.emit()

## +Скорость атаки (%)
@export_range(-50, 100) var stat_attack_speed: int = 0:
	set(value):
		stat_attack_speed = value
		data_changed.emit()

## +Шанс блока (%)
@export_range(0, 100) var stat_block_chance: int = 0:
	set(value):
		stat_block_chance = value
		data_changed.emit()

## +Шанс уклонения (%)
@export_range(0, 100) var stat_dodge_chance: int = 0:
	set(value):
		stat_dodge_chance = value
		data_changed.emit()

# ===========================================
# ЭФФЕКТЫ (ДЛЯ РАСХОДНИКОВ И АРТЕФАКТОВ)
# ===========================================

@export_group("Эффекты")

## Список эффектов предмета
@export var effects: Array[Dictionary] = []:
	set(value):
		effects = value
		data_changed.emit()

# Формат эффекта:
# {
#     "type": InventoryEnums.EffectType,
#     "value": float,                    # Значение эффекта
#     "duration": float,                 # Длительность (0 = мгновенно/постоянно)
#     "application": InventoryEnums.EffectApplication,
#     "condition_value": float,          # Условие (например, % HP для ON_LOW_HP)
# }

# ===========================================
# СПЕЦИАЛЬНЫЕ ФЛАГИ
# ===========================================

@export_group("Особенности")

## Это квестовый предмет
@export var is_quest_item: bool = false:
	set(value):
		is_quest_item = value
		data_changed.emit()

## ID связанного квеста
@export var quest_id: String = "":
	set(value):
		quest_id = value
		data_changed.emit()

## Уникальный предмет (только 1 в инвентаре)
@export var is_unique: bool = false:
	set(value):
		is_unique = value
		data_changed.emit()

## Привязывается при подборе (нельзя передать/продать)
@export var binds_on_pickup: bool = false:
	set(value):
		binds_on_pickup = value
		data_changed.emit()

## Привязывается при экипировке
@export var binds_on_equip: bool = false:
	set(value):
		binds_on_equip = value
		data_changed.emit()

# ===========================================
# ВИЗУАЛЬНЫЕ ЭФФЕКТЫ
# ===========================================

@export_group("Визуал")

## Цвет свечения (для редких предметов)
@export var glow_color: Color = Color.WHITE:
	set(value):
		glow_color = value
		data_changed.emit()

## Звук при подборе
@export var pickup_sound: AudioStream:
	set(value):
		pickup_sound = value
		data_changed.emit()

## Звук при использовании
@export var use_sound: AudioStream:
	set(value):
		use_sound = value
		data_changed.emit()

# ===========================================
# КАСТОМНЫЕ ПОЛЯ
# ===========================================

@export_group("Дополнительно")

## Произвольные данные (для особых механик)
@export var custom_data: Dictionary = {}:
	set(value):
		custom_data = value
		data_changed.emit()

# ===========================================
# МЕТОДЫ
# ===========================================

## Проверяет валидность предмета
func is_valid() -> bool:
	return id >= 0 and not display_name.is_empty()


## Возвращает цвет редкости
func get_rarity_color() -> Color:
	return InventoryEnums.get_rarity_color(rarity)


## Возвращает название редкости
func get_rarity_name() -> String:
	return InventoryEnums.get_rarity_name(rarity)


## Возвращает название слота
func get_slot_name() -> String:
	return InventoryEnums.get_slot_name(equip_slot)


## Можно ли экипировать
func is_equippable() -> bool:
	return equip_slot != InventoryEnums.EquipSlot.NONE


## Можно ли использовать (расходник)
func is_usable() -> bool:
	return category == InventoryEnums.ItemCategory.CONSUMABLE


## Это артефакт
func is_artifact() -> bool:
	return category == InventoryEnums.ItemCategory.ARTIFACT


## Возвращает допустимые слоты для экипировки
func get_valid_equip_slots() -> Array[InventoryEnums.EquipSlot]:
	if category == InventoryEnums.ItemCategory.ARTIFACT:
		return [
			InventoryEnums.EquipSlot.ARTIFACT_1,
			InventoryEnums.EquipSlot.ARTIFACT_2,
			InventoryEnums.EquipSlot.ARTIFACT_3,
			InventoryEnums.EquipSlot.ARTIFACT_4,
		]
	
	return InventoryEnums.get_valid_slots_for_equipment(equipment_type)


## Проверяет, может ли класс использовать предмет
func can_class_use(char_class: InventoryEnums.CharacterClass) -> bool:
	if required_class == InventoryEnums.CharacterClass.ANY:
		return true
	return required_class == char_class


## Проверяет требования уровня
func meets_level_requirement(level: int) -> bool:
	return level >= required_level


## Возвращает суммарные статы как словарь
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


## Добавляет эффект к предмету
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


## Проверяет наличие эффекта определённого типа
func has_effect(effect_type: InventoryEnums.EffectType) -> bool:
	for effect in effects:
		if effect.get("type") == effect_type:
			return true
	return false


## Возвращает значение эффекта (или 0 если нет)
func get_effect_value(effect_type: InventoryEnums.EffectType) -> float:
	for effect in effects:
		if effect.get("type") == effect_type:
			return effect.get("value", 0.0)
	return 0.0


## Генерирует текст подсказки
func generate_tooltip() -> String:
	var text = ""
	
	# Название с цветом редкости
	text += "[color=%s]%s[/color]\n" % [get_rarity_color().to_html(), display_name]
	text += "[color=gray]%s[/color]\n" % get_rarity_name()
	
	# Тип предмета
	if is_equippable():
		text += "[color=yellow]%s[/color]\n" % get_slot_name()
	
	text += "\n"
	
	# Статы
	var stats = get_stats_dict()
	for stat_name in stats:
		var value = stats[stat_name]
		if value != 0:
			var sign_str = "+" if value > 0 else ""
			var suffix = "%" if "percent" in stat_name or "chance" in stat_name else ""
			var display = stat_name.replace("_", " ").capitalize()
			text += "[color=green]%s%d%s %s[/color]\n" % [sign_str, value, suffix, display]
	
	# Эффекты
	if not effects.is_empty():
		text += "\n[color=cyan]Эффекты:[/color]\n"
		for effect in effects:
			var eff_type = effect.get("type", 0)
			var eff_value = effect.get("value", 0)
			var eff_duration = effect.get("duration", 0)
			
			# Упрощённое описание эффекта
			text += "• %s\n" % _get_effect_description(eff_type, eff_value, eff_duration)
	
	# Описание
	if not description.is_empty():
		text += "\n[color=gray][i]%s[/i][/color]\n" % description
	
	# Требования
	if required_level > 0:
		text += "\n[color=red]Требуется уровень: %d[/color]" % required_level
	
	if required_class != InventoryEnums.CharacterClass.ANY:
		text += "\n[color=red]Только для: %s[/color]" % InventoryEnums.CharacterClass.keys()[required_class]
	
	return text


## Возвращает описание эффекта
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
			return "+%d%% урона%s" % [int(value), dur_text]
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


## Создаёт копию предмета
func duplicate_item() -> GameItemData:
	var copy = GameItemData.new()
	
	# Копируем все поля
	copy.id = -1  # Новый ID
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
