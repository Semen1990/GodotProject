extends CanvasLayer

# ===========================================
# GAME UI v5.0 - СОЗДАЁТСЯ ПРОГРАММНО
# ===========================================

# Контейнеры
var main_container: MarginContainer
var stats_vbox: VBoxContainer
var keys_hbox: HBoxContainer

# Здоровье
var health_label: Label
var health_bar: ProgressBar

# Броня  
var armor_label: Label
var armor_value_label: Label
var armor_container: HBoxContainer

# Мана
var mana_label: Label
var mana_bar: ProgressBar
var mana_container: VBoxContainer

# Способность
var ability_button: Button
var ability_cooldown: ColorRect
var ability_label: Label

# Данные
var current_stats = {
	"health": 12,
	"max_health": 12,
	"mana": 0,
	"max_mana": 0,
	"armor": 2
}

var key_labels: Array = []

func _ready():
	print("\n=== 🎮 GAME UI v5.0 ===")
	_create_all_ui()
	print("✅ UI создан")

func _create_all_ui():
	"""Создаёт весь UI с нуля"""
	
	# === ЛЕВЫЙ ВЕРХНИЙ УГОЛ - СТАТЫ ===
	stats_vbox = VBoxContainer.new()
	stats_vbox.position = Vector2(20, 20)
	stats_vbox.add_theme_constant_override("separation", 10)
	add_child(stats_vbox)
	
	# Здоровье
	_create_health_ui()
	
	# Броня
	_create_armor_ui()
	
	# Мана
	_create_mana_ui()
	
	# === СПОСОБНОСТЬ ===
	_create_ability_ui()
	
	# === ПРАВЫЙ ВЕРХНИЙ УГОЛ - КЛЮЧИ ===
	_create_keys_ui()

func _create_health_ui():
	"""Создаёт UI здоровья"""
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)
	stats_vbox.add_child(container)
	
	health_label = Label.new()
	health_label.text = "❤️ ЗДОРОВЬЕ"
	health_label.add_theme_font_size_override("font_size", 16)
	health_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	container.add_child(health_label)
	
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(200, 20)
	health_bar.max_value = 12
	health_bar.value = 12
	health_bar.show_percentage = false
	
	# Стилизация
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.8, 0.2, 0.2)
	health_bar.add_theme_stylebox_override("fill", style)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.1, 0.1)
	health_bar.add_theme_stylebox_override("background", bg_style)
	
	container.add_child(health_bar)

func _create_armor_ui():
	"""Создаёт UI брони"""
	armor_container = HBoxContainer.new()
	armor_container.add_theme_constant_override("separation", 10)
	stats_vbox.add_child(armor_container)
	
	armor_label = Label.new()
	armor_label.text = "🛡️ БРОНЯ:"
	armor_label.add_theme_font_size_override("font_size", 16)
	armor_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	armor_container.add_child(armor_label)
	
	armor_value_label = Label.new()
	armor_value_label.text = "2"
	armor_value_label.add_theme_font_size_override("font_size", 18)
	armor_value_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	armor_container.add_child(armor_value_label)

func _create_mana_ui():
	"""Создаёт UI маны"""
	mana_container = VBoxContainer.new()
	mana_container.add_theme_constant_override("separation", 2)
	mana_container.visible = false  # Скрыта по умолчанию
	stats_vbox.add_child(mana_container)
	
	mana_label = Label.new()
	mana_label.text = "💧 МАНА"
	mana_label.add_theme_font_size_override("font_size", 16)
	mana_label.add_theme_color_override("font_color", Color(0.3, 0.5, 1.0))
	mana_container.add_child(mana_label)
	
	mana_bar = ProgressBar.new()
	mana_bar.custom_minimum_size = Vector2(200, 16)
	mana_bar.max_value = 10
	mana_bar.value = 10
	mana_bar.show_percentage = false
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.4, 0.9)
	mana_bar.add_theme_stylebox_override("fill", style)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.2)
	mana_bar.add_theme_stylebox_override("background", bg_style)
	
	mana_container.add_child(mana_bar)

func _create_ability_ui():
	"""Создаёт UI способности"""
	var ability_vbox = VBoxContainer.new()
	ability_vbox.position = Vector2(20, 160)
	add_child(ability_vbox)
	
	# Кнопка способности
	ability_button = Button.new()
	ability_button.custom_minimum_size = Vector2(50, 50)
	ability_button.text = "🛡️"
	ability_button.add_theme_font_size_override("font_size", 24)
	ability_vbox.add_child(ability_button)
	
	# Оверлей кулдауна
	ability_cooldown = ColorRect.new()
	ability_cooldown.color = Color(0, 0, 0, 0.7)
	ability_cooldown.custom_minimum_size = Vector2(50, 50)
	ability_cooldown.size = Vector2(50, 0)
	ability_cooldown.position = Vector2(0, 50)
	ability_cooldown.visible = false
	ability_cooldown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ability_button.add_child(ability_cooldown)
	
	# Хоткей
	ability_label = Label.new()
	ability_label.text = "[E]"
	ability_label.add_theme_font_size_override("font_size", 14)
	ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ability_vbox.add_child(ability_label)

