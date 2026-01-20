extends CanvasLayer
class_name InventoryUI
## Главное окно инвентаря v3.0
##
## Путь: res://scripts/inventory/ui/inventory_ui.gd
##
## НОВОЕ:
## - Спрайт персонажа с анимацией idle
## - Панель характеристик (атака, броня, HP, скорость и т.д.)
## - Исправлено использование зелий через ПКМ
## - Игра НЕ на паузе

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
const VISIBLE_ROWS = 4

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

# UI элементы
var main_panel: Panel
var tabs_container: HBoxContainer
var slots_grid: GridContainer
var tooltip_panel: Panel
var tooltip_label: RichTextLabel
var close_button: Button
var title_label: Label
var dimmer: ColorRect

# Спрайт персонажа
var character_sprite: AnimatedSprite2D
var character_panel: Panel

# Панель характеристик
var stats_panel: Panel
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
	
	print("📦 InventoryUI v3 создан")


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
	
	# === ГЛАВНАЯ ПАНЕЛЬ (увеличена для характеристик) ===
	main_panel = Panel.new()
	main_panel.name = "MainPanel"
	main_panel.custom_minimum_size = Vector2(900, 600)
	main_panel.set_anchors_preset(Control.PRESET_CENTER)
	main_panel.offset_left = -450
	main_panel.offset_top = -300
	main_panel.offset_right = 450
	main_panel.offset_bottom = 300
	main_panel.mouse_filter = Control.MOUSE_FILTER_STOP
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
	title_label.text = "📦 ИНВЕНТАРЬ"
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	
	close_button = Button.new()
	close_button.text = "✕"
	close_button.custom_minimum_size = Vector2(30, 30)
	close_button.add_theme_font_size_override("font_size", 18)
	close_button.pressed.connect(hide_inventory)
	header.add_child(close_button)
	
	# === ВКЛАДКИ ===
	_create_tabs()
	
	# === ОСНОВНОЙ КОНТЕНТ ===
	var content = HBoxContainer.new()
	content.name = "Content"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 15
	content.offset_top = 90
	content.offset_right = -15
	content.offset_bottom = -15
	content.add_theme_constant_override("separation", 15)
	main_panel.add_child(content)
	
	# Левая часть - инвентарь
	_create_inventory_section(content)
	
	# Средняя часть - экипировка
	_create_equipment_section(content)
	
	# Правая часть - персонаж и характеристики
	_create_character_section(content)
	
	# === ПОДСКАЗКА ===
	_create_tooltip()


func _create_tabs():
	"""Создаёт вкладки"""
	tabs_container = HBoxContainer.new()
	tabs_container.name = "Tabs"
	tabs_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tabs_container.offset_left = 15
	tabs_container.offset_top = 50
	tabs_container.offset_right = -15
	tabs_container.offset_bottom = 80
	tabs_container.add_theme_constant_override("separation", 5)
	main_panel.add_child(tabs_container)
	
	var tab_names = ["Все", "Экипировка", "Артефакты", "Расходники"]
	
	for i in range(tab_names.size()):
		var btn = Button.new()
		btn.text = tab_names[i]
		btn.toggle_mode = true
		btn.button_pressed = (i == 0)
		btn.custom_minimum_size = Vector2(100, 30)
		btn.pressed.connect(_on_tab_pressed.bind(i))
		tabs_container.add_child(btn)


func _create_inventory_section(parent: Control):
	"""Создаёт секцию инвентаря"""
	var inv_panel = Panel.new()
	inv_panel.name = "InventorySection"
	inv_panel.custom_minimum_size = Vector2(290, 0)
	_style_panel(inv_panel, Color(0.08, 0.08, 0.1, 0.8))
	parent.add_child(inv_panel)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 10
	vbox.offset_top = 10
	vbox.offset_right = -10
	vbox.offset_bottom = -10
	vbox.add_theme_constant_override("separation", 10)
	inv_panel.add_child(vbox)
	
	var inv_label = Label.new()
	inv_label.text = "🎒 Сумка"
	inv_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(inv_label)
	
	# Сетка слотов
	slots_grid = GridContainer.new()
	slots_grid.columns = GRID_COLUMNS
	slots_grid.add_theme_constant_override("h_separation", SLOT_SPACING)
	slots_grid.add_theme_constant_override("v_separation", SLOT_SPACING)
	vbox.add_child(slots_grid)
	
	# 20 слотов
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
	label.add_theme_font_size_override("font_size", 14)
	parent.add_child(label)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	parent.add_child(hbox)
	
	for i in range(4):
		var slot = _create_hotbar_slot(i)
		hbox.add_child(slot)
		hotbar_slots.append(slot)


