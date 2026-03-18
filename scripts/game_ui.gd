extends CanvasLayer

const ENEMY_TARGET_HUD_SCENE := preload("res://scenes/Ui/enemy_target_hud.tscn")

var stats_vbox: VBoxContainer
var keys_hbox: HBoxContainer
var enemy_target_hud: PanelContainer

var health_container: VBoxContainer
var health_bg: ColorRect
var health_trail_bar: ProgressBar
var health_bar: ProgressBar
var health_barrier_bar: ProgressBar
var health_value_label: Label

var armor_container: HBoxContainer
var armor_value_label: Label

var status_effects_container: HBoxContainer
var status_effect_slots: Dictionary = {}
var status_effect_order: Array[String] = []

var mana_container: VBoxContainer
var mana_bar: ProgressBar
var mana_value_label: Label

var ability_container: HBoxContainer
var ability_slots: Dictionary = {}
var ability_button: TextureRect
var ability_cooldown: ColorRect
var ability_label: Label

var current_stats: Dictionary = {
	"health": 12,
	"max_health": 12,
	"mana": 0,
	"max_mana": 0,
	"armor": 2,
	"madness": 0,
	"max_madness": 9,
}

var key_labels: Array[Label] = []
var key_icons: Array[TextureRect] = []
var health_trail_target: float = 12.0
var health_trail_delay_timer: float = 0.0
const HEALTH_TRAIL_DELAY := 0.12
const HEALTH_TRAIL_SPEED := 48.0
const ABILITY_PANEL_SIZE := Vector2(56, 56)
const KEY_SLOT_SIZE := Vector2(46, 66)
const KEY_ICON_SIZE := Vector2(36, 36)
const KEY_ICON_PATHS: Array[String] = [
	"res://assets/items/keys_game/gold/frame_00.png",
	"res://assets/items/keys_game/silver/frame_00.png",
	"res://assets/items/keys_game/red/frame_00.png",
	"res://assets/items/keys_game/blue/frame_00.png",
	"res://assets/items/keys_game/green/frame_00.png",
	"res://assets/items/keys_game/purple/frame_00.png",
]
var key_colors: Array[Color] = [
	Color(1.0, 0.85, 0.0),
	Color(0.75, 0.75, 0.85),
	Color(1.0, 0.25, 0.25),
	Color(0.3, 0.5, 1.0),
	Color(0.3, 0.85, 0.3),
	Color(0.75, 0.3, 0.9),
]


func _ready() -> void:
	rebuild_ui()


func _exit_tree() -> void:
	if Global and Global.game_ui == self:
		Global.unregister_game_ui()


func rebuild_ui() -> void:
	_clear_runtime_ui()
	_create_all_ui()


func _clear_runtime_ui() -> void:
	for child in get_children():
		remove_child(child)
		child.free()

	stats_vbox = null
	keys_hbox = null
	enemy_target_hud = null
	health_container = null
	health_bg = null
	health_trail_bar = null
	health_bar = null
	health_barrier_bar = null
	health_value_label = null
	armor_container = null
	armor_value_label = null
	status_effects_container = null
	status_effect_slots.clear()
	status_effect_order.clear()
	mana_container = null
	mana_bar = null
	mana_value_label = null
	ability_container = null
	ability_slots.clear()
	ability_button = null
	ability_cooldown = null
	ability_label = null
	key_labels.clear()
	key_icons.clear()
	health_trail_target = current_stats.get("health", 12)
	health_trail_delay_timer = 0.0


func _create_all_ui() -> void:
	stats_vbox = VBoxContainer.new()
	stats_vbox.position = Vector2(20, 20)
	stats_vbox.add_theme_constant_override("separation", 8)
	add_child(stats_vbox)

	_create_health_ui()
	_create_armor_ui()
	_create_status_effects_ui()
	_create_mana_ui()
	_create_ability_ui()
	_create_keys_ui()
	_create_enemy_target_ui()


