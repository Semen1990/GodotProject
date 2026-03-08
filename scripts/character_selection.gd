extends CanvasLayer

var characters_container = null
var description_panel = null
var character_name_label = null
var health_value = null
var mana_value = null
var armor_value = null
var abilities_list = null
var start_button = null

var current_selected_character = null
var characters: Array = []

func _ready() -> void:
	initialize_nodes()
	initialize_characters()
	setup_ui()

func initialize_nodes() -> void:
	characters_container = get_node_or_null("CharactersContainer")
	description_panel = get_node_or_null("DescriptionPanel")
	start_button = get_node_or_null("DescriptionPanel/MarginContainer/VBoxContainer/StartButton")

	if start_button == null:
		start_button = get_node_or_null("StartButton")

	if start_button == null:
		start_button = get_node_or_null("DescriptionPanel/StartButton")

	if start_button and not start_button.pressed.is_connected(_on_start_button_pressed):
		start_button.pressed.connect(_on_start_button_pressed)

	if description_panel:
		character_name_label = get_node_or_null("DescriptionPanel/MarginContainer/VBoxContainer/CharacterName")
		health_value = get_node_or_null("DescriptionPanel/MarginContainer/VBoxContainer/StatsContainer/HealthContainer/HealthValue")
		mana_value = get_node_or_null("DescriptionPanel/MarginContainer/VBoxContainer/StatsContainer/ManaContainer/ManaValue")
		armor_value = get_node_or_null("DescriptionPanel/MarginContainer/VBoxContainer/StatsContainer/ArmorContainer/ArmorValue")
		abilities_list = get_node_or_null("DescriptionPanel/MarginContainer/VBoxContainer/AbilitiesList")

func initialize_characters() -> void:
	if characters_container == null:
		return

	characters.clear()

	for child in characters_container.get_children():
		if child.has_method("setup_character") and child.has_method("play_idle_animation"):
			characters.append(child)

			if child.has_signal("character_clicked") and not child.character_clicked.is_connected(_on_character_clicked):
				child.character_clicked.connect(_on_character_clicked)

			child.play_idle_animation()
			check_character_area2d(child)

func check_character_area2d(character: Node) -> void:
	var area2d = character.get_node_or_null("Area2D")
	if area2d == null:
		return

	var collision = area2d.get_node_or_null("CollisionShape2D")
	if collision == null:
		return

func setup_ui() -> void:
	if description_panel:
		description_panel.visible = false

	if start_button:
		start_button.visible = false

func select_character(character: Node) -> void:
	if current_selected_character == character:
		return

	if current_selected_character and current_selected_character.has_method("on_deselected"):
		current_selected_character.on_deselected()

	current_selected_character = character

	if character.has_method("on_selected"):
		character.on_selected()

	if description_panel:
		description_panel.visible = true

	if start_button:
		start_button.visible = true

	update_description_panel(character)

func _on_character_clicked(character: Node) -> void:
	select_character(character)

func update_description_panel(character: Node) -> void:
	if character_name_label:
		character_name_label.text = character.character_name

	if health_value:
		health_value.text = str(character.current_health) + "/" + str(character.max_health)

	if mana_value:
		mana_value.text = str(character.current_mana) + "/" + str(character.max_mana)

	if armor_value:
		armor_value.text = str(character.armor)

	if abilities_list:
		if abilities_list is ItemList:
			abilities_list.clear()
			for ability in character.abilities:
				abilities_list.add_item(ability)
		elif abilities_list is RichTextLabel or abilities_list is Label:
			var abilities_text := ""
			for ability in character.abilities:
				abilities_text += "- " + ability + "\n"
			abilities_list.text = abilities_text.strip_edges()

func _on_start_button_pressed() -> void:
	if current_selected_character:
		var character_key := get_character_key(current_selected_character.character_name)
		Global.selected_character = character_key

		var level_path := "res://scenes/levels/level1.tscn"
		if ResourceLoader.exists(level_path):
			get_tree().change_scene_to_file(level_path)
		else:
			OS.alert("Уровень не найден: " + level_path, "Ошибка загрузки")
	else:
		OS.alert("Выберите персонажа!", "Внимание")

func get_character_key(character_name: String) -> String:
	match character_name:
		"Воин":
			return "warrior"
		"Берсерк":
			return "berserk"
		"Разбойник":
			return "rogue"
		"Паладин":
			return "paladin"
		_:
			return "warrior"

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")