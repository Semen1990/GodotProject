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

signal item_added(item: InventoryItem, slot_index: int)
signal item_removed(item: InventoryItem, slot_index: int)
signal item_moved(item: InventoryItem, from_index: int, to_index: int)
signal inventory_changed()
signal inventory_full()

signal item_equipped(item: InventoryItem, slot: InventoryEnums.EquipSlot)
signal item_unequipped(item: InventoryItem, slot: InventoryEnums.EquipSlot)
signal equipment_changed()

signal hotbar_changed(slot_index: int)
signal hotbar_item_used(slot_index: int, item: InventoryItem)

signal stats_updated(stats: Dictionary)

# ===========================================
# КОНСТАНТЫ
# ===========================================

const BASE_INVENTORY_SLOTS: int = 20
const MAX_INVENTORY_SLOTS: int = 60
const HOTBAR_SLOTS: int = 4

# ===========================================
# ДАННЫЕ
# ===========================================

var item_database: GameItemDatabase = null
var inventory_slots: Array[InventoryItem] = []
var current_slot_count: int = BASE_INVENTORY_SLOTS
var equipment_slots: Dictionary = {}
var hotbar_slots: Array[InventoryItem] = []
var character_class: InventoryEnums.CharacterClass = InventoryEnums.CharacterClass.WARRIOR
var character_level: int = 1
var bonus_slots: int = 0

# === СИСТЕМА ИСПОЛЬЗОВАННЫХ ЗЕЛИЙ ===
# Хранит ID зелий, использованных в текущей комнате
var used_potions_this_room: Array[int] = []

# === АКТИВНЫЕ БАФФЫ ОТ ЗЕЛИЙ ===
# Ключ = ID предмета, Значение = словарь с данными баффа
var active_potion_buffs: Dictionary = {}

# === ФЛАГ ИНИЦИАЛИЗАЦИИ ===
var is_initialized: bool = false

# ===========================================
# ИНИЦИАЛИЗАЦИЯ
# ===========================================

func _ready():
	_initialize_slots()
	print("🎒 InventoryManager инициализирован")
	print("   Слотов инвентаря: %d" % current_slot_count)
	print("   Слотов экипировки: %d" % equipment_slots.size())
	print("   Быстрых слотов: %d" % HOTBAR_SLOTS)


func _initialize_slots():
	"""Инициализирует все слоты"""
	inventory_slots.clear()
	inventory_slots.resize(MAX_INVENTORY_SLOTS)
	for i in range(MAX_INVENTORY_SLOTS):
		inventory_slots[i] = null
	
	equipment_slots.clear()
	for slot in InventoryEnums.EquipSlot.values():
		if slot != InventoryEnums.EquipSlot.NONE:
			equipment_slots[slot] = null
	
	hotbar_slots.clear()
	hotbar_slots.resize(HOTBAR_SLOTS)
	for i in range(HOTBAR_SLOTS):
		hotbar_slots[i] = null


# ===========================================
# ОЧИСТКА ИНВЕНТАРЯ (для нового забега)
# ===========================================

func clear_all():
	"""Полностью очищает инвентарь для нового забега"""
	print("🗑️ Очистка инвентаря...")
	
	_initialize_slots()
	bonus_slots = 0
	current_slot_count = BASE_INVENTORY_SLOTS
	
	# Очищаем использованные зелья
	used_potions_this_room.clear()
	active_potion_buffs.clear()
	
	# Сбрасываем флаг инициализации
	is_initialized = false
	
	inventory_changed.emit()
	equipment_changed.emit()
	
	print("✅ Инвентарь очищен")


func reset_for_new_room():
	"""Сбрасывает состояние для новой комнаты"""
	print("🚪 Новая комната - сброс зелий")
	
	# Сбрасываем использованные зелья
	used_potions_this_room.clear()
	
	# Убираем все активные баффы от зелий
	active_potion_buffs.clear()
	
	print("✅ Зелья можно использовать снова")


func reset_on_death():
	"""Сбрасывает баффы при смерти"""
	print("💀 Смерть - сброс баффов от зелий")
	
	# Очищаем использованные зелья (можно использовать после возрождения)
	used_potions_this_room.clear()
	
	# Очищаем активные баффы
	active_potion_buffs.clear()
	
	print("✅ Баффы от зелий сброшены")


# ===========================================
# НАСТРОЙКА
# ===========================================

func set_database(database: GameItemDatabase):
	item_database = database
	print("🎒 База данных установлена: %d предметов" % database.items.size())