func _create_health_ui() -> void:
	health_container = VBoxContainer.new()
	health_container.add_theme_constant_override("separation", 2)
	stats_vbox.add_child(health_container)

	var health_label: Label = Label.new()
	health_label.text = "ЗДОРОВЬЕ"
	health_label.add_theme_font_size_override("font_size", 14)
	health_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	health_container.add_child(health_label)

	var bar_container: Control = Control.new()
	bar_container.custom_minimum_size = Vector2(200, 24)
	health_container.add_child(bar_container)

	health_bg = ColorRect.new()
	health_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	health_bg.color = Color(0.17, 0.08, 0.08, 0.95)
	bar_container.add_child(health_bg)

	health_trail_bar = ProgressBar.new()
	health_trail_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	health_trail_bar.max_value = 12
	health_trail_bar.value = 12
	health_trail_bar.show_percentage = false
	var trail_fill_style: StyleBoxFlat = StyleBoxFlat.new()
	trail_fill_style.bg_color = Color(1.0, 0.94, 0.94, 0.9)
	trail_fill_style.set_corner_radius_all(4)
	var transparent_bg_style: StyleBoxFlat = StyleBoxFlat.new()
	transparent_bg_style.bg_color = Color(0, 0, 0, 0)
	transparent_bg_style.set_corner_radius_all(4)
	health_trail_bar.add_theme_stylebox_override("fill", trail_fill_style)
	health_trail_bar.add_theme_stylebox_override("background", transparent_bg_style)
	bar_container.add_child(health_trail_bar)

	health_bar = ProgressBar.new()
	health_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	health_bar.max_value = 12
	health_bar.value = 12
	health_bar.show_percentage = false

	var fill_style: StyleBoxFlat = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.87, 0.18, 0.2)
	fill_style.set_corner_radius_all(4)
	health_bar.add_theme_stylebox_override("fill", fill_style)
	health_bar.add_theme_stylebox_override("background", transparent_bg_style)

	bar_container.add_child(health_bar)

	health_barrier_bar = ProgressBar.new()
	health_barrier_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	health_barrier_bar.max_value = 12
	health_barrier_bar.value = 0
	health_barrier_bar.show_percentage = false
	var barrier_fill_style: StyleBoxFlat = StyleBoxFlat.new()
	barrier_fill_style.bg_color = Color(0.24, 0.66, 1.0, 0.82)
	barrier_fill_style.set_corner_radius_all(4)
	health_barrier_bar.add_theme_stylebox_override("fill", barrier_fill_style)
	health_barrier_bar.add_theme_stylebox_override("background", transparent_bg_style)
	bar_container.add_child(health_barrier_bar)

	health_value_label = Label.new()
	health_value_label.text = "12 / 12"
	health_value_label.set_anchors_preset(Control.PRESET_CENTER)
	health_value_label.position = Vector2(-30, -8)
	health_value_label.add_theme_font_size_override("font_size", 14)
	health_value_label.add_theme_color_override("font_color", Color.WHITE)
	bar_container.add_child(health_value_label)


func _create_armor_ui() -> void:
	armor_container = HBoxContainer.new()
	armor_container.add_theme_constant_override("separation", 10)
	stats_vbox.add_child(armor_container)

	var armor_label: Label = Label.new()
	armor_label.text = "БРОНЯ:"
	armor_label.add_theme_font_size_override("font_size", 14)
	armor_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	armor_container.add_child(armor_label)

	armor_value_label = Label.new()
	armor_value_label.text = "2"
	armor_value_label.add_theme_font_size_override("font_size", 16)
	armor_value_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	armor_container.add_child(armor_value_label)


func _create_status_effects_ui() -> void:
	status_effects_container = HBoxContainer.new()
	status_effects_container.add_theme_constant_override("separation", 10)
	status_effects_container.visible = false
	stats_vbox.add_child(status_effects_container)


func _create_mana_ui() -> void:
	mana_container = VBoxContainer.new()
	mana_container.add_theme_constant_override("separation", 2)
	mana_container.visible = false
	stats_vbox.add_child(mana_container)

	var mana_label: Label = Label.new()
	mana_label.text = "МАНА"
	mana_label.add_theme_font_size_override("font_size", 14)
	mana_label.add_theme_color_override("font_color", Color(0.4, 0.6, 1.0))
	mana_container.add_child(mana_label)

	var bar_container: Control = Control.new()
	bar_container.custom_minimum_size = Vector2(200, 20)
	mana_container.add_child(bar_container)

	mana_bar = ProgressBar.new()
	mana_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	mana_bar.max_value = 10
	mana_bar.value = 10
	mana_bar.show_percentage = false

	var fill_style: StyleBoxFlat = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.2, 0.4, 0.9)
	fill_style.set_corner_radius_all(4)
	mana_bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style: StyleBoxFlat = StyleBoxFlat.new()
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


