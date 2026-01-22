extends CanvasLayer
class_name InventoryUI
## Главное окно инвентаря v6.0
##
## Путь: res://scripts/inventory/ui/inventory_ui.gd
##
## ═══════════════════════════════════════════════════════════════════
## ИНСТРУКЦИЯ ПО РЕДАКТИРОВАНИЮ РАЗМЕРОВ И ПОЗИЦИЙ:
## ═══════════════════════════════════════════════════════════════════
##
## 1. РАЗМЕР ГЛАВНОГО ОКНА:
##    Найди функцию _create_ui() и измени:
##    - custom_minimum_size = Vector2(ШИРИНА, ВЫСОТА)
##    - offset_left/right/top/bottom - отступы от центра экрана
##
## 2. РАЗМЕРЫ СЛОТОВ:
##    В начале файла есть константы:
##    - SLOT_SIZE = Vector2(48, 48)       # Обычные слоты
##    - SMALL_SLOT_SIZE = Vector2(40, 40) # Маленькие слоты
##    - TINY_SLOT_SIZE = Vector2(36, 36)  # Мелкие слоты (кольца)
##
## 3. РАЗМЕР ПАНЕЛИ СПРАЙТА:
##    В _create_character_section() найди:
##    - sprite_bg.custom_minimum_size = Vector2(280, 140)
##    Увеличь второе число чтобы панель была выше
##
## 4. ПОЗИЦИЯ СПРАЙТА:
##    В _create_character_section() найди:
##    - character_sprite.position = Vector2(140, 60)
##    X = горизонтально (140 = центр панели 280/2)
##    Y = вертикально (меньше = выше, больше = ниже)
##
## 5. МАСШТАБ СПРАЙТА:
##    - character_sprite.scale = Vector2(2.5, 2.5)
##    Увеличь числа для большего спрайта
##
## 6. РАЗМЕР СЕКЦИЙ (Сумка/Экипировка/Персонаж):
##    Найди custom_minimum_size в соответствующих функциях:
##    - _create_inventory_section(): inv_panel.custom_minimum_size
##    - _create_equipment_section(): equip_panel.custom_minimum_size
##    - _create_character_section(): char_panel.custom_minimum_size
##
## 7. ОТСТУПЫ ВНУТРИ ПАНЕЛЕЙ:
##    Ищи offset_left/right/top/bottom в VBoxContainer
##
## 8. РАССТОЯНИЕ МЕЖДУ ЭЛЕМЕНТАМИ:
##    - add_theme_constant_override("separation", ЧИСЛО)
##    - add_theme_constant_override("h_separation", ЧИСЛО) - горизонтально
##    - add_theme_constant_override("v_separation", ЧИСЛО) - вертикально
##
## ═══════════════════════════════════════════════════════════════════

# ===========================================
# СИГНАЛЫ
# ===========================================

signal inventory_opened()
signal inventory_closed()
signal item_used(item: InventoryItem)
signal item_equipped(item: InventoryItem, slot: InventoryEnums.EquipSlot)
signal item_unequipped(item: InventoryItem, slot: InventoryEnums.EquipSlot)

# ===========================================
# КОНСТАНТЫ - МЕНЯЙ ЗДЕСЬ РАЗМЕРЫ СЛОТОВ
# ===========================================

## Размер обычных слотов (сумка, основная экипировка)
const SLOT_SIZE = Vector2(48, 48)

## Размер маленьких слотов (артефакты)
const SMALL_SLOT_SIZE = Vector2(40, 40)

## Размер мелких слотов (кольца, серьги)
const TINY_SLOT_SIZE = Vector2(36, 36)

## Отступ между слотами
const SLOT_SPACING = 4

## Количество колонок в сумке
const GRID_COLUMNS = 5

## ═══════════════════════════════════════════════════════════════════
## ИКОНКИ СЛОТОВ (серые, для пустых слотов)
## Чтобы заменить на картинки - см. инструкцию в конце файла
## ═══════════════════════════════════════════════════════════════════
const SLOT_ICONS = {
	# Броня
	InventoryEnums.EquipSlot.HEAD: "🪖",        # Голова/Шлем
	InventoryEnums.EquipSlot.BODY: "👕",        # Нагрудник
	InventoryEnums.EquipSlot.LEGS: "👖",        # Штаны
	InventoryEnums.EquipSlot.FEET: "👢",        # Сапоги
	InventoryEnums.EquipSlot.HANDS: "🧤",       # Перчатки
	InventoryEnums.EquipSlot.SHOULDERS: "🦺",   # Наплечники
	InventoryEnums.EquipSlot.BRACERS: "⌚",     # Наручи
	InventoryEnums.EquipSlot.BELT: "〰️",        # Пояс
	
	# Оружие
	InventoryEnums.EquipSlot.MAIN_HAND: "⚔️",   # Оружие
	InventoryEnums.EquipSlot.OFF_HAND: "🛡️",   # Щит/Орб
	
	# Украшения
	InventoryEnums.EquipSlot.NECKLACE: "📿",    # Ожерелье
	InventoryEnums.EquipSlot.AMULET: "🔮",      # Кулон
	InventoryEnums.EquipSlot.EARRING_1: "💎",   # Серьга Л
	InventoryEnums.EquipSlot.EARRING_2: "💎",   # Серьга П
	InventoryEnums.EquipSlot.RING_1: "💍",      # Кольцо
	InventoryEnums.EquipSlot.RING_2: "💍",
	InventoryEnums.EquipSlot.RING_3: "💍",
	InventoryEnums.EquipSlot.RING_4: "💍",
	
	# Артефакты
	InventoryEnums.EquipSlot.ARTIFACT_1: "✨",
	InventoryEnums.EquipSlot.ARTIFACT_2: "✨",
	InventoryEnums.EquipSlot.ARTIFACT_3: "✨",
	InventoryEnums.EquipSlot.ARTIFACT_4: "✨",
	
	# Реликвия
	InventoryEnums.EquipSlot.RELIC: "🏆",
}

