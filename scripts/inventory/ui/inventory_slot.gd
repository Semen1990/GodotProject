extends Panel
class_name InventorySlot
## Один слот инвентаря (для сумки или экипировки)
##
## Путь: res://scripts/inventory/ui/inventory_slot.gd
##
## ИСПРАВЛЕНО:
## - Drag & Drop работает корректно
## - Клики не проходят к игроку

# ===========================================
# СИГНАЛЫ
# ===========================================

signal slot_clicked(slot: InventorySlot, button: int)
signal slot_right_clicked(slot: InventorySlot)
signal item_dropped(from_slot: InventorySlot, to_slot: InventorySlot)
signal slot_hovered(slot: InventorySlot)
signal slot_unhovered(slot: InventorySlot)

# ===========================================
# ЭКСПОРТ
# ===========================================

## Индекс слота в инвентаре (-1 для слотов экипировки)
@export var slot_index: int = -1

## Тип слота (для экипировки)
@export var slot_type: InventoryEnums.EquipSlot = InventoryEnums.EquipSlot.NONE

## Это слот экипировки?
@export var is_equipment_slot: bool = false

## Это быстрый слот (1-4)?
@export var is_hotbar_slot: bool = false

## Индекс быстрого слота (0-3)
@export var hotbar_index: int = -1

# ===========================================
# НОДЫ
# ===========================================

var icon_texture: TextureRect
var quantity_label: Label
var rarity_border: Panel
var slot_background: Panel
var cooldown_overlay: ColorRect
var slot_type_icon: TextureRect

# ===========================================
# ДАННЫЕ
# ===========================================

var current_item: InventoryItem = null
var is_hovered: bool = false
var is_dragging: bool = false
var is_locked: bool = false

# Цвета
const COLOR_EMPTY = Color(0.15, 0.15, 0.15, 0.8)
const COLOR_HOVER = Color(0.3, 0.3, 0.3, 0.9)
const COLOR_SELECTED = Color(0.4, 0.35, 0.2, 0.9)
const COLOR_LOCKED = Color(0.1, 0.1, 0.1, 0.95)
const COLOR_DROP_VALID = Color(0.2, 0.4, 0.2, 0.9)
const COLOR_DROP_INVALID = Color(0.4, 0.2, 0.2, 0.9)

# ===========================================
# ИНИЦИАЛИЗАЦИЯ
# ===========================================

func _ready():
	# ВАЖНО: Блокируем прохождение событий мыши
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Создаём структуру UI
	_create_ui_structure()
	
	# Настраиваем взаимодействие
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	
	# Начальное состояние
	_update_visual()


func _create_ui_structure():
	"""Создаёт дочерние элементы UI"""
	# Размер слота
	custom_minimum_size = Vector2(50, 50)
	size = Vector2(50, 50)
	
	# Фон слота
	slot_background = Panel.new()
	slot_background.name = "Background"
	slot_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(slot_background)
	
	# Рамка редкости
	rarity_border = Panel.new()
	rarity_border.name = "RarityBorder"
	rarity_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	rarity_border.visible = false
	rarity_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rarity_border)
	
	# Иконка предмета
	icon_texture = TextureRect.new()
	icon_texture.name = "Icon"
	icon_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_texture.offset_left = 4
	icon_texture.offset_top = 4
	icon_texture.offset_right = -4
	icon_texture.offset_bottom = -4
	icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_texture)
	
	# Иконка типа слота (для экипировки)
	slot_type_icon = TextureRect.new()
	slot_type_icon.name = "SlotTypeIcon"
	slot_type_icon.set_anchors_preset(Control.PRESET_CENTER)
	slot_type_icon.offset_left = -12
	slot_type_icon.offset_top = -12
	slot_type_icon.offset_right = 12
	slot_type_icon.offset_bottom = 12
	slot_type_icon.modulate = Color(1, 1, 1, 0.3)
	slot_type_icon.visible = false
	slot_type_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(slot_type_icon)
	
	# Количество
	quantity_label = Label.new()
	quantity_label.name = "Quantity"
	quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	quantity_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	quantity_label.offset_left = 2
	quantity_label.offset_top = 2
	quantity_label.offset_right = -4
	quantity_label.offset_bottom = -2
	quantity_label.add_theme_font_size_override("font_size", 12)
	quantity_label.add_theme_color_override("font_color", Color.WHITE)
	quantity_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	quantity_label.add_theme_constant_override("shadow_offset_x", 1)
	quantity_label.add_theme_constant_override("shadow_offset_y", 1)
	quantity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(quantity_label)
	
	# Оверлей кулдауна
	cooldown_overlay = ColorRect.new()
	cooldown_overlay.name = "CooldownOverlay"
	cooldown_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	cooldown_overlay.color = Color(0, 0, 0, 0.7)
	cooldown_overlay.visible = false
	cooldown_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cooldown_overlay)
	
	# Применяем стиль
	_apply_style()


func _apply_style():
	"""Применяет визуальный стиль к слоту"""
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_EMPTY
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.3, 0.3, 0.3)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	
	add_theme_stylebox_override("panel", style)

# ===========================================
# УПРАВЛЕНИЕ ПРЕДМЕТОМ
# ===========================================

func set_item(item: InventoryItem):
	"""Устанавливает предмет в слот"""
	current_item = item
	_update_visual()


func get_item() -> InventoryItem:
	"""Возвращает предмет из слота"""
	return current_item


func clear():
	"""Очищает слот"""
	current_item = null
	_update_visual()


