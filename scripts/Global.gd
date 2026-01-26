extends Node

# ===========================================
# GLOBAL.GD - ВЕРСИЯ v4.0 С СИСТЕМОЙ КЛЮЧЕЙ
# ===========================================

var selected_character = null
var character_data = {}

var character_player_scenes = {
	"warrior": "res://scenes/game_characters/warrior_player.tscn",
	"berserk": "res://scenes/game_characters/berserk_player.tscn",
	"paladin": "res://scenes/game_characters/paladin_player.tscn", 
	"rogue": "res://scenes/game_characters/rogue_player.tscn"
}

var player_data = {
	"character_type": "",
	"level": 1,
	"experience": 0
}

var game_ui: CanvasLayer = null
var current_player = null

var game_settings = {
	"music_volume": 80,
	"sfx_volume": 90,
	"fullscreen": true
}

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
# СИСТЕМА АРТЕФАКТОВ
# ===========================================

var collected_artifacts: Array = []

# ===========================================
# СИСТЕМА КЛЮЧЕЙ
# ===========================================

var collected_keys: Array = []
var spawn_point: String = ""
var opened_doors: Array = []

# ===========================================

var artifacts_database = {
	"hermes_wings": {
		"name": "Крылья Гермеса",
		"description": "Легендарные крылатые сандалии",
		"icon": "res://assets/artifacts/hermes_wings.png",
		"ability": "double_jump",
		"rarity": "rare",
		"effect_text": "Позволяет совершить второй прыжок в воздухе"
	},
	"phoenix_feather": {
		"name": "Перо Феникса",
		"description": "Магическое перо возрождения",
		"icon": "res://assets/artifacts/phoenix_feather.png",
		"ability": "revival",
		"rarity": "legendary",
		"effect_text": "Возрождает после смерти с 50% HP"
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
	},
	"mana_crystal": {
		"name": "Кристалл Маны",
		"description": "Кристалл магической энергии",
		"icon": "res://assets/artifacts/mana_crystal.png",
		"ability": "max_mana",
		"rarity": "rare",
		"effect_text": "Увеличивает максимальную ману на 20"
	},
	"vampire_ring": {
		"name": "Кольцо Вампира",
		"description": "Тёмное кольцо с кровавым камнем",
		"icon": "res://assets/artifacts/vampire_ring.png",
		"ability": "lifesteal",
		"rarity": "epic",
		"effect_text": "Восстанавливает HP при убийстве врагов"
	},
	"berserker_gloves": {
		"name": "Перчатки Берсерка",
		"description": "Окровавленные перчатки воина",
		"icon": "res://assets/artifacts/berserker_gloves.png",
		"ability": "damage_boost",
		"rarity": "epic",
		"effect_text": "+50% урона при HP ниже 30%"
	},
	"mirror_shield": {
		"name": "Зеркальный Щит",
		"description": "Щит отражающий атаки",
		"icon": "res://assets/artifacts/mirror_shield.png",
		"ability": "reflect",
		"rarity": "legendary",
		"effect_text": "20% шанс отразить урон"
	},
	"speed_boots": {
		"name": "Сапоги Скорости",
		"description": "Лёгкие сапоги для быстрого бега",
		"icon": "res://assets/artifacts/speed_boots.png",
		"ability": "speed",
		"rarity": "common",
		"effect_text": "Увеличивает скорость на 15%"
	}
}

signal artifact_collected(artifact_id: String)

var run_statistics: Dictionary = {
	"death_reason": "",
	"keys_collected": 0,
	"items_collected": 0,
	"artifacts_collected": 0,
	"coins_collected": 0,
	"enemies_simple": 0,
	"enemies_elite": 0,
	"enemies_boss": 0,
	"damage_dealt": 0,
	"damage_taken": 0,
	"rooms_visited": 1,
	"time_played": 0.0,
	"start_time": 0.0
}

var revival_artifact_id: String = ""
var last_room_path: String = ""
var last_safe_position: Vector2 = Vector2.ZERO
var run_started: bool = false


