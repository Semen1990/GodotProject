extends Node
class_name InventoryManager
## Главный менеджер инвентаря.
## Управляет сумкой, экипировкой и быстрыми слотами.
##
## Путь: res://scripts/inventory/core/inventory_manager.gd
##
## Добавьте как Autoload: Project Settings → Autoload → inventory_manager.gd
## Имя: Inventory

# ===========================================
# СИГНАЛЫ
# ===========================================

# --- Сумка ---
signal item_added(item: InventoryItem, slot_index: int)
signal item_removed(item: InventoryItem, slot_index: int)
signal item_moved(item: InventoryItem, from_index: int, to_index: int)
signal inventory_changed()
signal inventory_full()

# --- Экипировка ---
signal item_equipped(item: InventoryItem, slot: InventoryEnums.EquipSlot)
signal item_unequipped(item: InventoryItem, slot: InventoryEnums.EquipSlot)
signal equipment_changed()

# --- Быстрые слоты ---
signal hotbar_changed(slot_index: int)
signal hotbar_item_used(slot_index: int, item: InventoryItem)

# --- Статы ---
signal stats_updated(stats: Dictionary)

# ===========================================
# КОНСТАНТЫ
# ===========================================

## Базовое количество слотов в сумке
const BASE_INVENTORY_SLOTS: int = 20

## Максимальное количество слотов
const MAX_INVENTORY_SLOTS: int = 60

## Количество быстрых слотов
const HOTBAR_SLOTS: int = 4

# ===========================================
# ДАННЫЕ
# ===========================================

## База данных предметов
var item_database: GameItemDatabase = null

## Слоты инвентаря (сумка)
var inventory_slots: Array[InventoryItem] = []

## Текущее количество слотов
var current_slot_count: int = BASE_INVENTORY_SLOTS

## Слоты экипировки (ключ = EquipSlot, значение = InventoryItem)
var equipment_slots: Dictionary = {}

## Быстрые слоты (0-3 для клавиш 1-4)
var hotbar_slots: Array[InventoryItem] = []

## Текущий класс персонажа (для ограничений)
var character_class: InventoryEnums.CharacterClass = InventoryEnums.CharacterClass.WARRIOR

## Уровень персонажа (для ограничений)
var character_level: int = 1

## Бонусные слоты от эффектов
var bonus_slots: int = 0

# ===========================================
# ИНИЦИАЛИЗАЦИЯ
# ===========================================

func _ready():
	_initialize_slots()
	print("🎒 InventoryManager инициализирован")
	print("   Слотов инвентаря: %d" % current_slot_count)
	print("   Слотов экипировки: %d" % equipment_slots.size())
	print("   Быстрых слотов: %d" % HOTBAR_SLOTS)


## Инициализирует все слоты
func _initialize_slots():
	# Инвентарь (сумка)
	inventory_slots.clear()
	inventory_slots.resize(MAX_INVENTORY_SLOTS)
	for i in range(MAX_INVENTORY_SLOTS):
		inventory_slots[i] = null
	
	# Экипировка
	equipment_slots.clear()
	for slot in InventoryEnums.EquipSlot.values():
		if slot != InventoryEnums.EquipSlot.NONE:
			equipment_slots[slot] = null
	
	# Быстрые слоты
	hotbar_slots.clear()
	hotbar_slots.resize(HOTBAR_SLOTS)
	for i in range(HOTBAR_SLOTS):
		hotbar_slots[i] = null


## Устанавливает базу данных предметов
func set_database(database: GameItemDatabase):
	item_database = database
	print("🎒 База данных установлена: %d предметов" % database.items.size())


## Устанавливает класс персонажа
func set_character_class(char_class: InventoryEnums.CharacterClass):
	character_class = char_class
	
	# Применяем классовые бонусы
	match char_class:
		InventoryEnums.CharacterClass.WARRIOR:
			# "Вьючная сила" - +4 слота
			add_bonus_slots(4)

# ===========================================
# УПРАВЛЕНИЕ СЛОТАМИ
# ===========================================

## Добавляет бонусные слоты
func add_bonus_slots(amount: int):
	bonus_slots += amount
	current_slot_count = mini(BASE_INVENTORY_SLOTS + bonus_slots, MAX_INVENTORY_SLOTS)
	print("🎒 Бонусные слоты: +%d (всего %d)" % [amount, current_slot_count])
	inventory_changed.emit()


## Возвращает текущее количество доступных слотов
func get_available_slot_count() -> int:
	return current_slot_count


