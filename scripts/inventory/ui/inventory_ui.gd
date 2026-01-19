extends CanvasLayer
class_name InventoryUI
## Главное окно инвентаря
##
## Путь: res://scripts/inventory/ui/inventory_ui.gd
##
## ИСПРАВЛЕНЫ БАГИ:
## - Инвентарь не открывается автоматически
## - ESC закрывает инвентарь (не меню паузы)
## - 15 слотов в сетке (5x3)
## - Добавлены слоты расходников
## - Блокируется ввод игрока когда инвентарь открыт
## - Открытие/закрытие по action "inventory" (клавиша B)

# ===========================================
# СИГНАЛЫ
# ===========================================

signal inventory_opened()
signal inventory_closed()
signal item_used(item: InventoryItem)
signal item_equipped(item: InventoryItem, slot: InventoryEnums.EquipSlot)
signal item_unequipped(item: InventoryItem, slot: InventoryEnums.EquipSlot)

# ===========================================
# КОНСТАНТЫ
# ===========================================

const SLOT_SIZE = Vector2(50, 50)
const SLOT_SPACING = 5
const GRID_COLUMNS = 5
const VISIBLE_ROWS = 4  # 5 колонок * 4 ряда = 20 видимых слотов

# Вкладки
enum Tab {
	ALL,
	EQUIPMENT,
	ARTIFACTS,
	CONSUMABLES
}

# ===========================================
# ПЕРЕМЕННЫЕ
# ===========================================

var is_open: bool = false
var current_tab: Tab = Tab.ALL
var inventory_slots: Array[InventorySlot] = []
var equipment_slots: Dictionary = {}  # EquipSlot -> InventorySlot
var hotbar_slots: Array[InventorySlot] = []
var selected_slot: InventorySlot = null

# UI элементы
var main_panel: Panel
var inventory_container: VBoxContainer
var tabs_container: HBoxContainer
var slots_grid: GridContainer
var equipment_panel: Panel
var hotbar_panel: Panel
var tooltip_panel: Panel
var tooltip_label: RichTextLabel
var close_button: Button
var title_label: Label
var dimmer: ColorRect

# ===========================================
# ИНИЦИАЛИЗАЦИЯ
# ===========================================

func _ready():
	layer = 100  # Поверх игры
	
	# ВАЖНО: Обрабатываем ввод даже на паузе
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_create_ui()
	_connect_signals()
	
	# ИСПРАВЛЕНИЕ: Скрываем при старте
	visible = false
	is_open = false
	
	print("📦 InventoryUI создан (нажми B чтобы открыть)")


