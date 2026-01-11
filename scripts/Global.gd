extends Node

# ===========================================
# GLOBAL.GD - ИСПРАВЛЕННАЯ ВЕРСИЯ
# ===========================================

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

# ===========================================
# ОСНОВНЫЕ ФУНКЦИИ
# ===========================================

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

# ===========================================
# ФУНКЦИИ ПЕРСОНАЖЕЙ
# ===========================================

func get_character_scene_path(character_key: String) -> String:
	print("🔍 Получаем путь для персонажа: ", character_key)
	if not character_player_scenes.has(character_key):
		print("❌ Ключ не найден в character_player_scenes: ", character_key)
		print("📋 Доступные ключи: ", character_player_scenes.keys())
		return ""
	
	var path = character_player_scenes[character_key]
	print("📁 Путь к сцене: ", path)
	
	if ResourceLoader.exists(path):
		print("✅ Файл существует!")
		return path
	else:
		print("❌ ФАЙЛ НЕ НАЙДЕН: ", path)
		return ""

func character_scene_exists(character_key: String) -> bool:
	var path = get_character_scene_path(character_key)
	return path != ""

func load_character_scene(character_key: String):
	var path = get_character_scene_path(character_key)
	if path == "":
		return null
	return load(path)

# ===========================================
# UI И РЕГИСТРАЦИЯ
# ===========================================

func register_game_ui(ui_node: CanvasLayer):
	game_ui = ui_node
	print("✅ Game UI зарегистрирован в Global")

func unregister_game_ui():
	game_ui = null
	print("🗑️ Game UI удален из Global")

func register_player(player_node):
	if player_node == null:
		print("❌ Попытка зарегистрировать null игрока!")
		return
	
	current_player = player_node
	if player_node is Node:
		print("✅ Игрок зарегистрирован: ", player_node.name)
		apply_all_artifacts_to_player()
	else:
		print("❌ Player node не является Node!")

func unregister_player():
	"""Безопасная отмена регистрации игрока"""
	if current_player:
		print("🗑️ Игрок отрегистрирован: ", current_player.name)
	current_player = null

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

func get_selected_character_name():
	var data = get_selected_character_data()
	if data == null:
		return "Unknown"
	if data is Dictionary and data.has("name"):
		return data["name"]
	return "Unknown"

# ===========================================
# СМЕНА УРОВНЯ И МЕНЮ
# ===========================================

func change_level(level_path: String):
	if level_path == null or level_path == "":
		print("❌ Level path is empty!")
		return
	
	# Сначала отрегистрируем игрока и UI
	unregister_player()
	unregister_game_ui()
	
	if ResourceLoader.exists(level_path):
		get_tree().change_scene_to_file(level_path)
	else:
		print("❌ Level not found: ", level_path)

func return_to_main_menu():
	"""Возврат в главное меню СО СБРОСОМ"""
	print("🏠 ВОЗВРАЩАЕМСЯ В ГЛАВНОЕ МЕНЮ")
	
	# ВАЖНО: Полный сброс данных
	reset_all_for_new_game()
	
	# Сменяем сцену
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func quit_game():
	print("🛑 Quitting game...")
	get_tree().quit()

func debug_print_state():
	print("=== GLOBAL STATE DEBUG ===")
	print("Selected character: ", selected_character)
	print("Current player: ", current_player)
	print("Game UI: ", game_ui)
	print("Character data is null: ", character_data == null)
	if character_data != null:
		print("Character data keys: ", character_data.keys())
	print("Character scenes: ", character_player_scenes)
	print("Collected artifacts: ", collected_artifacts)
	print("==========================")

# ===========================================
# СИСТЕМА АРТЕФАКТОВ
# ===========================================

# Собранные артефакты игрока
var collected_artifacts: Array = []

