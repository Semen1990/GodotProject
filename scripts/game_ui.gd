extends CanvasLayer

# ===========================================
# GAME UI v7.2 - БЕЗ ПРОВЕРКИ ДУБЛИКАТОВ
# ===========================================

var stats_vbox: VBoxContainer
var keys_hbox: HBoxContainer

var health_container: VBoxContainer
var health_bar: ProgressBar
var health_value_label: Label

var armor_container: HBoxContainer
var armor_value_label: Label

var mana_container: VBoxContainer
var mana_bar: ProgressBar
var mana_value_label: Label

var ability_container: VBoxContainer
var ability_button: TextureRect
var ability_cooldown: ColorRect
var ability_label: Label

var current_stats = {
	"health": 12,
	"max_health": 12,
	"mana": 0,
	"max_mana": 0,
	"armor": 2
}

var key_labels: Array = []
var key_icons: Array = []


func _ready():
	print("\n=== 🎮 GAME UI v7.2 ===")
	_create_all_ui()
	print("✅ UI создан")


func _exit_tree():
	print("🗑️ GameUI удалён")


func _create_all_ui():
	# === ЛЕВЫЙ ВЕРХНИЙ УГОЛ - СТАТЫ ===
	stats_vbox = VBoxContainer.new()
	stats_vbox.position = Vector2(20, 20)
	stats_vbox.add_theme_constant_override("separation", 8)
	add_child(stats_vbox)
	
	_create_health_ui()
	_create_armor_ui()
	_create_mana_ui()
	_create_ability_ui()
	_create_keys_ui()


func _create_health_ui():
	health_container = VBoxContainer.new()
	health_container.add_theme_constant_override("separation", 2)
	stats_vbox.add_child(health_container)
	
	var health_label = Label.new()
	health_label.text = "❤️ ЗДОРОВЬЕ"
	health_label.add_theme_font_size_override("font_size", 14)
	health_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	health_container.add_child(health_label)
	
	var bar_container = Control.new()
	bar_container.custom_minimum_size = Vector2(200, 24)
	health_container.add_child(bar_container)
	
	health_bar = ProgressBar.new()
	health_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	health_bar.max_value = 12
	health_bar.value = 12
	health_bar.show_percentage = false
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.85, 0.2, 0.2)
	fill_style.set_corner_radius_all(4)
	health_bar.add_theme_stylebox_override("fill", fill_style)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.1, 0.1)
	bg_style.set_corner_radius_all(4)
	health_bar.add_theme_stylebox_override("background", bg_style)
	
	bar_container.add_child(health_bar)
	
	health_value_label = Label.new()
	health_value_label.text = "12 / 12"
	health_value_label.set_anchors_preset(Control.PRESET_CENTER)
	health_value_label.position = Vector2(-30, -8)
	health_value_label.add_theme_font_size_override("font_size", 14)
	health_value_label.add_theme_color_override("font_color", Color.WHITE)
	bar_container.add_child(health_value_label)


func _create_armor_ui():
	armor_container = HBoxContainer.new()
	armor_container.add_theme_constant_override("separation", 10)
	stats_vbox.add_child(armor_container)
	
	var armor_label = Label.new()
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
	mana_container = VBoxContainer.new()
	mana_container.add_theme_constant_override("separation", 2)
	mana_container.visible = false
	stats_vbox.add_child(mana_container)
	
	var mana_label = Label.new()
	mana_label.text = "💧 МАНА"
	mana_label.add_theme_font_size_override("font_size", 14)
	mana_label.add_theme_color_override("font_color", Color(0.4, 0.6, 1.0))
	mana_container.add_child(mana_label)
	
	var bar_container = Control.new()
	bar_container.custom_minimum_size = Vector2(200, 20)
	mana_container.add_child(bar_container)
	
	mana_bar = ProgressBar.new()
	mana_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	mana_bar.max_value = 10
	mana_bar.value = 10
	mana_bar.show_percentage = false
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.2, 0.4, 0.9)
	fill_style.set_corner_radius_all(4)
	mana_bar.add_theme_stylebox_override("fill", fill_style)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.25)
	bg_style.set_corner_radius_all(4)
	mana_bar.add_theme_stylebox_override("background", bg_style)
	
	bar_container.add_child(mana_bar)
	
	mana_value_label = Label.new()
	mana_value_label.text = "10 / 10"
	mana_value_label.set_anchors_preset(Control.PRESET_CENTER)
	mana_value_label.position = Vector2(-25, -7)
	mana_value_label.add_theme_font_size_override("font_size", 12)
	mana_value_label.add_theme_color_override("font_color", Color.WHITE)
	bar_container.add_child(mana_value_label)


func _create_ability_ui():
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
		ability_button.texture = load(icon_path)
	
	icon_panel.add_child(ability_button)
	
	ability_cooldown = ColorRect.new()
	ability_cooldown.color = Color(0, 0, 0, 0.7)
	ability_cooldown.visible = false
	icon_panel.add_child(ability_cooldown)
	
	ability_label = Label.new()
	ability_label.text = "[RMB]"
	ability_label.add_theme_font_size_override("font_size", 12)
	ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ability_container.add_child(ability_label)


