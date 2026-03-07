extends Node
class_name InventoryManager
## Ð“Ð»Ð°Ð²Ð½Ñ‹Ð¹ Ð¼ÐµÐ½ÐµÐ´Ð¶ÐµÑ€ Ð¸Ð½Ð²ÐµÐ½Ñ‚Ð°Ñ€Ñ.
## Ð£Ð¿Ñ€Ð°Ð²Ð»ÑÐµÑ‚ ÑÑƒÐ¼ÐºÐ¾Ð¹, ÑÐºÐ¸Ð¿Ð¸Ñ€Ð¾Ð²ÐºÐ¾Ð¹ Ð¸ Ð±Ñ‹ÑÑ‚Ñ€Ñ‹Ð¼Ð¸ ÑÐ»Ð¾Ñ‚Ð°Ð¼Ð¸.
##
## ÐŸÑƒÑ‚ÑŒ: res://scripts/inventory/core/inventory_manager.gd
##
## Ð”Ð¾Ð±Ð°Ð²ÑŒÑ‚Ðµ ÐºÐ°Ðº Autoload: Project Settings â†’ Autoload â†’ inventory_manager.gd
## Ð˜Ð¼Ñ: Inventory

# ===========================================
# Ð¡Ð˜Ð“ÐÐÐ›Ð«
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
# ÐšÐžÐÐ¡Ð¢ÐÐÐ¢Ð«
# ===========================================

const BASE_INVENTORY_SLOTS: int = 20
const MAX_INVENTORY_SLOTS: int = 60
const HOTBAR_SLOTS: int = 4

# ===========================================
# Ð”ÐÐÐÐ«Ð•
# ===========================================

var item_database: GameItemDatabase = null
var inventory_slots: Array[InventoryItem] = []
var current_slot_count: int = BASE_INVENTORY_SLOTS
var equipment_slots: Dictionary = {}
var hotbar_slots: Array[InventoryItem] = []
var character_class: InventoryEnums.CharacterClass = InventoryEnums.CharacterClass.WARRIOR
var character_level: int = 1
var bonus_slots: int = 0

# === Ð¡Ð˜Ð¡Ð¢Ð•ÐœÐ Ð˜Ð¡ÐŸÐžÐ›Ð¬Ð—ÐžÐ’ÐÐÐÐ«Ð¥ Ð—Ð•Ð›Ð˜Ð™ ===
# Ð¥Ñ€Ð°Ð½Ð¸Ñ‚ ID Ð·ÐµÐ»Ð¸Ð¹, Ð¸ÑÐ¿Ð¾Ð»ÑŒÐ·Ð¾Ð²Ð°Ð½Ð½Ñ‹Ñ… Ð² Ñ‚ÐµÐºÑƒÑ‰ÐµÐ¹ ÐºÐ¾Ð¼Ð½Ð°Ñ‚Ðµ
var used_potions_this_room: Array[int] = []

# === ÐÐšÐ¢Ð˜Ð’ÐÐ«Ð• Ð‘ÐÐ¤Ð¤Ð« ÐžÐ¢ Ð—Ð•Ð›Ð˜Ð™ ===
# ÐšÐ»ÑŽÑ‡ = ID Ð¿Ñ€ÐµÐ´Ð¼ÐµÑ‚Ð°, Ð—Ð½Ð°Ñ‡ÐµÐ½Ð¸Ðµ = ÑÐ»Ð¾Ð²Ð°Ñ€ÑŒ Ñ Ð´Ð°Ð½Ð½Ñ‹Ð¼Ð¸ Ð±Ð°Ñ„Ñ„Ð°
var active_potion_buffs: Dictionary = {}

# === Ð¤Ð›ÐÐ“ Ð˜ÐÐ˜Ð¦Ð˜ÐÐ›Ð˜Ð—ÐÐ¦Ð˜Ð˜ ===
var is_initialized: bool = false

# ===========================================
# Ð˜ÐÐ˜Ð¦Ð˜ÐÐ›Ð˜Ð—ÐÐ¦Ð˜Ð¯
# ===========================================

func _ready():
	_initialize_slots()
	print("ðŸŽ’ InventoryManager Ð¸Ð½Ð¸Ñ†Ð¸Ð°Ð»Ð¸Ð·Ð¸Ñ€Ð¾Ð²Ð°Ð½")
	print("   Ð¡Ð»Ð¾Ñ‚Ð¾Ð² Ð¸Ð½Ð²ÐµÐ½Ñ‚Ð°Ñ€Ñ: %d" % current_slot_count)
	print("   Ð¡Ð»Ð¾Ñ‚Ð¾Ð² ÑÐºÐ¸Ð¿Ð¸Ñ€Ð¾Ð²ÐºÐ¸: %d" % equipment_slots.size())
	print("   Ð‘Ñ‹ÑÑ‚Ñ€Ñ‹Ñ… ÑÐ»Ð¾Ñ‚Ð¾Ð²: %d" % HOTBAR_SLOTS)


func _initialize_slots():
	"""Ð˜Ð½Ð¸Ñ†Ð¸Ð°Ð»Ð¸Ð·Ð¸Ñ€ÑƒÐµÑ‚ Ð²ÑÐµ ÑÐ»Ð¾Ñ‚Ñ‹"""
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
# ÐžÐ§Ð˜Ð¡Ð¢ÐšÐ Ð˜ÐÐ’Ð•ÐÐ¢ÐÐ Ð¯ (Ð´Ð»Ñ Ð½Ð¾Ð²Ð¾Ð³Ð¾ Ð·Ð°Ð±ÐµÐ³Ð°)
# ===========================================

