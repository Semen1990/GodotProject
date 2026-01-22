extends CanvasLayer

class_name DeathMenu

signal main_menu_requested
signal restart_requested
signal revive_requested(data: Dictionary)

enum MenuMode { NORMAL, REVIVAL }
var current_mode: MenuMode = MenuMode.NORMAL

var has_revival_artifact: bool = false
var current_revival_artifact_id: String = ""
var death_statistics: Dictionary = {}
var player_last_room: String = ""
var player_last_position: Vector2 = Vector2.ZERO
var is_confirmation_active: bool = false
var pending_action: String = ""
var countdown_time: float = 6.0
var current_countdown: float = 6.0
const STATS_DISPLAY_TIME: float = 6.0

const RARITY_COLORS = {
	"common": Color(0.7, 0.7, 0.7),
	"rare": Color(0.2, 0.5, 1.0),
	"epic": Color(0.8, 0.2, 0.8),
	"legendary": Color(1.0, 0.8, 0.0)
}
const RARITY_NAMES = {
	"common": "ÐžÐ±Ñ‹Ñ‡Ð½Ñ‹Ð¹",
	"rare": "Ð ÐµÐ´ÐºÐ¸Ð¹",
	"epic": "Ð­Ð¿Ð¸Ñ‡ÐµÑÐºÐ¸Ð¹",
	"legendary": "Ð›ÐµÐ³ÐµÐ½Ð´Ð°Ñ€Ð½Ñ‹Ð¹"
}

var background: ColorRect
var main_container: CenterContainer
var main_content: VBoxContainer
var death_title: Label
var stats_panel: PanelContainer
var stats_container: VBoxContainer
var artifacts_panel: PanelContainer
var artifacts_container: VBoxContainer
var buttons_container: HBoxContainer
var main_menu_button: Button
var restart_button: Button
var revive_button: Button
var revival_panel: PanelContainer
var confirmation_dialog: PanelContainer
var confirmation_text: Label
var countdown_bar: ProgressBar
var confirm_yes_button: Button
var confirm_no_button: Button
var countdown_timer: Timer

func _ready():
	add_to_group("death_menu")
	_create_ui()
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

func _create_ui():
	background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.85)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	
	main_container = CenterContainer.new()
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.add_child(main_container)
	
	main_content = VBoxContainer.new()
	main_content.custom_minimum_size = Vector2(500, 400)
	main_content.add_theme_constant_override("separation", 15)
	main_container.add_child(main_content)
	
	death_title = Label.new()
	death_title.text = "Ð’Ð« ÐŸÐžÐ“Ð˜Ð‘Ð›Ð˜"
	death_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_title.add_theme_font_size_override("font_size", 48)
	death_title.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1))
	main_content.add_child(death_title)
	
	_create_stats_panel()
	_create_artifacts_panel()
	_create_revival_panel()
	_create_buttons()
	_create_confirmation_dialog()
	
	countdown_timer = Timer.new()
	countdown_timer.one_shot = false
	countdown_timer.timeout.connect(_on_countdown_tick)
	add_child(countdown_timer)

func _create_stats_panel():
	stats_panel = PanelContainer.new()
	stats_panel.custom_minimum_size = Vector2(450, 200)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_color = Color(0.5, 0.1, 0.1)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(15)
	stats_panel.add_theme_stylebox_override("panel", style)
	main_content.add_child(stats_panel)
	stats_container = VBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 8)
	stats_panel.add_child(stats_container)