## Иконка для слотов быстрого доступа (хотбар)
const HOTBAR_ICON = "🧪"

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
var equipment_slots: Dictionary = {}
var hotbar_slots: Array[InventorySlot] = []
var selected_slot: InventorySlot = null

var main_panel: Panel
var tabs_container: HBoxContainer
var slots_grid: GridContainer
var tooltip_panel: Panel
var tooltip_label: RichTextLabel
var close_button: Button
var title_label: Label
var dimmer: ColorRect
var character_sprite: AnimatedSprite2D
var stats_labels: Dictionary = {}

# ===========================================
# ИНИЦИАЛИЗАЦИЯ
# ===========================================

func _ready():
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_create_ui()
	_connect_signals()
	
	visible = false
	is_open = false
	
	print("📦 InventoryUI v6 создан")


func _create_ui():
	"""Создаёт всю структуру UI"""
	
	# === ЗАТЕМНЕНИЕ ФОНА ===
	dimmer = ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.5)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.gui_input.connect(_on_dimmer_input)
	add_child(dimmer)
	
	# ═══════════════════════════════════════════════════════════════
	# ГЛАВНАЯ ПАНЕЛЬ - МЕНЯЙ РАЗМЕР ОКНА ЗДЕСЬ
	# ═══════════════════════════════════════════════════════════════
	main_panel = Panel.new()
	main_panel.name = "MainPanel"
	
	# РАЗМЕР ОКНА ИНВЕНТАРЯ (ширина x высота)
	main_panel.custom_minimum_size = Vector2(950, 700)
	
	main_panel.set_anchors_preset(Control.PRESET_CENTER)
	
	# Отступы от центра экрана (половина размера)
	main_panel.offset_left = -475   # -ширина/2
	main_panel.offset_top = -350    # -высота/2
	main_panel.offset_right = 475   # ширина/2
	main_panel.offset_bottom = 350  # высота/2
	
	main_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_style_panel(main_panel, Color(0.12, 0.12, 0.15, 0.95))
	add_child(main_panel)
	
	# === ЗАГОЛОВОК ===
	var header = HBoxContainer.new()
	header.name = "Header"
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 15
	header.offset_top = 8
	header.offset_right = -15
	header.offset_bottom = 35
	main_panel.add_child(header)
	
	title_label = Label.new()
	title_label.text = "📦 ИНВЕНТАРЬ"
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	
	close_button = Button.new()
	close_button.text = "✕"
	close_button.custom_minimum_size = Vector2(28, 28)
	close_button.add_theme_font_size_override("font_size", 16)
	close_button.pressed.connect(hide_inventory)
	header.add_child(close_button)
	
	# === ВКЛАДКИ ===
	_create_tabs()
	
	# === ОСНОВНОЙ КОНТЕНТ ===
	var content = HBoxContainer.new()
	content.name = "Content"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 10
	content.offset_top = 75
	content.offset_right = -10
	content.offset_bottom = -10
	content.add_theme_constant_override("separation", 10)
	main_panel.add_child(content)
	
	# Левая часть - сумка
	_create_inventory_section(content)
	
	# Средняя часть - экипировка
	_create_equipment_section(content)
	
	# Правая часть - персонаж
	_create_character_section(content)
	
	# === ПОДСКАЗКА ===
	_create_tooltip()


func _create_tabs():
	"""Создаёт вкладки"""
	tabs_container = HBoxContainer.new()
	tabs_container.name = "Tabs"
	tabs_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tabs_container.offset_left = 15
	tabs_container.offset_top = 42
	tabs_container.offset_right = -15
	tabs_container.offset_bottom = 68
	tabs_container.add_theme_constant_override("separation", 5)
	main_panel.add_child(tabs_container)
	
	var tab_names = ["Все", "Экипировка", "Артефакты", "Расходники"]
	
	for i in range(tab_names.size()):
		var btn = Button.new()
		btn.text = tab_names[i]
		btn.toggle_mode = true
		btn.button_pressed = (i == 0)
		btn.custom_minimum_size = Vector2(90, 24)
		btn.pressed.connect(_on_tab_pressed.bind(i))
		tabs_container.add_child(btn)


# ===========================================
# СЕКЦИЯ СУМКИ
# ===========================================

func _create_inventory_section(parent: Control):
	"""Создаёт секцию инвентаря"""
	var inv_panel = Panel.new()
	inv_panel.name = "InventorySection"
	
	# ═══════════════════════════════════════════════════════════════
	# РАЗМЕР ПАНЕЛИ СУМКИ
	# ═══════════════════════════════════════════════════════════════
	inv_panel.custom_minimum_size = Vector2(280, 0)
	
	_style_panel(inv_panel, Color(0.08, 0.08, 0.1, 0.8))
	parent.add_child(inv_panel)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Отступы внутри панели
	vbox.offset_left = 8
	vbox.offset_top = 8
	vbox.offset_right = -8
	vbox.offset_bottom = -8
	
	# Расстояние между элементами
	vbox.add_theme_constant_override("separation", 8)
	inv_panel.add_child(vbox)
	
	var inv_label = Label.new()
	inv_label.text = "🎒 Сумка"
	inv_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(inv_label)
	
	# Сетка слотов
	slots_grid = GridContainer.new()
	slots_grid.columns = GRID_COLUMNS
	slots_grid.add_theme_constant_override("h_separation", SLOT_SPACING)
	slots_grid.add_theme_constant_override("v_separation", SLOT_SPACING)
	vbox.add_child(slots_grid)
	
	# 20 слотов (4 ряда по 5)
	for i in range(20):
		var slot = _create_inventory_slot(i)
		slots_grid.add_child(slot)
		inventory_slots.append(slot)
	
	# Быстрые слоты
	_create_hotbar_section(vbox)


