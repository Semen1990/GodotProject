extends CanvasLayer

# Ссылки на UI элементы
var characters_container
var description_panel
var character_name_label
var health_value
var mana_value
var armor_value
var abilities_list
var start_button

var current_selected_character = null
var characters = []

func _ready():
	print("=== 🎮 CHARACTER SELECTION LOADING ===")
	
	# Безопасная инициализация узлов
	initialize_nodes()
	initialize_characters()
	setup_ui()

func initialize_nodes():
	# Безопасно получаем узлы
	characters_container = get_node_or_null("CharactersContainer")
	description_panel = get_node_or_null("DescriptionPanel")
	
	# Ищем StartButton в разных возможных местах
	start_button = get_node_or_null("StartButton")
	if start_button == null:
		start_button = get_node_or_null("DescriptionPanel/StartButton")
	if start_button == null:
		start_button = get_node_or_null("MarginContainer/StartButton")
	if start_button == null:
		start_button = get_node_or_null("VBoxContainer/StartButton")
	if start_button == null:
		start_button = get_node_or_null("DescriptionPanel/MarginContainer/VBoxContainer/StartButton")
	
	# Если кнопка все еще не найдена, создадим ее программно
	if start_button == null:
		print("❌ StartButton not found, creating one programmatically")
		start_button = Button.new()
		start_button.text = "Начать игру"
		start_button.name = "StartButton"
		add_child(start_button)
		start_button.position = Vector2(500, 600)  # Позиция по умолчанию
		start_button.pressed.connect(_on_start_button_pressed)
	
	# Получаем остальные UI элементы если description_panel существует
	if description_panel:
		character_name_label = get_node_or_null("DescriptionPanel/MarginContainer/VBoxContainer/CharacterName")
		health_value = get_node_or_null("DescriptionPanel/MarginContainer/VBoxContainer/StatsContainer/HealthContainer/HealthValue")
		mana_value = get_node_or_null("DescriptionPanel/MarginContainer/VBoxContainer/StatsContainer/ManaContainer/ManaValue")
		armor_value = get_node_or_null("DescriptionPanel/MarginContainer/VBoxContainer/StatsContainer/ArmorContainer/ArmorValue")
		abilities_list = get_node_or_null("DescriptionPanel/MarginContainer/VBoxContainer/AbilitiesList")
	
	# Отладочная информация
	print("CharactersContainer: ", characters_container != null)
	print("DescriptionPanel: ", description_panel != null)
	print("StartButton: ", start_button != null)
	print("CharacterNameLabel: ", character_name_label != null)

func initialize_characters():
	print("=== 🔍 ИНИЦИАЛИЗАЦИЯ ПЕРСОНАЖЕЙ ===")
	
	if characters_container == null:
		print("❌ CharactersContainer не найден!")
		return
	
	characters = []
	
	# Получаем всех дочерних узлов в контейнере
	for child in characters_container.get_children():
		print("🔍 Found child: ", child.name, " | Type: ", child.get_class())
		
		# Проверяем, что это персонаж с нужными методами
		if child.has_method("setup_character") and child.has_method("play_idle_animation"):
			characters.append(child)
			print("✅ Valid character found: ", child.name)
			
			# Подключаем сигнал клика
			if child.has_signal("character_clicked"):
				child.character_clicked.connect(_on_character_clicked)
				print("✅ Connected signal for: ", child.name)
			else:
				print("❌ No character_clicked signal for: ", child.name)
			
			# Убеждаемся, что персонаж проигрывает idle анимацию
			child.play_idle_animation()
			
			# ПРОВЕРКА AREA2D - ДОБАВЛЕНО
			check_character_area2d(child)
		else:
			print("❌ Not a valid character: ", child.name)
	
	print("=== ✅ CHARACTERS INITIALIZED: ", characters.size(), " ===")

# НОВАЯ ФУНКЦИЯ: Проверка Area2D у персонажей
func check_character_area2d(character):
	var area2d = character.get_node_or_null("Area2D")
	if area2d:
		print("✅ Area2D found for: ", character.character_name)
		print("   Input pickable: ", area2d.input_pickable)
		print("   Monitoring: ", area2d.monitoring)
		print("   Monitorable: ", area2d.monitorable)
		
		# Проверяем коллизию
		var collision = area2d.get_node_or_null("CollisionShape2D")
		if collision:
			print("   CollisionShape2D found: ", collision.shape != null)
			print("   Collision disabled: ", collision.disabled)
		else:
			print("   ❌ No CollisionShape2D found!")
	else:
		print("❌ No Area2D found for: ", character.character_name)