func _create_ability_ui() -> void:
	ability_container = HBoxContainer.new()
	ability_container.add_theme_constant_override("separation", 10)
	stats_vbox.add_child(ability_container)

	var block_slot: Dictionary = _create_ability_slot("block", "Блок", "E", "res://assets/Spell/shield_defence.png")
	var slide_slot: Dictionary = _create_ability_slot("slide", "Подкат", "ПКМ", "res://assets/Spell/Icon43.png")
	var ability_q_slot: Dictionary = _create_ability_slot("ability_q", "", "", "")
	var ability_r_slot: Dictionary = _create_ability_slot("ability_r", "", "", "")
	ability_slots["block"] = block_slot
	ability_slots["slide"] = slide_slot
	ability_slots["ability_q"] = ability_q_slot
	ability_slots["ability_r"] = ability_r_slot

	var q_root: VBoxContainer = ability_q_slot.get("root")
	if q_root != null:
		q_root.visible = false

	var r_root: VBoxContainer = ability_r_slot.get("root")
	if r_root != null:
		r_root.visible = false

	# Совместимость со старым кодом, который знает только один слот способности.
	ability_button = block_slot.get("icon")
	ability_cooldown = block_slot.get("cooldown")
	ability_label = block_slot.get("hotkey")


func _create_ability_slot(slot_id: String, title_text: String, hotkey_text: String, icon_path: String) -> Dictionary:
	var slot_box := VBoxContainer.new()
	slot_box.name = "%s_ability_slot" % slot_id
	slot_box.add_theme_constant_override("separation", 2)
	ability_container.add_child(slot_box)

	var icon_panel := PanelContainer.new()
	icon_panel.custom_minimum_size = ABILITY_PANEL_SIZE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.13, 0.18, 0.95)
	panel_style.border_color = Color(0.58, 0.62, 0.74, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(6)
	icon_panel.add_theme_stylebox_override("panel", panel_style)
	slot_box.add_child(icon_panel)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(50, 50)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	icon_panel.add_child(icon)

	var cooldown := ColorRect.new()
	cooldown.color = Color(0.0, 0.0, 0.0, 0.72)
	cooldown.visible = false
	icon_panel.add_child(cooldown)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.92, 0.94, 1.0))
	slot_box.add_child(title)

	var hotkey := Label.new()
	hotkey.text = hotkey_text
	hotkey.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hotkey.add_theme_font_size_override("font_size", 11)
	hotkey.add_theme_color_override("font_color", Color(0.68, 0.76, 0.9))
	slot_box.add_child(hotkey)

	return {
		"root": slot_box,
		"panel": icon_panel,
		"icon": icon,
		"cooldown": cooldown,
		"title": title,
		"hotkey": hotkey,
	}


func _create_keys_ui() -> void:
	keys_hbox = HBoxContainer.new()
	keys_hbox.add_theme_constant_override("separation", 12)
	add_child(keys_hbox)

	key_labels.clear()
	key_icons.clear()

	for i in range(6):
		var slot: VBoxContainer = VBoxContainer.new()
		slot.custom_minimum_size = KEY_SLOT_SIZE
		slot.add_theme_constant_override("separation", 2)

		var icon: TextureRect = TextureRect.new()
		icon.custom_minimum_size = KEY_ICON_SIZE
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if i < KEY_ICON_PATHS.size() and ResourceLoader.exists(KEY_ICON_PATHS[i]):
			icon.texture = load(KEY_ICON_PATHS[i]) as Texture2D
		slot.add_child(icon)
		key_icons.append(icon)

		var count: Label = Label.new()
		count.text = "0"
		count.add_theme_font_size_override("font_size", 14)
		count.add_theme_color_override("font_color", key_colors[i])
		count.add_theme_color_override("font_shadow_color", Color(0.08, 0.08, 0.08, 0.9))
		count.add_theme_constant_override("shadow_offset_x", 1)
		count.add_theme_constant_override("shadow_offset_y", 1)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(count)
		key_labels.append(count)

		keys_hbox.add_child(slot)
		_update_key_visual(i, 0)

	_update_keys_position()


func _update_keys_position() -> void:
	await get_tree().process_frame
	if not keys_hbox:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	keys_hbox.position = Vector2(viewport_size.x - 280, 20)
	_update_enemy_target_position()


func _create_enemy_target_ui() -> void:
	if ENEMY_TARGET_HUD_SCENE == null:
		return

	enemy_target_hud = ENEMY_TARGET_HUD_SCENE.instantiate() as PanelContainer
	if enemy_target_hud == null:
		return

	enemy_target_hud.visible = false
	add_child(enemy_target_hud)
	_update_enemy_target_position()


