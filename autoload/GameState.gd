extends Node

# ===========================================
# GAMESTATE.GD - СОСТОЯНИЕ ЗАБЕГА (AUTOLOAD)
# ===========================================
# Путь: res://scripts/autoload/GameState.gd
# AutoLoad: GameState
#
# Хранит ВСЁ состояние текущего забега.
# НЕ сбрасывается при смене сцены!

signal run_started
signal run_ended
signal player_died
signal player_revived

# ===========================================
# ФЛАГИ ЗАБЕГА
# ===========================================

var is_run_active: bool = false
var current_level_path: String = ""
var previous_level_path: String = ""

# ===========================================
# СОСТОЯНИЕ ОБЪЕКТОВ (ПО ИМЕНАМ УЗЛОВ)
# ===========================================

var collected_pickups: Dictionary = {}   # {"Level1/Key_Gold": true}
var killed_enemies: Dictionary = {}      # {"Level1/Lizard1": true}
var opened_doors: Dictionary = {}        # {"Level1/Door_ToLevel2": true}
var opened_chests: Dictionary = {}       # {"Level1/Chest1": true}

# ===========================================
# КЛЮЧИ (ПО ЦВЕТАМ)
# ===========================================

enum KeyColor { GOLD = 0, SILVER = 1, ORANGE = 2, BLUE = 3, GREEN = 4, RED = 5 }

var keys: Dictionary = {
	KeyColor.GOLD: 0,
	KeyColor.SILVER: 0,
	KeyColor.ORANGE: 0,
	KeyColor.BLUE: 0,
	KeyColor.GREEN: 0,
	KeyColor.RED: 0
}

signal keys_changed(keys: Dictionary)

# ===========================================
# АРТЕФАКТЫ
# ===========================================

var collected_artifacts: Array = []
var revival_artifact_id: String = ""

signal artifact_collected(artifact_id: String)

# ===========================================
# СОХРАНЁННЫЕ СТАТЫ ИГРОКА
# ===========================================

var saved_health: int = -1
var saved_mana: int = -1
var saved_armor: int = -1

# ===========================================
# ТОЧКА СПАВНА
# ===========================================

var spawn_point_id: String = ""

# ===========================================
# СТАТИСТИКА ЗАБЕГА
# ===========================================

var stats: Dictionary = {
	"start_time": 0.0,
	"play_time": 0.0,
	"enemies_killed": 0,
	"damage_dealt": 0,
	"damage_taken": 0,
	"keys_collected": 0,
	"items_collected": 0,
	"rooms_visited": 1,
	"death_reason": ""
}


func _ready():
	print("🎮 GameState.gd loaded (AutoLoad)")


# ===========================================
# УПРАВЛЕНИЕ ЗАБЕГОМ
# ===========================================

func start_new_run():
	"""Начинает новый забег - полный сброс"""
	print("🎮 ═══════════════════════════════")
	print("🎮 НОВЫЙ ЗАБЕГ")
	print("🎮 ═══════════════════════════════")
	
	is_run_active = true
	
	# Сброс состояния объектов
	collected_pickups.clear()
	killed_enemies.clear()
	opened_doors.clear()
	opened_chests.clear()
	
	# Сброс ключей
	for color in keys:
		keys[color] = 0
	keys_changed.emit(keys)
	
	# Сброс артефактов
	collected_artifacts.clear()
	revival_artifact_id = ""
	
	# Сброс сохранённых статов
	saved_health = -1
	saved_mana = -1
	saved_armor = -1
	spawn_point_id = ""
	
	# Сброс статистики
	stats = {
		"start_time": Time.get_unix_time_from_system(),
		"play_time": 0.0,
		"enemies_killed": 0,
		"damage_dealt": 0,
		"damage_taken": 0,
		"keys_collected": 0,
		"items_collected": 0,
		"rooms_visited": 1,
		"death_reason": ""
	}
	
	run_started.emit()


func end_run(reason: String = ""):
	"""Завершает забег"""
	print("🎮 ЗАБЕГ ЗАВЕРШЁН: %s" % reason)
	
	is_run_active = false
	stats["death_reason"] = reason
	_update_play_time()
	
	run_ended.emit()


func _update_play_time():
	if stats["start_time"] > 0:
		stats["play_time"] = Time.get_unix_time_from_system() - stats["start_time"]


# ===========================================
# ПЕРЕХОД МЕЖДУ УРОВНЯМИ
# ===========================================

func prepare_level_transition(target_level: String, spawn_id: String = ""):
	"""Подготовка к переходу на другой уровень"""
	print("🚪 Переход: %s → %s (spawn: %s)" % [current_level_path, target_level, spawn_id])
	
	previous_level_path = current_level_path
	spawn_point_id = spawn_id
	
	stats["rooms_visited"] += 1


func set_current_level(level_path: String):
	"""Устанавливает текущий уровень"""
	current_level_path = level_path


# ===========================================
# РЕГИСТРАЦИЯ ОБЪЕКТОВ
# ===========================================

func _get_full_id(object_name: String) -> String:
	"""Формирует полный ID: Level/ObjectName"""
	var level_name = current_level_path.get_file().get_basename()
	return "%s/%s" % [level_name, object_name]