func _ready():
	print("🌍 Global.gd v4.0 loaded!")
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


func load_settings():
	print("⚙️ Default settings loaded")


func get_character_scene_path(character_key: String) -> String:
	if not character_player_scenes.has(character_key):
		return ""
	
	var path = character_player_scenes[character_key]
	
	if ResourceLoader.exists(path):
		return path
	else:
		return ""


func character_scene_exists(character_key: String) -> bool:
	return get_character_scene_path(character_key) != ""


func load_character_scene(character_key: String):
	var path = get_character_scene_path(character_key)
	if path == "":
		return null
	return load(path)


func register_game_ui(ui_node: CanvasLayer):
	game_ui = ui_node


func unregister_game_ui():
	game_ui = null


func register_player(player_node):
	if player_node == null:
		return
	
	current_player = player_node
	if player_node is Node:
		print("✅ Игрок зарегистрирован: ", player_node.name)
		apply_all_artifacts_to_player()


func unregister_player():
	current_player = null


func get_selected_character_data():
	if selected_character == null:
		return null
	if character_data == null:
		return null
	if character_data.has(selected_character):
		return character_data[selected_character]
	return null


func get_selected_character_name():
	var data = get_selected_character_data()
	if data == null:
		return "Unknown"
	if data is Dictionary and data.has("name"):
		return data["name"]
	return "Unknown"


func change_level(level_path: String):
	if level_path == null or level_path == "":
		return
	
	unregister_player()
	unregister_game_ui()
	
	if ResourceLoader.exists(level_path):
		get_tree().change_scene_to_file(level_path)


func return_to_main_menu():
	full_reset()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func quit_game():
	get_tree().quit()


func debug_print_state():
	print("=== GLOBAL STATE DEBUG ===")
	print("Selected character: ", selected_character)
	print("Current player: ", current_player)
	print("Collected keys: ", collected_keys)
	print("Spawn point: ", spawn_point)
	print("==========================")


# ===========================================
# АРТЕФАКТЫ
# ===========================================

func has_artifact(artifact_id: String) -> bool:
	return collected_artifacts.has(artifact_id)


func has_ability(ability_name: String) -> bool:
	for artifact_id in collected_artifacts:
		if artifacts_database.has(artifact_id):
			var artifact = artifacts_database[artifact_id]
			if artifact.get("ability", "") == ability_name:
				return true
	return false


func collect_artifact(artifact_id: String) -> bool:
	if not artifacts_database.has(artifact_id):
		return false
	
	if collected_artifacts.has(artifact_id):
		return false
	
	collected_artifacts.append(artifact_id)
	add_artifact_collected()
	
	var artifact = artifacts_database[artifact_id]
	if artifact.get("ability", "") == "revival":
		set_revival_artifact(artifact_id)
	
	if current_player:
		apply_artifact_effect(artifact_id)
	
	artifact_collected.emit(artifact_id)
	return true


func apply_artifact_effect(artifact_id: String):
	if not current_player:
		return
	
	if not artifacts_database.has(artifact_id):
		return
	
	var artifact = artifacts_database[artifact_id]
	
	match artifact.get("ability", ""):
		"double_jump":
			if "enable_double_jump" in current_player:
				current_player.enable_double_jump = true
		
		"dash":
			if "base_speed" in current_player and "current_speed" in current_player:
				current_player.base_speed = int(current_player.base_speed * 1.3)
				current_player.current_speed = current_player.base_speed
		
		"speed":
			if "base_speed" in current_player and "current_speed" in current_player:
				current_player.base_speed = int(current_player.base_speed * 1.15)
				current_player.current_speed = current_player.base_speed
		
		"max_health":
			if "max_health" in current_player and "current_health" in current_player:
				current_player.max_health += 20
				current_player.current_health += 20
		
		"max_mana":
			if "max_mana" in current_player and "current_mana" in current_player:
				current_player.max_mana += 20
				current_player.current_mana += 20