func _update_enemy_target_position() -> void:
	if enemy_target_hud == null or keys_hbox == null:
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var hud_size: Vector2 = enemy_target_hud.size
	if hud_size.x <= 0.0 or hud_size.y <= 0.0:
		hud_size = enemy_target_hud.get_combined_minimum_size()

	var key_height: float = maxf(keys_hbox.size.y, keys_hbox.get_combined_minimum_size().y)
	var key_width: float = maxf(keys_hbox.size.x, keys_hbox.get_combined_minimum_size().x)
	var right_edge: float = keys_hbox.position.x + key_width
	var target_x: float = right_edge - hud_size.x
	target_x = clampf(target_x, 20.0, viewport_size.x - hud_size.x - 20.0)
	enemy_target_hud.position = Vector2(
		target_x,
		keys_hbox.position.y + key_height + 14.0
	)


func _process(_delta: float) -> void:
	_update_health_damage_trail(_delta)
	if keys_hbox:
		var viewport_size: Vector2 = get_viewport().get_visible_rect().size
		var target_x: float = viewport_size.x - 280
		if absf(keys_hbox.position.x - target_x) > 10.0:
			keys_hbox.position.x = target_x
	_update_enemy_target_position()


func setup_character_ui(stats: Dictionary) -> void:
	current_stats = stats.duplicate()

	if health_bar:
		health_bar.max_value = current_stats["max_health"]
		health_bar.value = current_stats["health"]
	if health_barrier_bar:
		health_barrier_bar.max_value = current_stats["max_health"]
		health_barrier_bar.value = 0
	if health_trail_bar:
		health_trail_bar.max_value = current_stats["max_health"]
		health_trail_bar.value = current_stats["health"]
	health_trail_target = current_stats["health"]
	health_trail_delay_timer = 0.0
	_update_health_text()

	if armor_container:
		armor_container.visible = current_stats.get("armor", 0) > 0
	if armor_value_label:
		armor_value_label.text = str(current_stats["armor"])

	update_madness(current_stats.get("madness", 0), current_stats.get("max_madness", 9))

	if mana_container:
		mana_container.visible = current_stats["max_mana"] > 0
	if mana_bar:
		mana_bar.max_value = current_stats["max_mana"]
		mana_bar.value = current_stats["mana"]
	_update_mana_text()
	_update_keys_from_global()


func _update_health_text() -> void:
	if health_value_label:
		health_value_label.text = "%d / %d" % [current_stats["health"], current_stats["max_health"]]


func _update_mana_text() -> void:
	if mana_value_label:
		mana_value_label.text = "%d / %d" % [current_stats["mana"], current_stats["max_mana"]]


func _update_keys_from_global() -> void:
	if not Global:
		return

	if Global.has_method("get_keys_array"):
		update_keys(Global.get_keys_array())
	elif "keys" in Global and Global.keys is Dictionary:
		var keys_array: Array = []
		for i in range(6):
			keys_array.append(Global.keys.get(i, 0))
		update_keys(keys_array)


func update_health(new_health: int) -> void:
	var previous_health: int = int(current_stats.get("health", new_health))
	current_stats["health"] = clamp(new_health, 0, current_stats["max_health"])
	if health_bar:
		health_bar.value = current_stats["health"]
	if health_barrier_bar:
		health_barrier_bar.max_value = current_stats["max_health"]
		health_barrier_bar.value = clamp(health_barrier_bar.value, 0.0, float(current_stats["health"]))
	if health_trail_bar:
		if current_stats["health"] >= previous_health or current_stats["health"] >= health_trail_bar.value:
			health_trail_bar.value = current_stats["health"]
			health_trail_delay_timer = 0.0
		else:
			health_trail_target = current_stats["health"]
			health_trail_delay_timer = HEALTH_TRAIL_DELAY
	_update_health_text()


func update_max_health(new_max: int) -> void:
	current_stats["max_health"] = max(1, new_max)
	if health_bar:
		health_bar.max_value = current_stats["max_health"]
		health_bar.value = clamp(health_bar.value, 0.0, float(current_stats["max_health"]))
	if health_barrier_bar:
		health_barrier_bar.max_value = current_stats["max_health"]
		health_barrier_bar.value = clamp(health_barrier_bar.value, 0.0, float(current_stats["max_health"]))
	if health_trail_bar:
		health_trail_bar.max_value = current_stats["max_health"]
		health_trail_bar.value = clamp(health_trail_bar.value, 0.0, float(current_stats["max_health"]))
	health_trail_target = clampf(health_trail_target, 0.0, float(current_stats["max_health"]))
	_update_health_text()