func _create_inventory_slot(index: int) -> InventorySlot:
	"""Создаёт слот инвентаря"""
	var slot = InventorySlot.new()
	slot.slot_index = index
	slot.custom_minimum_size = SLOT_SIZE
	
	slot.slot_clicked.connect(_on_inventory_slot_clicked)
	slot.slot_right_clicked.connect(_on_inventory_slot_right_clicked)
	slot.slot_hovered.connect(_on_slot_hovered)
	slot.slot_unhovered.connect(_on_slot_unhovered)
	slot.item_dropped.connect(_on_inventory_item_dropped)
	
	return slot


func _create_hotbar_slot(index: int) -> InventorySlot:
	"""Создаёт быстрый слот"""
	var slot = InventorySlot.new()
	slot.slot_index = index
	slot.is_hotbar_slot = true
	slot.custom_minimum_size = SLOT_SIZE
	
	slot.slot_clicked.connect(_on_hotbar_slot_clicked)
	slot.slot_hovered.connect(_on_slot_hovered)
	slot.slot_unhovered.connect(_on_slot_unhovered)
	slot.item_dropped.connect(_on_hotbar_item_dropped)
	
	# Номер слота
	var key_label = Label.new()
	key_label.text = str(index + 1)
	key_label.add_theme_font_size_override("font_size", 10)
	key_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	key_label.position = Vector2(2, 2)
	slot.add_child(key_label)
	
	return slot


func _create_equipment_section(parent: Control):
	"""Создаёт секцию экипировки"""
	var equip_panel = Panel.new()
	equip_panel.name = "EquipmentSection"
	equip_panel.custom_minimum_size = Vector2(200, 0)
	_style_panel(equip_panel, Color(0.08, 0.08, 0.1, 0.8))
	parent.add_child(equip_panel)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 10
	vbox.offset_top = 10
	vbox.offset_right = -10
	vbox.offset_bottom = -10
	vbox.add_theme_constant_override("separation", 8)
	equip_panel.add_child(vbox)
	
	var equip_label = Label.new()
	equip_label.text = "⚔️ Экипировка"
	equip_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(equip_label)
	
	# Слоты экипировки (компактнее)
	_create_equipment_slots(vbox)
	
	# Артефакты
	var art_label = Label.new()
	art_label.text = "✨ Артефакты"
	art_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(art_label)
	
	_create_artifact_slots(vbox)
	
	# Кольца
	var ring_label = Label.new()
	ring_label.text = "💍 Кольца"
	ring_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(ring_label)
	
	_create_ring_slots(vbox)


func _create_equipment_slots(parent: Control):
	"""Создаёт сетку слотов экипировки"""
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	parent.add_child(grid)
	
	var equip_layout = [
		{"slot": InventoryEnums.EquipSlot.NECKLACE, "label": "📿"},
		{"slot": InventoryEnums.EquipSlot.HEAD, "label": "🪖"},
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
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(45, 45)
			grid.add_child(spacer)
		else:
			var slot = _create_equip_slot(data.slot, data.label)
			slot.custom_minimum_size = Vector2(45, 45)
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
		slot.custom_minimum_size = Vector2(40, 40)
		hbox.add_child(slot)


func _create_ring_slots(parent: Control):
	"""Создаёт слоты колец"""
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 3)
	parent.add_child(hbox)
	
	var ring_slots_data = [
		InventoryEnums.EquipSlot.RING_1,
		InventoryEnums.EquipSlot.RING_2,
		InventoryEnums.EquipSlot.RING_3,
		InventoryEnums.EquipSlot.RING_4,
	]
	
	for slot_type in ring_slots_data:
		var slot = _create_equip_slot(slot_type, "💍")
		slot.custom_minimum_size = Vector2(35, 35)
		hbox.add_child(slot)