func _create_artifacts_panel():
	artifacts_panel = PanelContainer.new()
	artifacts_panel.custom_minimum_size = Vector2(450, 50)
	artifacts_panel.visible = false
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.18, 0.95)
	style.border_color = Color(0.5, 0.3, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	artifacts_panel.add_theme_stylebox_override("panel", style)
	main_content.add_child(artifacts_panel)
	artifacts_container = VBoxContainer.new()
	artifacts_container.add_theme_constant_override("separation", 5)
	artifacts_panel.add_child(artifacts_container)

func _create_revival_panel():
	revival_panel = PanelContainer.new()
	revival_panel.custom_minimum_size = Vector2(400, 100)
	revival_panel.visible = false
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.1, 0.95)
	style.border_color = Color(0.2, 0.8, 0.2)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(15)
	revival_panel.add_theme_stylebox_override("panel", style)
	main_content.add_child(revival_panel)
	
	var hbox = HBoxContainer.new()
	hbox.name = "HBoxContainer"
	hbox.add_theme_constant_override("separation", 15)
	revival_panel.add_child(hbox)
	var icon = Label.new()
	icon.text = "ðŸ”®"
	icon.add_theme_font_size_override("font_size", 40)
	hbox.add_child(icon)
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	hbox.add_child(vbox)
	var title = Label.new()
	title.text = "Ð£ Ð’ÐÐ¡ Ð•Ð¡Ð¢Ð¬ Ð¨ÐÐÐ¡!"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	vbox.add_child(title)
	var artifact_name = Label.new()
	artifact_name.name = "ArtifactName"
	artifact_name.text = "ÐŸÐµÑ€Ð¾ Ð¤ÐµÐ½Ð¸ÐºÑÐ°"
	artifact_name.add_theme_font_size_override("font_size", 18)
	artifact_name.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	vbox.add_child(artifact_name)

func _create_buttons():
	buttons_container = HBoxContainer.new()
	buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_container.add_theme_constant_override("separation", 20)
	main_content.add_child(buttons_container)
	
	revive_button = Button.new()
	revive_button.text = "ðŸ”® Ð’ÐžÐ—Ð ÐžÐ”Ð˜Ð¢Ð¬Ð¡Ð¯"
	revive_button.custom_minimum_size = Vector2(180, 50)
	revive_button.visible = false
	revive_button.pressed.connect(_on_revive_pressed)
	_style_button(revive_button, Color(0.2, 0.7, 0.2))
	buttons_container.add_child(revive_button)
	
	main_menu_button = Button.new()
	main_menu_button.text = "ðŸ  Ð’ ÐœÐ•ÐÐ®"
	main_menu_button.custom_minimum_size = Vector2(150, 50)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	_style_button(main_menu_button, Color(0.5, 0.5, 0.5))
	buttons_container.add_child(main_menu_button)
	
	restart_button = Button.new()
	restart_button.text = "ðŸ”„ Ð—ÐÐÐžÐ’Ðž"
	restart_button.custom_minimum_size = Vector2(150, 50)
	restart_button.pressed.connect(_on_restart_pressed)
	_style_button(restart_button, Color(0.6, 0.4, 0.2))
	buttons_container.add_child(restart_button)

func _style_button(button: Button, base_color: Color):
	var normal = StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.set_corner_radius_all(5)
	normal.set_content_margin_all(10)
	button.add_theme_stylebox_override("normal", normal)
	var hover = StyleBoxFlat.new()
	hover.bg_color = base_color.lightened(0.2)
	hover.set_corner_radius_all(5)
	hover.set_content_margin_all(10)
	button.add_theme_stylebox_override("hover", hover)
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = base_color.darkened(0.2)
	pressed_style.set_corner_radius_all(5)
	pressed_style.set_content_margin_all(10)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_font_size_override("font_size", 18)

func _create_confirmation_dialog():
	confirmation_dialog = PanelContainer.new()
	confirmation_dialog.custom_minimum_size = Vector2(400, 180)
	confirmation_dialog.visible = false
	confirmation_dialog.set_anchors_preset(Control.PRESET_CENTER)
	confirmation_dialog.position = Vector2(-200, -90)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.98)
	style.border_color = Color(0.9, 0.7, 0.1)
	style.set_border_width_all(4)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(20)
	confirmation_dialog.add_theme_stylebox_override("panel", style)
	background.add_child(confirmation_dialog)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	confirmation_dialog.add_child(vbox)
	confirmation_text = Label.new()
	confirmation_text.text = "Ð’Ñ‹ Ð¿Ð¾Ñ‚ÐµÑ€ÑÐµÑ‚Ðµ Ð°Ñ€Ñ‚ÐµÑ„Ð°ÐºÑ‚ Ð²Ð¾Ð·Ñ€Ð¾Ð¶Ð´ÐµÐ½Ð¸Ñ!\nÐ’Ñ‹ ÑƒÐ²ÐµÑ€ÐµÐ½Ñ‹?"
	confirmation_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirmation_text.add_theme_font_size_override("font_size", 18)
	confirmation_text.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	vbox.add_child(confirmation_text)
	countdown_bar = ProgressBar.new()
	countdown_bar.custom_minimum_size = Vector2(350, 20)
	countdown_bar.max_value = countdown_time
	countdown_bar.value = countdown_time
	countdown_bar.show_percentage = false
	vbox.add_child(countdown_bar)
	var buttons = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 30)
	vbox.add_child(buttons)
	confirm_yes_button = Button.new()
	confirm_yes_button.text = "Ð”Ð, Ð’Ð«Ð™Ð¢Ð˜"
	confirm_yes_button.custom_minimum_size = Vector2(120, 40)
	confirm_yes_button.pressed.connect(_on_confirm_yes)
	_style_button(confirm_yes_button, Color(0.7, 0.2, 0.2))
	buttons.add_child(confirm_yes_button)
	confirm_no_button = Button.new()
	confirm_no_button.text = "ÐÐ•Ð¢"
	confirm_no_button.custom_minimum_size = Vector2(120, 40)
	confirm_no_button.pressed.connect(_on_confirm_no)
	_style_button(confirm_no_button, Color(0.2, 0.5, 0.2))
	buttons.add_child(confirm_no_button)