func _create_ui():
	"""Создаёт всю структуру UI"""
	
	# === ЗАТЕМНЕНИЕ ФОНА ===
	dimmer = ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.6)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP  # Блокирует клики
	dimmer.gui_input.connect(_on_dimmer_input)
	add_child(dimmer)
	
	# === ГЛАВНАЯ ПАНЕЛЬ ===
	main_panel = Panel.new()
	main_panel.name = "MainPanel"
	main_panel.custom_minimum_size = Vector2(700, 550)
	main_panel.set_anchors_preset(Control.PRESET_CENTER)
	main_panel.offset_left = -350
	main_panel.offset_top = -275
	main_panel.offset_right = 350
	main_panel.offset_bottom = 275
	main_panel.mouse_filter = Control.MOUSE_FILTER_STOP  # Блокирует клики
	_style_panel(main_panel, Color(0.12, 0.12, 0.15, 0.95))
	add_child(main_panel)
	
	# === ЗАГОЛОВОК ===
	var header = HBoxContainer.new()
	header.name = "Header"
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 15
	header.offset_top = 10
	header.offset_right = -15
	header.offset_bottom = 40
	main_panel.add_child(header)
	
	title_label = Label.new()
	title_label.text = "🎒 ИНВЕНТАРЬ"
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	
	# Подсказка
	var hint_label = Label.new()
	hint_label.text = "[B] или [ESC] - закрыть"
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	header.add_child(hint_label)
	
	close_button = Button.new()
	close_button.text = "✕"
	close_button.custom_minimum_size = Vector2(30, 30)
	close_button.pressed.connect(hide_inventory)
	header.add_child(close_button)
	
	# === ОСНОВНОЙ КОНТЕЙНЕР ===
	var main_hbox = HBoxContainer.new()
	main_hbox.name = "MainHBox"
	main_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_hbox.offset_left = 15
	main_hbox.offset_top = 50
	main_hbox.offset_right = -15
	main_hbox.offset_bottom = -15
	main_hbox.add_theme_constant_override("separation", 15)
	main_panel.add_child(main_hbox)
	
	# === ЛЕВАЯ ЧАСТЬ (Сумка) ===
	var left_panel = VBoxContainer.new()
	left_panel.name = "LeftPanel"
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.add_theme_constant_override("separation", 10)
	main_hbox.add_child(left_panel)
	
	# Вкладки
	_create_tabs(left_panel)
	
	# Сетка слотов
	_create_inventory_grid(left_panel)
	
	# Быстрые слоты (расходники)
	_create_consumable_hotbar(left_panel)
	
	# === ПРАВАЯ ЧАСТЬ (Экипировка) ===
	_create_equipment_panel(main_hbox)
	
	# === ПОДСКАЗКА ===
	_create_tooltip()


func _create_tabs(parent: Control):
	"""Создаёт вкладки"""
	tabs_container = HBoxContainer.new()
	tabs_container.name = "Tabs"
	tabs_container.add_theme_constant_override("separation", 5)
	parent.add_child(tabs_container)
	
	var tab_names = ["Всё", "Экипировка", "Артефакты", "Расходники"]
	
	for i in range(tab_names.size()):
		var btn = Button.new()
		btn.text = tab_names[i]
		btn.toggle_mode = true
		btn.button_pressed = (i == 0)
		btn.custom_minimum_size = Vector2(90, 30)
		btn.pressed.connect(_on_tab_pressed.bind(i))
		tabs_container.add_child(btn)


func _create_inventory_grid(parent: Control):
	"""Создаёт сетку слотов инвентаря"""
	# Заголовок
	var grid_label = Label.new()
	grid_label.text = "📦 Сумка"
	grid_label.add_theme_font_size_override("font_size", 14)
	parent.add_child(grid_label)
	
	var scroll = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 230)  # Высота для 4 рядов
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	
	slots_grid = GridContainer.new()
	slots_grid.name = "SlotsGrid"
	slots_grid.columns = GRID_COLUMNS
	slots_grid.add_theme_constant_override("h_separation", SLOT_SPACING)
	slots_grid.add_theme_constant_override("v_separation", SLOT_SPACING)
	scroll.add_child(slots_grid)
	
	# Создаём слоты
	_create_inventory_slots()


func _create_inventory_slots():
	"""Создаёт слоты инвентаря"""
	inventory_slots.clear()
	
	# Очищаем старые
	for child in slots_grid.get_children():
		child.queue_free()
	
	# Создаём новые (по количеству доступных слотов)
	var slot_count = Inventory.get_available_slot_count() if Inventory else 24
	
	for i in range(slot_count):
		var slot = InventorySlot.new()
		slot.slot_index = i
		slot.is_equipment_slot = false
		
		# Подключаем сигналы
		slot.slot_clicked.connect(_on_slot_clicked)
		slot.slot_hovered.connect(_on_slot_hovered)
		slot.slot_unhovered.connect(_on_slot_unhovered)
		slot.item_dropped.connect(_on_item_dropped)
		
		slots_grid.add_child(slot)
		inventory_slots.append(slot)