## Возвращает количество занятых слотов
func get_used_slot_count() -> int:
	var count = 0
	for i in range(current_slot_count):
		if inventory_slots[i] != null:
			count += 1
	return count


## Возвращает количество свободных слотов
func get_free_slot_count() -> int:
	return current_slot_count - get_used_slot_count()


## Проверяет, есть ли свободные слоты
func has_free_slots() -> bool:
	return get_free_slot_count() > 0

# ===========================================
# ДОБАВЛЕНИЕ ПРЕДМЕТОВ
# ===========================================

## Добавляет предмет в инвентарь
## Возвращает количество, которое НЕ поместилось
func add_item(item: InventoryItem) -> int:
	if item == null or item.is_empty():
		return 0
	
	var remaining = item.quantity
	
	# Сначала пытаемся добавить в существующие стаки
	if item.is_stackable():
		for i in range(current_slot_count):
			if inventory_slots[i] != null and inventory_slots[i].is_same_type(item):
				if not inventory_slots[i].is_full():
					remaining = inventory_slots[i].add(remaining)
					if remaining == 0:
						item_added.emit(item, i)
						inventory_changed.emit()
						return 0
	
	# Затем ищем пустой слот
	var empty_slot = _find_empty_slot()
	if empty_slot >= 0:
		if item.is_stackable():
			item.quantity = remaining
		inventory_slots[empty_slot] = item
		item_added.emit(item, empty_slot)
		inventory_changed.emit()
		return 0
	
	# Инвентарь полон
	inventory_full.emit()
	return remaining


## Добавляет предмет по ID (создаёт новый экземпляр)
func add_item_by_id(item_id: int, quantity: int = 1) -> int:
	if item_database == null:
		push_error("InventoryManager: база данных не установлена")
		return quantity
	
	var item = InventoryItem.create_from_id(item_id, quantity, item_database)
	if item == null:
		return quantity
	
	return add_item(item)


## Добавляет предмет по внутреннему имени
func add_item_by_name(internal_name: String, quantity: int = 1) -> int:
	if item_database == null:
		push_error("InventoryManager: база данных не установлена")
		return quantity
	
	var item_data = item_database.get_item_by_name(internal_name)
	if item_data == null:
		push_error("InventoryManager: предмет '%s' не найден" % internal_name)
		return quantity
	
	var item = InventoryItem.new(item_data, quantity)
	return add_item(item)


## Находит первый пустой слот
func _find_empty_slot() -> int:
	for i in range(current_slot_count):
		if inventory_slots[i] == null:
			return i
	return -1

# ===========================================
# УДАЛЕНИЕ ПРЕДМЕТОВ
# ===========================================

## Удаляет предмет из слота
func remove_item_at(slot_index: int) -> InventoryItem:
	if slot_index < 0 or slot_index >= current_slot_count:
		return null
	
	var item = inventory_slots[slot_index]
	if item == null:
		return null
	
	inventory_slots[slot_index] = null
	item_removed.emit(item, slot_index)
	inventory_changed.emit()
	
	return item


## Удаляет указанное количество предмета по ID
## Возвращает сколько реально удалено
func remove_item_by_id(item_id: int, quantity: int = 1) -> int:
	var removed = 0
	
	for i in range(current_slot_count):
		if inventory_slots[i] != null and inventory_slots[i].get_item_id() == item_id:
			var to_remove = mini(quantity - removed, inventory_slots[i].quantity)
			inventory_slots[i].remove(to_remove)
			removed += to_remove
			
			# Удаляем пустой слот
			if inventory_slots[i].is_empty():
				var old_item = inventory_slots[i]
				inventory_slots[i] = null
				item_removed.emit(old_item, i)
			
			if removed >= quantity:
				break
	
	if removed > 0:
		inventory_changed.emit()
	
	return removed


## Проверяет наличие предмета
func has_item(item_id: int, quantity: int = 1) -> bool:
	return get_item_count(item_id) >= quantity


## Возвращает общее количество предмета в инвентаре
func get_item_count(item_id: int) -> int:
	var count = 0
	for i in range(current_slot_count):
		if inventory_slots[i] != null and inventory_slots[i].get_item_id() == item_id:
			count += inventory_slots[i].quantity
	return count

# ===========================================
# ПЕРЕМЕЩЕНИЕ ПРЕДМЕТОВ
# ===========================================