func set_character_class(char_class: InventoryEnums.CharacterClass):
	character_class = char_class
	
	# Применяем классовые бонусы только если ещё не применяли
	if not is_initialized:
		match char_class:
			InventoryEnums.CharacterClass.WARRIOR:
				add_bonus_slots(4)
		is_initialized = true


# ===========================================
# УПРАВЛЕНИЕ СЛОТАМИ
# ===========================================

func add_bonus_slots(amount: int):
	bonus_slots += amount
	current_slot_count = mini(BASE_INVENTORY_SLOTS + bonus_slots, MAX_INVENTORY_SLOTS)
	print("🎒 Бонусные слоты: +%d (всего %d)" % [amount, current_slot_count])
	inventory_changed.emit()


func get_available_slot_count() -> int:
	return current_slot_count


func get_used_slot_count() -> int:
	var count = 0
	for i in range(current_slot_count):
		if inventory_slots[i] != null:
			count += 1
	return count


func get_free_slot_count() -> int:
	return current_slot_count - get_used_slot_count()


func has_free_slots() -> bool:
	return get_free_slot_count() > 0


# ===========================================
# СИСТЕМА ЗЕЛИЙ (1 РАЗ ЗА КОМНАТУ)
# ===========================================

func can_use_potion(item_id: int) -> bool:
	"""Проверяет, можно ли использовать зелье"""
	return not item_id in used_potions_this_room


func mark_potion_used(item_id: int):
	"""Помечает зелье как использованное в этой комнате"""
	if not item_id in used_potions_this_room:
		used_potions_this_room.append(item_id)
		print("🧪 Зелье ID %d помечено как использованное" % item_id)


func is_potion_used(item_id: int) -> bool:
	"""Проверяет, использовано ли зелье в этой комнате"""
	return item_id in used_potions_this_room


func add_active_buff(item_id: int, buff_data: Dictionary):
	"""Добавляет активный бафф от зелья"""
	active_potion_buffs[item_id] = buff_data
	print("✨ Добавлен бафф от зелья ID %d: %s" % [item_id, buff_data])


func remove_active_buff(item_id: int):
	"""Удаляет активный бафф"""
	if item_id in active_potion_buffs:
		active_potion_buffs.erase(item_id)


func get_active_buffs() -> Dictionary:
	"""Возвращает все активные баффы"""
	return active_potion_buffs.duplicate()


func get_total_buff_value(stat_name: String) -> int:
	"""Возвращает суммарное значение баффа по имени стата"""
	var total = 0
	for item_id in active_potion_buffs:
		var buff = active_potion_buffs[item_id]
		if buff.has(stat_name):
			total += buff[stat_name]
	return total


# ===========================================
# ДОБАВЛЕНИЕ ПРЕДМЕТОВ
# ===========================================

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
	
	inventory_full.emit()
	return remaining


func add_item_by_id(item_id: int, quantity: int = 1) -> int:
	if item_database == null:
		push_error("InventoryManager: база данных не установлена")
		return quantity
	
	var item = InventoryItem.create_from_id(item_id, quantity, item_database)
	if item == null:
		return quantity
	
	return add_item(item)


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


func _find_empty_slot() -> int:
	for i in range(current_slot_count):
		if inventory_slots[i] == null:
			return i
	return -1


# ===========================================
# УДАЛЕНИЕ ПРЕДМЕТОВ
# ===========================================

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


func remove_item_by_id(item_id: int, quantity: int = 1) -> int:
	var removed = 0
	
	for i in range(current_slot_count):
		if inventory_slots[i] != null and inventory_slots[i].get_item_id() == item_id:
			var to_remove = mini(quantity - removed, inventory_slots[i].quantity)
			inventory_slots[i].remove(to_remove)
			removed += to_remove
			
			if inventory_slots[i].is_empty():
				var old_item = inventory_slots[i]
				inventory_slots[i] = null
				item_removed.emit(old_item, i)
			
			if removed >= quantity:
				break
	
	if removed > 0:
		inventory_changed.emit()
	
	return removed


func has_item(item_id: int, quantity: int = 1) -> bool:
	return get_item_count(item_id) >= quantity


func get_item_count(item_id: int) -> int:
	var count = 0
	for i in range(current_slot_count):
		if inventory_slots[i] != null and inventory_slots[i].get_item_id() == item_id:
			count += inventory_slots[i].quantity
	return count