func clear_all():
	"""ÐŸÐ¾Ð»Ð½Ð¾ÑÑ‚ÑŒÑŽ Ð¾Ñ‡Ð¸Ñ‰Ð°ÐµÑ‚ Ð¸Ð½Ð²ÐµÐ½Ñ‚Ð°Ñ€ÑŒ Ð´Ð»Ñ Ð½Ð¾Ð²Ð¾Ð³Ð¾ Ð·Ð°Ð±ÐµÐ³Ð°"""
	print("ðŸ—‘ï¸ ÐžÑ‡Ð¸ÑÑ‚ÐºÐ° Ð¸Ð½Ð²ÐµÐ½Ñ‚Ð°Ñ€Ñ...")
	
	_initialize_slots()
	bonus_slots = 0
	current_slot_count = BASE_INVENTORY_SLOTS
	
	# ÐžÑ‡Ð¸Ñ‰Ð°ÐµÐ¼ Ð¸ÑÐ¿Ð¾Ð»ÑŒÐ·Ð¾Ð²Ð°Ð½Ð½Ñ‹Ðµ Ð·ÐµÐ»ÑŒÑ
	used_potions_this_room.clear()
	active_potion_buffs.clear()
	
	# Ð¡Ð±Ñ€Ð°ÑÑ‹Ð²Ð°ÐµÐ¼ Ñ„Ð»Ð°Ð³ Ð¸Ð½Ð¸Ñ†Ð¸Ð°Ð»Ð¸Ð·Ð°Ñ†Ð¸Ð¸
	is_initialized = false
	
	inventory_changed.emit()
	equipment_changed.emit()
	
	print("âœ… Ð˜Ð½Ð²ÐµÐ½Ñ‚Ð°Ñ€ÑŒ Ð¾Ñ‡Ð¸Ñ‰ÐµÐ½")


func reset_for_new_room():
	"""Ð¡Ð±Ñ€Ð°ÑÑ‹Ð²Ð°ÐµÑ‚ ÑÐ¾ÑÑ‚Ð¾ÑÐ½Ð¸Ðµ Ð´Ð»Ñ Ð½Ð¾Ð²Ð¾Ð¹ ÐºÐ¾Ð¼Ð½Ð°Ñ‚Ñ‹"""
	print("ðŸšª ÐÐ¾Ð²Ð°Ñ ÐºÐ¾Ð¼Ð½Ð°Ñ‚Ð° - ÑÐ±Ñ€Ð¾Ñ Ð·ÐµÐ»Ð¸Ð¹")
	
	# Ð¡Ð±Ñ€Ð°ÑÑ‹Ð²Ð°ÐµÐ¼ Ð¸ÑÐ¿Ð¾Ð»ÑŒÐ·Ð¾Ð²Ð°Ð½Ð½Ñ‹Ðµ Ð·ÐµÐ»ÑŒÑ
	used_potions_this_room.clear()
	
	# Ð£Ð±Ð¸Ñ€Ð°ÐµÐ¼ Ð²ÑÐµ Ð°ÐºÑ‚Ð¸Ð²Ð½Ñ‹Ðµ Ð±Ð°Ñ„Ñ„Ñ‹ Ð¾Ñ‚ Ð·ÐµÐ»Ð¸Ð¹
	active_potion_buffs.clear()
	
	print("âœ… Ð—ÐµÐ»ÑŒÑ Ð¼Ð¾Ð¶Ð½Ð¾ Ð¸ÑÐ¿Ð¾Ð»ÑŒÐ·Ð¾Ð²Ð°Ñ‚ÑŒ ÑÐ½Ð¾Ð²Ð°")


func reset_on_death():
	"""Ð¡Ð±Ñ€Ð°ÑÑ‹Ð²Ð°ÐµÑ‚ Ð±Ð°Ñ„Ñ„Ñ‹ Ð¿Ñ€Ð¸ ÑÐ¼ÐµÑ€Ñ‚Ð¸"""
	print("ðŸ’€ Ð¡Ð¼ÐµÑ€Ñ‚ÑŒ - ÑÐ±Ñ€Ð¾Ñ Ð±Ð°Ñ„Ñ„Ð¾Ð² Ð¾Ñ‚ Ð·ÐµÐ»Ð¸Ð¹")
	
	# ÐžÑ‡Ð¸Ñ‰Ð°ÐµÐ¼ Ð¸ÑÐ¿Ð¾Ð»ÑŒÐ·Ð¾Ð²Ð°Ð½Ð½Ñ‹Ðµ Ð·ÐµÐ»ÑŒÑ (Ð¼Ð¾Ð¶Ð½Ð¾ Ð¸ÑÐ¿Ð¾Ð»ÑŒÐ·Ð¾Ð²Ð°Ñ‚ÑŒ Ð¿Ð¾ÑÐ»Ðµ Ð²Ð¾Ð·Ñ€Ð¾Ð¶Ð´ÐµÐ½Ð¸Ñ)
	used_potions_this_room.clear()
	
	# ÐžÑ‡Ð¸Ñ‰Ð°ÐµÐ¼ Ð°ÐºÑ‚Ð¸Ð²Ð½Ñ‹Ðµ Ð±Ð°Ñ„Ñ„Ñ‹
	active_potion_buffs.clear()
	
	print("âœ… Ð‘Ð°Ñ„Ñ„Ñ‹ Ð¾Ñ‚ Ð·ÐµÐ»Ð¸Ð¹ ÑÐ±Ñ€Ð¾ÑˆÐµÐ½Ñ‹")