func _create_hotbar_section(parent: Control):
	"""Создаёт секцию быстрых слотов"""
	var sep = HSeparator.new()
	parent.add_child(sep)
	
	var label = Label.new()
	label.text = "⚡ Быстрые слоты [1-4]"
	label.add_theme_font_size_override("font_size", 12)
	parent.add_child(label)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	parent.add_child(hbox)
	
	for i in range(4):
		var slot = _create_hotbar_slot(i)
		hbox.add_child(slot)
		hotbar_slots.append(slot)


func _create_inventory_slot(index: int) -> InventorySlot:
	"""Создаёт слот инвентаря"""
	var slot = InventorySlot.new()
	slot.slot_index = index
	slot.custom_minimum_size = SLOT_SIZE  # Используем константу
	
	slot.slot_clicked.connect(_on_inventory_slot_clicked)
	slot.slot_right_clicked.connect(_on_inventory_slot_right_clicked)
	slot.slot_hovered.connect(_on_slot_hovered)
	slot.slot_unhovered.connect(_on_slot_unhovered)
	slot.item_dropped.connect(_on_inventory_item_dropped)
	
	return slot


func _create_hotbar_slot(index: int) -> InventorySlot:
	"""Создаёт быстрый слот с иконкой-подсказкой"""
	var slot = InventorySlot.new()
	slot.slot_index = index
	slot.is_hotbar_slot = true
	slot.hotbar_index = index  # Важно для обработки ПКМ
	slot.custom_minimum_size = SLOT_SIZE
	
	slot.slot_clicked.connect(_on_hotbar_slot_clicked)
	slot.slot_right_clicked.connect(_on_hotbar_slot_right_clicked)  # ПКМ
	slot.slot_hovered.connect(_on_slot_hovered)
	slot.slot_unhovered.connect(_on_slot_unhovered)
	slot.item_dropped.connect(_on_hotbar_item_dropped)
	
	# Номер клавиши (в углу)
	var key_label = Label.new()
	key_label.name = "KeyLabel"
	key_label.text = str(index + 1)
	key_label.add_theme_font_size_override("font_size", 10)
	key_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	key_label.position = Vector2(2, 2)
	key_label.z_index = 1  # Поверх иконки
	slot.add_child(key_label)
	
	# Иконка-подсказка (зелье/свиток) - серая, по центру
	var hint_label = Label.new()
	hint_label.name = "HintIcon"
	hint_label.text = HOTBAR_ICON  # 🧪
	hint_label.add_theme_font_size_override("font_size", 20)
	hint_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.5))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(hint_label)
	
	return slot


# ===========================================
# СЕКЦИЯ ЭКИПИРОВКИ (НОВЫЙ ЛЕЙАУТ v7.0)
# ===========================================

func _create_equipment_section(parent: Control):
	"""
	Создаёт секцию экипировки с новым лейаутом:
	
	Ряд 1:    [Серьга Л]  [Голова]   [Серьга П]
	Ряд 2:    [Наплечн]  [Ожерелье]  [Кулон]
	Ряд 3:    [Перчатки] [Нагрудник] [Наручи]
	Ряд 4:    [Оружие]    [Пояс]     [Щит/Орб]
	Ряд 5:    [Сапоги]   [Штаны]    [  пусто  ]
	─────────────────────────────────────────
	Ряд 6:    [Артеф 1] [Артеф 2] [Артеф 3] [Артеф 4]
	Ряд 7:    [Кольцо1] [Кольцо2] [Кольцо3] [Кольцо4]
	Ряд 8:           [  Реликвия  ]
	"""
	var equip_panel = Panel.new()
	equip_panel.name = "EquipmentSection"
	
	# ═══════════════════════════════════════════════════════════════
	# РАЗМЕР ПАНЕЛИ ЭКИПИРОВКИ (увеличен для 4 слотов артефактов/колец)
	# ═══════════════════════════════════════════════════════════════
	equip_panel.custom_minimum_size = Vector2(220, 0)
	
	_style_panel(equip_panel, Color(0.08, 0.08, 0.1, 0.8))
	parent.add_child(equip_panel)
	
	# ScrollContainer чтобы контент не выходил за рамки
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 8
	scroll.offset_top = 8
	scroll.offset_right = -8
	scroll.offset_bottom = -8
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	equip_panel.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(vbox)
	
	# Заголовок
	var equip_label = Label.new()
	equip_label.text = "⚔️ Экипировка"
	equip_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(equip_label)
	
	# === ОСНОВНАЯ СЕТКА ЭКИПИРОВКИ (5 рядов x 3 колонки) ===
	_create_main_equipment_grid(vbox)
	
	# Разделитель
	var sep1 = HSeparator.new()
	vbox.add_child(sep1)
	
	# === АРТЕФАКТЫ (4 слота) ===
	var art_label = Label.new()
	art_label.text = "✨ Артефакты"
	art_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(art_label)
	_create_artifact_row(vbox)
	
	# === КОЛЬЦА (4 слота) ===
	var ring_label = Label.new()
	ring_label.text = "💍 Кольца"
	ring_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(ring_label)
	_create_ring_row(vbox)
	
	# Разделитель
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)
	
	# === РЕЛИКВИЯ (1 слот с надписью) ===
	_create_relic_section(vbox)