# ===========================================
# ПЕРЕМЕЩЕНИЕ ПРЕДМЕТОВ
# ===========================================

func move_item(from_index: int, to_index: int) -> bool:
	if from_index < 0 or from_index >= current_slot_count:
		return false
	if to_index < 0 or to_index >= current_slot_count:
		return false
	if from_index == to_index:
		return false
	
	var from_item = inventory_slots[from_index]
	if from_item == null:
		return false
	
	var to_item = inventory_slots[to_index]
	
	# Если целевой слот пуст - просто перемещаем
	if to_item == null:
		inventory_slots[to_index] = from_item
		inventory_slots[from_index] = null
		item_moved.emit(from_item, from_index, to_index)
		inventory_changed.emit()
		return true
	
	# Если одинаковые предметы - пытаемся объединить стаки
	if from_item.is_same_type(to_item) and to_item.is_stackable():
		var overflow = to_item.add(from_item.quantity)
		if overflow == 0:
			inventory_slots[from_index] = null
		else:
			from_item.quantity = overflow
		inventory_changed.emit()
		return true
	
	# Иначе - меняем местами
	inventory_slots[from_index] = to_item
	inventory_slots[to_index] = from_item
	item_moved.emit(from_item, from_index, to_index)
	inventory_changed.emit()
	return true


func get_item_at(index: int) -> InventoryItem:
	if index < 0 or index >= current_slot_count:
		return null
	return inventory_slots[index]


# ===========================================
# ЭКИПИРОВКА
# ===========================================

func equip_item(inventory_index: int, slot: InventoryEnums.EquipSlot = InventoryEnums.EquipSlot.NONE) -> bool:
	if inventory_index < 0 or inventory_index >= current_slot_count:
		return false
	
	var item = inventory_slots[inventory_index]
	if item == null or item.data == null:
		return false
	
	# Проверяем, можно ли экипировать
	if not item.is_equippable():
		return false
	
	# Определяем слот
	if slot == InventoryEnums.EquipSlot.NONE:
		var valid_slots = item.get_valid_equip_slots()
		if valid_slots.is_empty():
			return false
		slot = valid_slots[0]
	
	# Проверяем, подходит ли слот
	if not item.can_equip_in_slot(slot):
		return false
	
	# Если в слоте уже есть предмет - снимаем его
	var old_item = equipment_slots.get(slot)
	if old_item != null:
		# Ищем пустой слот в инвентаре
		var empty = _find_empty_slot()
		if empty < 0:
			return false  # Нет места
		inventory_slots[empty] = old_item
		item_unequipped.emit(old_item, slot)
	
	# Экипируем новый предмет
	equipment_slots[slot] = item
	inventory_slots[inventory_index] = null
	
	item_equipped.emit(item, slot)
	equipment_changed.emit()
	inventory_changed.emit()
	
	# ВАЖНО: Пересчитываем статы
	_recalculate_stats()
	
	return true


func unequip_item(slot: InventoryEnums.EquipSlot) -> bool:
	if not equipment_slots.has(slot):
		return false
	
	var item = equipment_slots[slot]
	if item == null:
		return false
	
	# Ищем пустой слот
	var empty = _find_empty_slot()
	if empty < 0:
		return false
	
	inventory_slots[empty] = item
	equipment_slots[slot] = null
	
	item_unequipped.emit(item, slot)
	equipment_changed.emit()
	inventory_changed.emit()
	
	# ВАЖНО: Пересчитываем статы
	_recalculate_stats()
	
	return true


func get_equipped_item(slot: InventoryEnums.EquipSlot) -> InventoryItem:
	return equipment_slots.get(slot)


func is_slot_equipped(slot: InventoryEnums.EquipSlot) -> bool:
	return equipment_slots.get(slot) != null


# ===========================================
# БЫСТРЫЕ СЛОТЫ (HOTBAR)
# ===========================================

func set_hotbar_item(hotbar_index: int, inventory_index: int) -> bool:
	if hotbar_index < 0 or hotbar_index >= HOTBAR_SLOTS:
		return false
	
	if inventory_index < 0 or inventory_index >= current_slot_count:
		hotbar_slots[hotbar_index] = null
		hotbar_changed.emit(hotbar_index)
		return true
	
	var item = inventory_slots[inventory_index]
	if item == null:
		return false
	
	if not item.is_usable():
		return false
	
	hotbar_slots[hotbar_index] = item
	hotbar_changed.emit(hotbar_index)
	return true