func show_death_menu(statistics: Dictionary = {}, revival_artifact_id: String = ""):
	death_statistics = statistics
	current_revival_artifact_id = revival_artifact_id
	has_revival_artifact = revival_artifact_id != ""
	if has_revival_artifact:
		_setup_revival_mode()
	else:
		_setup_normal_mode()
	show()
	get_tree().paused = true
	if has_revival_artifact:
		revive_button.grab_focus()
	else:
		restart_button.grab_focus()

func _setup_normal_mode():
	death_title.text = "Ð’Ð« ÐŸÐžÐ“Ð˜Ð‘Ð›Ð˜"
	death_title.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1))
	stats_panel.visible = true
	_update_statistics()
	_update_artifacts_display()
	revival_panel.visible = false
	revive_button.visible = false
	main_menu_button.visible = true
	restart_button.visible = true

func _setup_revival_mode():
	death_title.text = "Ð•Ð¡Ð¢Ð¬ Ð’Ð¢ÐžÐ ÐžÐ™ Ð¨ÐÐÐ¡!"
	death_title.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	stats_panel.visible = false
	artifacts_panel.visible = false
	revival_panel.visible = true
	_update_revival_info()
	revive_button.visible = true
	main_menu_button.visible = true
	restart_button.visible = true

func _update_statistics():
	for child in stats_container.get_children():
		child.queue_free()
	_add_stat_row("ðŸ’€ ÐŸÑ€Ð¸Ñ‡Ð¸Ð½Ð° ÑÐ¼ÐµÑ€Ñ‚Ð¸:", death_statistics.get("death_reason", "ÐÐµÐ¸Ð·Ð²ÐµÑÑ‚Ð½Ð¾"), Color(0.9, 0.3, 0.3))
	_add_separator()
	_add_stat_row("â±ï¸ Ð’Ñ€ÐµÐ¼Ñ Ð¸Ð³Ñ€Ñ‹:", _format_time(death_statistics.get("time_played", 0.0)), Color(0.6, 0.8, 0.6))
	_add_stat_row("ðŸšª ÐšÐ¾Ð¼Ð½Ð°Ñ‚ Ð¿Ñ€Ð¾Ð¹Ð´ÐµÐ½Ð¾:", str(death_statistics.get("rooms_visited", 0)), Color(0.6, 0.6, 0.9))
	_add_separator()
	_add_stat_row("ðŸ”‘ ÐšÐ»ÑŽÑ‡ÐµÐ¹ ÑÐ¾Ð±Ñ€Ð°Ð½Ð¾:", str(death_statistics.get("keys_collected", 0)), Color(1.0, 0.9, 0.2))
	_add_stat_row("ðŸ“¦ ÐŸÑ€ÐµÐ´Ð¼ÐµÑ‚Ð¾Ð² Ð½Ð°Ð¹Ð´ÐµÐ½Ð¾:", str(death_statistics.get("items_collected", 0)), Color(0.5, 0.8, 1.0))
	_add_stat_row("ðŸ’° ÐœÐ¾Ð½ÐµÑ‚ ÑÐ¾Ð±Ñ€Ð°Ð½Ð¾:", str(death_statistics.get("coins_collected", 0)), Color(1.0, 0.85, 0.0))
	_add_separator()
	_add_stat_row("ðŸ‘¹ ÐžÐ±Ñ‹Ñ‡Ð½Ñ‹Ñ… Ð²Ñ€Ð°Ð³Ð¾Ð² Ð¿Ð¾Ð²ÐµÑ€Ð¶ÐµÐ½Ð¾:", str(death_statistics.get("enemies_simple", 0)), Color(0.7, 0.7, 0.7))
	_add_stat_row("âš”ï¸ Ð­Ð»Ð¸Ñ‚Ð½Ñ‹Ñ… Ð²Ñ€Ð°Ð³Ð¾Ð² Ð¿Ð¾Ð²ÐµÑ€Ð¶ÐµÐ½Ð¾:", str(death_statistics.get("enemies_elite", 0)), Color(1.0, 0.6, 0.2))
	_add_stat_row("ðŸ‘‘ Ð‘Ð¾ÑÑÐ¾Ð² Ð¿Ð¾Ð²ÐµÑ€Ð¶ÐµÐ½Ð¾:", str(death_statistics.get("enemies_boss", 0)), Color(0.8, 0.2, 0.8))
	_add_separator()
	_add_stat_row("âš”ï¸ Ð£Ñ€Ð¾Ð½Ð° Ð½Ð°Ð½ÐµÑÐµÐ½Ð¾:", str(death_statistics.get("damage_dealt", 0)), Color(0.9, 0.5, 0.3))
	_add_stat_row("ðŸ’” Ð£Ñ€Ð¾Ð½Ð° Ð¿Ð¾Ð»ÑƒÑ‡ÐµÐ½Ð¾:", str(death_statistics.get("damage_taken", 0)), Color(0.9, 0.3, 0.3))