func _create_keys_ui():
	"""Создаёт UI ключей"""
	keys_hbox = HBoxContainer.new()
	keys_hbox.add_theme_constant_override("separation", 15)
	add_child(keys_hbox)
	
	var colors = [
		Color(1.0, 0.2, 0.2),  # Красный
		Color(0.2, 0.5, 1.0),  # Синий
		Color(0.2, 0.9, 0.2),  # Зелёный
		Color(1.0, 0.9, 0.0),  # Жёлтый
		Color(0.8, 0.2, 0.8),  # Фиолетовый
		Color(1.0, 0.5, 0.0)   # Оранжевый
	]
	
	key_labels.clear()
	
	for i in range(6):
		var slot = VBoxContainer.new()
		slot.custom_minimum_size = Vector2(35, 50)
		
		var icon = Label.new()
		icon.text = "🔑"
		icon.add_theme_font_size_override("font_size", 18)
		icon.add_theme_color_override("font_color", colors[i])
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(icon)
		
		var count = Label.new()
		count.text = "0"
		count.add_theme_font_size_override("font_size", 14)
		count.add_theme_color_override("font_color", colors[i])
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(count)
		
		keys_hbox.add_child(slot)
		key_labels.append(count)
	
	# Позиционируем справа
	_update_keys_position()

func _update_keys_position():
	"""Позиционирует ключи в правом верхнем углу"""
	await get_tree().process_frame
	var viewport_size = get_viewport().get_visible_rect().size
	keys_hbox.position = Vector2(viewport_size.x - 320, 20)

func _process(_delta):
	# Обновляем позицию ключей при изменении размера окна
	if keys_hbox:
		var viewport_size = get_viewport().get_visible_rect().size
		var target_x = viewport_size.x - 320
		if abs(keys_hbox.position.x - target_x) > 10:
			keys_hbox.position.x = target_x

# ===========================================
# НАСТРОЙКА ПЕРСОНАЖА
# ===========================================

func setup_character_ui(stats: Dictionary):
	"""Настраивает UI под персонажа"""
	print("\n=== 🔧 НАСТРОЙКА UI ===")
	
	current_stats = stats.duplicate()
	
	# Здоровье
	if health_bar:
		health_bar.max_value = current_stats["max_health"]
		health_bar.value = current_stats["health"]
	
	# Броня
	if armor_container:
		armor_container.visible = current_stats.get("armor", 0) > 0
	if armor_value_label:
		armor_value_label.text = str(current_stats["armor"])
	
	# Мана
	if mana_container:
		mana_container.visible = current_stats["max_mana"] > 0
	if mana_bar:
		mana_bar.max_value = current_stats["max_mana"]
		mana_bar.value = current_stats["mana"]
	
	print("✅ HP:", current_stats["health"], "/", current_stats["max_health"])
	print("✅ ARM:", current_stats["armor"])
	print("✅ MP:", current_stats["mana"], "/", current_stats["max_mana"])

# ===========================================
# ОБНОВЛЕНИЕ
# ===========================================

func update_health(new_health: int):
	current_stats["health"] = clamp(new_health, 0, current_stats["max_health"])
	if health_bar:
		health_bar.value = current_stats["health"]
	print("❤️ HP:", current_stats["health"], "/", current_stats["max_health"])

func update_mana(new_mana: int):
	current_stats["mana"] = clamp(new_mana, 0, current_stats["max_mana"])
	if mana_bar:
		mana_bar.value = current_stats["mana"]

func update_max_mana(new_max: int):
	current_stats["max_mana"] = max(0, new_max)
	if mana_container:
		mana_container.visible = current_stats["max_mana"] > 0
	if mana_bar:
		mana_bar.max_value = current_stats["max_mana"]

func update_armor(new_armor: int):
	current_stats["armor"] = max(0, new_armor)
	if armor_container:
		armor_container.visible = current_stats["armor"] > 0
	if armor_value_label:
		armor_value_label.text = str(current_stats["armor"])

func update_keys(counts: Array):
	for i in range(min(6, counts.size())):
		if i < key_labels.size():
			key_labels[i].text = str(counts[i])

func update_ability_cooldown(_id: String, percent: float):
	"""Обновляет визуал кулдауна (0.0 = на кулдауне, 1.0 = готово)"""
	if not ability_cooldown:
		return
	
	if percent >= 1.0:
		ability_cooldown.visible = false
	else:
		ability_cooldown.visible = true
		# Заполняем снизу вверх
		var height = 50.0 * (1.0 - percent)
		ability_cooldown.size = Vector2(50, height)
		ability_cooldown.position = Vector2(0, 50 - height)
		