func _create_equip_slot(slot_type: InventoryEnums.EquipSlot, label_text: String) -> InventorySlot:
	"""Создаёт один слот экипировки"""
	var slot = InventorySlot.new()
	slot.slot_type = slot_type
	slot.is_equipment_slot = true
	slot.custom_minimum_size = SLOT_SIZE
	
	slot.slot_clicked.connect(_on_equip_slot_clicked)
	slot.slot_right_clicked.connect(_on_equip_slot_right_clicked)
	slot.slot_hovered.connect(_on_slot_hovered)
	slot.slot_unhovered.connect(_on_slot_unhovered)
	slot.item_dropped.connect(_on_equip_item_dropped)
	
	equipment_slots[slot_type] = slot
	
	return slot


# ===========================================
# СЕКЦИЯ ПЕРСОНАЖА И ХАРАКТЕРИСТИК
# ===========================================

func _create_character_section(parent: Control):
	"""Создаёт секцию персонажа и характеристик"""
	character_panel = Panel.new()
	character_panel.name = "CharacterSection"
	character_panel.custom_minimum_size = Vector2(300, 0)
	character_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_panel(character_panel, Color(0.08, 0.08, 0.1, 0.8))
	parent.add_child(character_panel)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 10
	vbox.offset_top = 10
	vbox.offset_right = -10
	vbox.offset_bottom = -10
	vbox.add_theme_constant_override("separation", 10)
	character_panel.add_child(vbox)
	
	# Заголовок
	var char_label = Label.new()
	char_label.text = "👤 Персонаж"
	char_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(char_label)
	
	# Контейнер для спрайта
	var sprite_container = CenterContainer.new()
	sprite_container.custom_minimum_size = Vector2(0, 120)
	vbox.add_child(sprite_container)
	
	# Создаём AnimatedSprite2D для персонажа
	var sprite_holder = Control.new()
	sprite_holder.custom_minimum_size = Vector2(100, 100)
	sprite_container.add_child(sprite_holder)
	
	character_sprite = AnimatedSprite2D.new()
	character_sprite.name = "CharacterSprite"
	character_sprite.position = Vector2(50, 50)
	character_sprite.scale = Vector2(3, 3)  # Увеличиваем для видимости
	sprite_holder.add_child(character_sprite)
	
	# Разделитель
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# Заголовок характеристик
	var stats_title = Label.new()
	stats_title.text = "📊 Характеристики"
	stats_title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(stats_title)
	
	# Панель характеристик
	_create_stats_panel(vbox)