func _create_consumable_hotbar(parent: Control):
	"""Создаёт панель быстрых слотов для расходников"""
	var sep = HSeparator.new()
	parent.add_child(sep)
	
	var hotbar_label = Label.new()
	hotbar_label.text = "🧪 Быстрые слоты (1-4)"
	hotbar_label.add_theme_font_size_override("font_size", 14)
	parent.add_child(hotbar_label)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", SLOT_SPACING)
	parent.add_child(hbox)
	
	for i in range(4):
		var slot_vbox = VBoxContainer.new()
		slot_vbox.add_theme_constant_override("separation", 2)
		hbox.add_child(slot_vbox)
		
		var slot = InventorySlot.new()
		slot.slot_index = -1
		slot.is_hotbar_slot = true
		slot.hotbar_index = i
		slot.custom_minimum_size = SLOT_SIZE
		
		slot.slot_clicked.connect(_on_hotbar_slot_clicked.bind(i))
		slot.item_dropped.connect(_on_hotbar_item_dropped.bind(i))
		
		slot_vbox.add_child(slot)
		hotbar_slots.append(slot)
		
		var key_label = Label.new()
		key_label.text = "[%d]" % (i + 1)
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_label.add_theme_font_size_override("font_size", 11)
		key_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		slot_vbox.add_child(key_label)


func _create_equipment_panel(parent: Control):
	"""Создаёт панель экипировки"""
	equipment_panel = Panel.new()
	equipment_panel.name = "EquipmentPanel"
	equipment_panel.custom_minimum_size = Vector2(220, 0)
	_style_panel(equipment_panel, Color(0.1, 0.1, 0.12, 0.9))
	parent.add_child(equipment_panel)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 10
	vbox.offset_top = 10
	vbox.offset_right = -10
	vbox.offset_bottom = -10
	vbox.add_theme_constant_override("separation", 8)
	equipment_panel.add_child(vbox)
	
	# Заголовок
	var equip_title = Label.new()
	equip_title.text = "⚔️ ЭКИПИРОВКА"
	equip_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equip_title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(equip_title)
	
	# Слоты экипировки
	_create_equipment_slots(vbox)
	
	# Разделитель
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# Артефакты
	var art_title = Label.new()
	art_title.text = "✨ АРТЕФАКТЫ"
	art_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(art_title)
	
	_create_artifact_slots(vbox)
	
	# Разделитель
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)
	
	# Кольца
	var rings_title = Label.new()
	rings_title.text = "💍 КОЛЬЦА"
	rings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rings_title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(rings_title)
	
	_create_ring_slots(vbox)


func _create_equipment_slots(parent: Control):
	"""Создаёт слоты экипировки"""
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	parent.add_child(grid)
	
	# Основные слоты экипировки (3x4)
	var equip_layout = [
		{"slot": InventoryEnums.EquipSlot.HEAD, "label": "🪖"},
		{"slot": InventoryEnums.EquipSlot.NECKLACE, "label": "📿"},
		{"slot": InventoryEnums.EquipSlot.EARRING_1, "label": "💎"},
		{"slot": InventoryEnums.EquipSlot.MAIN_HAND, "label": "⚔️"},
		{"slot": InventoryEnums.EquipSlot.BODY, "label": "🛡️"},
		{"slot": InventoryEnums.EquipSlot.OFF_HAND, "label": "🛡️"},
		{"slot": InventoryEnums.EquipSlot.HANDS, "label": "🧤"},
		{"slot": InventoryEnums.EquipSlot.LEGS, "label": "👖"},
		{"slot": InventoryEnums.EquipSlot.EARRING_2, "label": "💎"},
		{"slot": InventoryEnums.EquipSlot.NONE, "label": ""},
		{"slot": InventoryEnums.EquipSlot.FEET, "label": "👢"},
		{"slot": InventoryEnums.EquipSlot.RELIC, "label": "🏆"},
	]
	
	for data in equip_layout:
		if data.slot == InventoryEnums.EquipSlot.NONE:
			# Пустая ячейка
			var spacer = Control.new()
			spacer.custom_minimum_size = SLOT_SIZE
			grid.add_child(spacer)
		else:
			var slot = _create_equip_slot(data.slot, data.label)
			grid.add_child(slot)


