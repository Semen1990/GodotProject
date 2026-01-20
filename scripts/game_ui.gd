extends CanvasLayer

# ===========================================
# GAME UI v6.0 - С ЦИФРОВЫМИ ЗНАЧЕНИЯМИ HP/MP
# ===========================================

# Контейнеры
var main_container: MarginContainer
var stats_vbox: VBoxContainer
var keys_hbox: HBoxContainer

# Здоровье
var health_container: VBoxContainer
var health_label: Label
var health_bar: ProgressBar
var health_value_label: Label  # НОВОЕ: Цифры внутри полоски

# Броня  
var armor_label: Label
var armor_value_label: Label
var armor_container: HBoxContainer

# Мана
var mana_label: Label
var mana_bar: ProgressBar
var mana_value_label: Label  # НОВОЕ: Цифры внутри полоски
var mana_container: VBoxContainer

# Способность
var ability_container: VBoxContainer
var ability_button: TextureRect
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
	print("\n=== 🎮 GAME UI v6.0 ===")
	_create_all_ui()
	print("✅ UI создан с цифровыми значениями HP/MP")

func _create_all_ui():
	"""Создаёт весь UI с нуля"""
	
	# === ЛЕВЫЙ ВЕРХНИЙ УГОЛ - СТАТЫ ===
	stats_vbox = VBoxContainer.new()
	stats_vbox.position = Vector2(20, 20)
	stats_vbox.add_theme_constant_override("separation", 8)
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
	"""Создаёт UI здоровья с цифрами внутри"""
	health_container = VBoxContainer.new()
	health_container.add_theme_constant_override("separation", 2)
	stats_vbox.add_child(health_container)
	
	# Заголовок
	health_label = Label.new()
	health_label.text = "❤️ ЗДОРОВЬЕ"
	health_label.add_theme_font_size_override("font_size", 14)
	health_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	health_container.add_child(health_label)
	
	# Контейнер для полоски с цифрами
	var bar_container = Control.new()
	bar_container.custom_minimum_size = Vector2(200, 24)
	health_container.add_child(bar_container)
	
	# Полоска здоровья
	health_bar = ProgressBar.new()
	health_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	health_bar.max_value = 12
	health_bar.value = 12
	health_bar.show_percentage = false
	
	# Стилизация полоски
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.85, 0.2, 0.2)
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	health_bar.add_theme_stylebox_override("fill", fill_style)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.1, 0.1)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	health_bar.add_theme_stylebox_override("background", bg_style)
	
	bar_container.add_child(health_bar)
	
	# === ЦИФРЫ ВНУТРИ ПОЛОСКИ ===
	health_value_label = Label.new()
	health_value_label.text = "12 / 12"
	health_value_label.set_anchors_preset(Control.PRESET_CENTER)
	health_value_label.position = Vector2(-30, -8)  # Центрируем
	health_value_label.add_theme_font_size_override("font_size", 14)
	health_value_label.add_theme_color_override("font_color", Color.WHITE)
	health_value_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	health_value_label.add_theme_constant_override("shadow_offset_x", 1)
	health_value_label.add_theme_constant_override("shadow_offset_y", 1)
	health_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bar_container.add_child(health_value_label)


func _create_armor_ui():
	"""Создаёт UI брони"""
	armor_container = HBoxContainer.new()
	armor_container.add_theme_constant_override("separation", 10)
	stats_vbox.add_child(armor_container)
	
	armor_label = Label.new()
	armor_label.text = "🛡️ БРОНЯ:"
	armor_label.add_theme_font_size_override("font_size", 14)
	armor_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	armor_container.add_child(armor_label)
	
	armor_value_label = Label.new()
	armor_value_label.text = "2"
	armor_value_label.add_theme_font_size_override("font_size", 16)
	armor_value_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	armor_container.add_child(armor_value_label)


