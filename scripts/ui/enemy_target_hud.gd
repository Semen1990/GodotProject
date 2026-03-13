extends PanelContainer

const PANEL_WIDTH := 212.0
const PANEL_HEIGHT := 90.0
const ICON_SIZE := Vector2(45, 45)
const BAR_WIDTH := 141.0
const BAR_HEIGHT := 15.0
const HEALTH_TRAIL_DELAY := 0.12
const HEALTH_TRAIL_SPEED := 42.0

var icon_rect: TextureRect = null
var health_trail_bar: ProgressBar = null
var health_bar: ProgressBar = null
var health_value_label: Label = null
var armor_container: HBoxContainer = null
var armor_value_label: Label = null
var status_effects_container: HBoxContainer = null
var status_effect_slots: Dictionary = {}
var status_effect_order: Array[String] = []

var current_snapshot: Dictionary = {}
var health_trail_target: float = 0.0
var health_trail_delay_timer: float = 0.0
var exact_health_visible: bool = false
var trimmed_icon_cache: Dictionary = {}


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	_build_ui()


func _process(delta: float) -> void:
	_update_health_damage_trail(delta)


func show_target(snapshot: Dictionary, show_exact_health: bool = false) -> void:
	exact_health_visible = show_exact_health
	visible = true
	update_target(snapshot, show_exact_health)


func update_target(snapshot: Dictionary, show_exact_health: bool = false) -> void:
	if snapshot.is_empty():
		hide_target()
		return

	exact_health_visible = show_exact_health
	current_snapshot = snapshot.duplicate(true)
	_update_icon()
	_update_health()
	_update_armor()
	_update_status_effects()


func hide_target() -> void:
	visible = false
	current_snapshot.clear()
	_clear_status_effects()