func register_pickup(object_name: String):
	"""Регистрирует подобранный объект"""
	var full_id = _get_full_id(object_name)
	collected_pickups[full_id] = true
	print("📦 Подобрано: %s" % full_id)


func register_enemy_killed(enemy_name: String):
	"""Регистрирует убитого врага"""
	var full_id = _get_full_id(enemy_name)
	killed_enemies[full_id] = true
	stats["enemies_killed"] += 1
	print("💀 Убит: %s" % full_id)


func register_door_opened(door_name: String):
	"""Регистрирует открытую дверь"""
	var full_id = _get_full_id(door_name)
	opened_doors[full_id] = true
	print("🚪 Открыта: %s" % full_id)


func register_chest_opened(chest_name: String):
	"""Регистрирует открытый сундук"""
	var full_id = _get_full_id(chest_name)
	opened_chests[full_id] = true
	print("📦 Сундук открыт: %s" % full_id)


# ===========================================
# ПРОВЕРКА СОСТОЯНИЯ
# ===========================================

func is_pickup_collected(object_name: String) -> bool:
	var full_id = _get_full_id(object_name)
	return collected_pickups.has(full_id)


func is_enemy_killed(enemy_name: String) -> bool:
	var full_id = _get_full_id(enemy_name)
	return killed_enemies.has(full_id)


func is_door_opened(door_name: String) -> bool:
	var full_id = _get_full_id(door_name)
	return opened_doors.has(full_id)


func is_chest_opened(chest_name: String) -> bool:
	var full_id = _get_full_id(chest_name)
	return opened_chests.has(full_id)


# ===========================================
# КЛЮЧИ
# ===========================================

func add_key(color: int, amount: int = 1):
	if not keys.has(color):
		keys[color] = 0
	keys[color] += amount
	stats["keys_collected"] += amount
	print("🔑 +%d ключ (цвет %d), всего: %d" % [amount, color, keys[color]])
	keys_changed.emit(keys)


func remove_key(color: int, amount: int = 1) -> bool:
	if keys.get(color, 0) < amount:
		return false
	keys[color] -= amount
	print("🔑 -%d ключ (цвет %d), осталось: %d" % [amount, color, keys[color]])
	keys_changed.emit(keys)
	return true


func has_key(color: int) -> bool:
	return keys.get(color, 0) > 0


func get_key_count(color: int) -> int:
	return keys.get(color, 0)


func get_all_keys() -> Dictionary:
	return keys.duplicate()


# ===========================================
# АРТЕФАКТЫ
# ===========================================

func collect_artifact(artifact_id: String):
	if artifact_id in collected_artifacts:
		return false
	
	collected_artifacts.append(artifact_id)
	print("🎁 Артефакт: %s" % artifact_id)
	
	artifact_collected.emit(artifact_id)
	return true


func has_artifact(artifact_id: String) -> bool:
	return artifact_id in collected_artifacts


func set_revival_artifact(artifact_id: String):
	revival_artifact_id = artifact_id
	print("✨ Артефакт возрождения: %s" % artifact_id)


func has_revival_artifact() -> bool:
	return revival_artifact_id != ""


func use_revival_artifact() -> String:
	var used = revival_artifact_id
	revival_artifact_id = ""
	collected_artifacts.erase(used)
	print("🔥 Использован артефакт: %s" % used)
	return used


# ===========================================
# СОХРАНЕНИЕ СТАТОВ ИГРОКА
# ===========================================

func save_player_stats(health: int, mana: int = -1, armor: int = -1):
	"""Сохраняет статы перед переходом"""
	saved_health = health
	saved_mana = mana
	saved_armor = armor
	print("💾 Сохранено: HP=%d, Mana=%d, Armor=%d" % [health, mana, armor])


func get_saved_stats() -> Dictionary:
	return {
		"health": saved_health,
		"mana": saved_mana,
		"armor": saved_armor
	}


func has_saved_stats() -> bool:
	return saved_health > 0


func clear_saved_stats():
	saved_health = -1
	saved_mana = -1
	saved_armor = -1


# ===========================================
# СТАТИСТИКА
# ===========================================

func add_damage_dealt(amount: int):
	stats["damage_dealt"] += amount


func add_damage_taken(amount: int):
	stats["damage_taken"] += amount


func add_item_collected():
	stats["items_collected"] += 1


func get_stats() -> Dictionary:
	_update_play_time()
	return stats.duplicate()


# ===========================================
# ОТЛАДКА
# ===========================================

func debug_print():
	print("═══════════════════════════════════")
	print("GAMESTATE DEBUG")
	print("═══════════════════════════════════")
	print("Run active: %s" % is_run_active)
	print("Current level: %s" % current_level_path)
	print("Spawn point: %s" % spawn_point_id)
	print("Keys: %s" % keys)
	print("Pickups: %d" % collected_pickups.size())
	print("Enemies killed: %d" % killed_enemies.size())
	print("Doors opened: %d" % opened_doors.size())
	print("Artifacts: %s" % collected_artifacts)
	print("Saved HP: %d" % saved_health)
	print("═══════════════════════════════════")