func use_hotbar_item(hotbar_index: int) -> bool:
	if hotbar_index < 0 or hotbar_index >= HOTBAR_SLOTS:
		return false
	
	var item = hotbar_slots[hotbar_index]
	if item == null or item.is_empty():
		hotbar_slots[hotbar_index] = null
		hotbar_changed.emit(hotbar_index)
		return false
	
	if _use_item(item):
		hotbar_item_used.emit(hotbar_index, item)
		
		if item.is_empty():
			hotbar_slots[hotbar_index] = null
			for i in range(current_slot_count):
				if inventory_slots[i] == item:
					inventory_slots[i] = null
					break
			inventory_changed.emit()
		
		hotbar_changed.emit(hotbar_index)
		return true
	
	return false


func get_hotbar_item(hotbar_index: int) -> InventoryItem:
	if hotbar_index < 0 or hotbar_index >= HOTBAR_SLOTS:
		return null
	return hotbar_slots[hotbar_index]


# ===========================================
# ИСПОЛЬЗОВАНИЕ ПРЕДМЕТОВ
# ===========================================

func _use_item(item: InventoryItem) -> bool:
	if item == null or item.data == null:
		return false
	
	if not item.is_usable():
		return false
	
	# ПРОВЕРКА: Зелье уже использовано в этой комнате?
	var item_id = item.get_item_id()
	if is_potion_used(item_id):
		print("⚠️ Зелье уже использовано в этой комнате!")
		return false
	
	# Помечаем зелье как использованное
	mark_potion_used(item_id)
	
	# Применяем эффекты
	for effect in item.data.effects:
		_apply_effect(effect)
	
	# Уменьшаем количество
	item.remove(1)
	
	return true


func _apply_effect(effect: Dictionary):
	var effect_type = effect.get("type", InventoryEnums.EffectType.NONE)
	var value = effect.get("value", 0.0)
	var duration = effect.get("duration", 0.0)
	
	print("🧪 Применяем эффект: тип=%d, значение=%.1f, длительность=%.1f" % [effect_type, value, duration])


# ===========================================
# РАСЧЁТ СТАТОВ ОТ ЭКИПИРОВКИ
# ===========================================

func _recalculate_stats():
	"""Пересчитывает статы от экипировки"""
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
	
	for slot in equipment_slots:
		var item = equipment_slots[slot]
		if item == null or item.data == null:
			continue
		
		var stats = item.data.get_stats_dict()
		for stat_name in stats:
			total_stats[stat_name] = total_stats.get(stat_name, 0) + stats[stat_name]
		
		for effect in item.data.effects:
			if effect.get("application") == InventoryEnums.EffectApplication.PASSIVE:
				special_effects.append(effect)
	
	total_stats["special_effects"] = special_effects
	
	print("📊 Статы от экипировки: ", total_stats)
	stats_updated.emit(total_stats)


func get_equipment_stats() -> Dictionary:
	"""Возвращает текущие бонусы от экипировки"""
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


func has_special_effect(effect_type: InventoryEnums.EffectType) -> bool:
	for slot in equipment_slots:
		var item = equipment_slots[slot]
		if item != null and item.data != null:
			if item.data.has_effect(effect_type):
				return true
	return false


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


func deserialize(data: Dictionary):
	if item_database == null:
		push_error("InventoryManager: база данных не установлена для десериализации")
		return
	
	_initialize_slots()
	
	bonus_slots = data.get("bonus_slots", 0)
	current_slot_count = mini(BASE_INVENTORY_SLOTS + bonus_slots, MAX_INVENTORY_SLOTS)
	character_class = data.get("character_class", InventoryEnums.CharacterClass.WARRIOR)
	character_level = data.get("character_level", 1)
	
	var inv_data = data.get("inventory", [])
	for entry in inv_data:
		var slot = entry.get("slot", -1)
		var item_data = entry.get("item", {})
		if slot >= 0 and slot < current_slot_count:
			var item = InventoryItem.deserialize(item_data, item_database)
			if item != null:
				inventory_slots[slot] = item
	
	var equip_data = data.get("equipment", {})
	for slot_str in equip_data:
		var slot = int(slot_str)
		var item_data_dict = equip_data[slot_str]
		var item = InventoryItem.deserialize(item_data_dict, item_database)
		if item != null:
			equipment_slots[slot] = item
	
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
	
	print("=== ИСПОЛЬЗОВАННЫЕ ЗЕЛЬЯ ===")
	print("  ", used_potions_this_room)
