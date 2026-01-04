extends Node

# Выбранный персонаж
var selected_character = null

# Данные персонажей для меню выбора
var character_data = {}

# ПУТИ К ИГРОВЫМ ПЕРСОНАЖАМ
var character_player_scenes = {
	"warrior": "res://scenes/game_characters/warrior_player.tscn",
	"berserk": "res://scenes/game_characters/berserk_player.tscn",
	"paladin": "res://scenes/game_characters/paladin_player.tscn", 
	"rogue": "res://scenes/game_characters/rogue_player.tscn"
}

# Игровые данные
var player_data = {
	"character_type": "",
	"level": 1,
	"experience": 0
}

# Ссылка на игровой UI
var game_ui: CanvasLayer = null

# Текущий игрок в уровне
var current_player = null

# Настройки игры
var game_settings = {
	"music_volume": 80,
	"sfx_volume": 90,
	"fullscreen": true
}

# Резервные данные персонажей
var fallback_character_data = {
	"warrior": {
		"name": "Воин",
		"max_health": 150,
		"current_health": 150,
		"max_mana": 10,
		"current_mana": 10,
		"armor": 8,
		"abilities": ["Блок", "Высокое здоровье"],
		"selection_animation": "demonstration"
	},
	"berserk": {
		"name": "Берсерк", 
		"max_health": 120,
		"current_health": 120,
		"max_mana": 20,
		"current_mana": 20,
		"armor": 5,
		"abilities": ["Ярость", "Двойная атака"],
		"selection_animation": "demonstration"
	},
	"rogue": {
		"name": "Разбойник",
		"max_health": 90,
		"current_health": 90,
		"max_mana": 30,
		"current_mana": 30,
		"armor": 2,
		"abilities": ["Подкат", "Критический удар"],
		"selection_animation": "demonstration"
	},
	"paladin": {
		"name": "Паладин",
		"max_health": 130,
		"current_health": 130,
		"max_mana": 50,
		"current_mana": 50,
		"armor": 6,
		"abilities": ["Исцеление", "Божественная защита"],
		"selection_animation": "spellcast"
	}
}

func _ready():
	print("🌍 Global.gd loaded!")
	load_character_data()
	load_settings()

func load_character_data():
	var data_script = load("res://scripts/character_data.gd")
	if data_script:
		character_data = data_script.get_characters()
		print("✅ Character data loaded! Count: ", character_data.size())
		validate_character_data()
	else:
		print("❌ ERROR: Failed to load character_data.gd, using fallback")
		character_data = fallback_character_data

func validate_character_data():
	var required_characters = ["warrior", "berserk", "rogue", "paladin"]
	var missing_characters = []
	
	for char_key in required_characters:
		if not character_data.has(char_key):
			missing_characters.append(char_key)
	
	if missing_characters.size() > 0:
		print("⚠️ Missing character data: ", missing_characters)
		for char_key in missing_characters:
			if fallback_character_data.has(char_key):
				character_data[char_key] = fallback_character_data[char_key]
				print("✅ Added fallback data for: ", char_key)

func load_settings():
	print("⚙️ Default settings loaded")

# ЕДИНСТВЕННАЯ правильная функция для получения пути
func get_character_scene_path(character_key: String) -> String:
	print("🔍 Получаем путь для персонажа: ", character_key)
	
	if not character_player_scenes.has(character_key):
		print("❌ Ключ не найден в character_player_scenes: ", character_key)
		print("📋 Доступные ключи: ", character_player_scenes.keys())
		return ""
	
	var path = character_player_scenes[character_key]
	print("📁 Путь к сцене: ", path)
	
	# Проверяем существование файла
	if ResourceLoader.exists(path):
		print("✅ Файл существует!")
		return path
	else:
		print("❌ ФАЙЛ НЕ НАЙДЕН: ", path)
		return ""

# Функция для проверки существования сцены персонажа
func character_scene_exists(character_key: String) -> bool:
	var path = get_character_scene_path(character_key)
	return path != ""

# Функция для загрузки сцены персонажа
func load_character_scene(character_key: String):
	var path = get_character_scene_path(character_key)
	if path == "":
		return null
	
	return load(path)

# Функция для регистрации UI
func register_game_ui(ui_node: CanvasLayer):
	game_ui = ui_node
	print("✅ Game UI зарегистрирован в Global")

# Функция для удаления UI
func unregister_game_ui():
	game_ui = null
	print("🗑️ Game UI удален из Global")

# Функция для регистрации игрока
func register_player(player_node):
	if player_node == null:
		print("❌ Попытка зарегистрировать null игрока!")
		return
		
	current_player = player_node
	
	if player_node is Node:
		print("✅ Игрок зарегистрирован: ", player_node.name)
	else:
		print("❌ Player node не является Node!")

# Функция для получения данных выбранного персонажа
func get_selected_character_data():
	if selected_character == null:
		return null
	
	if character_data == null:
		print("❌ character_data is null!")
		return null
		
	if character_data.has(selected_character):
		return character_data[selected_character]
	
	print("❌ Character data not found for: ", selected_character)
	return null

# Функция для получения имени выбранного персонажа
func get_selected_character_name():
	var data = get_selected_character_data()
	if data == null:
		return "Unknown"
	
	if data is Dictionary and data.has("name"):
		return data["name"]
	
	return "Unknown"

# Функция для смены уровня
func change_level(level_path: String):
	if level_path == null or level_path == "":
		print("❌ Level path is empty!")
		return
		
	if ResourceLoader.exists(level_path):
		get_tree().change_scene_to_file(level_path)
	else:
		print("❌ Level not found: ", level_path)

# Функция для возврата в главное меню
func return_to_main_menu():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

# Функция для выхода из игры
func quit_game():
	print("🛑 Quitting game...")
	get_tree().quit()

# Функция для отладки
func debug_print_state():
	print("=== GLOBAL STATE DEBUG ===")
	print("Selected character: ", selected_character)
	print("Current player: ", current_player)
	print("Game UI: ", game_ui)
	print("Character data is null: ", character_data == null)
	if character_data != null:
		print("Character data keys: ", character_data.keys())
	print("Character scenes: ", character_player_scenes)
	print("==========================")