# ===========================================
# ÐÐÐ¡Ð¢Ð ÐžÐ™ÐšÐ
# ===========================================

func set_database(database: GameItemDatabase):
	item_database = database
	print("ðŸŽ’ Ð‘Ð°Ð·Ð° Ð´Ð°Ð½Ð½Ñ‹Ñ… ÑƒÑÑ‚Ð°Ð½Ð¾Ð²Ð»ÐµÐ½Ð°: %d Ð¿Ñ€ÐµÐ´Ð¼ÐµÑ‚Ð¾Ð²" % database.items.size())


func set_character_class(char_class: InventoryEnums.CharacterClass):
	character_class = char_class
	
	# ÐŸÑ€Ð¸Ð¼ÐµÐ½ÑÐµÐ¼ ÐºÐ»Ð°ÑÑÐ¾Ð²Ñ‹Ðµ Ð±Ð¾Ð½ÑƒÑÑ‹ Ñ‚Ð¾Ð»ÑŒÐºÐ¾ ÐµÑÐ»Ð¸ ÐµÑ‰Ñ‘ Ð½Ðµ Ð¿Ñ€Ð¸Ð¼ÐµÐ½ÑÐ»Ð¸
	if not is_initialized:
		match char_class:
			InventoryEnums.CharacterClass.WARRIOR:
				add_bonus_slots(4)
		is_initialized = true


# ===========================================
# Ð£ÐŸÐ ÐÐ’Ð›Ð•ÐÐ˜Ð• Ð¡Ð›ÐžÐ¢ÐÐœÐ˜
# ===========================================

func add_bonus_slots(amount: int):
	bonus_slots += amount
	current_slot_count = mini(BASE_INVENTORY_SLOTS + bonus_slots, MAX_INVENTORY_SLOTS)
	print("ðŸŽ’ Ð‘Ð¾Ð½ÑƒÑÐ½Ñ‹Ðµ ÑÐ»Ð¾Ñ‚Ñ‹: +%d (Ð²ÑÐµÐ³Ð¾ %d)" % [amount, current_slot_count])
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
# Ð¡Ð˜Ð¡Ð¢Ð•ÐœÐ Ð—Ð•Ð›Ð˜Ð™ (1 Ð ÐÐ— Ð—Ð ÐšÐžÐœÐÐÐ¢Ð£)
# ===========================================

func can_use_potion(item_id: int) -> bool:
	"""ÐŸÑ€Ð¾Ð²ÐµÑ€ÑÐµÑ‚, Ð¼Ð¾Ð¶Ð½Ð¾ Ð»Ð¸ Ð¸ÑÐ¿Ð¾Ð»ÑŒÐ·Ð¾Ð²Ð°Ñ‚ÑŒ Ð·ÐµÐ»ÑŒÐµ"""
	return not item_id in used_potions_this_room


func mark_potion_used(item_id: int):
	"""ÐŸÐ¾Ð¼ÐµÑ‡Ð°ÐµÑ‚ Ð·ÐµÐ»ÑŒÐµ ÐºÐ°Ðº Ð¸ÑÐ¿Ð¾Ð»ÑŒÐ·Ð¾Ð²Ð°Ð½Ð½Ð¾Ðµ Ð² ÑÑ‚Ð¾Ð¹ ÐºÐ¾Ð¼Ð½Ð°Ñ‚Ðµ"""
	if not item_id in used_potions_this_room:
		used_potions_this_room.append(item_id)
		print("ðŸ§ª Ð—ÐµÐ»ÑŒÐµ ID %d Ð¿Ð¾Ð¼ÐµÑ‡ÐµÐ½Ð¾ ÐºÐ°Ðº Ð¸ÑÐ¿Ð¾Ð»ÑŒÐ·Ð¾Ð²Ð°Ð½Ð½Ð¾Ðµ" % item_id)


func is_potion_used(item_id: int) -> bool:
	"""ÐŸÑ€Ð¾Ð²ÐµÑ€ÑÐµÑ‚, Ð¸ÑÐ¿Ð¾Ð»ÑŒÐ·Ð¾Ð²Ð°Ð½Ð¾ Ð»Ð¸ Ð·ÐµÐ»ÑŒÐµ Ð² ÑÑ‚Ð¾Ð¹ ÐºÐ¾Ð¼Ð½Ð°Ñ‚Ðµ"""
	return item_id in used_potions_this_room


func add_active_buff(item_id: int, buff_data: Dictionary):
	"""Ð”Ð¾Ð±Ð°Ð²Ð»ÑÐµÑ‚ Ð°ÐºÑ‚Ð¸Ð²Ð½Ñ‹Ð¹ Ð±Ð°Ñ„Ñ„ Ð¾Ñ‚ Ð·ÐµÐ»ÑŒÑ"""
	active_potion_buffs[item_id] = buff_data
	print("âœ¨ Ð”Ð¾Ð±Ð°Ð²Ð»ÐµÐ½ Ð±Ð°Ñ„Ñ„ Ð¾Ñ‚ Ð·ÐµÐ»ÑŒÑ ID %d: %s" % [item_id, buff_data])