func _create_stats_panel(parent: Control):
	"""Создаёт панель характеристик"""
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 5)
	parent.add_child(grid)
	
	# Основные характеристики
	var stats_config = [
		{"key": "health", "icon": "❤️", "label": "Здоровье", "color": Color(1.0, 0.4, 0.4)},
		{"key": "mana", "icon": "💙", "label": "Мана", "color": Color(0.4, 0.6, 1.0)},
		{"key": "attack", "icon": "⚔️", "label": "Атака", "color": Color(1.0, 0.8, 0.4)},
		{"key": "armor", "icon": "🛡️", "label": "Броня", "color": Color(0.6, 0.6, 0.7)},
		{"key": "speed", "icon": "👟", "label": "Скорость", "color": Color(0.5, 1.0, 0.5)},
		{"key": "crit", "icon": "💥", "label": "Крит. шанс", "color": Color(1.0, 0.6, 0.2)},
	]
	
	for stat in stats_config:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 5)
		
		var icon_label = Label.new()
		icon_label.text = stat.icon
		icon_label.add_theme_font_size_override("font_size", 14)
		hbox.add_child(icon_label)
		
		var name_label = Label.new()
		name_label.text = stat.label + ":"
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		name_label.custom_minimum_size = Vector2(80, 0)
		hbox.add_child(name_label)
		
		grid.add_child(hbox)
		
		var value_label = Label.new()
		value_label.text = "0"
		value_label.add_theme_font_size_override("font_size", 12)
		value_label.add_theme_color_override("font_color", stat.color)
		grid.add_child(value_label)
		
		stats_labels[stat.key] = value_label
	
	# Разделитель
	var sep = HSeparator.new()
	parent.add_child(sep)
	
	# Дополнительные характеристики (по умолчанию 0)
	var extra_label = Label.new()
	extra_label.text = "🔮 Сопротивления"
	extra_label.add_theme_font_size_override("font_size", 12)
	extra_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	parent.add_child(extra_label)
	
	var extra_grid = GridContainer.new()
	extra_grid.columns = 2
	extra_grid.add_theme_constant_override("h_separation", 15)
	extra_grid.add_theme_constant_override("v_separation", 3)
	parent.add_child(extra_grid)
	
	var extra_stats = [
		{"key": "dodge", "label": "Уклонение", "color": Color(0.5, 0.8, 0.5)},
		{"key": "lifesteal", "label": "Вампиризм", "color": Color(0.8, 0.2, 0.2)},
		{"key": "fire_res", "label": "🔥 Огонь", "color": Color(1.0, 0.5, 0.2)},
		{"key": "cold_res", "label": "❄️ Холод", "color": Color(0.5, 0.8, 1.0)},
		{"key": "poison_res", "label": "☠️ Яд", "color": Color(0.5, 0.8, 0.3)},
		{"key": "madness_res", "label": "🌀 Безумие", "color": Color(0.8, 0.4, 0.8)},
		{"key": "bleed_res", "label": "🩸 Кровотечение", "color": Color(0.8, 0.2, 0.2)},
	]
	
	for stat in extra_stats:
		var name_lbl = Label.new()
		name_lbl.text = stat.label + ":"
		name_lbl.add_theme_font_size_override("font_size", 10)
		name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		extra_grid.add_child(name_lbl)
		
		var val_lbl = Label.new()
		val_lbl.text = "0%"
		val_lbl.add_theme_font_size_override("font_size", 10)
		val_lbl.add_theme_color_override("font_color", stat.color)
		extra_grid.add_child(val_lbl)
		
		stats_labels[stat.key] = val_lbl


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
	"""Стилизует панель"""
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.35, 0.25)
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
		Inventory.hotbar_changed.connect(_on_hotbar_changed)


# ===========================================
# ОТКРЫТИЕ / ЗАКРЫТИЕ
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
	_update_character_display()
	_update_stats_display()
	
	# НЕ ставим паузу!
	
	inventory_opened.emit()
	print("📦 Инвентарь открыт")


func hide_inventory():
	"""Закрывает инвентарь"""
	if not is_open:
		return
	
	is_open = false
	visible = false
	
	tooltip_panel.visible = false
	
	inventory_closed.emit()
	print("📦 Инвентарь закрыт")


func toggle_inventory():
	"""Переключает инвентарь"""
	if is_open:
		hide_inventory()
	else:
		show_inventory()


# ===========================================
# ОБНОВЛЕНИЕ ПЕРСОНАЖА И ХАРАКТЕРИСТИК
# ===========================================

func _update_character_display():
	"""Обновляет спрайт персонажа"""
	if not character_sprite:
		return
	
	# Получаем игрока из Global
	var player = null
	if Global and Global.current_player:
		player = Global.current_player
	
	if not player:
		return
	
	# Получаем AnimatedSprite2D игрока
	var player_sprite = player.get_node_or_null("AnimatedSprite2D")
	if player_sprite and player_sprite.sprite_frames:
		character_sprite.sprite_frames = player_sprite.sprite_frames
		
		# Пытаемся проиграть анимацию idle
		if character_sprite.sprite_frames.has_animation("idle"):
			character_sprite.play("idle")
		elif character_sprite.sprite_frames.has_animation("demonstration"):
			character_sprite.play("demonstration")
		else:
			# Берём первую доступную анимацию
			var anims = character_sprite.sprite_frames.get_animation_names()
			if anims.size() > 0:
				character_sprite.play(anims[0])


