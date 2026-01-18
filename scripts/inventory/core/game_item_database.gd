@tool
class_name GameItemDatabase
extends Resource
## База данных всех игровых предметов.
## Хранит все GameItemData и предоставляет методы поиска.
##
## Путь: res://scripts/inventory/core/game_item_database.gd
##
## Использование:
## 1. Создайте Resource типа GameItemDatabase
## 2. Добавляйте предметы через редактор или код
## 3. Сохраните как .tres файл

# ===========================================
# СИГНАЛЫ
# ===========================================

signal item_added(item: GameItemData)
signal item_removed(item: GameItemData)
signal database_changed()

# ===========================================
# ДАННЫЕ
# ===========================================

## Список всех предметов
@export var items: Array[GameItemData] = []:
	set(value):
		items = value
		emit_changed()
		database_changed.emit()

## Название базы данных (для отладки)
@export var database_name: String = "Game Items"

# ===========================================
# ПОИСК ПРЕДМЕТОВ
# ===========================================

## Возвращает предмет по ID
func get_item_by_id(id: int) -> GameItemData:
	for item in items:
		if item and item.id == id:
			return item
	return null


## Возвращает предмет по внутреннему имени
func get_item_by_name(internal_name: String) -> GameItemData:
	for item in items:
		if item and item.internal_name == internal_name:
			return item
	return null


## Проверяет существование предмета
func has_item(id: int) -> bool:
	return get_item_by_id(id) != null


## Возвращает все предметы категории
func get_items_by_category(category: InventoryEnums.ItemCategory) -> Array[GameItemData]:
	var result: Array[GameItemData] = []
	for item in items:
		if item and item.category == category:
			result.append(item)
	return result


## Возвращает все предметы редкости
func get_items_by_rarity(rarity: InventoryEnums.ItemRarity) -> Array[GameItemData]:
	var result: Array[GameItemData] = []
	for item in items:
		if item and item.rarity == rarity:
			result.append(item)
	return result


## Возвращает все предметы для слота
func get_items_for_slot(slot: InventoryEnums.EquipSlot) -> Array[GameItemData]:
	var result: Array[GameItemData] = []
	for item in items:
		if item and item.equip_slot == slot:
			result.append(item)
	return result


## Возвращает все артефакты
func get_all_artifacts() -> Array[GameItemData]:
	return get_items_by_category(InventoryEnums.ItemCategory.ARTIFACT)


## Возвращает все расходники
func get_all_consumables() -> Array[GameItemData]:
	return get_items_by_category(InventoryEnums.ItemCategory.CONSUMABLE)


## Возвращает всю экипировку
func get_all_equipment() -> Array[GameItemData]:
	return get_items_by_category(InventoryEnums.ItemCategory.EQUIPMENT)


## Поиск предметов по названию
func search_items(query: String) -> Array[GameItemData]:
	if query.is_empty():
		return items.duplicate()
	
	var result: Array[GameItemData] = []
	var query_lower = query.to_lower()
	
	for item in items:
		if item == null:
			continue
		
		# Поиск в названии
		if item.display_name.to_lower().contains(query_lower):
			result.append(item)
			continue
		
		# Поиск во внутреннем имени
		if item.internal_name.to_lower().contains(query_lower):
			result.append(item)
			continue
		
		# Поиск в описании
		if item.description.to_lower().contains(query_lower):
			result.append(item)
	
	return result


## Фильтрует предметы по нескольким критериям
func filter_items(
	category: int = -1,  # -1 = все категории
	rarity: int = -1,    # -1 = все редкости
	equip_slot: int = -1, # -1 = все слоты
	search_query: String = ""
) -> Array[GameItemData]:
	var result: Array[GameItemData] = []
	var query_lower = search_query.to_lower()
	
	for item in items:
		if item == null:
			continue
		
		# Фильтр категории
		if category >= 0 and item.category != category:
			continue
		
		# Фильтр редкости
		if rarity >= 0 and item.rarity != rarity:
			continue
		
		# Фильтр слота
		if equip_slot >= 0 and item.equip_slot != equip_slot:
			continue
		
		# Поиск по тексту
		if not query_lower.is_empty():
			var matches = item.display_name.to_lower().contains(query_lower)
			matches = matches or item.internal_name.to_lower().contains(query_lower)
			if not matches:
				continue
		
		result.append(item)
	
	return result

