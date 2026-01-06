extends CanvasLayer

# ===========================================
# GAME UI v3.0 - КОМПАКТНЫЙ ИНТЕРФЕЙС
# ===========================================

# Контейнеры
var stats_container: VBoxContainer
var keys_container: HBoxContainer

# Элементы статов
var health_container: HBoxContainer
var health_icon: Label
var health_value: Label

var armor_container: HBoxContainer
var armor_icon: Label
var armor_value: Label

var mana_container: HBoxContainer
var mana_icon: Label
var mana_value: Label

# Ключи
var key_slots: Array = []

# Текущие характеристики
var current_stats = {
	"health": 12,
	"max_health": 12,
	"mana": 0,
	"max_mana": 0,
	"armor": 2
}

# Цвета ключей
# Цвета ключей - яркие и различимые
const KEY_COLORS = [
	Color(1.0, 0.2, 0.2, 1.0),    # Красный
	Color(0.2, 0.5, 1.0, 1.0),    # Синий
	Color(0.2, 0.9, 0.2, 1.0),    # Зелёный
	Color(1.0, 0.9, 0.0, 1.0),    # Жёлтый
	Color(0.8, 0.2, 0.8, 1.0),    # Фиолетовый
	Color(1.0, 0.5, 0.0, 1.0)     # Оранжевый
]

var viewport_size: Vector2 = Vector2.ZERO

func _ready():
	print("\n=== 🎮 GAME UI v3.0 ЗАГРУЖЕН ===")
	
	# Очищаем все дочерние узлы
	for child in get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Получаем размер окна
	viewport_size = get_viewport().get_visible_rect().size
	
	# Создаём UI программно
	_create_ui()
	
	print("✅ UI готов к работе")

func _process(_delta):
	# Обновляем позицию ключей при изменении размера окна
	var new_size = get_viewport().get_visible_rect().size
	if new_size != viewport_size:
		viewport_size = new_size
		_update_keys_position()

func _create_ui():
	"""Создаёт весь UI программно"""
	
	# === ЛЕВАЯ ПАНЕЛЬ (Статы) ===
	stats_container = VBoxContainer.new()
	stats_container.name = "StatsContainer"
	stats_container.position = Vector2(20, 20)
	stats_container.add_theme_constant_override("separation", 5)
	add_child(stats_container)
	
	# Здоровье
	health_container = _create_stat_row("❤️", "12/12", Color.RED)
	stats_container.add_child(health_container)
	health_icon = health_container.get_child(0)
	health_value = health_container.get_child(1)
	
	# Броня
	armor_container = _create_stat_row("🛡️", "2", Color.LIGHT_GRAY)
	stats_container.add_child(armor_container)
	armor_icon = armor_container.get_child(0)
	armor_value = armor_container.get_child(1)
	
	# Мана
	mana_container = _create_stat_row("💧", "0/0", Color.DODGER_BLUE)
	stats_container.add_child(mana_container)
	mana_icon = mana_container.get_child(0)
	mana_value = mana_container.get_child(1)
	mana_container.visible = false
	
	# === ПРАВАЯ ПАНЕЛЬ (Ключи) ===
	keys_container = HBoxContainer.new()
	keys_container.name = "KeysContainer"
	keys_container.add_theme_constant_override("separation", 15)
	add_child(keys_container)
	
	# Создаём 6 слотов ключей
	for i in range(6):
		var key_slot = _create_key_slot(i)
		keys_container.add_child(key_slot)
		key_slots.append(key_slot)
	
	# Позиционируем ключи
	_update_keys_position()

func _create_stat_row(icon_text: String, value_text: String, color: Color) -> HBoxContainer:
	"""Создаёт строку статов: иконка + значение"""
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	
	# Иконка
	var icon = Label.new()
	icon.text = icon_text
	icon.add_theme_font_size_override("font_size", 24)
	row.add_child(icon)
	
	# Значение
	var value = Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 20)
	value.add_theme_color_override("font_color", color)
	row.add_child(value)
	
	return row