func _create_artifact_slots(parent: Control):
	"""Создаёт слоты артефактов"""
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 5)
	parent.add_child(hbox)
	
	var artifact_slots_data = [
		InventoryEnums.EquipSlot.ARTIFACT_1,
		InventoryEnums.EquipSlot.ARTIFACT_2,
		InventoryEnums.EquipSlot.ARTIFACT_3,
		InventoryEnums.EquipSlot.ARTIFACT_4,
	]
	
	for slot_type in artifact_slots_data:
		var slot = _create_equip_slot(slot_type, "✨")
		hbox.add_child(slot)


func _create_ring_slots(parent: Control):
	"""Создаёт слоты колец"""
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 3)
	parent.add_child(hbox)
	
	# 4 кольца в ряд (можно расширить)
	var ring_slots_data = [
		InventoryEnums.EquipSlot.RING_1,
		InventoryEnums.EquipSlot.RING_2,
		InventoryEnums.EquipSlot.RING_3,
		InventoryEnums.EquipSlot.RING_4,
	]
	
	for slot_type in ring_slots_data:
		var slot = _create_equip_slot(slot_type, "💍")
		slot.custom_minimum_size = Vector2(40, 40)  # Чуть меньше
		hbox.add_child(slot)


func _create_equip_slot(slot_type: InventoryEnums.EquipSlot, label_text: String) -> InventorySlot:
	"""Создаёт один слот экипировки"""
	var slot = InventorySlot.new()
	slot.slot_type = slot_type
	slot.is_equipment_slot = true
	slot.custom_minimum_size = SLOT_SIZE
	
	# Подключаем сигналы
	slot.slot_clicked.connect(_on_equip_slot_clicked)
	slot.slot_hovered.connect(_on_slot_hovered)
	slot.slot_unhovered.connect(_on_slot_unhovered)
	slot.item_dropped.connect(_on_equip_item_dropped)
	
	equipment_slots[slot_type] = slot
	
	return slot


func _create_tooltip():
	"""Создаёт панель подсказки"""
	tooltip_panel = Panel.new()
	tooltip_panel.name = "Tooltip"
	tooltip_panel.custom_minimum_size = Vector2(250, 100)
	tooltip_panel.visible = false
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_panel(tooltip_panel, Color(0.08, 0.08, 0.1, 0.95))
	add_child(tooltip_panel)
	
	tooltip_label = RichTextLabel.new()
	tooltip_label.name = "TooltipText"
	tooltip_label.bbcode_enabled = true
	tooltip_label.fit_content = true
	tooltip_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	tooltip_label.offset_left = 10
	tooltip_label.offset_top = 10
	tooltip_label.offset_right = -10
	tooltip_label.offset_bottom = -10
	tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.add_child(tooltip_label)


func _style_panel(panel: Panel, color: Color):
	"""Применяет стиль к панели"""
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.35)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)


func _connect_signals():
	"""Подключает сигналы инвентаря"""
	if Inventory:
		Inventory.inventory_changed.connect(_refresh_inventory)
		Inventory.equipment_changed.connect(_refresh_equipment)
		Inventory.hotbar_changed.connect(_refresh_hotbar)

# ===========================================
# ОТКРЫТИЕ/ЗАКРЫТИЕ
# ===========================================

func show_inventory():
	"""Открывает инвентарь"""
	if is_open:
		return
	
	is_open = true
	visible = true
	
	# Обновляем содержимое
	_refresh_inventory()
	_refresh_equipment()
	_refresh_hotbar()
	
	# ИСПРАВЛЕНИЕ: Ставим паузу чтобы игрок не двигался/атаковал
	get_tree().paused = true
	
	inventory_opened.emit()
	print("📦 Инвентарь открыт")