func _format_time(seconds: float) -> String:
	var total_seconds = int(seconds)
	var hours = total_seconds / 3600
	var minutes = (total_seconds % 3600) / 60
	var secs = total_seconds % 60
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, secs]
	return "%d:%02d" % [minutes, secs]

func _add_stat_row(label_text: String, value_text: String, color: Color):
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	stats_container.add_child(hbox)
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)
	var value = Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 16)
	value.add_theme_color_override("font_color", color)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(value)

func _add_separator():
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 5)
	stats_container.add_child(sep)

func _update_artifacts_display():
	for child in artifacts_container.get_children():
		child.queue_free()
	var artifacts = []
	if Global and "collected_artifacts" in Global:
		artifacts = Global.collected_artifacts
	if artifacts.is_empty():
		artifacts_panel.visible = false
		return
	artifacts_panel.visible = true
	var title = Label.new()
	title.text = "ðŸ”® Ð¡Ð¾Ð±Ñ€Ð°Ð½Ð½Ñ‹Ðµ Ð°Ñ€Ñ‚ÐµÑ„Ð°ÐºÑ‚Ñ‹:"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
	artifacts_container.add_child(title)
	var rarity_count = {"common": 0, "rare": 0, "epic": 0, "legendary": 0}
	for artifact_id in artifacts:
		var rarity = _get_artifact_rarity(artifact_id)
		rarity_count[rarity] += 1
	for rarity in ["legendary", "epic", "rare", "common"]:
		var count = rarity_count[rarity]
		if count > 0:
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			var rarity_label = Label.new()
			rarity_label.text = "  %s:" % RARITY_NAMES[rarity]
			rarity_label.add_theme_font_size_override("font_size", 14)
			rarity_label.add_theme_color_override("font_color", RARITY_COLORS[rarity])
			rarity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(rarity_label)
			var count_label = Label.new()
			count_label.text = str(count)
			count_label.add_theme_font_size_override("font_size", 14)
			count_label.add_theme_color_override("font_color", RARITY_COLORS[rarity])
			row.add_child(count_label)
			artifacts_container.add_child(row)

func _get_artifact_rarity(artifact_id: String) -> String:
	if Global and Global.has_method("get_artifact_rarity"):
		return Global.get_artifact_rarity(artifact_id)
	match artifact_id:
		"phoenix_feather", "mirror_shield":
			return "legendary"
		"vampire_ring", "berserker_gloves", "griffin_feather", "eagle_amulet":
			return "epic"
		"hermes_wings", "mana_crystal", "wind_ring", "dash_boots":
			return "rare"
		_:
			return "common"