func remove_active_buff(item_id: int):
	"""Ð£Ð´Ð°Ð»ÑÐµÑ‚ Ð°ÐºÑ‚Ð¸Ð²Ð½Ñ‹Ð¹ Ð±Ð°Ñ„Ñ„"""
	if item_id in active_potion_buffs:
		active_potion_buffs.erase(item_id)


func get_active_buffs() -> Dictionary:
	"""Ð’Ð¾Ð·Ð²Ñ€Ð°Ñ‰Ð°ÐµÑ‚ Ð²ÑÐµ Ð°ÐºÑ‚Ð¸Ð²Ð½Ñ‹Ðµ Ð±Ð°Ñ„Ñ„Ñ‹"""
	return active_potion_buffs.duplicate()


func get_total_buff_value(stat_name: String) -> int:
	"""Ð’Ð¾Ð·Ð²Ñ€Ð°Ñ‰Ð°ÐµÑ‚ ÑÑƒÐ¼Ð¼Ð°Ñ€Ð½Ð¾Ðµ Ð·Ð½Ð°Ñ‡ÐµÐ½Ð¸Ðµ Ð±Ð°Ñ„Ñ„Ð° Ð¿Ð¾ Ð¸Ð¼ÐµÐ½Ð¸ ÑÑ‚Ð°Ñ‚Ð°"""
	var total = 0
	for item_id in active_potion_buffs:
		var buff = active_potion_buffs[item_id]
		if buff.has(stat_name):
			total += buff[stat_name]
	return total


# ===========================================
# Ð”ÐžÐ‘ÐÐ’Ð›Ð•ÐÐ˜Ð• ÐŸÐ Ð•Ð”ÐœÐ•Ð¢ÐžÐ’
# ===========================================

func add_item(item: InventoryItem) -> int:
	if item == null or item.is_empty():
		return 0
	
	var remaining = item.quantity
	
	# Ð¡Ð½Ð°Ñ‡Ð°Ð»Ð° Ð¿Ñ‹Ñ‚Ð°ÐµÐ¼ÑÑ Ð´Ð¾Ð±Ð°Ð²Ð¸Ñ‚ÑŒ Ð² ÑÑƒÑ‰ÐµÑÑ‚Ð²ÑƒÑŽÑ‰Ð¸Ðµ ÑÑ‚Ð°ÐºÐ¸
	if item.is_stackable():
		for i in range(current_slot_count):
			if inventory_slots[i] != null and inventory_slots[i].is_same_type(item):
				if not inventory_slots[i].is_full():
					remaining = inventory_slots[i].add(remaining)
					if remaining == 0:
						item_added.emit(item, i)
						inventory_changed.emit()
						return 0
	
	# Ð—Ð°Ñ‚ÐµÐ¼ Ð¸Ñ‰ÐµÐ¼ Ð¿ÑƒÑÑ‚Ð¾Ð¹ ÑÐ»Ð¾Ñ‚
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
		push_error("InventoryManager: Ð±Ð°Ð·Ð° Ð´Ð°Ð½Ð½Ñ‹Ñ… Ð½Ðµ ÑƒÑÑ‚Ð°Ð½Ð¾Ð²Ð»ÐµÐ½Ð°")
		return quantity
	
	var item = InventoryItem.create_from_id(item_id, quantity, item_database)
	if item == null:
		return quantity
	
	return add_item(item)


func add_item_by_name(internal_name: String, quantity: int = 1) -> int:
	if item_database == null:
		push_error("InventoryManager: Ð±Ð°Ð·Ð° Ð´Ð°Ð½Ð½Ñ‹Ñ… Ð½Ðµ ÑƒÑÑ‚Ð°Ð½Ð¾Ð²Ð»ÐµÐ½Ð°")
		return quantity
	
	var item_data = item_database.get_item_by_name(internal_name)
	if item_data == null:
		push_error("InventoryManager: Ð¿Ñ€ÐµÐ´Ð¼ÐµÑ‚ '%s' Ð½Ðµ Ð½Ð°Ð¹Ð´ÐµÐ½" % internal_name)
		return quantity
	
	var item = InventoryItem.new(item_data, quantity)
	return add_item(item)


func _find_empty_slot() -> int:
	for i in range(current_slot_count):
		if inventory_slots[i] == null:
			return i
	return -1


# ===========================================
# Ð£Ð”ÐÐ›Ð•ÐÐ˜Ð• ÐŸÐ Ð•Ð”ÐœÐ•Ð¢ÐžÐ’
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
# ÐŸÐ•Ð Ð•ÐœÐ•Ð©Ð•ÐÐ˜Ð• ÐŸÐ Ð•Ð”ÐœÐ•Ð¢ÐžÐ’
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
	
	# Ð•ÑÐ»Ð¸ Ñ†ÐµÐ»ÐµÐ²Ð¾Ð¹ ÑÐ»Ð¾Ñ‚ Ð¿ÑƒÑÑ‚ - Ð¿Ñ€Ð¾ÑÑ‚Ð¾ Ð¿ÐµÑ€ÐµÐ¼ÐµÑ‰Ð°ÐµÐ¼
	if to_item == null:
		inventory_slots[to_index] = from_item
		inventory_slots[from_index] = null
		item_moved.emit(from_item, from_index, to_index)
		inventory_changed.emit()
		return true
	
	# Ð•ÑÐ»Ð¸ Ð¾Ð´Ð¸Ð½Ð°ÐºÐ¾Ð²Ñ‹Ðµ Ð¿Ñ€ÐµÐ´Ð¼ÐµÑ‚Ñ‹ - Ð¿Ñ‹Ñ‚Ð°ÐµÐ¼ÑÑ Ð¾Ð±ÑŠÐµÐ´Ð¸Ð½Ð¸Ñ‚ÑŒ ÑÑ‚Ð°ÐºÐ¸
	if from_item.is_same_type(to_item) and to_item.is_stackable():
		var overflow = to_item.add(from_item.quantity)
		if overflow == 0:
			inventory_slots[from_index] = null
		else:
			from_item.quantity = overflow
		inventory_changed.emit()
		return true
	
	# Ð˜Ð½Ð°Ñ‡Ðµ - Ð¼ÐµÐ½ÑÐµÐ¼ Ð¼ÐµÑÑ‚Ð°Ð¼Ð¸
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
# Ð­ÐšÐ˜ÐŸÐ˜Ð ÐžÐ’ÐšÐ
# ===========================================

