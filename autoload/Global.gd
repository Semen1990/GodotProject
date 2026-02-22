extends Node

# ===========================================
# GLOBAL.GD - ВЕРСИЯ v6.0
# ===========================================
# ИЗМЕНЕНИЯ:
# 1. Правильный порядок цветов ключей
# 2. Артефакты НЕ активируются автоматически
# 3. Добавлен get_keys_array() для UI
# 4. Система сохранения открытых сундуков
# 5. Система восстановления выпавших предметов

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
# СИСТЕМА АРТЕФАКТОВ (ТОЛЬКО ДЛЯ ОТСЛЕЖИВАНИЯ)
# ===========================================
# ВАЖНО: Артефакты теперь работают ТОЛЬКО через инвентарь!
# collected_artifacts - только для статистики

var collected_artifacts: Array = []

# ===========================================
# СИСТЕМА КЛЮЧЕЙ
# ===========================================
# Порядок цветов (соответствует KeyPickup.KeyColor):
# 0 = GOLD (Золотой)
# 1 = SILVER (Серебряный)
# 2 = RED (Красный)
# 3 = BLUE (Синий)
# 4 = GREEN (Зелёный)
# 5 = PURPLE (Фиолетовый)

var keys: Dictionary = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0}

const KEY_COLOR_NAMES = {
	0: "золотой",
	1: "серебряный",
	2: "красный",
	3: "синий",
	4: "зелёный",
	5: "фиолетовый"
}

var spawn_point: String = ""
var opened_doors: Array = []

# ===========================================
# СИСТЕМА СОХРАНЕНИЯ СОСТОЯНИЯ
# ===========================================

var collected_pickups: Array = []
var killed_enemies: Array = []

var saved_player_health: int = -1
var saved_player_mana: int = -1

# === НОВОЕ: Сохранение сундуков и выпавших предметов ===
var opened_chests: Dictionary = {}  # {"level1": ["Chest", "ChestEquipment"], ...}
var dropped_pickups: Dictionary = {}  # {"level1": [{type, id, position}, ...], ...}
var current_level: String = ""  # Текущий уровень для отслеживания

# ===========================================
# БАЗА ДАННЫХ АРТЕФАКТОВ (для справки)
# ===========================================