func setup_ui():
	print("=== 🎮 SETUP UI ===")
	
	# Безопасно скрываем описание и кнопку
	if description_panel:
		description_panel.visible = false
		print("✅ DescriptionPanel hidden")
	else:
		print("❌ DescriptionPanel not found - cannot hide")
	
	if start_button:
		start_button.visible = false
		print("✅ StartButton hidden")
	else:
		print("❌ StartButton not found - cannot hide")
	
	print("=== ✅ CHARACTER SELECTION READY ===")

func select_character(character):
	print("=== 🎯 SELECT CHARACTER CALLED ===")
	print("Selecting character: ", character.character_name)
	
	if current_selected_character == character:
		print("ℹ️ Character already selected")
		return
	
	# Сбрасываем предыдущего выбранного персонажа
	if current_selected_character:
		print("🔄 Deselecting previous character: ", current_selected_character.character_name)
		current_selected_character.on_deselected()
	
	# Выбираем нового персонажа
	current_selected_character = character
	print("⭐ NEW SELECTION: ", character.character_name)
	
	# Проигрываем анимацию выбора
	character.on_selected()
	
	# Показываем описание и кнопку начала игры
	if description_panel:
		description_panel.visible = true
		print("✅ DescriptionPanel shown")
	
	if start_button:
		start_button.visible = true
		print("✅ StartButton shown")
	
	# Обновляем описание
	update_description_panel(character)
	
	print("=== ✅ SELECTION COMPLETE ===")

func _on_character_clicked(character):
	print("=== 🎯 CHARACTER CLICKED ===")
	print("Character: ", character.character_name)
	select_character(character)

func update_description_panel(character):
	print("=== 📊 UPDATING DESCRIPTION ===")
	
	# Безопасно обновляем UI элементы
	if character_name_label:
		character_name_label.text = character.character_name
		print("✅ Character name updated: ", character.character_name)
	
	if health_value:
		health_value.text = str(character.current_health) + "/" + str(character.max_health)
		print("✅ Health updated: ", health_value.text)
	
	if mana_value:
		mana_value.text = str(character.current_mana) + "/" + str(character.max_mana)
		print("✅ Mana updated: ", mana_value.text)
	
	if armor_value:
		armor_value.text = str(character.armor)
		print("✅ Armor updated: ", armor_value.text)
	
	# Обновляем способности
	if abilities_list:
		if abilities_list is ItemList:
			abilities_list.clear()
			for ability in character.abilities:
				abilities_list.add_item(ability)
			print("✅ Abilities updated (ItemList): ", character.abilities)
		elif abilities_list is RichTextLabel or abilities_list is Label:
			var abilities_text = ""
			for ability in character.abilities:
				abilities_text += "• " + ability + "\n"
			abilities_list.text = abilities_text
			print("✅ Abilities updated (Text): ", character.abilities)
	else:
		print("❌ AbilitiesList not available")

func _on_start_button_pressed():
	print("🎯 START BUTTON PRESSED")
	
	if current_selected_character:
		var character_key = get_character_key(current_selected_character.character_name)
		print("🚀 Starting game with: ", current_selected_character.character_name, " (key: ", character_key, ")")
		
		# Сохраняем выбор в Global
		Global.selected_character = character_key
		print("✅ Selected character saved in Global: ", character_key)
		
		# Загружаем игровую сцену
		var level_path = "res://scenes/levels/level1.tscn"
		if ResourceLoader.exists(level_path):
			print("✅ Level scene exists, loading...")
			get_tree().change_scene_to_file(level_path)
		else:
			print("❌ Level scene not found: ", level_path)
			# Показываем ошибку
			OS.alert("Уровень не найден: " + level_path, "Ошибка загрузки")
	else:
		print("❌ No character selected!")
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
	return "warrior" # fallback

func _on_back_button_pressed():
	print("🔙 BACK BUTTON PRESSED")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