func apply_all_artifacts_to_player():
	if not current_player:
		return
	
	for artifact_id in collected_artifacts:
		apply_artifact_effect(artifact_id)


func get_artifact_data(artifact_id: String) -> Dictionary:
	if artifacts_database.has(artifact_id):
		return artifacts_database[artifact_id]
	return {"name": artifact_id, "rarity": "common", "ability": "unknown"}


func get_artifact_rarity(artifact_id: String) -> String:
	if artifacts_database.has(artifact_id):
		return artifacts_database[artifact_id].get("rarity", "common")
	return "common"


func get_artifacts_by_rarity() -> Dictionary:
	var result = {"common": [], "rare": [], "epic": [], "legendary": []}
	
	for artifact_id in collected_artifacts:
		var rarity = get_artifact_rarity(artifact_id)
		if result.has(rarity):
			result[rarity].append(artifact_id)
	
	return result


func reset_artifacts():
	collected_artifacts.clear()
	revival_artifact_id = ""


# ===========================================
# КЛЮЧИ
# ===========================================

func has_key(key_color: int) -> bool:
	return collected_keys.has(key_color)


func add_key(key_color: int):
	if not collected_keys.has(key_color):
		collected_keys.append(key_color)
		add_key_collected()
		print("🔑 Ключ добавлен: цвет %d" % key_color)


func remove_key(key_color: int):
	if collected_keys.has(key_color):
		collected_keys.erase(key_color)


func get_keys_count() -> int:
	return collected_keys.size()


func get_all_keys() -> Array:
	return collected_keys.duplicate()


func reset_keys():
	collected_keys.clear()
	spawn_point = ""
	opened_doors.clear()


func mark_door_opened(door_id: String):
	if not opened_doors.has(door_id):
		opened_doors.append(door_id)


func is_door_opened(door_id: String) -> bool:
	return opened_doors.has(door_id)


# ===========================================
# ЗАБЕГ
# ===========================================

func start_run():
	reset_run_statistics()
	run_statistics["start_time"] = Time.get_unix_time_from_system()
	run_started = true


func reset_run_statistics():
	run_statistics = {
		"death_reason": "",
		"keys_collected": 0,
		"items_collected": 0,
		"artifacts_collected": 0,
		"coins_collected": 0,
		"enemies_simple": 0,
		"enemies_elite": 0,
		"enemies_boss": 0,
		"damage_dealt": 0,
		"damage_taken": 0,
		"rooms_visited": 1,
		"time_played": 0.0,
		"start_time": 0.0
	}
	run_started = false


func full_reset():
	reset_run_statistics()
	reset_artifacts()
	reset_keys()
	unregister_player()
	unregister_game_ui()


func reset_all_for_new_game():
	full_reset()


# ===========================================
# СТАТИСТИКА
# ===========================================

func add_key_collected():
	run_statistics["keys_collected"] += 1


func add_item_collected():
	run_statistics["items_collected"] += 1


func add_artifact_collected():
	run_statistics["artifacts_collected"] += 1


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
	if run_started and run_statistics["start_time"] > 0:
		run_statistics["time_played"] = Time.get_unix_time_from_system() - run_statistics["start_time"]


func get_run_statistics() -> Dictionary:
	update_play_time()
	run_statistics["artifacts_collected"] = collected_artifacts.size()
	return run_statistics.duplicate()


# ===========================================
# ВОЗРОЖДЕНИЕ
# ===========================================

func set_revival_artifact(artifact_id: String):
	revival_artifact_id = artifact_id


func get_revival_artifact() -> String:
	return revival_artifact_id


func has_revival_artifact() -> bool:
	return revival_artifact_id != ""


func use_revival_artifact() -> String:
	var used_id = revival_artifact_id
	revival_artifact_id = ""
	
	if collected_artifacts.has(used_id):
		collected_artifacts.erase(used_id)
	
	return used_id


func save_safe_position(room_path: String, pos: Vector2):
	last_room_path = room_path
	last_safe_position = pos