func hide_inventory():
	"""Закрывает инвентарь"""
	if not is_open:
		return
	
	is_open = false
	visible = false
	
	# Скрываем подсказку
	tooltip_panel.visible = false
	
	# Снимаем паузу
	get_tree().paused = false
	
	inventory_closed.emit()
	print("📦 Инвентарь закрыт")


func toggle_inventory():
	"""Переключает инвентарь"""
	if is_open:
		hide_inventory()
	else:
		show_inventory()

# ===========================================
# ОБРАБОТКА ВВОДА - ИСПРАВЛЕНО
# ===========================================

func _input(event: InputEvent):
	# ИСПРАВЛЕНИЕ: Используем action "inventory" (клавиша B)
	if event.is_action_pressed("inventory"):
		toggle_inventory()
		get_viewport().set_input_as_handled()
		return
	
	# ИСПРАВЛЕНИЕ: ESC закрывает инвентарь, а не меню паузы
	if is_open and event.is_action_pressed("ui_cancel"):
		hide_inventory()
		get_viewport().set_input_as_handled()
		return


func _on_dimmer_input(event: InputEvent):
	"""Клик по затемнению закрывает инвентарь"""
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			hide_inventory()

# ===========================================
# ОБНОВЛЕНИЕ
# ===========================================

func _refresh_inventory():
	"""Обновляет отображение инвентаря"""
	if not Inventory:
		return
	
	# Проверяем количество слотов
	var needed_slots = Inventory.get_available_slot_count()
	if inventory_slots.size() != needed_slots:
		_create_inventory_slots()
	
	# Получаем предметы
	var items = Inventory.inventory_slots
	
	# Заполняем слоты
	for i in range(inventory_slots.size()):
		var slot = inventory_slots[i]
		
		if i < items.size() and items[i] != null:
			var item = items[i]
			
			# Фильтрация по вкладке
			if _should_show_item(item):
				slot.set_item(item)
			else:
				slot.clear()
		else:
			slot.clear()
		
		# Блокируем недоступные слоты
		slot.set_locked(i >= Inventory.current_slot_count)


func _refresh_equipment():
	"""Обновляет отображение экипировки"""
	if not Inventory:
		return
	
	for slot_type in equipment_slots:
		var slot = equipment_slots[slot_type]
		var item = Inventory.get_equipped_item(slot_type)
		
		if item:
			slot.set_item(item)
		else:
			slot.clear()


func _refresh_hotbar():
	"""Обновляет быстрые слоты"""
	if not Inventory:
		return
	
	for i in range(hotbar_slots.size()):
		var item = Inventory.get_hotbar_item(i)
		if item and not item.is_empty():
			hotbar_slots[i].set_item(item)
		else:
			hotbar_slots[i].clear()


func _should_show_item(item: InventoryItem) -> bool:
	"""Проверяет, показывать ли предмет в текущей вкладке"""
	if current_tab == Tab.ALL:
		return true
	
	match current_tab:
		Tab.EQUIPMENT:
			return item.get_category() == InventoryEnums.ItemCategory.EQUIPMENT
		Tab.ARTIFACTS:
			return item.get_category() == InventoryEnums.ItemCategory.ARTIFACT
		Tab.CONSUMABLES:
			return item.get_category() == InventoryEnums.ItemCategory.CONSUMABLE
	
	return true

# ===========================================
# ОБРАБОТЧИКИ
# ===========================================

func _on_tab_pressed(tab_index: int):
	"""Обработчик нажатия вкладки"""
	current_tab = tab_index as Tab
	
	# Обновляем состояние кнопок
	for i in range(tabs_container.get_child_count()):
		var btn = tabs_container.get_child(i) as Button
		btn.button_pressed = (i == tab_index)
	
	_refresh_inventory()


