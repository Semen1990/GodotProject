class_name InventoryItem
extends RefCounted
## Экземпляр предмета в инвентаре.
## Содержит ссылку на данные предмета + количество + уникальный ID экземпляра.
##
## Путь: res://scripts/inventory/core/inventory_item.gd
##
## Использование:
## var item = InventoryItem.new(item_data, 5)  # 5 штук
## item.add(3)  # Теперь 8 штук
## item.remove(2)  # Теперь 6 штук

# ===========================================
# СИГНАЛЫ
# ===========================================

## Количество изменилось
signal quantity_changed(new_quantity: int)

## Предмет закончился (quantity = 0)
signal depleted()

## Предмет был привязан к персонажу
signal bound()

# ===========================================
# ДАННЫЕ
# ===========================================

## Уникальный ID этого экземпляра (для сохранения)
var instance_id: int = -1

## Ссылка на данные предмета
var data: GameItemData = null

## Текущее количество
var quantity: int = 1:
	set(value):
		var old_value = quantity
		quantity = maxi(0, value)
		
		if quantity != old_value:
			quantity_changed.emit(quantity)
		
		if quantity == 0:
			depleted.emit()

## Привязан ли предмет к персонажу
var is_bound: bool = false

## ID персонажа, к которому привязан (если привязан)
var bound_to_character: String = ""

## Дополнительные данные экземпляра (например, зачарования)
var instance_data: Dictionary = {}

# ===========================================
# СТАТИЧЕСКИЙ СЧЁТЧИК ID
# ===========================================

static var _next_instance_id: int = 1

static func _get_next_id() -> int:
	var id = _next_instance_id
	_next_instance_id += 1
	return id

# ===========================================
# КОНСТРУКТОР
# ===========================================

func _init(item_data: GameItemData = null, initial_quantity: int = 1):
	instance_id = _get_next_id()
	data = item_data
	quantity = initial_quantity
	
	# Автопривязка при создании если нужно
	if data and data.binds_on_pickup:
		bind()


## Создаёт экземпляр из ID предмета (требует базу данных)
static func create_from_id(item_id: int, qty: int = 1, database: Resource = null) -> InventoryItem:
	if database == null:
		push_error("InventoryItem.create_from_id: database is null")
		return null
	
	var item_data = database.get_item_by_id(item_id)
	if item_data == null:
		push_error("InventoryItem.create_from_id: item %d not found" % item_id)
		return null
	
	return InventoryItem.new(item_data, qty)

# ===========================================
# МЕТОДЫ КОЛИЧЕСТВА
# ===========================================

## Добавляет количество, возвращает сколько НЕ поместилось
func add(amount: int) -> int:
	if data == null:
		return amount
	
	if not data.stackable:
		# Нестакаемый предмет - нельзя добавить
		return amount
	
	var space_available = data.max_stack - quantity
	var to_add = mini(amount, space_available)
	var overflow = amount - to_add
	
	quantity += to_add
	
	return overflow


## Удаляет количество, возвращает сколько реально удалено
func remove(amount: int) -> int:
	var to_remove = mini(amount, quantity)
	quantity -= to_remove
	return to_remove


## Проверяет, можно ли добавить указанное количество
func can_add(amount: int) -> bool:
	if data == null:
		return false
	
	if not data.stackable:
		return false
	
	return quantity + amount <= data.max_stack


## Проверяет, полный ли стак
func is_full() -> bool:
	if data == null:
		return true
	
	return quantity >= data.max_stack


## Возвращает свободное место в стаке
func get_free_space() -> int:
	if data == null or not data.stackable:
		return 0
	
	return data.max_stack - quantity


## Проверяет, пустой ли предмет
func is_empty() -> bool:
	return quantity <= 0

# ===========================================
# МЕТОДЫ ПРИВЯЗКИ
# ===========================================

## Привязывает предмет к персонажу
func bind(character_id: String = "") -> void:
	if is_bound:
		return
	
	is_bound = true
	bound_to_character = character_id
	bound.emit()


## Проверяет, можно ли передать предмет
func can_trade() -> bool:
	if data == null:
		return false
	
	if is_bound:
		return false
	
	if data.is_quest_item:
		return false
	
	return true