func _update_health_damage_trail(delta: float) -> void:
	if health_trail_bar == null:
		return

	var target_value: float = float(current_stats.get("health", 0))
	if health_trail_bar.value <= target_value:
		health_trail_bar.value = target_value
		health_trail_target = target_value
		return

	health_trail_target = target_value
	if health_trail_delay_timer > 0.0:
		health_trail_delay_timer = maxf(0.0, health_trail_delay_timer - delta)
		return

	var catchup_speed: float = maxf(HEALTH_TRAIL_SPEED, float(current_stats.get("max_health", 0)) * 0.65)
	health_trail_bar.value = move_toward(health_trail_bar.value, health_trail_target, catchup_speed * delta)


func update_mana(new_mana: int) -> void:
	current_stats["mana"] = clamp(new_mana, 0, current_stats["max_mana"])
	if mana_bar:
		mana_bar.value = current_stats["mana"]
	_update_mana_text()


func update_max_mana(new_max: int) -> void:
	current_stats["max_mana"] = max(0, new_max)
	if mana_container:
		mana_container.visible = current_stats["max_mana"] > 0
	if mana_bar:
		mana_bar.max_value = current_stats["max_mana"]
	_update_mana_text()


func update_armor(new_armor: int) -> void:
	current_stats["armor"] = max(0, new_armor)
	if armor_container:
		armor_container.visible = current_stats["armor"] > 0
	if armor_value_label:
		armor_value_label.text = str(current_stats["armor"])


func update_barrier(current_strength: int, max_strength: int = -1) -> void:
	if health_barrier_bar == null:
		return

	var max_health_value: int = int(current_stats.get("max_health", 1))
	if max_strength <= 0:
		max_strength = max_health_value

	var displayed_value: int = clampi(current_strength, 0, max_health_value)
	displayed_value = mini(displayed_value, int(current_stats.get("health", max_health_value)))
	health_barrier_bar.max_value = max_health_value
	health_barrier_bar.value = displayed_value


func update_madness(new_stacks: int, max_stacks: int = -1) -> void:
	if max_stacks > 0:
		current_stats["max_madness"] = max_stacks
	current_stats["madness"] = clamp(new_stacks, 0, current_stats.get("max_madness", 9))
	set_status_effect("madness", current_stats["madness"], "🌀", Color(0.84, 0.54, 0.92))


func update_max_madness(new_max: int) -> void:
	current_stats["max_madness"] = max(1, new_max)
	if current_stats.get("madness", 0) > current_stats["max_madness"]:
		current_stats["madness"] = current_stats["max_madness"]
	update_madness(current_stats.get("madness", 0), current_stats["max_madness"])


func set_status_effect(effect_id: String, stacks: int, icon_text: String, color: Color) -> void:
	if effect_id.is_empty():
		return

	if stacks <= 0:
		clear_status_effect(effect_id)
		return

	var slot: HBoxContainer = null
	if status_effect_slots.has(effect_id):
		slot = status_effect_slots[effect_id] as HBoxContainer
	else:
		slot = _create_status_effect_slot(effect_id, icon_text, color)
		status_effect_slots[effect_id] = slot
		status_effect_order.append(effect_id)
		status_effects_container.add_child(slot)

	var icon_label: Label = slot.get_meta("icon_label") as Label
	var value_label: Label = slot.get_meta("value_label") as Label
	if icon_label:
		icon_label.text = icon_text
		icon_label.add_theme_color_override("font_color", color)
	if value_label:
		value_label.text = str(stacks)
		value_label.add_theme_color_override("font_color", color)

	_refresh_status_effects_visibility()


func clear_status_effect(effect_id: String) -> void:
	if not status_effect_slots.has(effect_id):
		_refresh_status_effects_visibility()
		return

	var slot: HBoxContainer = status_effect_slots[effect_id] as HBoxContainer
	status_effect_slots.erase(effect_id)
	status_effect_order.erase(effect_id)
	if slot != null and is_instance_valid(slot):
		if slot.get_parent() == status_effects_container:
			status_effects_container.remove_child(slot)
		slot.queue_free()

	_refresh_status_effects_visibility()