func _create_keys_ui():
	"""Создаёт UI ключей с ПРАВИЛЬНЫМИ цветами"""
	keys_hbox = HBoxContainer.new()
	keys_hbox.add_theme_constant_override("separation", 12)
	add_child(keys_hbox)
	
	# === ПОРЯДОК ЦВЕТОВ СООТВЕТСТВУЕТ KeyPickup.KeyColor ===
	# 0 - GOLD, 1 - SILVER, 2 - RED, 3 - BLUE, 4 - GREEN, 5 - PURPLE
	var key_colors = [
		Color(1.0, 0.85, 0.0),    # 0: GOLD - Золотой
		Color(0.75, 0.75, 0.85),  # 1: SILVER - Серебряный
		Color(1.0, 0.25, 0.25),   # 2: RED - Красный
		Color(0.3, 0.5, 1.0),     # 3: BLUE - Синий
		Color(0.3, 0.85, 0.3),    # 4: GREEN - Зелёный
		Color(0.75, 0.3, 0.9),    # 5: PURPLE - Фиолетовый
	]
	
	key_labels.clear()
	key_icons.clear()
	
	for i in range(6):
		var slot = VBoxContainer.new()
		slot.custom_minimum_size = Vector2(35, 50)
		slot.add_theme_constant_override("separation", 2)
		
		# Иконка ключа
		var icon = Label.new()
		icon.text = "🔑"
		icon.add_theme_font_size_override("font_size", 20)
		icon.add_theme_color_override("font_color", key_colors[i])
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(icon)
		key_icons.append(icon)
		
		# Счётчик
		var count = Label.new()
		count.text = "0"
		count.add_theme_font_size_override("font_size", 14)
		count.add_theme_color_override("font_color", key_colors[i])
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(count)
		key_labels.append(count)
		
		keys_hbox.add_child(slot)
	
	_update_keys_position()


func _update_keys_position():
	await get_tree().process_frame
	var viewport_size = get_viewport().get_visible_rect().size
	keys_hbox.position = Vector2(viewport_size.x - 280, 20)


func _process(_delta):
	if keys_hbox:
		var viewport_size = get_viewport().get_visible_rect().size
		var target_x = viewport_size.x - 280
		if abs(keys_hbox.position.x - target_x) > 10:
			keys_hbox.position.x = target_x


# ===========================================
# НАСТРОЙКА И ОБНОВЛЕНИЕ
# ===========================================

func setup_character_ui(stats: Dictionary):
	print("\n=== 🔧 НАСТРОЙКА UI ===")
	
	current_stats = stats.duplicate()
	
	if health_bar:
		health_bar.max_value = current_stats["max_health"]
		health_bar.value = current_stats["health"]
	_update_health_text()
	
	if armor_container:
		armor_container.visible = current_stats.get("armor", 0) > 0
	if armor_value_label:
		armor_value_label.text = str(current_stats["armor"])
	
	if mana_container:
		mana_container.visible = current_stats["max_mana"] > 0
	if mana_bar:
		mana_bar.max_value = current_stats["max_mana"]
		mana_bar.value = current_stats["mana"]
	_update_mana_text()
	
	# Обновляем ключи из Global
	_update_keys_from_global()
	
	print("✅ HP:%d/%d" % [current_stats["health"], current_stats["max_health"]])
	print("✅ ARM:%d" % current_stats["armor"])
	print("✅ MP:%d/%d" % [current_stats["mana"], current_stats["max_mana"]])


func _update_health_text():
	if health_value_label:
		health_value_label.text = "%d / %d" % [current_stats["health"], current_stats["max_health"]]


func _update_mana_text():
	if mana_value_label:
		mana_value_label.text = "%d / %d" % [current_stats["mana"], current_stats["max_mana"]]


func _update_keys_from_global():
	"""Обновляет счётчики ключей из Global"""
	if not Global:
		return
	
	if Global.has_method("get_keys_array"):
		var keys_array = Global.get_keys_array()
		update_keys(keys_array)
	elif "keys" in Global and Global.keys is Dictionary:
		var keys_array = []
		for i in range(6):
			keys_array.append(Global.keys.get(i, 0))
		update_keys(keys_array)


# ===========================================
# ОБНОВЛЕНИЕ СТАТОВ
# ===========================================

func update_health(new_health: int):
	current_stats["health"] = clamp(new_health, 0, current_stats["max_health"])
	if health_bar:
		health_bar.value = current_stats["health"]
	_update_health_text()
	print("❤️ HP:%d/%d" % [current_stats["health"], current_stats["max_health"]])


func update_max_health(new_max: int):
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
	"""Обновляет счётчики ключей
	counts[0] = золотые, counts[1] = серебряные, и т.д.
	"""
	for i in range(min(6, counts.size())):
		if i < key_labels.size():
			key_labels[i].text = str(counts[i])
			
			# Подсветка если есть ключи
			if counts[i] > 0:
				key_icons[i].modulate = Color(1.2, 1.2, 1.2)  # Ярче
			else:
				key_icons[i].modulate = Color(0.5, 0.5, 0.5)  # Тусклее


func update_single_key(color_index: int, count: int):
	"""Обновляет счётчик одного типа ключа"""
	if color_index >= 0 and color_index < key_labels.size():
		key_labels[color_index].text = str(count)
		
		if count > 0:
			key_icons[color_index].modulate = Color(1.2, 1.2, 1.2)
		else:
			key_icons[color_index].modulate = Color(0.5, 0.5, 0.5)


func set_ability_icon(icon_path: String):
	if ability_button and ResourceLoader.exists(icon_path):
		ability_button.texture = load(icon_path)


func set_ability_hotkey(hotkey_text: String):
	if ability_label:
		ability_label.text = hotkey_text


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
