class_name InventoryItem
extends RefCounted
## Экземпляр предмета в инвентаре.
## Содержит ссылку на данные предмета + количество + уникальный ID экземпляра.
##
## Путь: res://scripts/inventory/core/inventory_item.gd

# ===========================================
# СИГНАЛЫ
# ===========================================

signal quantity_changed(new_quantity: int)
signal depleted()
signal bound()

# ===========================================
# ДАННЫЕ
# ===========================================

var instance_id: int = -1
var data: GameItemData = null
var quantity: int = 1:
	set(value):
		var old_value = quantity
		quantity = maxi(0, value)
		
		if quantity != old_value:
			quantity_changed.emit(quantity)
		
		if quantity == 0:
			depleted.emit()

var is_bound: bool = false
var bound_to_character: String = ""
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
	
	if data and data.binds_on_pickup:
		bind()


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

func add(amount: int) -> int:
	if data == null:
		return amount
	
	if not data.stackable:
		return amount
	
	var space_available = data.max_stack - quantity
	var to_add = mini(amount, space_available)
	var overflow = amount - to_add
	
	quantity += to_add
	
	return overflow


func remove(amount: int) -> int:
	var to_remove = mini(amount, quantity)
	quantity -= to_remove
	return to_remove


func can_add(amount: int) -> bool:
	if data == null:
		return false
	
	if not data.stackable:
		return false
	
	return quantity + amount <= data.max_stack


func is_full() -> bool:
	if data == null:
		return true
	
	return quantity >= data.max_stack


func get_free_space() -> int:
	if data == null or not data.stackable:
		return 0
	
	return data.max_stack - quantity


func is_empty() -> bool:
	return quantity <= 0

# ===========================================
# МЕТОДЫ ПРИВЯЗКИ
# ===========================================

func bind(character_id: String = "") -> void:
	if is_bound:
		return
	
	is_bound = true
	bound_to_character = character_id
	bound.emit()


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

func get_item_id() -> int:
	return data.id if data else -1


func get_display_name() -> String:
	return data.display_name if data else "???"


func get_icon() -> Texture2D:
	return data.icon if data else null


func get_rarity() -> InventoryEnums.ItemRarity:
	return data.rarity if data else InventoryEnums.ItemRarity.COMMON


func get_rarity_color() -> Color:
	return data.get_rarity_color() if data else Color.WHITE


func get_category() -> InventoryEnums.ItemCategory:
	return data.category if data else InventoryEnums.ItemCategory.MISC


func is_equippable() -> bool:
	return data.is_equippable() if data else false


func is_usable() -> bool:
	return data.is_usable() if data else false


func is_artifact() -> bool:
	return data.is_artifact() if data else false


func is_stackable() -> bool:
	return data.stackable if data else false


func get_valid_equip_slots() -> Array[InventoryEnums.EquipSlot]:
	return data.get_valid_equip_slots() if data else []


# ===========================================
# ПРОВЕРКА СЛОТА ЭКИПИРОВКИ - ИСПРАВЛЕНО
# ===========================================

func can_equip_in_slot(slot: InventoryEnums.EquipSlot) -> bool:
	"""Проверяет, можно ли экипировать предмет в указанный слот"""
	if data == null:
		return false
	
	# Проверяем через данные предмета
	if data.has_method("can_equip_in_slot"):
		return data.can_equip_in_slot(slot)
	
	# Fallback: проверяем через список допустимых слотов
	var valid_slots = get_valid_equip_slots()
	return slot in valid_slots


func generate_tooltip() -> String:
	if data == null:
		return "[color=red]Ошибка: нет данных предмета[/color]"
	
	var tooltip = data.generate_tooltip()
	
	if data.stackable and quantity > 1:
		tooltip = "[color=white]Количество: %d/%d[/color]\n\n%s" % [quantity, data.max_stack, tooltip]
	
	if is_bound:
		tooltip += "\n\n[color=red]Привязан[/color]"
	
	return tooltip

# ===========================================
# СОХРАНЕНИЕ / ЗАГРУЗКА
# ===========================================

func serialize() -> Dictionary:
	return {
		"instance_id": instance_id,
		"item_id": get_item_id(),
		"quantity": quantity,
		"is_bound": is_bound,
		"bound_to_character": bound_to_character,
		"instance_data": instance_data.duplicate(true),
	}


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
	
	if item.instance_id >= _next_instance_id:
		_next_instance_id = item.instance_id + 1
	
	return item

# ===========================================
# УТИЛИТЫ
# ===========================================

func is_same_type(other: InventoryItem) -> bool:
	if other == null or data == null or other.data == null:
		return false
	
	return data.id == other.data.id


func merge_with(other: InventoryItem) -> int:
	if not is_same_type(other):
		return other.quantity if other else 0
	
	if not data.stackable:
		return other.quantity
	
	var overflow = add(other.quantity)
	other.quantity = overflow
	
	return overflow


func split(amount: int) -> InventoryItem:
	if amount <= 0 or amount >= quantity:
		return null
	
	var new_item = InventoryItem.new(data, amount)
	new_item.is_bound = is_bound
	new_item.bound_to_character = bound_to_character
	new_item.instance_data = instance_data.duplicate(true)
	
	quantity -= amount
	
	return new_item


func _to_string() -> String:
	var name = get_display_name()
	if is_stackable() and quantity > 1:
		return "%s x%d" % [name, quantity]
	return name