func _create_key_slot(index: int) -> VBoxContainer:
	"""Создаёт слот для ключа"""
	var slot = VBoxContainer.new()
	slot.custom_minimum_size = Vector2(35, 50)
	
	# Иконка ключа - РАЗНЫЕ ЦВЕТА
	var icon = Label.new()
	icon.name = "Icon"
	icon.text = "🔑"
	icon.add_theme_font_size_override("font_size", 18)
	icon.add_theme_color_override("font_color", KEY_COLORS[index])  # Цвет по индексу
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot.add_child(icon)
	
	# Количество
	var count = Label.new()
	count.name = "Count"
	count.text = "0"
	count.add_theme_font_size_override("font_size", 14)
	count.add_theme_color_override("font_color", KEY_COLORS[index])  # Тот же цвет
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot.add_child(count)
	
	return slot

func _update_keys_position():
	"""Обновляет позицию ключей"""
	if keys_container:
		# Сдвигаем левее - было 300, стало 350
		keys_container.position = Vector2(viewport_size.x - 350, 20)

# ===========================================
# НАСТРОЙКА ДЛЯ ПЕРСОНАЖА
# ===========================================

func setup_character_ui(character_stats: Dictionary):
	"""Настраивает UI под характеристики персонажа"""
	print("\n=== 🔧 НАСТРОЙКА UI ДЛЯ ПЕРСОНАЖА ===")
	
	current_stats = character_stats.duplicate()
	
	_update_sections_visibility()
	update_ui_display()
	
	print("✅ UI настроен")
	print("  HP: ", current_stats["health"], "/", current_stats["max_health"])
	print("  MP: ", current_stats["mana"], "/", current_stats["max_mana"], " (видимо: ", mana_container.visible if mana_container else false, ")")
	print("  ARM: ", current_stats["armor"], " (видимо: ", armor_container.visible if armor_container else false, ")")

func _update_sections_visibility():
	"""Обновляет видимость секций"""
	
	if mana_container:
		mana_container.visible = current_stats["max_mana"] > 0
		if mana_container.visible:
			print("💙 Мана видима")
		else:
			print("🚫 Мана скрыта (max_mana = 0)")
	
	if armor_container:
		armor_container.visible = current_stats.get("armor", 0) > 0
		if armor_container.visible:
			print("🛡️ Броня видима")
		else:
			print("🚫 Броня скрыта")

# ===========================================
# ОБНОВЛЕНИЕ ОТОБРАЖЕНИЯ
# ===========================================

func update_ui_display():
	"""Обновляет все визуальные элементы"""
	
	if health_value:
		health_value.text = "%d/%d" % [current_stats["health"], current_stats["max_health"]]
	
	if mana_value and mana_container and mana_container.visible:
		mana_value.text = "%d/%d" % [current_stats["mana"], current_stats["max_mana"]]
	
	if armor_value and armor_container and armor_container.visible:
		armor_value.text = str(current_stats["armor"])

func update_health(new_health: int):
	"""Обновляет здоровье"""
	current_stats["health"] = clamp(new_health, 0, current_stats["max_health"])
	update_ui_display()
	print("❤️ HP обновлено: ", current_stats["health"], "/", current_stats["max_health"])

func update_mana(new_mana: int):
	"""Обновляет ману"""
	current_stats["mana"] = clamp(new_mana, 0, current_stats["max_mana"])
	update_ui_display()

func update_max_mana(new_max_mana: int):
	"""Изменяет максимальную ману"""
	current_stats["max_mana"] = max(0, new_max_mana)
	current_stats["mana"] = min(current_stats["mana"], current_stats["max_mana"])
	
	_update_sections_visibility()
	update_ui_display()

func update_armor(new_armor: int):
	"""Обновляет броню"""
	current_stats["armor"] = max(0, new_armor)
	_update_sections_visibility()
	update_ui_display()

func update_keys(key_counts: Array):
	"""Обновляет количество ключей"""
	for i in range(min(6, key_counts.size())):
		if i < key_slots.size():
			var count_label = key_slots[i].get_node_or_null("Count")
			if count_label:
				count_label.text = str(key_counts[i])

# ===========================================
# СПОСОБНОСТИ
# ===========================================

func update_ability_cooldown(_ability_id: String, _percent: float):
	"""Обновляет визуал кулдауна способности"""
	pass
