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
# Функция для регистрации игрока
func register_player(player_node):
	if player_node == null:
		print("❌ Попытка зарегистрировать null игрока!")
		return
		
	current_player = player_node
	
	if player_node is Node:
		print("✅ Игрок зарегистрирован: ", player_node.name)
		
		# ВАЖНО: Применяем артефакты сразу после регистрации
		apply_all_artifacts_to_player()
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
# ============================================
# СИСТЕМА АРТЕФАКТОВ
# ============================================

# Собранные артефакты игрока
var collected_artifacts: Array = []

# База данных всех артефактов
var artifacts_database = {
	"hermes_wings": {
		"name": "Крылья Гермеса",
		"description": "Легендарные крылатые сандалии, дарующие способность к двойному прыжку",
		"icon": "res://assets/artifacts/hermes_wings.png",
		"ability": "double_jump",
		"rarity": "legendary",
		"effect_text": "Позволяет совершить второй прыжок в воздухе"
	},
	"griffin_feather": {
		"name": "Перо Грифона",
		"description": "Магическое перо мифического существа, позволяющее парить в воздухе",
		"icon": "res://assets/artifacts/griffin_feather.png",
		"ability": "double_jump",
		"rarity": "epic",
		"effect_text": "Дарует возможность двойного прыжка"
	},
	"wind_ring": {
		"name": "Кольцо Ветра",
		"description": "Древнее кольцо с силой воздушной стихии",
		"icon": "res://assets/artifacts/wind_ring.png",
		"ability": "double_jump",
		"rarity": "rare",
		"effect_text": "Усиливает прыжки, позволяя прыгать дважды"
	},
	"eagle_amulet": {
		"name": "Амулет Орла",
		"description": "Амулет с духом великого орла",
		"icon": "res://assets/artifacts/eagle_amulet.png",
		"ability": "double_jump",
		"rarity": "epic",
		"effect_text": "Дух орла помогает взлететь выше"
	},
	"dash_boots": {
		"name": "Сапоги Рывка",
		"description": "Магические сапоги увеличивающие скорость",
		"icon": "res://assets/artifacts/dash_boots.png",
		"ability": "dash",
		"rarity": "rare",
		"effect_text": "Увеличивает скорость передвижения на 30%"
	},
	"health_crystal": {
		"name": "Кристалл Здоровья",
		"description": "Светящийся кристалл усиливающий жизненную силу",
		"icon": "res://assets/artifacts/health_crystal.png",
		"ability": "max_health",
		"rarity": "common",
		"effect_text": "Увеличивает максимальное здоровье на 20"
	}
}

# Сигнал для уведомления об артефакте
signal artifact_collected(artifact_id: String)

# Функция проверки наличия артефакта
func has_artifact(artifact_id: String) -> bool:
	return collected_artifacts.has(artifact_id)

# Функция проверки наличия способности
func has_ability(ability_name: String) -> bool:
	for artifact_id in collected_artifacts:
		if artifacts_database.has(artifact_id):
			var artifact = artifacts_database[artifact_id]
			if artifact.has("ability") and artifact["ability"] == ability_name:
				return true
	return false

# Функция добавления артефакта
func collect_artifact(artifact_id: String) -> bool:
	if not artifacts_database.has(artifact_id):
		print("❌ Артефакт не найден в базе: ", artifact_id)
		return false
	
	if collected_artifacts.has(artifact_id):
		print("⚠️ Артефакт уже собран: ", artifact_id)
		return false
	
	collected_artifacts.append(artifact_id)
	var artifact = artifacts_database[artifact_id]
	print("✨ Получен артефакт: ", artifact["name"])
	
	# Применяем эффект к текущему игроку
	if current_player:
		apply_artifact_effect(artifact_id)
	
	# Отправляем сигнал
	artifact_collected.emit(artifact_id)
	return true

# Функция применения эффекта артефакта
# Функция применения эффекта артефакта
func apply_artifact_effect(artifact_id: String):
	if not current_player:
		print("⚠️ current_player is null, cannot apply artifact")
		return
	
	if not artifacts_database.has(artifact_id):
		print("❌ Артефакт не найден в базе: ", artifact_id)
		return
	
	var artifact = artifacts_database[artifact_id]
	
	print("🎁 Применяем эффект артефакта: ", artifact["name"])
	
	match artifact["ability"]:
		"double_jump":
			# ИСПРАВЛЕНО: используем "in" вместо has()
			if "enable_double_jump" in current_player:
				current_player.enable_double_jump = true
				print("🦘 Двойной прыжок активирован!")
			else:
				print("⚠️ Переменная enable_double_jump не найдена у персонажа")
		
		"dash":
			if "base_speed" in current_player and "current_speed" in current_player:
				current_player.base_speed = int(current_player.base_speed * 1.3)
				current_player.current_speed = current_player.base_speed
				print("⚡ Скорость увеличена до: ", current_player.current_speed)
			else:
				print("⚠️ Переменные скорости не найдены у персонажа")
		
		"max_health":
			if "max_health" in current_player and "current_health" in current_player:
				current_player.max_health += 20
				current_player.current_health += 20
				if current_player.has_signal("health_changed"):
					current_player.health_changed.emit(current_player.current_health)
				print("❤️ Здоровье увеличено до: ", current_player.max_health)
			else:
				print("⚠️ Переменные здоровья не найдены у персонажа")
		
		_:
			print("⚠️ Неизвестная способность: ", artifact["ability"])

# Функция применения всех артефактов к игроку
func apply_all_artifacts_to_player():
	if not current_player:
		return
	
	print("🎁 Применяем артефакты к игроку...")
	for artifact_id in collected_artifacts:
		apply_artifact_effect(artifact_id)

# Функция получения данных артефакта
func get_artifact_data(artifact_id: String):
	if artifacts_database.has(artifact_id):
		return artifacts_database[artifact_id]
	return null

# Функция сброса артефактов (для новой игры)
func reset_artifacts():
	collected_artifacts.clear()
	print("🔄 Артефакты сброшены")