func equip_item(inventory_index: int, slot: InventoryEnums.EquipSlot = InventoryEnums.EquipSlot.NONE) -> bool:
	if inventory_index < 0 or inventory_index >= current_slot_count:
		return false
	
	var item = inventory_slots[inventory_index]
	if item == null or item.data == null:
		return false
	
	# ÐŸÑ€Ð¾Ð²ÐµÑ€ÑÐµÐ¼, Ð¼Ð¾Ð¶Ð½Ð¾ Ð»Ð¸ ÑÐºÐ¸Ð¿Ð¸Ñ€Ð¾Ð²Ð°Ñ‚ÑŒ
	if not item.is_equippable():
		return false
	
	# ÐžÐ¿Ñ€ÐµÐ´ÐµÐ»ÑÐµÐ¼ ÑÐ»Ð¾Ñ‚
	if slot == InventoryEnums.EquipSlot.NONE:
		var valid_slots = item.get_valid_equip_slots()
		if valid_slots.is_empty():
			return false
		# === ИСПРАВЛЕНИЕ: Для предметов с несколькими слотами (артефакты, кольца, серьги) ===
		# Ищем ПЕРВЫЙ СВОБОДНЫЙ слот, а не всегда берём первый
		slot = InventoryEnums.EquipSlot.NONE
		for valid_slot in valid_slots:
			if equipment_slots.get(valid_slot) == null:
				slot = valid_slot
				break
		
		# Если все слоты заняты - заменяем в первом
		if slot == InventoryEnums.EquipSlot.NONE:
			slot = valid_slots[0]
	
	# ÐŸÑ€Ð¾Ð²ÐµÑ€ÑÐµÐ¼, Ð¿Ð¾Ð´Ñ…Ð¾Ð´Ð¸Ñ‚ Ð»Ð¸ ÑÐ»Ð¾Ñ‚
	if not item.can_equip_in_slot(slot):
		return false
	
	# Ð•ÑÐ»Ð¸ Ð² ÑÐ»Ð¾Ñ‚Ðµ ÑƒÐ¶Ðµ ÐµÑÑ‚ÑŒ Ð¿Ñ€ÐµÐ´Ð¼ÐµÑ‚ - ÑÐ½Ð¸Ð¼Ð°ÐµÐ¼ ÐµÐ³Ð¾
	var old_item = equipment_slots.get(slot)
	if old_item != null:
		# Ð˜Ñ‰ÐµÐ¼ Ð¿ÑƒÑÑ‚Ð¾Ð¹ ÑÐ»Ð¾Ñ‚ Ð² Ð¸Ð½Ð²ÐµÐ½Ñ‚Ð°Ñ€Ðµ
		var empty = _find_empty_slot()
		if empty < 0:
			return false  # ÐÐµÑ‚ Ð¼ÐµÑÑ‚Ð°
		inventory_slots[empty] = old_item
		item_unequipped.emit(old_item, slot)
	
	# Ð­ÐºÐ¸Ð¿Ð¸Ñ€ÑƒÐµÐ¼ Ð½Ð¾Ð²Ñ‹Ð¹ Ð¿Ñ€ÐµÐ´Ð¼ÐµÑ‚
	equipment_slots[slot] = item
	inventory_slots[inventory_index] = null
	
	item_equipped.emit(item, slot)
	equipment_changed.emit()
	inventory_changed.emit()
	
	# Ð’ÐÐ–ÐÐž: ÐŸÐµÑ€ÐµÑÑ‡Ð¸Ñ‚Ñ‹Ð²Ð°ÐµÐ¼ ÑÑ‚Ð°Ñ‚Ñ‹
	_recalculate_stats()
	
	return true


func unequip_item(slot: InventoryEnums.EquipSlot) -> bool:
	if not equipment_slots.has(slot):
		return false
	
	var item = equipment_slots[slot]
	if item == null:
		return false
	
	# Ð˜Ñ‰ÐµÐ¼ Ð¿ÑƒÑÑ‚Ð¾Ð¹ ÑÐ»Ð¾Ñ‚
	var empty = _find_empty_slot()
	if empty < 0:
		return false
	
	inventory_slots[empty] = item
	equipment_slots[slot] = null
	
	item_unequipped.emit(item, slot)
	equipment_changed.emit()
	inventory_changed.emit()
	
	# Ð’ÐÐ–ÐÐž: ÐŸÐµÑ€ÐµÑÑ‡Ð¸Ñ‚Ñ‹Ð²Ð°ÐµÐ¼ ÑÑ‚Ð°Ñ‚Ñ‹
	_recalculate_stats()
	
	return true