# База данных всех артефактов
var artifacts_database = {
	"hermes_wings": {
		"name": "Крылья Гермеса",
		"description": "Легендарные крылатые сандалии",
		"icon": "res://assets/artifacts/hermes_wings.png",
		"ability": "double_jump",
		"rarity": "legendary",
		"effect_text": "Позволяет совершить второй прыжок в воздухе"
	},
	"griffin_feather": {
		"name": "Перо Грифона",
		"description": "Магическое перо мифического существа",
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
		"effect_text": "Усиливает прыжки"
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

# ===========================================
# ФУНКЦИИ АРТЕФАКТОВ
# ===========================================

func has_artifact(artifact_id: String) -> bool:
	return collected_artifacts.has(artifact_id)

func has_ability(ability_name: String) -> bool:
	for artifact_id in collected_artifacts:
		if artifacts_database.has(artifact_id):
			var artifact = artifacts_database[artifact_id]
			if artifact.has("ability") and artifact["ability"] == ability_name:
				return true
	return false

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

func apply_artifact_effect(artifact_id: String):
	if not current_player:
		print("⚠️ current_player is null, cannot apply artifact")
		return
	
	if not artifacts_database.has(artifact_id):
		print("❌ Артефакт не найден в базе: ", artifact_id)
		return
	
	var artifact = artifacts_database[artifact_id]
	print("🎁 Применяем эффект артефакта: ", artifact["name"])
	
	match artifact.get("ability", ""):
		"double_jump":
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
				if "health_changed" in current_player:
					current_player.health_changed.emit(current_player.current_health)
				print("❤️ Здоровье увеличено до: ", current_player.max_health)
			else:
				print("⚠️ Переменные здоровья не найдены у персонажа")
		
		_:
			print("⚠️ Неизвестная способность: ", artifact.get("ability", "unknown"))

func apply_all_artifacts_to_player():
	if not current_player:
		return
	
	print("🎁 Применяем артефакты к игроку...")
	for artifact_id in collected_artifacts:
		apply_artifact_effect(artifact_id)

func get_artifact_data(artifact_id: String):
	if artifacts_database.has(artifact_id):
		return artifacts_database[artifact_id]
	return null

# ===========================================
# СБРОС АРТЕФАКТОВ
# ===========================================

func reset_artifacts():
	collected_artifacts.clear()
	print("🔄 Артефакты сброшены")

func reset_all_for_new_game():
	"""ПОЛНЫЙ СБРОС для новой игры/возврата в меню"""
	print("🔄 === ПОЛНЫЙ СБРОС ДЛЯ НОВОЙ ИГРЫ ===")
	
	# Отрегистрируем игрока
	unregister_player()
	
	# Отрегистрируем UI
	unregister_game_ui()
	
	# Сбрасываем данные персонажа
	player_data = {
		"character_type": "",
		"level": 1,
		"experience": 0
	}
	
	# Сбрасываем артефакты
	reset_artifacts()
	
	print("✅ Все данные сброшены для новой игры")
# ===========================================
# ДОБАВЬТЕ ЭТО В Global.gd
# ===========================================

# Статистика текущего забега
var run_statistics: Dictionary = {
	"death_reason": "",
	"keys_collected": 0,
	"items_collected": 0,
	"coins_collected": 0,
	"enemies_simple": 0,
	"enemies_elite": 0,
	"enemies_boss": 0,
	"damage_dealt": 0,
	"damage_taken": 0,
	"rooms_visited": 0,
	"time_played": 0.0,
	"start_time": 0.0
}

# Артефакт возрождения (если есть)
var revival_artifact_id: String = ""

# Данные для возрождения
var last_room_path: String = ""
var last_safe_position: Vector2 = Vector2.ZERO

func reset_run_statistics():
	"""Сбрасывает статистику забега"""
	run_statistics = {
		"death_reason": "",
		"keys_collected": 0,
		"items_collected": 0,
		"coins_collected": 0,
		"enemies_simple": 0,
		"enemies_elite": 0,
		"enemies_boss": 0,
		"damage_dealt": 0,
		"damage_taken": 0,
		"rooms_visited": 0,
		"time_played": 0.0,
		"start_time": Time.get_unix_time_from_system()
	}
	revival_artifact_id = ""
	print("📊 Статистика забега сброшена")

func add_key_collected():
	run_statistics["keys_collected"] += 1

func add_item_collected():
	run_statistics["items_collected"] += 1

func add_coins(amount: int):
	run_statistics["coins_collected"] += amount

func add_enemy_killed(enemy_type: String):
	match enemy_type:
		"simple":
			run_statistics["enemies_simple"] += 1
		"elite":
			run_statistics["enemies_elite"] += 1
		"boss":
			run_statistics["enemies_boss"] += 1

func add_damage_dealt(amount: int):
	run_statistics["damage_dealt"] += amount

func add_damage_taken(amount: int):
	run_statistics["damage_taken"] += amount

func add_room_visited():
	run_statistics["rooms_visited"] += 1

func set_death_reason(reason: String):
	run_statistics["death_reason"] = reason

func update_play_time():
	"""Обновляет время игры"""
	if run_statistics["start_time"] > 0:
		run_statistics["time_played"] = Time.get_unix_time_from_system() - run_statistics["start_time"]

func get_run_statistics() -> Dictionary:
	"""Возвращает статистику с обновлённым временем"""
	update_play_time()
	return run_statistics.duplicate()

func set_revival_artifact(artifact_id: String):
	"""Устанавливает артефакт возрождения"""
	revival_artifact_id = artifact_id
	print("🔮 Артефакт возрождения установлен: ", artifact_id)

func get_revival_artifact() -> String:
	return revival_artifact_id

func use_revival_artifact():
	"""Использует артефакт возрождения"""
	var used_id = revival_artifact_id
	revival_artifact_id = ""
	
	# Удаляем из инвентаря
	if collected_artifacts.has(used_id):
		collected_artifacts.erase(used_id)
	
	print("🔮 Артефакт возрождения использован: ", used_id)
	return used_id

func save_safe_position(room_path: String, position: Vector2):
	"""Сохраняет безопасную позицию для возрождения"""
	last_room_path = room_path
	last_safe_position = position