func _update_revival_info():
	var artifact_name_node = revival_panel.find_child("ArtifactName", true, false)
	if artifact_name_node:
		var artifact_name = "ÐÑ€Ñ‚ÐµÑ„Ð°ÐºÑ‚ Ð²Ð¾Ð·Ñ€Ð¾Ð¶Ð´ÐµÐ½Ð¸Ñ"
		if Global and Global.has_method("get_artifact_data"):
			var data = Global.get_artifact_data(current_revival_artifact_id)
			if data and data.has("name"):
				artifact_name = data["name"]
		else:
			match current_revival_artifact_id:
				"phoenix_feather":
					artifact_name = "ÐŸÐµÑ€Ð¾ Ð¤ÐµÐ½Ð¸ÐºÑÐ°"
		artifact_name_node.text = artifact_name

func _on_revive_pressed():
	get_tree().paused = false
	hide()
	revive_requested.emit({"artifact_id": current_revival_artifact_id, "last_room": player_last_room, "last_position": player_last_position})

func _on_main_menu_pressed():
	if has_revival_artifact:
		_show_confirmation("main_menu")
	else:
		_go_to_main_menu()

func _on_restart_pressed():
	if has_revival_artifact:
		_show_confirmation("restart")
	else:
		_restart_game()

func _show_confirmation(action: String):
	pending_action = action
	is_confirmation_active = true
	var artifact_name = "Ð°Ñ€Ñ‚ÐµÑ„Ð°ÐºÑ‚ Ð²Ð¾Ð·Ñ€Ð¾Ð¶Ð´ÐµÐ½Ð¸Ñ"
	if Global and Global.has_method("get_artifact_data"):
		var data = Global.get_artifact_data(current_revival_artifact_id)
		if data and data.has("name"):
			artifact_name = data["name"]
	confirmation_text.text = "Ð’Ñ‹ Ð¿Ð¾Ñ‚ÐµÑ€ÑÐµÑ‚Ðµ " + artifact_name + "!\nÐ’Ñ‹ ÑƒÐ²ÐµÑ€ÐµÐ½Ñ‹?"
	current_countdown = countdown_time
	countdown_bar.value = countdown_time
	confirmation_dialog.visible = true
	confirm_no_button.grab_focus()
	countdown_timer.start(0.1)

func _on_confirm_yes():
	countdown_timer.stop()
	confirmation_dialog.visible = false
	is_confirmation_active = false
	stats_panel.visible = true
	_update_statistics()
	_update_artifacts_display()
	revival_panel.visible = false
	revive_button.visible = false
	death_title.text = "Ð’Ð« ÐŸÐžÐ“Ð˜Ð‘Ð›Ð˜"
	death_title.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1))
	await get_tree().create_timer(STATS_DISPLAY_TIME).timeout
	if pending_action == "main_menu":
		_go_to_main_menu()
	elif pending_action == "restart":
		_restart_game()

func _on_confirm_no():
	countdown_timer.stop()
	confirmation_dialog.visible = false
	is_confirmation_active = false
	revive_button.grab_focus()

func _on_countdown_tick():
	current_countdown -= 0.1
	countdown_bar.value = current_countdown
	if current_countdown <= 0:
		_on_confirm_no()

func _go_to_main_menu():
	get_tree().paused = false
	hide()
	
	# === Очищаем инвентарь при выходе в меню ===
	if Inventory:
		Inventory.clear_all()
	
	if Global and Global.has_method("full_reset"):
		Global.full_reset()
	
	main_menu_requested.emit()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _restart_game():
	get_tree().paused = false
	hide()
	
	# === ВАЖНО: Очищаем инвентарь ПЕРЕД загрузкой сцены! ===
	# Иначе артефакты на уровне увидят что они "уже собраны" и удалятся
	if Inventory:
		Inventory.clear_all()
		print("🗑️ Инвентарь очищен перед рестартом")
	
	if Global and Global.has_method("reset_artifacts"):
		Global.reset_artifacts()
	
	restart_requested.emit()
	get_tree().change_scene_to_file("res://scenes/levels/level1.tscn")

func _input(event):
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if is_confirmation_active:
			_on_confirm_no()
		get_viewport().set_input_as_handled()