# ===========================================
# УПРАВЛЕНИЕ БАЗОЙ
# ===========================================

## Добавляет предмет в базу
func add_item(item: GameItemData) -> void:
	if item == null:
		return
	
	# Назначаем ID если нет
	if item.id < 0:
		item.id = get_next_available_id()
	
	items.append(item)
	emit_changed()
	item_added.emit(item)
	database_changed.emit()


## Удаляет предмет из базы
func remove_item(item: GameItemData) -> bool:
	var index = items.find(item)
	if index >= 0:
		items.remove_at(index)
		emit_changed()
		item_removed.emit(item)
		database_changed.emit()
		return true
	return false


## Удаляет предмет по ID
func remove_item_by_id(id: int) -> bool:
	var item = get_item_by_id(id)
	if item:
		return remove_item(item)
	return false


## Возвращает следующий свободный ID
func get_next_available_id() -> int:
	var max_id = -1
	for item in items:
		if item and item.id > max_id:
			max_id = item.id
	return max_id + 1


## Проверяет наличие дублирующихся ID
func has_duplicate_ids() -> bool:
	var seen_ids: Array[int] = []
	for item in items:
		if item == null:
			continue
		if item.id in seen_ids:
			return true
		seen_ids.append(item.id)
	return false


## Возвращает список дублирующихся ID
func get_duplicate_ids() -> Array[int]:
	var id_count: Dictionary = {}
	var duplicates: Array[int] = []
	
	for item in items:
		if item == null:
			continue
		if id_count.has(item.id):
			id_count[item.id] += 1
			if item.id not in duplicates:
				duplicates.append(item.id)
		else:
			id_count[item.id] = 1
	
	return duplicates


## Сортирует предметы по ID
func sort_by_id() -> void:
	items.sort_custom(func(a, b): return a.id < b.id if a and b else false)
	emit_changed()
	database_changed.emit()


## Сортирует предметы по названию
func sort_by_name() -> void:
	items.sort_custom(func(a, b): return a.display_name < b.display_name if a and b else false)
	emit_changed()
	database_changed.emit()


## Сортирует предметы по редкости
func sort_by_rarity() -> void:
	items.sort_custom(func(a, b): return a.rarity > b.rarity if a and b else false)
	emit_changed()
	database_changed.emit()

# ===========================================
# ВАЛИДАЦИЯ
# ===========================================

## Возвращает список ошибок валидации
func validate() -> Array[String]:
	var errors: Array[String] = []
	
	# Проверка дубликатов ID
	var duplicate_ids = get_duplicate_ids()
	for dup_id in duplicate_ids:
		errors.append("Дублирующийся ID: %d" % dup_id)
	
	# Проверка каждого предмета
	for item in items:
		if item == null:
			errors.append("Найден null предмет в базе")
			continue
		
		if not item.is_valid():
			errors.append("Невалидный предмет ID %d: %s" % [item.id, item.display_name])
		
		if item.id < 0:
			errors.append("Отрицательный ID: %s" % item.display_name)
		
		if item.display_name.is_empty():
			errors.append("Пустое название для ID %d" % item.id)
	
	return errors

# ===========================================
# СТАТИСТИКА
# ===========================================

## Возвращает общее количество предметов
func get_total_count() -> int:
	return items.size()


## Возвращает количество предметов по категориям
func get_category_counts() -> Dictionary:
	var counts: Dictionary = {}
	
	for cat in InventoryEnums.ItemCategory.values():
		counts[cat] = 0
	
	for item in items:
		if item:
			counts[item.category] = counts.get(item.category, 0) + 1
	
	return counts


## Возвращает количество предметов по редкостям
func get_rarity_counts() -> Dictionary:
	var counts: Dictionary = {}
	
	for rar in InventoryEnums.ItemRarity.values():
		counts[rar] = 0
	
	for item in items:
		if item:
			counts[item.rarity] = counts.get(item.rarity, 0) + 1
	
	return counts