func get_equipped_item(slot: InventoryEnums.EquipSlot) -> InventoryItem:
	return equipment_slots.get(slot)


func is_slot_equipped(slot: InventoryEnums.EquipSlot) -> bool:
	return equipment_slots.get(slot) != null


# ===========================================
# Ð‘Ð«Ð¡Ð¢Ð Ð«Ð• Ð¡Ð›ÐžÐ¢Ð« (HOTBAR)
# ===========================================

func _append_hotbar_change(changed_slots: Array[int], slot_index: int) -> void:
	if slot_index >= 0 and not changed_slots.has(slot_index):
		changed_slots.append(slot_index)


func _emit_hotbar_changes(changed_slots: Array[int]) -> void:
	for slot_index in changed_slots:
		hotbar_changed.emit(slot_index)


func _can_merge_stack(target_item: InventoryItem, source_item: InventoryItem) -> bool:
	return (
		target_item != null
		and source_item != null
		and target_item != source_item
		and target_item.is_same_type(source_item)
		and target_item.is_stackable()
		and not target_item.is_full()
	)


func _merge_item_into_hotbar(source_item: InventoryItem, changed_slots: Array[int], preferred_slot: int = -1, only_preferred: bool = false) -> bool:
	if source_item == null or source_item.is_empty() or not source_item.is_stackable():
		return false

	var merged := false
	var slot_order: Array[int] = []

	if preferred_slot >= 0 and preferred_slot < HOTBAR_SLOTS:
		slot_order.append(preferred_slot)

	if not only_preferred:
		for i in range(HOTBAR_SLOTS):
			if i != preferred_slot:
				slot_order.append(i)

	for slot_index in slot_order:
		var target_item := hotbar_slots[slot_index]
		if not _can_merge_stack(target_item, source_item):
			continue

		var overflow := target_item.add(source_item.quantity)
		if overflow != source_item.quantity:
			source_item.quantity = overflow
			merged = true
			_append_hotbar_change(changed_slots, slot_index)

		if source_item.is_empty():
			break

	return merged


func _merge_item_into_inventory(source_item: InventoryItem, preferred_slot: int = -1, only_preferred: bool = false, exclude_slot: int = -1) -> bool:
	if source_item == null or source_item.is_empty() or not source_item.is_stackable():
		return false

	var merged := false
	var slot_order: Array[int] = []

	if preferred_slot >= 0 and preferred_slot < current_slot_count and preferred_slot != exclude_slot:
		slot_order.append(preferred_slot)

	if not only_preferred:
		for i in range(current_slot_count):
			if i == preferred_slot or i == exclude_slot:
				continue
			slot_order.append(i)

	for slot_index in slot_order:
		var target_item := inventory_slots[slot_index]
		if not _can_merge_stack(target_item, source_item):
			continue

		var overflow := target_item.add(source_item.quantity)
		if overflow != source_item.quantity:
			source_item.quantity = overflow
			merged = true

		if source_item.is_empty():
			break

	return merged


func find_free_hotbar_slot() -> int:
	for i in range(HOTBAR_SLOTS):
		if hotbar_slots[i] == null or hotbar_slots[i].is_empty():
			return i
	return -1


func set_hotbar_item(hotbar_index: int, inventory_index: int) -> bool:
	if hotbar_index < 0 or hotbar_index >= HOTBAR_SLOTS:
		return false

	if inventory_index < 0 or inventory_index >= current_slot_count:
		hotbar_slots[hotbar_index] = null
		hotbar_changed.emit(hotbar_index)
		return true

	return move_item_to_specific_hotbar_slot(inventory_index, hotbar_index)


func use_hotbar_item(hotbar_index: int) -> bool:
	if hotbar_index < 0 or hotbar_index >= HOTBAR_SLOTS:
		return false

	var item := hotbar_slots[hotbar_index]
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


func move_item_to_hotbar(inventory_index: int) -> int:
	if inventory_index < 0 or inventory_index >= current_slot_count:
		return -1

	var item := inventory_slots[inventory_index]
	if item == null or item.is_empty():
		return -1

	if not item.is_usable():
		return -1

	var changed_hotbar: Array[int] = []
	_merge_item_into_hotbar(item, changed_hotbar)

	if item.is_empty():
		inventory_slots[inventory_index] = null
		_emit_hotbar_changes(changed_hotbar)
		inventory_changed.emit()
		return changed_hotbar[0] if not changed_hotbar.is_empty() else -1

	var free_hotbar := find_free_hotbar_slot()
	if free_hotbar >= 0:
		hotbar_slots[free_hotbar] = item
		inventory_slots[inventory_index] = null
		_append_hotbar_change(changed_hotbar, free_hotbar)
		_emit_hotbar_changes(changed_hotbar)
		inventory_changed.emit()
		return changed_hotbar[0]

	if not changed_hotbar.is_empty():
		_emit_hotbar_changes(changed_hotbar)
		inventory_changed.emit()
		return changed_hotbar[0]

	return -1