func _update_stats_display():
	"""Обновляет отображение характеристик"""
	var player = null
	if Global and Global.current_player:
		player = Global.current_player
	
	if not player:
		return
	
	# Основные характеристики
	if stats_labels.has("health"):
		var hp_text = "%d/%d" % [player.current_health, player.max_health]
		stats_labels["health"].text = hp_text
	
	if stats_labels.has("mana"):
		var mp_text = "%d/%d" % [player.current_mana, player.max_mana]
		stats_labels["mana"].text = mp_text
	
	if stats_labels.has("armor"):
		stats_labels["armor"].text = str(player.armor)
	
	if stats_labels.has("speed"):
		var speed = player.current_speed if "current_speed" in player else 200
		stats_labels["speed"].text = str(speed)
	
	# Атака - пытаемся получить из разных источников
	if stats_labels.has("attack"):
		var attack = 2  # Базовый урон
		if "BASE_DAMAGE" in player:
			attack = player.BASE_DAMAGE
		elif "base_damage" in player:
			attack = player.base_damage
		stats_labels["attack"].text = str(attack)
	
	# Крит шанс
	if stats_labels.has("crit"):
		var crit = 0
		if "crit_chance" in player:
			crit = player.crit_chance
		stats_labels["crit"].text = "%d%%" % crit
	
	# Дополнительные (по умолчанию 0)
	var extra_stats = ["dodge", "lifesteal", "fire_res", "cold_res", "poison_res", "madness_res", "bleed_res"]
	for stat_key in extra_stats:
		if stats_labels.has(stat_key):
			var value = 0
			if stat_key in player:
				value = player.get(stat_key)
			stats_labels[stat_key].text = "%d%%" % value


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


# ===========================================
# ВКЛАДКИ
# ===========================================

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
					show = item.is_equippable()
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

func _on_inventory_slot_clicked(slot: InventorySlot):
	print("📦 Клик по слоту %d" % slot.slot_index)


func _on_inventory_slot_right_clicked(slot: InventorySlot):
	"""Правый клик - использовать/экипировать"""
	if not slot.current_item:
		return
	
	var item = slot.current_item
	
	if item.is_usable():
		# ИСПРАВЛЕНО: Сначала проверяем можно ли использовать
		var item_id = item.get_item_id()
		
		if Inventory and Inventory.is_potion_used(item_id):
			print("⚠️ Это зелье уже использовано в этой комнате!")
			return
		
		# Отправляем сигнал (level1.gd применит эффекты)
		item_used.emit(item)
		
		# Уменьшаем количество ПОСЛЕ применения эффекта
		item.remove(1)
		
		if item.is_empty():
			Inventory.remove_item_at(slot.slot_index)
		
		_refresh_inventory()
		_refresh_hotbar()
		_update_stats_display()
	
	elif item.is_equippable() or item.is_artifact():
		if Inventory.equip_item(slot.slot_index):
			_refresh_inventory()
			_refresh_equipment()
			_update_stats_display()


func _on_equip_slot_clicked(slot: InventorySlot):
	print("⚔️ Клик по слоту экипировки: %s" % InventoryEnums.get_slot_name(slot.slot_type))


func _on_equip_slot_right_clicked(slot: InventorySlot):
	if slot.current_item and Inventory:
		Inventory.unequip_item(slot.slot_type)
		_refresh_inventory()
		_refresh_equipment()
		_update_stats_display()


func _on_hotbar_slot_clicked(slot: InventorySlot):
	print("⚡ Клик по быстрому слоту %d" % slot.slot_index)


# ===========================================
# DRAG & DROP
# ===========================================

func _on_inventory_item_dropped(from_slot: InventorySlot, to_slot: InventorySlot):
	if Inventory:
		Inventory.move_item(from_slot.slot_index, to_slot.slot_index)
		_refresh_inventory()


func _on_equip_item_dropped(from_slot: InventorySlot, to_slot: InventorySlot):
	if not from_slot.current_item or not Inventory:
		return
	
	var item = from_slot.current_item
	
	if item.can_equip_in_slot(to_slot.slot_type):
		if from_slot.is_equipment_slot:
			pass
		else:
			Inventory.equip_item(from_slot.slot_index, to_slot.slot_type)
		
		_refresh_inventory()
		_refresh_equipment()
		_update_stats_display()


func _on_hotbar_item_dropped(from_slot: InventorySlot, to_slot: InventorySlot):
	if not from_slot.current_item or not Inventory:
		return
	
	# В хотбар можно класть только расходники
	if from_slot.current_item.is_usable():
		Inventory.set_hotbar_item(to_slot.slot_index, from_slot.slot_index)
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
	
	# Обновляем статы периодически пока открыт инвентарь
	if is_open:
		_update_stats_display()