## Перемещает предмет между слотами
func move_item(from_index: int, to_index: int) -> bool:
	if from_index < 0 or from_index >= current_slot_count:
		return false
	if to_index < 0 or to_index >= current_slot_count:
		return false
	if from_index == to_index:
		return false
	
	var from_item = inventory_slots[from_index]
	var to_item = inventory_slots[to_index]
	
	# Если целевой слот пуст - просто перемещаем
	if to_item == null:
		inventory_slots[to_index] = from_item
		inventory_slots[from_index] = null
		item_moved.emit(from_item, from_index, to_index)
		inventory_changed.emit()
		return true
	
	# Если одинаковые стакаемые предметы - объединяем
	if from_item.is_same_type(to_item) and from_item.is_stackable():
		var overflow = to_item.add(from_item.quantity)
		if overflow == 0:
			inventory_slots[from_index] = null
		else:
			from_item.quantity = overflow
		inventory_changed.emit()
		return true
	
	# Иначе меняем местами
	inventory_slots[from_index] = to_item
	inventory_slots[to_index] = from_item
	item_moved.emit(from_item, from_index, to_index)
	inventory_changed.emit()
	return true


## Разделяет стак
func split_stack(slot_index: int, amount: int) -> bool:
	if slot_index < 0 or slot_index >= current_slot_count:
		return false
	
	var item = inventory_slots[slot_index]
	if item == null or not item.is_stackable():
		return false
	
	if amount <= 0 or amount >= item.quantity:
		return false
	
	var empty_slot = _find_empty_slot()
	if empty_slot < 0:
		inventory_full.emit()
		return false
	
	var new_item = item.split(amount)
	inventory_slots[empty_slot] = new_item
	
	item_added.emit(new_item, empty_slot)
	inventory_changed.emit()
	return true

# ===========================================
# ЭКИПИРОВКА
# ===========================================

## Экипирует предмет из инвентаря
func equip_item(inventory_index: int, target_slot: InventoryEnums.EquipSlot = InventoryEnums.EquipSlot.NONE) -> bool:
	if inventory_index < 0 or inventory_index >= current_slot_count:
		return false
	
	var item = inventory_slots[inventory_index]
	if item == null or not item.is_equippable():
		return false
	
	# Определяем слот
	var valid_slots = item.get_valid_equip_slots()
	if valid_slots.is_empty():
		return false
	
	var slot = target_slot
	if slot == InventoryEnums.EquipSlot.NONE or slot not in valid_slots:
		# Ищем первый свободный подходящий слот
		slot = InventoryEnums.EquipSlot.NONE
		for s in valid_slots:
			if equipment_slots.get(s) == null:
				slot = s
				break
		
		# Если все заняты - берём первый
		if slot == InventoryEnums.EquipSlot.NONE:
			slot = valid_slots[0]
	
	# Проверяем требования
	if not _can_equip(item):
		return false
	
	# Снимаем текущий предмет из слота (если есть)
	var old_item = equipment_slots.get(slot)
	if old_item != null:
		# Пытаемся положить в инвентарь
		var overflow = add_item(old_item)
		if overflow > 0:
			inventory_full.emit()
			return false
		item_unequipped.emit(old_item, slot)
	
	# Экипируем новый
	equipment_slots[slot] = item
	inventory_slots[inventory_index] = null
	
	# Привязываем если нужно
	if item.data and item.data.binds_on_equip:
		item.bind()
	
	item_equipped.emit(item, slot)
	item_removed.emit(item, inventory_index)
	equipment_changed.emit()
	inventory_changed.emit()
	
	_recalculate_stats()
	
	return true


## Снимает экипировку
func unequip_item(slot: InventoryEnums.EquipSlot) -> bool:
	var item = equipment_slots.get(slot)
	if item == null:
		return false
	
	# Проверяем место в инвентаре
	if not has_free_slots():
		inventory_full.emit()
		return false
	
	equipment_slots[slot] = null
	add_item(item)
	
	item_unequipped.emit(item, slot)
	equipment_changed.emit()
	
	_recalculate_stats()
	
	return true


## Проверяет, можно ли экипировать предмет
func _can_equip(item: InventoryItem) -> bool:
	if item == null or item.data == null:
		return false
	
	# Проверка класса
	if not item.data.can_class_use(character_class):
		return false
	
	# Проверка уровня
	if not item.data.meets_level_requirement(character_level):
		return false
	
	return true


## Возвращает экипированный предмет
func get_equipped_item(slot: InventoryEnums.EquipSlot) -> InventoryItem:
	return equipment_slots.get(slot)


## Возвращает все экипированные предметы
func get_all_equipped() -> Dictionary:
	var result: Dictionary = {}
	for slot in equipment_slots:
		if equipment_slots[slot] != null:
			result[slot] = equipment_slots[slot]
	return result

# ===========================================
# БЫСТРЫЕ СЛОТЫ (1-4)
# ===========================================