func move_hotbar_to_inventory(hotbar_index: int) -> bool:
	if hotbar_index < 0 or hotbar_index >= HOTBAR_SLOTS:
		return false

	var item := hotbar_slots[hotbar_index]
	if item == null or item.is_empty():
		return false

	var changed := _merge_item_into_inventory(item)
	if item.is_empty():
		hotbar_slots[hotbar_index] = null
		hotbar_changed.emit(hotbar_index)
		inventory_changed.emit()
		return true

	var free_inv := _find_empty_slot()
	if free_inv >= 0:
		inventory_slots[free_inv] = item
		hotbar_slots[hotbar_index] = null
		hotbar_changed.emit(hotbar_index)
		inventory_changed.emit()
		return true

	if changed:
		hotbar_changed.emit(hotbar_index)
		inventory_changed.emit()
		return true

	return false


func is_item_in_hotbar(item: InventoryItem) -> int:
	for i in range(HOTBAR_SLOTS):
		if hotbar_slots[i] == item:
			return i
	return -1


func move_item_to_specific_hotbar_slot(inventory_index: int, hotbar_index: int) -> bool:
	if inventory_index < 0 or inventory_index >= current_slot_count:
		return false
	if hotbar_index < 0 or hotbar_index >= HOTBAR_SLOTS:
		return false

	var item := inventory_slots[inventory_index]
	if item == null or item.is_empty() or not item.is_usable():
		return false

	var target_item := hotbar_slots[hotbar_index]
	if _can_merge_stack(target_item, item):
		var overflow := target_item.add(item.quantity)
		if overflow == item.quantity:
			return false

		item.quantity = overflow
		if item.is_empty():
			inventory_slots[inventory_index] = null

		hotbar_changed.emit(hotbar_index)
		inventory_changed.emit()
		return true

	if target_item == null or target_item.is_empty():
		hotbar_slots[hotbar_index] = item
		inventory_slots[inventory_index] = null
		hotbar_changed.emit(hotbar_index)
		inventory_changed.emit()
		return true

	if target_item.is_same_type(item):
		return false

	inventory_slots[inventory_index] = target_item
	hotbar_slots[hotbar_index] = item
	hotbar_changed.emit(hotbar_index)
	inventory_changed.emit()
	return true


func move_hotbar_to_inventory_slot(hotbar_index: int, inventory_index: int) -> bool:
	if hotbar_index < 0 or hotbar_index >= HOTBAR_SLOTS:
		return false
	if inventory_index < 0 or inventory_index >= current_slot_count:
		return false

	var item := hotbar_slots[hotbar_index]
	if item == null or item.is_empty():
		return false

	var target_item := inventory_slots[inventory_index]
	if target_item == null:
		inventory_slots[inventory_index] = item
		hotbar_slots[hotbar_index] = null
		hotbar_changed.emit(hotbar_index)
		inventory_changed.emit()
		return true

	if _can_merge_stack(target_item, item):
		var overflow := target_item.add(item.quantity)
		if overflow == item.quantity:
			return false

		item.quantity = overflow
		if item.is_empty():
			hotbar_slots[hotbar_index] = null

		hotbar_changed.emit(hotbar_index)
		inventory_changed.emit()
		return true

	if not target_item.is_usable():
		return false

	inventory_slots[inventory_index] = item
	hotbar_slots[hotbar_index] = target_item
	hotbar_changed.emit(hotbar_index)
	inventory_changed.emit()
	return true


func swap_hotbar_slots(from_hotbar_index: int, to_hotbar_index: int) -> bool:
	if from_hotbar_index < 0 or from_hotbar_index >= HOTBAR_SLOTS:
		return false
	if to_hotbar_index < 0 or to_hotbar_index >= HOTBAR_SLOTS:
		return false
	if from_hotbar_index == to_hotbar_index:
		return false

	var from_item := hotbar_slots[from_hotbar_index]
	var to_item := hotbar_slots[to_hotbar_index]

	if from_item == null and to_item == null:
		return false

	if _can_merge_stack(to_item, from_item):
		var overflow := to_item.add(from_item.quantity)
		if overflow != from_item.quantity:
			from_item.quantity = overflow
			if from_item.is_empty():
				hotbar_slots[from_hotbar_index] = null
			hotbar_changed.emit(from_hotbar_index)
			hotbar_changed.emit(to_hotbar_index)
			return true

	hotbar_slots[from_hotbar_index] = to_item
	hotbar_slots[to_hotbar_index] = from_item
	hotbar_changed.emit(from_hotbar_index)
	hotbar_changed.emit(to_hotbar_index)
	return true


func _use_item(item: InventoryItem) -> bool:
	if item == null or item.data == null:
		return false
	
	if not item.is_usable():
		return false
	
	# ÐŸÐ ÐžÐ’Ð•Ð ÐšÐ: Ð—ÐµÐ»ÑŒÐµ ÑƒÐ¶Ðµ Ð¸ÑÐ¿Ð¾Ð»ÑŒÐ·Ð¾Ð²Ð°Ð½Ð¾ Ð² ÑÑ‚Ð¾Ð¹ ÐºÐ¾Ð¼Ð½Ð°Ñ‚Ðµ?
	var item_id = item.get_item_id()
	if is_potion_used(item_id):
		print("âš ï¸ Ð—ÐµÐ»ÑŒÐµ ÑƒÐ¶Ðµ Ð¸ÑÐ¿Ð¾Ð»ÑŒÐ·Ð¾Ð²Ð°Ð½Ð¾ Ð² ÑÑ‚Ð¾Ð¹ ÐºÐ¾Ð¼Ð½Ð°Ñ‚Ðµ!")
		return false
	
	# ÐŸÐ¾Ð¼ÐµÑ‡Ð°ÐµÐ¼ Ð·ÐµÐ»ÑŒÐµ ÐºÐ°Ðº Ð¸ÑÐ¿Ð¾Ð»ÑŒÐ·Ð¾Ð²Ð°Ð½Ð½Ð¾Ðµ
	mark_potion_used(item_id)
	
	# ÐŸÑ€Ð¸Ð¼ÐµÐ½ÑÐµÐ¼ ÑÑ„Ñ„ÐµÐºÑ‚Ñ‹
	for effect in item.data.effects:
		_apply_effect(effect)
	
	# Ð£Ð¼ÐµÐ½ÑŒÑˆÐ°ÐµÐ¼ ÐºÐ¾Ð»Ð¸Ñ‡ÐµÑÑ‚Ð²Ð¾
	item.remove(1)
	
	return true