func _on_slot_clicked(slot: InventorySlot, button: int):
	"""Обработчик клика по слоту инвентаря"""
	if slot.is_empty():
		return
	
	var item = slot.get_item()
	
	if button == MOUSE_BUTTON_LEFT:
		# ЛКМ - выбор (Drag начнётся автоматически)
		selected_slot = slot
	
	elif button == MOUSE_BUTTON_RIGHT:
		# ПКМ - использование или экипировка
		if item.is_usable():
			_use_item(slot)
		elif item.is_equippable():
			_quick_equip(slot)


func _on_equip_slot_clicked(slot: InventorySlot, button: int):
	"""Обработчик клика по слоту экипировки"""
	if button == MOUSE_BUTTON_RIGHT:
		# ПКМ - снять экипировку
		if not slot.is_empty():
			Inventory.unequip_item(slot.slot_type)


func _on_hotbar_slot_clicked(slot: InventorySlot, button: int, index: int):
	"""Обработчик клика по быстрому слоту"""
	if button == MOUSE_BUTTON_RIGHT:
		# ПКМ - очистить слот
		Inventory.set_hotbar_item(index, -1)
		_refresh_hotbar()


func _on_slot_hovered(slot: InventorySlot):
	"""Показывает подсказку"""
	if slot.is_empty():
		tooltip_panel.visible = false
		return
	
	var item = slot.get_item()
	tooltip_label.text = item.generate_tooltip()
	
	# Позиционируем подсказку
	await get_tree().process_frame
	
	var mouse_pos = get_viewport().get_mouse_position()
	tooltip_panel.position = mouse_pos + Vector2(15, 15)
	
	# Проверяем границы экрана
	var screen_size = get_viewport().get_visible_rect().size
	if tooltip_panel.position.x + tooltip_panel.size.x > screen_size.x:
		tooltip_panel.position.x = mouse_pos.x - tooltip_panel.size.x - 15
	if tooltip_panel.position.y + tooltip_panel.size.y > screen_size.y:
		tooltip_panel.position.y = mouse_pos.y - tooltip_panel.size.y - 15
	
	tooltip_panel.visible = true


func _on_slot_unhovered(_slot: InventorySlot):
	"""Скрывает подсказку"""
	tooltip_panel.visible = false


func _on_item_dropped(from_slot: InventorySlot, to_slot: InventorySlot):
	"""Обработчик перетаскивания между слотами инвентаря"""
	if from_slot == to_slot:
		return
	
	Inventory.move_item(from_slot.slot_index, to_slot.slot_index)


func _on_equip_item_dropped(from_slot: InventorySlot, to_slot: InventorySlot):
	"""Обработчик перетаскивания на слот экипировки"""
	if from_slot.is_equipment_slot:
		# Из экипировки - снимаем
		Inventory.unequip_item(from_slot.slot_type)
		return
	
	# Из инвентаря в экипировку
	Inventory.equip_item(from_slot.slot_index, to_slot.slot_type)


func _on_hotbar_item_dropped(from_slot: InventorySlot, to_slot: InventorySlot, hotbar_index: int):
	"""Обработчик перетаскивания на быстрый слот"""
	if from_slot.is_equipment_slot or from_slot.is_hotbar_slot:
		return
	
	var item = from_slot.get_item()
	if item and item.is_usable():
		Inventory.set_hotbar_item(hotbar_index, from_slot.slot_index)
		_refresh_hotbar()


func _quick_equip(slot: InventorySlot):
	"""Быстрая экипировка предмета"""
	if slot.is_empty():
		return
	
	var item = slot.get_item()
	if item.is_equippable():
		Inventory.equip_item(slot.slot_index)


func _use_item(slot: InventorySlot):
	"""Использует предмет"""
	if slot.is_empty():
		return
	
	var item = slot.get_item()
	if not item.is_usable():
		return
	
	# Применяем эффекты
	print("🧪 Использован: %s" % item.get_display_name())
	item_used.emit(item)
	
	# Уменьшаем количество
	item.remove(1)
	
	if item.is_empty():
		Inventory.remove_item_at(slot.slot_index)
	
	_refresh_inventory()
	_refresh_hotbar()