## Устанавливает предмет в быстрый слот
func set_hotbar_item(hotbar_index: int, inventory_index: int) -> bool:
	if hotbar_index < 0 or hotbar_index >= HOTBAR_SLOTS:
		return false
	
	if inventory_index < 0 or inventory_index >= current_slot_count:
		# Очищаем слот
		hotbar_slots[hotbar_index] = null
		hotbar_changed.emit(hotbar_index)
		return true
	
	var item = inventory_slots[inventory_index]
	if item == null:
		return false
	
	# Только расходники могут быть в быстрых слотах
	if not item.is_usable():
		return false
	
	hotbar_slots[hotbar_index] = item
	hotbar_changed.emit(hotbar_index)
	return true


## Использует предмет из быстрого слота
func use_hotbar_item(hotbar_index: int) -> bool:
	if hotbar_index < 0 or hotbar_index >= HOTBAR_SLOTS:
		return false
	
	var item = hotbar_slots[hotbar_index]
	if item == null or item.is_empty():
		hotbar_slots[hotbar_index] = null
		hotbar_changed.emit(hotbar_index)
		return false
	
	# Используем предмет
	if _use_item(item):
		hotbar_item_used.emit(hotbar_index, item)
		
		# Удаляем если закончился
		if item.is_empty():
			hotbar_slots[hotbar_index] = null
			# Удаляем из инвентаря тоже
			for i in range(current_slot_count):
				if inventory_slots[i] == item:
					inventory_slots[i] = null
					break
			inventory_changed.emit()
		
		hotbar_changed.emit(hotbar_index)
		return true
	
	return false


## Возвращает предмет из быстрого слота
func get_hotbar_item(hotbar_index: int) -> InventoryItem:
	if hotbar_index < 0 or hotbar_index >= HOTBAR_SLOTS:
		return null
	return hotbar_slots[hotbar_index]

# ===========================================
# ИСПОЛЬЗОВАНИЕ ПРЕДМЕТОВ
# ===========================================

## Использует предмет (внутренний метод)
func _use_item(item: InventoryItem) -> bool:
	if item == null or item.data == null:
		return false
	
	if not item.is_usable():
		return false
	
	# Применяем эффекты
	for effect in item.data.effects:
		_apply_effect(effect)
	
	# Уменьшаем количество
	item.remove(1)
	
	return true


## Применяет эффект (заглушка - нужно подключить к персонажу)
func _apply_effect(effect: Dictionary):
	var effect_type = effect.get("type", InventoryEnums.EffectType.NONE)
	var value = effect.get("value", 0.0)
	var duration = effect.get("duration", 0.0)
	
	print("🧪 Применяем эффект: тип=%d, значение=%.1f, длительность=%.1f" % [effect_type, value, duration])
	
	# TODO: Подключить к системе персонажа
	# Global.current_player.apply_effect(effect_type, value, duration)

# ===========================================
# РАСЧЁТ СТАТОВ
# ===========================================

## Пересчитывает статы от экипировки
func _recalculate_stats():
	var total_stats = {
		"max_hp": 0,
		"max_mana": 0,
		"armor": 0,
		"damage": 0,
		"speed_percent": 0,
		"crit_chance": 0,
		"crit_damage": 0,
		"attack_speed": 0,
		"block_chance": 0,
		"dodge_chance": 0,
	}
	
	var special_effects: Array[Dictionary] = []
	
	# Суммируем от всей экипировки
	for slot in equipment_slots:
		var item = equipment_slots[slot]
		if item == null or item.data == null:
			continue
		
		var stats = item.data.get_stats_dict()
		for stat_name in stats:
			total_stats[stat_name] = total_stats.get(stat_name, 0) + stats[stat_name]
		
		# Собираем специальные эффекты
		for effect in item.data.effects:
			if effect.get("application") == InventoryEnums.EffectApplication.PASSIVE:
				special_effects.append(effect)
	
	total_stats["special_effects"] = special_effects
	
	print("📊 Статы обновлены: ", total_stats)
	stats_updated.emit(total_stats)


## Возвращает текущие бонусы от экипировки
func get_equipment_stats() -> Dictionary:
	var total_stats = {
		"max_hp": 0,
		"max_mana": 0,
		"armor": 0,
		"damage": 0,
		"speed_percent": 0,
		"crit_chance": 0,
		"crit_damage": 0,
		"attack_speed": 0,
		"block_chance": 0,
		"dodge_chance": 0,
	}
	
	for slot in equipment_slots:
		var item = equipment_slots[slot]
		if item == null or item.data == null:
			continue
		
		var stats = item.data.get_stats_dict()
		for stat_name in stats:
			total_stats[stat_name] = total_stats.get(stat_name, 0) + stats[stat_name]
	
	return total_stats