func is_empty() -> bool:
	"""Проверяет пустой ли слот"""
	return current_item == null


func set_locked(locked: bool):
	"""Блокирует/разблокирует слот"""
	is_locked = locked
	_update_visual()

# ===========================================
# ОБНОВЛЕНИЕ ВИЗУАЛА
# ===========================================

func _update_visual():
	"""Обновляет визуальное отображение слота"""
	
	# Получаем иконку-подсказку (эмодзи или картинку)
	var hint_icon = get_node_or_null("HintIcon")
	
	if current_item and current_item.data:
		# Есть предмет
		icon_texture.texture = current_item.get_icon()
		icon_texture.visible = true
		
		# Количество (только для стакаемых)
		if current_item.is_stackable() and current_item.quantity > 1:
			quantity_label.text = str(current_item.quantity)
			quantity_label.visible = true
		else:
			quantity_label.visible = false
		
		# Рамка редкости
		_update_rarity_border(current_item.get_rarity())
		
		# Скрываем иконку типа слота
		slot_type_icon.visible = false
		
		# Скрываем иконку-подсказку
		if hint_icon:
			hint_icon.visible = false
	else:
		# Пустой слот
		icon_texture.texture = null
		icon_texture.visible = false
		quantity_label.visible = false
		rarity_border.visible = false
		
		# Показываем иконку типа слота (для экипировки)
		if is_equipment_slot:
			slot_type_icon.visible = true
		
		# Показываем иконку-подсказку
		if hint_icon:
			hint_icon.visible = true
	
	# Обновляем фон
	_update_background()


func _update_rarity_border(rarity: InventoryEnums.ItemRarity):
	"""Обновляет рамку редкости"""
	if rarity == InventoryEnums.ItemRarity.COMMON:
		rarity_border.visible = false
		return
	
	rarity_border.visible = true
	
	var color = InventoryEnums.get_rarity_color(rarity)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	
	rarity_border.add_theme_stylebox_override("panel", style)


func _update_background():
	"""Обновляет цвет фона"""
	var style = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	
	if is_locked:
		style.bg_color = COLOR_LOCKED
	elif is_hovered:
		style.bg_color = COLOR_HOVER
	else:
		style.bg_color = COLOR_EMPTY
	
	add_theme_stylebox_override("panel", style)

# ===========================================
# ОБРАБОТКА ВВОДА
# ===========================================

func _on_mouse_entered():
	is_hovered = true
	_update_background()
	slot_hovered.emit(self)


func _on_mouse_exited():
	is_hovered = false
	_update_background()
	slot_unhovered.emit(self)


func _on_gui_input(event: InputEvent):
	if is_locked:
		return
	
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				slot_clicked.emit(self, MOUSE_BUTTON_LEFT)
				# ВАЖНО: Помечаем событие как обработанное
				accept_event()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				slot_clicked.emit(self, MOUSE_BUTTON_RIGHT)
				slot_right_clicked.emit(self)
				accept_event()


# ===========================================
# DRAG & DROP - ИСПРАВЛЕНО
# ===========================================

func _get_drag_data(_position: Vector2):
	"""Начало перетаскивания"""
	if is_empty() or is_locked:
		return null
	
	is_dragging = true
	
	# Создаём превью
	var preview = TextureRect.new()
	preview.texture = current_item.get_icon()
	preview.custom_minimum_size = Vector2(40, 40)
	preview.size = Vector2(40, 40)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.modulate = Color(1, 1, 1, 0.8)
	
	# Центрируем превью под курсором
	var control = Control.new()
	control.add_child(preview)
	preview.position = -preview.size / 2
	
	set_drag_preview(control)
	
	# Делаем оригинал полупрозрачным
	modulate = Color(1, 1, 1, 0.5)
	
	return {
		"type": "inventory_item",
		"item": current_item,
		"source_slot": self
	}


func _can_drop_data(_position: Vector2, data) -> bool:
	"""Проверка можно ли сбросить сюда"""
	if is_locked:
		return false
	
	if not data is Dictionary:
		return false
	
	if data.get("type") != "inventory_item":
		return false
	
	var item = data.get("item") as InventoryItem
	if not item:
		return false
	
	# Проверка для слотов экипировки
	if is_equipment_slot:
		var valid_slots = item.get_valid_equip_slots()
		if slot_type not in valid_slots:
			# Подсвечиваем красным
			_highlight_invalid()
			return false
		# Подсвечиваем зелёным
		_highlight_valid()
	
	# Проверка для быстрых слотов - только расходники
	if is_hotbar_slot:
		if not item.is_usable():
			_highlight_invalid()
			return false
		_highlight_valid()
	
	return true


func _drop_data(_position: Vector2, data):
	"""Обработка сброса предмета"""
	_reset_highlight()
	
	var source_slot = data.get("source_slot") as InventorySlot
	if source_slot:
		source_slot.modulate = Color.WHITE  # Восстанавливаем прозрачность
		item_dropped.emit(source_slot, self)


func _notification(what: int):
	if what == NOTIFICATION_DRAG_END:
		is_dragging = false
		modulate = Color.WHITE
		_reset_highlight()


func _highlight_valid():
	"""Подсветка валидного сброса"""
	var style = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.bg_color = COLOR_DROP_VALID
	add_theme_stylebox_override("panel", style)


func _highlight_invalid():
	"""Подсветка невалидного сброса"""
	var style = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.bg_color = COLOR_DROP_INVALID
	add_theme_stylebox_override("panel", style)


func _reset_highlight():
	"""Сброс подсветки"""
	_update_background()