var artifacts_database = {
	"hermes_wings": {
		"name": "Крылья Гермеса",
		"description": "Легендарные крылатые сандалии",
		"icon": "res://assets/items/artifacts/hermes_wings.png",
		"ability": "double_jump",
		"rarity": "rare",
		"effect_text": "Позволяет совершить второй прыжок в воздухе",
		"item_id": 201  # ID в инвентаре
	},
	"phoenix_feather": {
		"name": "Перо Феникса",
		"description": "Магическое перо возрождения",
		"icon": "res://assets/items/artifacts/phoenix_feather.png",
		"ability": "revival",
		"rarity": "legendary",
		"effect_text": "Возрождает после смерти с 50% HP",
		"item_id": 202  # ID в инвентаре
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

# Артефакт возрождения - устанавливается ТОЛЬКО из level1.gd
# когда артефакт ЭКИПИРОВАН в слот!
var revival_artifact_id: String = ""

var last_room_path: String = ""
var last_safe_position: Vector2 = Vector2.ZERO
var run_started: bool = false


func _ready():
	print("🌍 Global.gd v5.0 loaded!")
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
	_update_keys_ui()


func unregister_game_ui():
	game_ui = null


func register_player(player_node):
	if player_node == null:
		return
	
	current_player = player_node
	if player_node is Node:
		print("✅ Игрок зарегистрирован: ", player_node.name)
		# НЕ применяем артефакты автоматически!
		# Артефакты работают только через инвентарь
		if saved_player_health > 0:
			call_deferred("restore_player_stats")


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
	print("Keys: ", keys)
	print("Collected pickups: ", collected_pickups)
	print("Killed enemies: ", killed_enemies)
	print("Spawn point: ", spawn_point)
	print("Run started: ", run_started)
	print("Revival artifact: ", revival_artifact_id)
	print("==========================")


# ===========================================
# АРТЕФАКТЫ (ТОЛЬКО ДЛЯ СТАТИСТИКИ!)
# ===========================================
# ВАЖНО: Теперь артефакты работают ТОЛЬКО через систему инвентаря!
# Эти методы оставлены для обратной совместимости

func has_artifact(artifact_id: String) -> bool:
	"""Проверяет был ли артефакт собран (для статистики)"""
	return collected_artifacts.has(artifact_id)


func has_ability(ability_name: String) -> bool:
	"""УСТАРЕЛО: Теперь проверяется через инвентарь!"""
	# Оставляем для обратной совместимости, но не используем
	return false


func collect_artifact(artifact_id: String) -> bool:
	"""Регистрирует артефакт как собранный (для статистики)
	   НЕ активирует эффекты! Эффекты применяются через инвентарь."""
	if not artifacts_database.has(artifact_id):
		return false
	
	if collected_artifacts.has(artifact_id):
		return false
	
	collected_artifacts.append(artifact_id)
	add_artifact_collected()
	
	# НЕ применяем эффекты автоматически!
	# Артефакт нужно экипировать в слот инвентаря
	
	artifact_collected.emit(artifact_id)
	print("📦 Артефакт '%s' добавлен в статистику (нужно экипировать!)" % artifact_id)
	return true


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


func apply_all_artifacts_to_player():
	"""УСТАРЕЛО: Оставлено для обратной совместимости.
	   Артефакты теперь применяются через систему инвентаря!"""
	pass


func apply_artifact_effect(_artifact_id: String):
	"""УСТАРЕЛО: Оставлено для обратной совместимости.
	   Артефакты теперь применяются через систему инвентаря!"""
	pass


# ===========================================
# СИСТЕМА КЛЮЧЕЙ
# ===========================================

func has_key(color: int) -> bool:
	"""Проверяет наличие ключа указанного цвета"""
	return keys.get(color, 0) > 0


func add_key(color: int, amount: int = 1):
	"""Добавляет ключ(и) указанного цвета"""
	if not keys.has(color):
		keys[color] = 0
	keys[color] += amount
	run_statistics["keys_collected"] += amount
	
	var color_name = KEY_COLOR_NAMES.get(color, "неизвестный")
	print("🔑 +%d %s ключ (всего: %d)" % [amount, color_name, keys[color]])
	_update_keys_ui()


func remove_key(color: int, amount: int = 1) -> bool:
	"""Удаляет ключ. Возвращает true если успешно"""
	if keys.get(color, 0) < amount:
		var color_name = KEY_COLOR_NAMES.get(color, "неизвестный")
		print("🔑 ❌ Недостаточно %s ключей" % color_name)
		return false
	
	keys[color] -= amount
	var color_name = KEY_COLOR_NAMES.get(color, "неизвестный")
	print("🔑 -%d %s ключ (осталось: %d)" % [amount, color_name, keys[color]])
	_update_keys_ui()
	return true


func get_key_count(color: int) -> int:
	"""Возвращает количество ключей указанного цвета"""
	return keys.get(color, 0)


func get_all_keys() -> Dictionary:
	"""Возвращает все ключи"""
	return keys.duplicate()


func get_keys_array() -> Array:
	"""Возвращает массив количества ключей для UI
	   [gold, silver, red, blue, green, purple]"""
	return [
		keys.get(0, 0),  # Gold
		keys.get(1, 0),  # Silver
		keys.get(2, 0),  # Red
		keys.get(3, 0),  # Blue
		keys.get(4, 0),  # Green
		keys.get(5, 0),  # Purple
	]


func reset_keys():
	"""Сбрасывает все ключи"""
	keys = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
	spawn_point = ""
	opened_doors.clear()
	_update_keys_ui()


func _update_keys_ui():
	"""Обновляет UI ключей"""
	if not game_ui:
		return
	
	if game_ui.has_method("update_keys"):
		game_ui.update_keys(get_keys_array())
	elif game_ui.has_method("update_single_key"):
		for i in range(6):
			game_ui.update_single_key(i, keys.get(i, 0))


func mark_door_opened(door_id: String):
	if not opened_doors.has(door_id):
		opened_doors.append(door_id)


func is_door_opened(door_id: String) -> bool:
	return opened_doors.has(door_id)


# ===========================================
# СОХРАНЕНИЕ СОСТОЯНИЯ
# ===========================================

func register_collected_pickup(object_name: String):
	"""Регистрирует подобранный объект по имени узла"""
	if object_name not in collected_pickups:
		collected_pickups.append(object_name)
		print("📦 Собрано: %s" % object_name)


func register_killed_enemy(enemy_name: String):
	"""Регистрирует убитого врага по имени узла"""
	if enemy_name not in killed_enemies:
		killed_enemies.append(enemy_name)
		print("💀 Убит: %s" % enemy_name)


func is_pickup_collected(object_name: String) -> bool:
	"""Проверяет, был ли объект уже подобран"""
	return object_name in collected_pickups


func is_enemy_killed(enemy_name: String) -> bool:
	"""Проверяет, был ли враг уже убит"""
	return enemy_name in killed_enemies


# ===========================================
# СИСТЕМА СУНДУКОВ И ВЫПАВШИХ ПРЕДМЕТОВ
# ===========================================

func set_current_level(level_name: String):
	"""Устанавливает текущий уровень"""
	current_level = level_name
	print("🗺️ Текущий уровень: %s" % level_name)


func register_opened_chest(chest_name: String):
	"""Регистрирует открытый сундук"""
	if current_level == "":
		current_level = "unknown"
	
	if current_level not in opened_chests:
		opened_chests[current_level] = []
	
	if chest_name not in opened_chests[current_level]:
		opened_chests[current_level].append(chest_name)
		print("📦 Сундук открыт: %s на %s" % [chest_name, current_level])


func is_chest_opened(chest_name: String) -> bool:
	"""Проверяет, был ли сундук уже открыт (ищем во всех уровнях)"""
	for level in opened_chests.keys():
		if chest_name in opened_chests[level]:
			return true
	return false


func register_dropped_pickup(pickup_data: Dictionary):
	"""Регистрирует выпавший предмет для восстановления при возврате
	pickup_data = {type: "item"/"artifact", id: int/String, position: Vector2}
	"""
	if current_level == "":
		current_level = "unknown"
	
	if current_level not in dropped_pickups:
		dropped_pickups[current_level] = []
	
	dropped_pickups[current_level].append(pickup_data)


func get_dropped_pickups_for_level(level_name: String) -> Array:
	"""Возвращает список выпавших предметов для уровня"""
	if level_name in dropped_pickups:
		return dropped_pickups[level_name]
	return []


func remove_dropped_pickup(pickup_name: String):
	"""Удаляет выпавший предмет из списка (когда подобран)"""
	if current_level in dropped_pickups:
		for i in range(dropped_pickups[current_level].size() - 1, -1, -1):
			var pickup = dropped_pickups[current_level][i]
			if pickup.get("name", "") == pickup_name:
				dropped_pickups[current_level].remove_at(i)
				return


func clear_dropped_pickups_for_level(level_name: String):
	"""Очищает выпавшие предметы для уровня"""
	if level_name in dropped_pickups:
		dropped_pickups[level_name].clear()


func save_player_stats():
	"""Сохраняет HP/Mana игрока перед переходом"""
	if current_player:
		saved_player_health = current_player.current_health
		if "current_mana" in current_player:
			saved_player_mana = current_player.current_mana
		else:
			saved_player_mana = -1
		print("💾 Сохранено: HP=%d Mana=%d" % [saved_player_health, saved_player_mana])


func restore_player_stats():
	"""Восстанавливает HP/Mana после перехода"""
	if current_player and saved_player_health > 0:
		current_player.current_health = saved_player_health
		print("💾 Восстановлено: HP=%d" % saved_player_health)
		
		if "current_mana" in current_player and saved_player_mana >= 0:
			current_player.current_mana = saved_player_mana
		
		if current_player.has_signal("health_changed"):
			current_player.health_changed.emit(current_player.current_health)
		if current_player.has_signal("mana_changed") and "current_mana" in current_player:
			current_player.mana_changed.emit(current_player.current_mana)


func clear_saved_stats():
	saved_player_health = -1
	saved_player_mana = -1


# ===========================================
# ЗАБЕГ
# ===========================================

func start_run():
	print("🎮 === НОВЫЙ ЗАБЕГ ===")
	reset_run_statistics()
	run_statistics["start_time"] = Time.get_unix_time_from_system()
	run_started = true
	
	collected_pickups.clear()
	killed_enemies.clear()
	opened_chests.clear()  # Очищаем открытые сундуки
	dropped_pickups.clear()  # Очищаем выпавшие предметы
	reset_keys()
	reset_artifacts()
	clear_saved_stats()


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
	print("🔄 === ПОЛНЫЙ СБРОС ===")
	reset_run_statistics()
	reset_artifacts()
	reset_keys()
	
	collected_pickups.clear()
	killed_enemies.clear()
	opened_chests.clear()    # Очищаем открытые сундуки
	dropped_pickups.clear()  # Очищаем выпавшие предметы
	current_level = ""
	clear_saved_stats()
	
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
# ВАЖНО: revival_artifact_id устанавливается ТОЛЬКО из level1.gd
# когда Перо Феникса ЭКИПИРОВАНО в слот артефакта!

func set_revival_artifact(artifact_id: String):
	"""Устанавливает артефакт возрождения (вызывается из level1.gd)"""
	revival_artifact_id = artifact_id
	if artifact_id != "":
		print("✨ Артефакт возрождения активен: %s" % artifact_id)


func get_revival_artifact() -> String:
	return revival_artifact_id


func has_revival_artifact() -> bool:
	"""Проверяет есть ли АКТИВНЫЙ артефакт возрождения"""
	return revival_artifact_id != ""


func use_revival_artifact() -> String:
	"""Использует артефакт возрождения.
	   ВАЖНО: Удаление из инвентаря делается в level1.gd!"""
	var used_id = revival_artifact_id
	revival_artifact_id = ""
	print("🔮 Артефакт возрождения использован: %s" % used_id)
	return used_id


func save_safe_position(room_path: String, pos: Vector2):
	last_room_path = room_path
	last_safe_position = pos