func _create_mana_ui():
	"""Создаёт UI маны с цифрами внутри"""
	mana_container = VBoxContainer.new()
	mana_container.add_theme_constant_override("separation", 2)
	mana_container.visible = false  # Скрыта по умолчанию
	stats_vbox.add_child(mana_container)
	
	# Заголовок
	mana_label = Label.new()
	mana_label.text = "💧 МАНА"
	mana_label.add_theme_font_size_override("font_size", 14)
	mana_label.add_theme_color_override("font_color", Color(0.4, 0.6, 1.0))
	mana_container.add_child(mana_label)
	
	# Контейнер для полоски с цифрами
	var bar_container = Control.new()
	bar_container.custom_minimum_size = Vector2(200, 20)
	mana_container.add_child(bar_container)
	
	# Полоска маны
	mana_bar = ProgressBar.new()
	mana_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	mana_bar.max_value = 10
	mana_bar.value = 10
	mana_bar.show_percentage = false
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.2, 0.4, 0.9)
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	mana_bar.add_theme_stylebox_override("fill", fill_style)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.25)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	mana_bar.add_theme_stylebox_override("background", bg_style)
	
	bar_container.add_child(mana_bar)
	
	# === ЦИФРЫ ВНУТРИ ПОЛОСКИ ===
	mana_value_label = Label.new()
	mana_value_label.text = "10 / 10"
	mana_value_label.set_anchors_preset(Control.PRESET_CENTER)
	mana_value_label.position = Vector2(-25, -7)
	mana_value_label.add_theme_font_size_override("font_size", 12)
	mana_value_label.add_theme_color_override("font_color", Color.WHITE)
	mana_value_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	mana_value_label.add_theme_constant_override("shadow_offset_x", 1)
	mana_value_label.add_theme_constant_override("shadow_offset_y", 1)
	mana_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bar_container.add_child(mana_value_label)


func _create_ability_ui():
	"""Создаёт UI способности с иконкой из файла"""
	ability_container = VBoxContainer.new()
	ability_container.position = Vector2(20, 150)
	add_child(ability_container)
	
	var icon_panel = PanelContainer.new()
	icon_panel.custom_minimum_size = Vector2(54, 54)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	panel_style.border_color = Color(0.6, 0.6, 0.7)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(4)
	icon_panel.add_theme_stylebox_override("panel", panel_style)
	ability_container.add_child(icon_panel)
	
	ability_button = TextureRect.new()
	ability_button.custom_minimum_size = Vector2(50, 50)
	ability_button.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	ability_button.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var icon_path = "res://assets/Spell/shield_defence.png"
	if ResourceLoader.exists(icon_path):
		var icon_texture = load(icon_path)
		ability_button.texture = icon_texture
	else:
		_create_fallback_ability_icon()
	
	icon_panel.add_child(ability_button)
	
	ability_cooldown = ColorRect.new()
	ability_cooldown.color = Color(0, 0, 0, 0.7)
	ability_cooldown.custom_minimum_size = Vector2(50, 50)
	ability_cooldown.size = Vector2(50, 0)
	ability_cooldown.position = Vector2(2, 52)
	ability_cooldown.visible = false
	ability_cooldown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_panel.add_child(ability_cooldown)
	
	ability_label = Label.new()
	ability_label.text = "[RMB]"
	ability_label.add_theme_font_size_override("font_size", 12)
	ability_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ability_container.add_child(ability_label)


func _create_fallback_ability_icon():
	"""Создаёт запасную иконку"""
	var image = Image.create(50, 50, false, Image.FORMAT_RGBA8)
	
	for x in range(50):
		for y in range(50):
			var color = Color(0.3, 0.4, 0.6, 0.0)
			var center_x = 25
			var in_shield = false
			
			if y < 35:
				if x >= 8 and x <= 42:
					in_shield = true
			else:
				var width = 42 - 8
				var progress = float(y - 35) / 15.0
				var half_width = (width / 2) * (1.0 - progress)
				if x >= center_x - half_width and x <= center_x + half_width:
					in_shield = true
			
			if in_shield:
				color = Color(0.4, 0.5, 0.7, 1.0)
				if x < 20 and y < 25:
					color = color.lightened(0.2)
	
			image.set_pixel(x, y, color)
	
	var texture = ImageTexture.create_from_image(image)
	ability_button.texture = texture