func _create_main_equipment_grid(parent: Control):
	"""
	Создаёт основную сетку экипировки 3x5:
	
	[Серьга Л]  [Голова]   [Серьга П]
	[Наплечн]  [Ожерелье]  [Кулон]
	[Перчатки] [Нагрудник] [Наручи]
	[Оружие]    [Пояс]     [Щит/Орб]
	[Сапоги]   [Штаны]    [  пусто  ]
	"""
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	parent.add_child(grid)
	
	# Лейаут: [левый, центр, правый] для каждого ряда
	var equip_layout = [
		# Ряд 1: Серьги и голова
		InventoryEnums.EquipSlot.EARRING_1,
		InventoryEnums.EquipSlot.HEAD,
		InventoryEnums.EquipSlot.EARRING_2,
		
		# Ряд 2: Наплечники, ожерелье, кулон
		InventoryEnums.EquipSlot.SHOULDERS,
		InventoryEnums.EquipSlot.NECKLACE,
		InventoryEnums.EquipSlot.AMULET,
		
		# Ряд 3: Перчатки, нагрудник, наручи
		InventoryEnums.EquipSlot.HANDS,
		InventoryEnums.EquipSlot.BODY,
		InventoryEnums.EquipSlot.BRACERS,
		
		# Ряд 4: Оружие, пояс, щит
		InventoryEnums.EquipSlot.MAIN_HAND,
		InventoryEnums.EquipSlot.BELT,
		InventoryEnums.EquipSlot.OFF_HAND,
		
		# Ряд 5: Сапоги, штаны, пусто
		InventoryEnums.EquipSlot.FEET,
		InventoryEnums.EquipSlot.LEGS,
		InventoryEnums.EquipSlot.NONE,  # Пустой слот
	]
	
	for slot_type in equip_layout:
		if slot_type == InventoryEnums.EquipSlot.NONE:
			# Пустое место (spacer)
			var spacer = Control.new()
			spacer.custom_minimum_size = SLOT_SIZE
			grid.add_child(spacer)
		else:
			var slot = _create_equip_slot_with_icon(slot_type)
			grid.add_child(slot)


func _create_artifact_row(parent: Control):
	"""Создаёт ряд из 4 слотов артефактов"""
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(hbox)
	
	var artifact_slots = [
		InventoryEnums.EquipSlot.ARTIFACT_1,
		InventoryEnums.EquipSlot.ARTIFACT_2,
		InventoryEnums.EquipSlot.ARTIFACT_3,
		InventoryEnums.EquipSlot.ARTIFACT_4,
	]
	
	for slot_type in artifact_slots:
		var slot = _create_equip_slot_with_icon(slot_type)
		slot.custom_minimum_size = SMALL_SLOT_SIZE
		hbox.add_child(slot)


func _create_ring_row(parent: Control):
	"""Создаёт ряд из 4 слотов колец"""
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(hbox)
	
	var ring_slots = [
		InventoryEnums.EquipSlot.RING_1,
		InventoryEnums.EquipSlot.RING_2,
		InventoryEnums.EquipSlot.RING_3,
		InventoryEnums.EquipSlot.RING_4,
	]
	
	for slot_type in ring_slots:
		var slot = _create_equip_slot_with_icon(slot_type)
		slot.custom_minimum_size = SMALL_SLOT_SIZE
		hbox.add_child(slot)


func _create_relic_section(parent: Control):
	"""Создаёт секцию реликвии с надписью"""
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	parent.add_child(vbox)
	
	# Надпись "Реликвия"
	var label = Label.new()
	label.text = "🏆 Реликвия"
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	
	# Центрирование слота
	var center_box = HBoxContainer.new()
	center_box.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(center_box)
	
	# Слот реликвии (чуть больше обычного)
	var slot = _create_equip_slot_with_icon(InventoryEnums.EquipSlot.RELIC)
	slot.custom_minimum_size = Vector2(52, 52)
	center_box.add_child(slot)


func _create_equip_slot_with_icon(slot_type: InventoryEnums.EquipSlot) -> InventorySlot:
	"""
	Создаёт слот экипировки с иконкой-подсказкой.
	Иконка отображается серым цветом когда слот пустой.
	"""
	var slot = InventorySlot.new()
	slot.slot_type = slot_type
	slot.is_equipment_slot = true
	slot.custom_minimum_size = SLOT_SIZE
	
	# Подключаем сигналы
	slot.slot_clicked.connect(_on_equip_slot_clicked)
	slot.slot_right_clicked.connect(_on_equip_slot_right_clicked)
	slot.slot_hovered.connect(_on_slot_hovered)
	slot.slot_unhovered.connect(_on_slot_unhovered)
	slot.item_dropped.connect(_on_equip_item_dropped)
	
	# Сохраняем в словарь
	equipment_slots[slot_type] = slot
	
	# Добавляем иконку-подсказку (серую)
	_add_slot_hint_icon(slot, slot_type)
	
	return slot