## Проверяет наличие специального эффекта
func has_special_effect(effect_type: InventoryEnums.EffectType) -> bool:
	for slot in equipment_slots:
		var item = equipment_slots[slot]
		if item != null and item.data != null:
			if item.data.has_effect(effect_type):
				return true
	return false


## Возвращает суммарное значение специального эффекта
func get_special_effect_value(effect_type: InventoryEnums.EffectType) -> float:
	var total = 0.0
	for slot in equipment_slots:
		var item = equipment_slots[slot]
		if item != null and item.data != null:
			total += item.data.get_effect_value(effect_type)
	return total

# ===========================================
# СОХРАНЕНИЕ / ЗАГРУЗКА
# ===========================================

## Сериализует весь инвентарь
func serialize() -> Dictionary:
	var inv_data: Array[Dictionary] = []
	for i in range(current_slot_count):
		if inventory_slots[i] != null:
			inv_data.append({
				"slot": i,
				"item": inventory_slots[i].serialize()
			})
	
	var equip_data: Dictionary = {}
	for slot in equipment_slots:
		if equipment_slots[slot] != null:
			equip_data[slot] = equipment_slots[slot].serialize()
	
	var hotbar_data: Array = []
	for i in range(HOTBAR_SLOTS):
		if hotbar_slots[i] != null:
			# Ищем индекс в инвентаре
			var inv_index = -1
			for j in range(current_slot_count):
				if inventory_slots[j] == hotbar_slots[i]:
					inv_index = j
					break
			hotbar_data.append(inv_index)
		else:
			hotbar_data.append(-1)
	
	return {
		"inventory": inv_data,
		"equipment": equip_data,
		"hotbar": hotbar_data,
		"bonus_slots": bonus_slots,
		"character_class": character_class,
		"character_level": character_level,
	}


## Десериализует инвентарь
func deserialize(data: Dictionary):
	if item_database == null:
		push_error("InventoryManager: база данных не установлена для десериализации")
		return
	
	_initialize_slots()
	
	bonus_slots = data.get("bonus_slots", 0)
	current_slot_count = mini(BASE_INVENTORY_SLOTS + bonus_slots, MAX_INVENTORY_SLOTS)
	character_class = data.get("character_class", InventoryEnums.CharacterClass.WARRIOR)
	character_level = data.get("character_level", 1)
	
	# Загружаем инвентарь
	var inv_data = data.get("inventory", [])
	for entry in inv_data:
		var slot = entry.get("slot", -1)
		var item_data = entry.get("item", {})
		if slot >= 0 and slot < current_slot_count:
			var item = InventoryItem.deserialize(item_data, item_database)
			if item != null:
				inventory_slots[slot] = item
	
	# Загружаем экипировку
	var equip_data = data.get("equipment", {})
	for slot_str in equip_data:
		var slot = int(slot_str)
		var item_data = equip_data[slot_str]
		var item = InventoryItem.deserialize(item_data, item_database)
		if item != null:
			equipment_slots[slot] = item
	
	# Загружаем быстрые слоты (ссылки на инвентарь)
	var hotbar_data = data.get("hotbar", [])
	for i in range(mini(hotbar_data.size(), HOTBAR_SLOTS)):
		var inv_index = hotbar_data[i]
		if inv_index >= 0 and inv_index < current_slot_count:
			hotbar_slots[i] = inventory_slots[inv_index]
	
	inventory_changed.emit()
	equipment_changed.emit()
	_recalculate_stats()
	
	print("🎒 Инвентарь загружен")

# ===========================================
# ОТЛАДКА
# ===========================================

## Выводит содержимое инвентаря
func debug_print():
	print("=== ИНВЕНТАРЬ (%d/%d) ===" % [get_used_slot_count(), current_slot_count])
	for i in range(current_slot_count):
		if inventory_slots[i] != null:
			print("  [%d] %s" % [i, inventory_slots[i]])
	
	print("=== ЭКИПИРОВКА ===")
	for slot in equipment_slots:
		if equipment_slots[slot] != null:
			var slot_name = InventoryEnums.get_slot_name(slot)
			print("  %s: %s" % [slot_name, equipment_slots[slot]])
	
	print("=== БЫСТРЫЕ СЛОТЫ ===")
	for i in range(HOTBAR_SLOTS):
		var item = hotbar_slots[i]
		print("  [%d] %s" % [i + 1, item if item else "Пусто"])