func _apply_effect(effect: Dictionary):
	var effect_type = effect.get("type", InventoryEnums.EffectType.NONE)
	var value = effect.get("value", 0.0)
	var duration = effect.get("duration", 0.0)
	
	print("ðŸ§ª ÐŸÑ€Ð¸Ð¼ÐµÐ½ÑÐµÐ¼ ÑÑ„Ñ„ÐµÐºÑ‚: Ñ‚Ð¸Ð¿=%d, Ð·Ð½Ð°Ñ‡ÐµÐ½Ð¸Ðµ=%.1f, Ð´Ð»Ð¸Ñ‚ÐµÐ»ÑŒÐ½Ð¾ÑÑ‚ÑŒ=%.1f" % [effect_type, value, duration])


# ===========================================
# Ð ÐÐ¡Ð§ÐÐ¢ Ð¡Ð¢ÐÐ¢ÐžÐ’ ÐžÐ¢ Ð­ÐšÐ˜ÐŸÐ˜Ð ÐžÐ’ÐšÐ˜
# ===========================================

func _recalculate_stats():
	"""ÐŸÐµÑ€ÐµÑÑ‡Ð¸Ñ‚Ñ‹Ð²Ð°ÐµÑ‚ ÑÑ‚Ð°Ñ‚Ñ‹ Ð¾Ñ‚ ÑÐºÐ¸Ð¿Ð¸Ñ€Ð¾Ð²ÐºÐ¸"""
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
	
	print("ðŸ“Š Ð¡Ñ‚Ð°Ñ‚Ñ‹ Ð¾Ñ‚ ÑÐºÐ¸Ð¿Ð¸Ñ€Ð¾Ð²ÐºÐ¸: ", total_stats)
	stats_updated.emit(total_stats)


func get_equipment_stats() -> Dictionary:
	"""Ð’Ð¾Ð·Ð²Ñ€Ð°Ñ‰Ð°ÐµÑ‚ Ñ‚ÐµÐºÑƒÑ‰Ð¸Ðµ Ð±Ð¾Ð½ÑƒÑÑ‹ Ð¾Ñ‚ ÑÐºÐ¸Ð¿Ð¸Ñ€Ð¾Ð²ÐºÐ¸"""
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


func emit_current_stats() -> void:
	_recalculate_stats()


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
# Ð¡ÐžÐ¥Ð ÐÐÐ•ÐÐ˜Ð• / Ð—ÐÐ“Ð Ð£Ð—ÐšÐ
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
		push_error("InventoryManager: Ð±Ð°Ð·Ð° Ð´Ð°Ð½Ð½Ñ‹Ñ… Ð½Ðµ ÑƒÑÑ‚Ð°Ð½Ð¾Ð²Ð»ÐµÐ½Ð° Ð´Ð»Ñ Ð´ÐµÑÐµÑ€Ð¸Ð°Ð»Ð¸Ð·Ð°Ñ†Ð¸Ð¸")
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
	
	print("ðŸŽ’ Ð˜Ð½Ð²ÐµÐ½Ñ‚Ð°Ñ€ÑŒ Ð·Ð°Ð³Ñ€ÑƒÐ¶ÐµÐ½")


# ===========================================
# ÐžÐ¢Ð›ÐÐ”ÐšÐ
# ===========================================

func debug_print():
	print("=== Ð˜ÐÐ’Ð•ÐÐ¢ÐÐ Ð¬ (%d/%d) ===" % [get_used_slot_count(), current_slot_count])
	for i in range(current_slot_count):
		if inventory_slots[i] != null:
			print("  [%d] %s" % [i, inventory_slots[i]])
	
	print("=== Ð­ÐšÐ˜ÐŸÐ˜Ð ÐžÐ’ÐšÐ ===")
	for slot in equipment_slots:
		if equipment_slots[slot] != null:
			var slot_name = InventoryEnums.get_slot_name(slot)
			print("  %s: %s" % [slot_name, equipment_slots[slot]])
	
	print("=== Ð‘Ð«Ð¡Ð¢Ð Ð«Ð• Ð¡Ð›ÐžÐ¢Ð« ===")
	for i in range(HOTBAR_SLOTS):
		var item = hotbar_slots[i]
		print("  [%d] %s" % [i + 1, item if item else "ÐŸÑƒÑÑ‚Ð¾"])
	
	print("=== Ð˜Ð¡ÐŸÐžÐ›Ð¬Ð—ÐžÐ’ÐÐÐÐ«Ð• Ð—Ð•Ð›Ð¬Ð¯ ===")
	print("  ", used_potions_this_room)