func _add_slot_hint_icon(slot: InventorySlot, slot_type: InventoryEnums.EquipSlot):
	"""
	Добавляет иконку-подсказку на пустой слот.
	Иконка серая/белая и исчезает когда в слоте есть предмет.
	
	ИНСТРУКЦИЯ ПО ЗАМЕНЕ НА КАРТИНКИ:
	1. Создайте папку res://assets/ui/slot_icons/
	2. Положите туда PNG иконки (например: head.png, body.png, weapon.png)
	3. Раскомментируйте код с TextureRect ниже
	4. Закомментируйте код с Label (эмодзи)
	"""
	var icon_text = SLOT_ICONS.get(slot_type, "")
	if icon_text.is_empty():
		return
	
	# === ВАРИАНТ 1: ЭМОДЗИ (текущий) ===
	var hint_label = Label.new()
	hint_label.name = "HintIcon"
	hint_label.text = icon_text
	hint_label.add_theme_font_size_override("font_size", 20)
	hint_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))  # Серый
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(hint_label)
	
	# === ВАРИАНТ 2: КАРТИНКИ (раскомментируйте когда будут спрайты) ===
	# var icon_paths = {
	#     InventoryEnums.EquipSlot.HEAD: "res://assets/ui/slot_icons/head.png",
	#     InventoryEnums.EquipSlot.BODY: "res://assets/ui/slot_icons/body.png",
	#     # ... добавьте остальные пути
	# }
	# 
	# if icon_paths.has(slot_type):
	#     var hint_icon = TextureRect.new()
	#     hint_icon.name = "HintIcon"
	#     hint_icon.texture = load(icon_paths[slot_type])
	#     hint_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	#     hint_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	#     hint_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	#     hint_icon.offset_left = 8
	#     hint_icon.offset_top = 8
	#     hint_icon.offset_right = -8
	#     hint_icon.offset_bottom = -8
	#     hint_icon.modulate = Color(0.5, 0.5, 0.5, 0.6)  # Серый
	#     hint_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#     slot.add_child(hint_icon)


# ===========================================
# СЕКЦИЯ ПЕРСОНАЖА
# ===========================================

func _create_character_section(parent: Control):
	"""Создаёт секцию персонажа и характеристик"""
	var char_panel = Panel.new()
	char_panel.name = "CharacterSection"
	
	# ═══════════════════════════════════════════════════════════════
	# РАЗМЕР ПАНЕЛИ ПЕРСОНАЖА
	# ═══════════════════════════════════════════════════════════════
	char_panel.custom_minimum_size = Vector2(320, 0)
	char_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	_style_panel(char_panel, Color(0.08, 0.08, 0.1, 0.8))
	parent.add_child(char_panel)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 10
	vbox.offset_top = 8
	vbox.offset_right = -10
	vbox.offset_bottom = -8
	vbox.add_theme_constant_override("separation", 6)
	char_panel.add_child(vbox)
	
	# Заголовок
	var char_label = Label.new()
	char_label.text = "👤 Персонаж"
	char_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(char_label)
	
	# ═══════════════════════════════════════════════════════════════
	# ПАНЕЛЬ СПРАЙТА - МЕНЯЙ РАЗМЕР ЗДЕСЬ
	# ═══════════════════════════════════════════════════════════════
	var sprite_bg = Panel.new()
	sprite_bg.custom_minimum_size = Vector2(300, 150)  # Ширина x Высота
	_style_panel(sprite_bg, Color(0.05, 0.05, 0.07, 0.6))
	vbox.add_child(sprite_bg)
	
	var sprite_holder = Control.new()
	sprite_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	sprite_bg.add_child(sprite_holder)
	
	character_sprite = AnimatedSprite2D.new()
	character_sprite.name = "CharacterSprite"
	
	# ═══════════════════════════════════════════════════════════════
	# ПОЗИЦИЯ И МАСШТАБ СПРАЙТА
	# position.x = горизонтально (150 = центр панели 300/2)
	# position.y = вертикально (меньше = выше)
	# scale = размер спрайта
	# ═══════════════════════════════════════════════════════════════
	character_sprite.position = Vector2(150, 65)
	character_sprite.scale = Vector2(2.5, 2.5)
	
	sprite_holder.add_child(character_sprite)
	
	# Разделитель
	var sep1 = HSeparator.new()
	vbox.add_child(sep1)
	
	# Характеристики
	var stats_title = Label.new()
	stats_title.text = "📊 Характеристики"
	stats_title.add_theme_font_size_override("font_size", 12)
	vbox.add_child(stats_title)
	
	_create_main_stats(vbox)
	
	# Разделитель
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)
	
	# Сопротивления
	var resist_title = Label.new()
	resist_title.text = "🔮 Сопротивления"
	resist_title.add_theme_font_size_override("font_size", 11)
	resist_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(resist_title)
	
	_create_resistances(vbox)


func _create_main_stats(parent: Control):
	"""Создаёт основные характеристики"""
	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 3)
	parent.add_child(grid)
	
	var stats_config = [
		{"key": "health", "icon": "❤️", "label": "Здоровье", "color": Color(1.0, 0.4, 0.4)},
		{"key": "mana", "icon": "💙", "label": "Мана", "color": Color(0.4, 0.6, 1.0)},
		{"key": "attack", "icon": "⚔️", "label": "Атака", "color": Color(1.0, 0.8, 0.4)},
		{"key": "armor", "icon": "🛡️", "label": "Броня", "color": Color(0.6, 0.6, 0.7)},
		{"key": "speed", "icon": "👟", "label": "Скорость", "color": Color(0.5, 1.0, 0.5)},
		{"key": "crit", "icon": "💥", "label": "Крит", "color": Color(1.0, 0.6, 0.2)},
		{"key": "dodge", "icon": "💨", "label": "Уклонение", "color": Color(0.5, 0.8, 0.5)},
		{"key": "lifesteal", "icon": "🩸", "label": "Вампиризм", "color": Color(0.8, 0.2, 0.2)},
	]
	
	for stat in stats_config:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 2)
		
		var icon_label = Label.new()
		icon_label.text = stat.icon
		icon_label.add_theme_font_size_override("font_size", 11)
		hbox.add_child(icon_label)
		
		var name_label = Label.new()
		name_label.text = stat.label + ":"
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
		name_label.custom_minimum_size = Vector2(70, 0)
		hbox.add_child(name_label)
		
		grid.add_child(hbox)
		
		var value_label = Label.new()
		value_label.text = "0"
		value_label.add_theme_font_size_override("font_size", 11)
		value_label.add_theme_color_override("font_color", stat.color)
		value_label.custom_minimum_size = Vector2(50, 0)
		grid.add_child(value_label)
		
		stats_labels[stat.key] = value_label