func _build_ui() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.12, 0.92)
	panel_style.border_color = Color(0.55, 0.22, 0.22, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", panel_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 7)
	add_child(margin)

	var main_row := HBoxContainer.new()
	main_row.add_theme_constant_override("separation", 8)
	margin.add_child(main_row)

	var icon_panel := PanelContainer.new()
	icon_panel.custom_minimum_size = ICON_SIZE
	var icon_panel_style := StyleBoxFlat.new()
	icon_panel_style.bg_color = Color(0.15, 0.14, 0.16, 0.95)
	icon_panel_style.border_color = Color(0.55, 0.22, 0.22, 0.95)
	icon_panel_style.set_border_width_all(2)
	icon_panel_style.set_corner_radius_all(6)
	icon_panel.add_theme_stylebox_override("panel", icon_panel_style)
	main_row.add_child(icon_panel)

	icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = ICON_SIZE - Vector2(6.0, 6.0)
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_panel.add_child(icon_rect)

	var info_column := VBoxContainer.new()
	info_column.add_theme_constant_override("separation", 5)
	main_row.add_child(info_column)

	var health_label := Label.new()
	health_label.text = "ЦЕЛЬ"
	health_label.add_theme_font_size_override("font_size", 11)
	health_label.add_theme_color_override("font_color", Color(0.95, 0.7, 0.7))
	info_column.add_child(health_label)

	var health_bar_holder := Control.new()
	health_bar_holder.custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	info_column.add_child(health_bar_holder)

	var health_bg := ColorRect.new()
	health_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	health_bg.color = Color(0.17, 0.08, 0.08, 0.95)
	health_bar_holder.add_child(health_bg)

	health_trail_bar = ProgressBar.new()
	health_trail_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	health_trail_bar.show_percentage = false
	health_trail_bar.max_value = 1
	health_trail_bar.value = 1
	var trail_fill := StyleBoxFlat.new()
	trail_fill.bg_color = Color(1.0, 0.94, 0.94, 0.88)
	trail_fill.set_corner_radius_all(4)
	var transparent_bg := StyleBoxFlat.new()
	transparent_bg.bg_color = Color(0, 0, 0, 0)
	transparent_bg.set_corner_radius_all(4)
	health_trail_bar.add_theme_stylebox_override("fill", trail_fill)
	health_trail_bar.add_theme_stylebox_override("background", transparent_bg)
	health_bar_holder.add_child(health_trail_bar)

	health_bar = ProgressBar.new()
	health_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	health_bar.show_percentage = false
	health_bar.max_value = 1
	health_bar.value = 1
	var health_fill := StyleBoxFlat.new()
	health_fill.bg_color = Color(0.8, 0.22, 0.24)
	health_fill.set_corner_radius_all(4)
	health_bar.add_theme_stylebox_override("fill", health_fill)
	health_bar.add_theme_stylebox_override("background", transparent_bg)
	health_bar_holder.add_child(health_bar)

	health_value_label = Label.new()
	health_value_label.visible = false
	health_value_label.set_anchors_preset(Control.PRESET_CENTER)
	health_value_label.position = Vector2(-22.0, -7.0)
	health_value_label.add_theme_font_size_override("font_size", 10)
	health_value_label.add_theme_color_override("font_color", Color.WHITE)
	health_bar_holder.add_child(health_value_label)

	armor_container = HBoxContainer.new()
	armor_container.add_theme_constant_override("separation", 6)
	armor_container.visible = false
	info_column.add_child(armor_container)

	var armor_icon := Label.new()
	armor_icon.text = "🛡"
	armor_icon.add_theme_font_size_override("font_size", 14)
	armor_icon.add_theme_color_override("font_color", Color(0.86, 0.88, 0.95))
	armor_container.add_child(armor_icon)

	armor_value_label = Label.new()
	armor_value_label.text = "0"
	armor_value_label.add_theme_font_size_override("font_size", 12)
	armor_value_label.add_theme_color_override("font_color", Color(0.86, 0.88, 0.95))
	armor_container.add_child(armor_value_label)

	status_effects_container = HBoxContainer.new()
	status_effects_container.add_theme_constant_override("separation", 8)
	status_effects_container.visible = false
	info_column.add_child(status_effects_container)


func _update_icon() -> void:
	if icon_rect == null:
		return
	var icon_texture: Texture2D = current_snapshot.get("icon_texture", null)
	icon_rect.texture = _get_trimmed_icon_texture(icon_texture)


func _update_health() -> void:
	if health_bar == null or health_trail_bar == null:
		return

	var max_health: int = max(1, int(current_snapshot.get("max_health", 1)))
	var health: int = clampi(int(current_snapshot.get("health", max_health)), 0, max_health)
	var previous_health: int = int(health_bar.value)

	health_bar.max_value = max_health
	health_bar.value = health
	health_trail_bar.max_value = max_health

	if health >= previous_health or health >= health_trail_bar.value:
		health_trail_bar.value = health
		health_trail_target = health
		health_trail_delay_timer = 0.0
	else:
		health_trail_target = health
		health_trail_delay_timer = HEALTH_TRAIL_DELAY

	if health_value_label != null:
		health_value_label.visible = exact_health_visible
		health_value_label.text = "%d / %d" % [health, max_health]


func _update_armor() -> void:
	if armor_container == null or armor_value_label == null:
		return

	var armor_value: int = max(0, int(current_snapshot.get("armor", 0)))
	armor_container.visible = armor_value > 0
	armor_value_label.text = str(armor_value)


func _update_status_effects() -> void:
	var effects: Array = current_snapshot.get("status_effects", [])
	_clear_status_effects()

	for effect_data in effects:
		if not (effect_data is Dictionary):
			continue
		var effect_id: String = String(effect_data.get("id", ""))
		var stacks: int = int(effect_data.get("stacks", 0))
		if effect_id.is_empty() or stacks <= 0:
			continue

		var icon_text: String = String(effect_data.get("icon", "•"))
		var color_variant: Variant = effect_data.get("color", Color.WHITE)
		var color: Color = color_variant if color_variant is Color else Color.WHITE
		var slot := _create_status_effect_slot(effect_id, icon_text, color, stacks)
		status_effect_slots[effect_id] = slot
		status_effect_order.append(effect_id)
		status_effects_container.add_child(slot)

	status_effects_container.visible = not status_effect_order.is_empty()


func _create_status_effect_slot(effect_id: String, icon_text: String, color: Color, stacks: int) -> HBoxContainer:
	var slot := HBoxContainer.new()
	slot.name = "%s_enemy_status" % effect_id
	slot.add_theme_constant_override("separation", 3)

	var icon_label := Label.new()
	icon_label.text = icon_text
	icon_label.add_theme_font_size_override("font_size", 12)
	icon_label.add_theme_color_override("font_color", color)
	slot.add_child(icon_label)

	var value_label := Label.new()
	value_label.text = str(stacks)
	value_label.add_theme_font_size_override("font_size", 10)
	value_label.add_theme_color_override("font_color", color)
	slot.add_child(value_label)

	return slot


func _clear_status_effects() -> void:
	for effect_id in status_effect_order:
		var slot: HBoxContainer = status_effect_slots.get(effect_id) as HBoxContainer
		if slot != null and is_instance_valid(slot):
			slot.queue_free()
	status_effect_slots.clear()
	status_effect_order.clear()
	if status_effects_container != null:
		status_effects_container.visible = false


func _update_health_damage_trail(delta: float) -> void:
	if health_trail_bar == null or not visible:
		return

	var current_health: float = float(health_bar.value)
	if health_trail_bar.value <= current_health:
		health_trail_bar.value = current_health
		health_trail_target = current_health
		return

	health_trail_target = current_health
	if health_trail_delay_timer > 0.0:
		health_trail_delay_timer = maxf(0.0, health_trail_delay_timer - delta)
		return

	var catchup_speed: float = maxf(HEALTH_TRAIL_SPEED, float(health_bar.max_value) * 0.65)
	health_trail_bar.value = move_toward(health_trail_bar.value, health_trail_target, catchup_speed * delta)


func _get_trimmed_icon_texture(texture: Texture2D) -> Texture2D:
	if texture == null:
		return null

	var cache_key: String = texture.resource_path
	if cache_key.is_empty():
		cache_key = str(texture.get_rid().get_id())

	if trimmed_icon_cache.has(cache_key):
		return trimmed_icon_cache[cache_key]

	var image: Image = texture.get_image()
	if image == null or image.is_empty():
		trimmed_icon_cache[cache_key] = texture
		return texture

	var used_rect: Rect2i = image.get_used_rect()
	if used_rect.size.x <= 0 or used_rect.size.y <= 0:
		trimmed_icon_cache[cache_key] = texture
		return texture

	if used_rect.position == Vector2i.ZERO and used_rect.size == image.get_size():
		trimmed_icon_cache[cache_key] = texture
		return texture

	var cropped_image: Image = Image.create(used_rect.size.x, used_rect.size.y, false, image.get_format())
	cropped_image.blit_rect(image, used_rect, Vector2i.ZERO)
	var cropped_texture: ImageTexture = ImageTexture.create_from_image(cropped_image)
	trimmed_icon_cache[cache_key] = cropped_texture
	return cropped_texture