func _create_status_effect_slot(effect_id: String, icon_text: String, color: Color) -> HBoxContainer:
	var slot: HBoxContainer = HBoxContainer.new()
	slot.name = "%s_status" % effect_id
	slot.add_theme_constant_override("separation", 4)

	var icon_label: Label = Label.new()
	icon_label.text = icon_text
	icon_label.add_theme_font_size_override("font_size", 18)
	icon_label.add_theme_color_override("font_color", color)
	icon_label.add_theme_color_override("font_shadow_color", Color(0.08, 0.08, 0.08, 0.9))
	icon_label.add_theme_constant_override("shadow_offset_x", 1)
	icon_label.add_theme_constant_override("shadow_offset_y", 1)
	slot.add_child(icon_label)

	var value_label: Label = Label.new()
	value_label.text = "0"
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.add_theme_color_override("font_color", color)
	value_label.add_theme_color_override("font_shadow_color", Color(0.08, 0.08, 0.08, 0.9))
	value_label.add_theme_constant_override("shadow_offset_x", 1)
	value_label.add_theme_constant_override("shadow_offset_y", 1)
	slot.add_child(value_label)

	slot.set_meta("icon_label", icon_label)
	slot.set_meta("value_label", value_label)
	return slot


func _refresh_status_effects_visibility() -> void:
	if status_effects_container == null:
		return
	status_effects_container.visible = not status_effect_order.is_empty()


func _update_key_visual(index: int, count: int) -> void:
	if index < 0 or index >= key_colors.size() or index >= key_icons.size() or index >= key_labels.size():
		return

	var icon_color: Color = key_colors[index]
	var count_color: Color = key_colors[index]

	if count <= 0:
		icon_color.a = 0.45
		count_color.a = 0.7

	key_icons[index].modulate = icon_color
	key_labels[index].add_theme_color_override("font_color", count_color)


func update_keys(counts: Array) -> void:
	for i in range(min(6, counts.size())):
		if i < key_labels.size():
			var count: int = int(counts[i])
			key_labels[i].text = str(count)
			_update_key_visual(i, count)


func update_single_key(color_index: int, count: int) -> void:
	if color_index >= 0 and color_index < key_labels.size():
		key_labels[color_index].text = str(count)
		_update_key_visual(color_index, count)


func show_enemy_target(snapshot: Dictionary, show_exact_health: bool = false) -> void:
	if enemy_target_hud == null or not enemy_target_hud.has_method("show_target"):
		return
	enemy_target_hud.show_target(snapshot, show_exact_health)
	_update_enemy_target_position()


func update_enemy_target(snapshot: Dictionary, show_exact_health: bool = false) -> void:
	if enemy_target_hud == null or not enemy_target_hud.has_method("update_target"):
		return
	enemy_target_hud.update_target(snapshot, show_exact_health)
	_update_enemy_target_position()


func hide_enemy_target() -> void:
	if enemy_target_hud == null or not enemy_target_hud.has_method("hide_target"):
		return
	enemy_target_hud.hide_target()


func set_ability_icon(icon_path: String) -> void:
	configure_ability_slot("block", "", "", icon_path)


func set_ability_hotkey(hotkey_text: String) -> void:
	configure_ability_slot("block", "", hotkey_text, "")


func configure_ability_slot(id: String, title_text: String = "", hotkey_text: String = "", icon_path: String = "") -> void:
	if not ability_slots.has(id):
		return

	var slot: Dictionary = ability_slots[id]
	var icon: TextureRect = slot.get("icon")
	var title: Label = slot.get("title")
	var hotkey: Label = slot.get("hotkey")
	var root: VBoxContainer = slot.get("root")

	if icon != null and not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	if title != null and not title_text.is_empty():
		title.text = title_text
	if hotkey != null and not hotkey_text.is_empty():
		hotkey.text = hotkey_text
	if root != null and (not title_text.is_empty() or not hotkey_text.is_empty() or not icon_path.is_empty()):
		root.visible = true


func update_ability_cooldown(id: String, percent: float) -> void:
	if not ability_slots.has(id):
		if id != "block" or not ability_cooldown:
			return
		_update_ability_overlay(ability_cooldown, percent)
		return

	var slot: Dictionary = ability_slots[id]
	var cooldown: ColorRect = slot.get("cooldown")
	_update_ability_overlay(cooldown, percent)


func _update_ability_overlay(cooldown_rect: ColorRect, percent: float) -> void:
	if cooldown_rect == null:
		return

	if percent >= 1.0:
		cooldown_rect.visible = false
	else:
		cooldown_rect.visible = true
		var height: float = 52.0 * (1.0 - percent)
		cooldown_rect.size = Vector2(52.0, height)
		cooldown_rect.position = Vector2(2.0, 54.0 - height)