func _create_resistances(parent: Control):
	"""Создаёт сопротивления"""
	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 2)
	parent.add_child(grid)
	
	var resist_config = [
		{"key": "fire_res", "label": "🔥Огонь:", "color": Color(1.0, 0.5, 0.2)},
		{"key": "cold_res", "label": "❄️Холод:", "color": Color(0.5, 0.8, 1.0)},
		{"key": "poison_res", "label": "☠️Яд:", "color": Color(0.5, 0.8, 0.3)},
		{"key": "madness_res", "label": "🌀Безумие:", "color": Color(0.8, 0.4, 0.8)},
		{"key": "bleed_res", "label": "💔Кровь:", "color": Color(0.8, 0.2, 0.2)},
	]
	
	for stat in resist_config:
		var name_lbl = Label.new()
		name_lbl.text = stat.label
		name_lbl.add_theme_font_size_override("font_size", 10)
		name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		grid.add_child(name_lbl)
		
		var val_lbl = Label.new()
		val_lbl.text = "0%"
		val_lbl.add_theme_font_size_override("font_size", 10)
		val_lbl.add_theme_color_override("font_color", stat.color)
		val_lbl.custom_minimum_size = Vector2(35, 0)
		grid.add_child(val_lbl)
		
		stats_labels[stat.key] = val_lbl


func _create_tooltip():
	"""Создаёт панель подсказки"""
	tooltip_panel = Panel.new()
	tooltip_panel.name = "Tooltip"
	tooltip_panel.custom_minimum_size = Vector2(220, 80)
	tooltip_panel.visible = false
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_panel(tooltip_panel, Color(0.08, 0.08, 0.1, 0.95))
	add_child(tooltip_panel)
	
	tooltip_label = RichTextLabel.new()
	tooltip_label.name = "TooltipText"
	tooltip_label.bbcode_enabled = true
	tooltip_label.fit_content = true
	tooltip_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	tooltip_label.offset_left = 8
	tooltip_label.offset_top = 8
	tooltip_label.offset_right = -8
	tooltip_label.offset_bottom = -8
	tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.add_child(tooltip_label)


func _style_panel(panel: Panel, color: Color):
	"""Стилизует панель"""
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.35, 0.25)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)


func _connect_signals():
	if Inventory:
		Inventory.inventory_changed.connect(_refresh_inventory)
		Inventory.equipment_changed.connect(_refresh_equipment)
		Inventory.hotbar_changed.connect(_on_hotbar_changed)


# ===========================================
# ОТКРЫТИЕ / ЗАКРЫТИЕ
# ===========================================

func show_inventory():
	if is_open:
		return
	
	is_open = true
	visible = true
	
	# === БЛОКИРУЕМ ИГРОКА ===
	if Global and Global.current_player:
		if Global.current_player.has_method("set_inventory_open"):
			Global.current_player.set_inventory_open(true)
		elif "is_inventory_open" in Global.current_player:
			Global.current_player.is_inventory_open = true
	
	_refresh_inventory()
	_refresh_equipment()
	_refresh_hotbar()
	_update_character_display()
	_update_stats_display()
	
	inventory_opened.emit()


func hide_inventory():
	if not is_open:
		return
	
	is_open = false
	visible = false
	tooltip_panel.visible = false
	
	# === РАЗБЛОКИРУЕМ ИГРОКА ===
	if Global and Global.current_player:
		if Global.current_player.has_method("set_inventory_open"):
			Global.current_player.set_inventory_open(false)
		elif "is_inventory_open" in Global.current_player:
			Global.current_player.is_inventory_open = false
	
	inventory_closed.emit()


func toggle_inventory():
	if is_open:
		hide_inventory()
	else:
		show_inventory()


# ===========================================
# ОБНОВЛЕНИЕ ОТОБРАЖЕНИЯ
# ===========================================

func _update_character_display():
	if not character_sprite:
		return
	
	var player = null
	if Global and Global.current_player:
		player = Global.current_player
	
	if not player:
		return
	
	var player_sprite = player.get_node_or_null("AnimatedSprite2D")
	if player_sprite and player_sprite.sprite_frames:
		character_sprite.sprite_frames = player_sprite.sprite_frames
		
		if character_sprite.sprite_frames.has_animation("idle"):
			character_sprite.play("idle")
		elif character_sprite.sprite_frames.has_animation("demonstration"):
			character_sprite.play("demonstration")
		else:
			var anims = character_sprite.sprite_frames.get_animation_names()
			if anims.size() > 0:
				character_sprite.play(anims[0])