# ===========================================
# ДЕЛЕГИРОВАНИЕ К DATA
# ===========================================

## Возвращает ID предмета (из data)
func get_item_id() -> int:
	return data.id if data else -1


## Возвращает название предмета
func get_display_name() -> String:
	return data.display_name if data else "???"


## Возвращает иконку
func get_icon() -> Texture2D:
	return data.icon if data else null


## Возвращает редкость
func get_rarity() -> InventoryEnums.ItemRarity:
	return data.rarity if data else InventoryEnums.ItemRarity.COMMON


## Возвращает цвет редкости
func get_rarity_color() -> Color:
	return data.get_rarity_color() if data else Color.WHITE


## Возвращает категорию
func get_category() -> InventoryEnums.ItemCategory:
	return data.category if data else InventoryEnums.ItemCategory.MISC


## Можно ли экипировать
func is_equippable() -> bool:
	return data.is_equippable() if data else false


## Можно ли использовать
func is_usable() -> bool:
	return data.is_usable() if data else false


## Это артефакт
func is_artifact() -> bool:
	return data.is_artifact() if data else false


## Можно ли стакать
func is_stackable() -> bool:
	return data.stackable if data else false


## Возвращает допустимые слоты
func get_valid_equip_slots() -> Array[InventoryEnums.EquipSlot]:
	return data.get_valid_equip_slots() if data else []


## Генерирует подсказку
func generate_tooltip() -> String:
	if data == null:
		return "[color=red]Ошибка: нет данных предмета[/color]"
	
	var tooltip = data.generate_tooltip()
	
	# Добавляем информацию о количестве
	if data.stackable and quantity > 1:
		tooltip = "[color=white]Количество: %d/%d[/color]\n\n%s" % [quantity, data.max_stack, tooltip]
	
	# Добавляем информацию о привязке
	if is_bound:
		tooltip += "\n\n[color=red]Привязан[/color]"
	
	return tooltip

# ===========================================
# СОХРАНЕНИЕ / ЗАГРУЗКА
# ===========================================

## Сериализует предмет в словарь
func serialize() -> Dictionary:
	return {
		"instance_id": instance_id,
		"item_id": get_item_id(),
		"quantity": quantity,
		"is_bound": is_bound,
		"bound_to_character": bound_to_character,
		"instance_data": instance_data.duplicate(true),
	}


## Десериализует предмет из словаря (требует базу данных)
static func deserialize(dict: Dictionary, database: Resource) -> InventoryItem:
	var item_id = dict.get("item_id", -1)
	var qty = dict.get("quantity", 1)
	
	var item = create_from_id(item_id, qty, database)
	if item == null:
		return null
	
	item.instance_id = dict.get("instance_id", _get_next_id())
	item.is_bound = dict.get("is_bound", false)
	item.bound_to_character = dict.get("bound_to_character", "")
	item.instance_data = dict.get("instance_data", {}).duplicate(true)
	
	# Обновляем статический счётчик
	if item.instance_id >= _next_instance_id:
		_next_instance_id = item.instance_id + 1
	
	return item

# ===========================================
# УТИЛИТЫ
# ===========================================

## Проверяет, тот же ли это тип предмета (для объединения стаков)
func is_same_type(other: InventoryItem) -> bool:
	if other == null or data == null or other.data == null:
		return false
	
	return data.id == other.data.id


## Пытается объединить с другим стаком, возвращает остаток
func merge_with(other: InventoryItem) -> int:
	if not is_same_type(other):
		return other.quantity if other else 0
	
	if not data.stackable:
		return other.quantity
	
	var overflow = add(other.quantity)
	other.quantity = overflow
	
	return overflow


## Разделяет стак на два
func split(amount: int) -> InventoryItem:
	if amount <= 0 or amount >= quantity:
		return null
	
	var new_item = InventoryItem.new(data, amount)
	new_item.is_bound = is_bound
	new_item.bound_to_character = bound_to_character
	new_item.instance_data = instance_data.duplicate(true)
	
	quantity -= amount
	
	return new_item


## Строковое представление
func _to_string() -> String:
	var name = get_display_name()
	if is_stackable() and quantity > 1:
		return "%s x%d" % [name, quantity]
	return name