func _create_keys_ui():
	"""Создаёт UI ключей"""
	keys_hbox = HBoxContainer.new()
	keys_hbox.add_theme_constant_override("separation", 15)
	add_child(keys_hbox)
	
	var colors = [
		Color(1.0, 0.2, 0.2),
		Color(0.2, 0.5, 1.0),
		Color(0.2, 0.9, 0.2),
		Color(1.0, 0.9, 0.0),
		Color(0.8, 0.2, 0.8),
		Color(1.0, 0.5, 0.0)
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
	
	_update_keys_position()


func _update_keys_position():
	await get_tree().process_frame
	var viewport_size = get_viewport().get_visible_rect().size
	keys_hbox.position = Vector2(viewport_size.x - 320, 20)


func _process(_delta):
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
	
	# Обновляем цифры HP
	_update_health_text()
	
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
	
	# Обновляем цифры маны
	_update_mana_text()
	
	print("✅ HP:", current_stats["health"], "/", current_stats["max_health"])
	print("✅ ARM:", current_stats["armor"])
	print("✅ MP:", current_stats["mana"], "/", current_stats["max_mana"])


# ===========================================
# ОБНОВЛЕНИЕ ЦИФРОВЫХ ЗНАЧЕНИЙ
# ===========================================

func _update_health_text():
	"""Обновляет текст здоровья"""
	if health_value_label:
		health_value_label.text = "%d / %d" % [current_stats["health"], current_stats["max_health"]]


func _update_mana_text():
	"""Обновляет текст маны"""
	if mana_value_label:
		mana_value_label.text = "%d / %d" % [current_stats["mana"], current_stats["max_mana"]]


# ===========================================
# СМЕНА ИКОНКИ СПОСОБНОСТИ
# ===========================================

func set_ability_icon(icon_path: String):
	if ability_button and ResourceLoader.exists(icon_path):
		var texture = load(icon_path)
		ability_button.texture = texture


func set_ability_hotkey(hotkey_text: String):
	if ability_label:
		ability_label.text = hotkey_text


# ===========================================
# ОБНОВЛЕНИЕ СТАТОВ
# ===========================================

func update_health(new_health: int):
	current_stats["health"] = clamp(new_health, 0, current_stats["max_health"])
	if health_bar:
		health_bar.value = current_stats["health"]
	_update_health_text()
	print("❤️ HP:", current_stats["health"], "/", current_stats["max_health"])


func update_max_health(new_max: int):
	"""Обновляет максимальное здоровье"""
	current_stats["max_health"] = max(1, new_max)
	if health_bar:
		health_bar.max_value = current_stats["max_health"]
	_update_health_text()


func update_mana(new_mana: int):
	current_stats["mana"] = clamp(new_mana, 0, current_stats["max_mana"])
	if mana_bar:
		mana_bar.value = current_stats["mana"]
	_update_mana_text()


func update_max_mana(new_max: int):
	current_stats["max_mana"] = max(0, new_max)
	if mana_container:
		mana_container.visible = current_stats["max_mana"] > 0
	if mana_bar:
		mana_bar.max_value = current_stats["max_mana"]
	_update_mana_text()


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
	if not ability_cooldown:
		return
	
	if percent >= 1.0:
		ability_cooldown.visible = false
	else:
		ability_cooldown.visible = true
		var height = 50.0 * (1.0 - percent)
		ability_cooldown.size = Vector2(50, height)
		ability_cooldown.position = Vector2(2, 52 - height)