func _update_stats_display():
	var player = null
	if Global and Global.current_player:
		player = Global.current_player
	
	if not player:
		return
	
	if stats_labels.has("health"):
		stats_labels["health"].text = "%d/%d" % [player.current_health, player.max_health]
	
	if stats_labels.has("mana"):
		stats_labels["mana"].text = "%d/%d" % [player.current_mana, player.max_mana]
	
	if stats_labels.has("armor"):
		stats_labels["armor"].text = str(player.armor)
	
	if stats_labels.has("speed"):
		var speed = player.current_speed if "current_speed" in player else 200
		stats_labels["speed"].text = str(speed)
	
	if stats_labels.has("attack"):
		var attack = 2
		if "BASE_DAMAGE" in player:
			attack = player.BASE_DAMAGE
		elif "base_damage" in player:
			attack = player.base_damage
		stats_labels["attack"].text = str(attack)
	
	if stats_labels.has("crit"):
		var crit = 0
		if "crit_chance" in player:
			crit = player.crit_chance
		stats_labels["crit"].text = "%d%%" % crit
	
	if stats_labels.has("dodge"):
		var dodge = 0
		if "dodge" in player:
			dodge = player.dodge
		stats_labels["dodge"].text = "%d%%" % dodge
	
	if stats_labels.has("lifesteal"):
		var lifesteal = 0
		if "lifesteal" in player:
			lifesteal = player.lifesteal
		stats_labels["lifesteal"].text = "%d%%" % lifesteal
	
	var resist_keys = ["fire_res", "cold_res", "poison_res", "madness_res", "bleed_res"]
	for key in resist_keys:
		if stats_labels.has(key):
			var value = 0
			if key in player:
				value = player.get(key)
			stats_labels[key].text = "%d%%" % value


# ===========================================
# ОБРАБОТКА ВВОДА
# ===========================================

func _input(event: InputEvent):
	if event.is_action_pressed("inventory"):
		toggle_inventory()
		get_viewport().set_input_as_handled()
		return
	
	if is_open and event.is_action_pressed("ui_cancel"):
		hide_inventory()
		get_viewport().set_input_as_handled()
		return


func _on_dimmer_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			hide_inventory()


func _on_tab_pressed(tab_index: int):
	current_tab = tab_index as Tab
	
	for i in range(tabs_container.get_child_count()):
		var btn = tabs_container.get_child(i) as Button
		if btn:
			btn.button_pressed = (i == tab_index)
	
	_refresh_inventory()


# ===========================================
# ОБНОВЛЕНИЕ СЛОТОВ
# ===========================================

func _refresh_inventory():
	if not Inventory:
		return
	
	for i in range(inventory_slots.size()):
		var slot = inventory_slots[i]
		var item = Inventory.get_item_at(i)
		
		if item and current_tab != Tab.ALL:
			var show = false
			match current_tab:
				Tab.EQUIPMENT:
					# Экипировка БЕЗ артефактов (артефакты в отдельной вкладке)
					show = item.is_equippable() and not item.is_artifact()
				Tab.ARTIFACTS:
					show = item.is_artifact()
				Tab.CONSUMABLES:
					show = item.is_usable()
			
			if not show:
				item = null
		
		slot.set_item(item)


func _refresh_equipment():
	if not Inventory:
		return
	
	for slot_type in equipment_slots:
		var slot = equipment_slots[slot_type]
		var item = Inventory.get_equipped_item(slot_type)
		slot.set_item(item)


func _refresh_hotbar():
	if not Inventory:
		return
	
	for i in range(hotbar_slots.size()):
		var slot = hotbar_slots[i]
		var item = Inventory.get_hotbar_item(i)
		slot.set_item(item)


func _on_hotbar_changed(_index: int):
	_refresh_hotbar()


# ===========================================
# ОБРАБОТКА КЛИКОВ
# ===========================================

func _on_inventory_slot_clicked(slot: InventorySlot, _button: int):
	pass


func _on_inventory_slot_right_clicked(slot: InventorySlot):
	if not slot.current_item:
		return
	
	var item = slot.current_item
	
	# === РАСХОДНИКИ: ПКМ = переместить в хотбар (НЕ использовать!) ===
	if item.is_usable():
		if Inventory:
			var result = Inventory.move_item_to_hotbar(slot.slot_index)
			if result >= 0:
				_refresh_inventory()
				_refresh_hotbar()
			# Если не удалось переместить - ничего не делаем
		return
	
	# === ЭКИПИРОВКА/АРТЕФАКТЫ: ПКМ = экипировать ===
	if item.is_equippable() or item.is_artifact():
		if Inventory.equip_item(slot.slot_index):
			_refresh_inventory()
			_refresh_equipment()
			_update_stats_display()


func _on_equip_slot_clicked(slot: InventorySlot, _button: int):
	pass


func _on_equip_slot_right_clicked(slot: InventorySlot):
	if slot.current_item and Inventory:
		Inventory.unequip_item(slot.slot_type)
		_refresh_inventory()
		_refresh_equipment()
		_update_stats_display()


func _on_hotbar_slot_clicked(slot: InventorySlot, _button: int):
	pass


func _on_hotbar_slot_right_clicked(slot: InventorySlot):
	"""ПКМ по слоту хотбара - возвращает расходник в инвентарь"""
	if not slot.current_item:
		return
	
	if Inventory:
		if Inventory.move_hotbar_to_inventory(slot.hotbar_index):
			_refresh_inventory()
			_refresh_hotbar()


# ===========================================
# DRAG & DROP
# ===========================================

func _on_inventory_item_dropped(from_slot: InventorySlot, to_slot: InventorySlot):
	if not Inventory:
		return
	
	# Перетаскивание из хотбара в инвентарь
	if from_slot.is_hotbar_slot and not to_slot.is_hotbar_slot:
		# Если целевой слот пуст - просто перемещаем
		if to_slot.current_item == null:
			var item = Inventory.hotbar_slots[from_slot.hotbar_index]
			if item:
				Inventory.inventory_slots[to_slot.slot_index] = item
				Inventory.hotbar_slots[from_slot.hotbar_index] = null
				Inventory.hotbar_changed.emit(from_slot.hotbar_index)
				Inventory.inventory_changed.emit()
		# Если занят расходником - меняем местами
		elif to_slot.current_item.is_usable():
			var hotbar_item = Inventory.hotbar_slots[from_slot.hotbar_index]
			var inv_item = Inventory.inventory_slots[to_slot.slot_index]
			Inventory.inventory_slots[to_slot.slot_index] = hotbar_item
			Inventory.hotbar_slots[from_slot.hotbar_index] = inv_item
			Inventory.hotbar_changed.emit(from_slot.hotbar_index)
			Inventory.inventory_changed.emit()
		_refresh_inventory()
		_refresh_hotbar()
		return
	
	# Обычное перемещение внутри инвентаря
	if from_slot.current_item:
		Inventory.move_item(from_slot.slot_index, to_slot.slot_index)
		_refresh_inventory()


func _on_equip_item_dropped(from_slot: InventorySlot, to_slot: InventorySlot):
	if not from_slot.current_item or not Inventory:
		return
	
	var item = from_slot.current_item
	
	if item.can_equip_in_slot(to_slot.slot_type):
		if not from_slot.is_equipment_slot:
			Inventory.equip_item(from_slot.slot_index, to_slot.slot_type)
		
		_refresh_inventory()
		_refresh_equipment()
		_update_stats_display()


func _on_hotbar_item_dropped(from_slot: InventorySlot, to_slot: InventorySlot):
	if not from_slot.current_item or not Inventory:
		return
	
	# Только расходники можно класть в хотбар
	if not from_slot.current_item.is_usable():
		return
	
	# Перетаскивание из инвентаря в хотбар
	if not from_slot.is_hotbar_slot and to_slot.is_hotbar_slot:
		Inventory.move_item_to_specific_hotbar_slot(from_slot.slot_index, to_slot.hotbar_index)
		_refresh_inventory()
		_refresh_hotbar()
	
	# Перетаскивание из хотбара в хотбар (обмен местами)
	elif from_slot.is_hotbar_slot and to_slot.is_hotbar_slot:
		var temp = Inventory.hotbar_slots[from_slot.hotbar_index]
		Inventory.hotbar_slots[from_slot.hotbar_index] = Inventory.hotbar_slots[to_slot.hotbar_index]
		Inventory.hotbar_slots[to_slot.hotbar_index] = temp
		Inventory.hotbar_changed.emit(from_slot.hotbar_index)
		Inventory.hotbar_changed.emit(to_slot.hotbar_index)
		_refresh_hotbar()


# ===========================================
# ПОДСКАЗКИ
# ===========================================

func _on_slot_hovered(slot: InventorySlot):
	if not slot.current_item:
		tooltip_panel.visible = false
		return
	
	tooltip_label.text = slot.current_item.generate_tooltip()
	tooltip_panel.visible = true
	
	var mouse_pos = get_viewport().get_mouse_position()
	tooltip_panel.position = mouse_pos + Vector2(15, 15)
	
	var viewport_size = get_viewport().get_visible_rect().size
	if tooltip_panel.position.x + tooltip_panel.size.x > viewport_size.x:
		tooltip_panel.position.x = mouse_pos.x - tooltip_panel.size.x - 15
	if tooltip_panel.position.y + tooltip_panel.size.y > viewport_size.y:
		tooltip_panel.position.y = mouse_pos.y - tooltip_panel.size.y - 15


func _on_slot_unhovered(_slot: InventorySlot):
	tooltip_panel.visible = false


func _process(_delta):
	if tooltip_panel.visible:
		var mouse_pos = get_viewport().get_mouse_position()
		tooltip_panel.position = mouse_pos + Vector2(15, 15)
	
	if is_open:
		_update_stats_display()


# ═══════════════════════════════════════════════════════════════════════════════
# ИНСТРУКЦИЯ: КАК ЗАМЕНИТЬ ЭМОДЗИ НА КАРТИНКИ
# ═══════════════════════════════════════════════════════════════════════════════
#
# Шаг 1: Создайте папку для иконок
#        res://assets/ui/slot_icons/
#
# Шаг 2: Подготовьте PNG иконки (рекомендуемый размер 32x32 или 48x48):
#        - head.png       (шлем)
#        - body.png       (нагрудник)
#        - legs.png       (штаны)
#        - feet.png       (сапоги)
#        - hands.png      (перчатки)
#        - shoulders.png  (наплечники)
#        - bracers.png    (наручи)
#        - belt.png       (пояс)
#        - weapon.png     (оружие)
#        - offhand.png    (щит/орб)
#        - necklace.png   (ожерелье)
#        - amulet.png     (кулон)
#        - earring.png    (серьга)
#        - ring.png       (кольцо)
#        - artifact.png   (артефакт)
#        - relic.png      (реликвия)
#        - potion.png     (зелье - для хотбара)
#
# Шаг 3: Замените константу SLOT_ICONS в начале файла на пути к картинкам:
#
#        const SLOT_ICON_PATHS = {
#            InventoryEnums.EquipSlot.HEAD: "res://assets/ui/slot_icons/head.png",
#            InventoryEnums.EquipSlot.BODY: "res://assets/ui/slot_icons/body.png",
#            # ... и так далее для всех слотов
#        }
#
# Шаг 4: В функции _add_slot_hint_icon() замените Label на TextureRect:
#        Раскомментируйте блок "ВАРИАНТ 2: КАРТИНКИ" и закомментируйте "ВАРИАНТ 1: ЭМОДЗИ"
#
# Шаг 5: Для хотбара - измените константу HOTBAR_ICON на путь к картинке
#        и обновите функцию _create_hotbar_slot() аналогично
#
# ═══════════════════════════════════════════════════════════════════════════════
