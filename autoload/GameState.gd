extends Node

# ===========================================
# GAMESTATE v2.1 - СОСТОЯНИЕ ЗАБЕГА
# ===========================================
# AutoLoad: GameState
# Хранит ВСЁ состояние текущего забега
# НЕ сбрасывается при смене сцены!

signal run_started
signal run_ended
signal keys_changed(keys: Dictionary)
signal artifact_collected(artifact_id: String)

# ===========================================
# ФЛАГИ
# ===========================================

var is_run_active: bool = false
var current_level_path: String = ""

# ===========================================
# СОСТОЯНИЕ ОБЪЕКТОВ (по имени узла)
# ===========================================

var collected_pickups: Dictionary = {}   # {"Key_Gold": true}
var killed_enemies: Dictionary = {}      # {"Lizard1": true}
var opened_doors: Dictionary = {}        # {"Door_ToLevel2": true}
var opened_chests: Dictionary = {}       # {"Chest1": true}

# ===========================================
# КЛЮЧИ (по цветам)
# ===========================================

var keys: Dictionary = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0}

# ===========================================
# АРТЕФАКТЫ
# ===========================================

var collected_artifacts: Array = []
var revival_artifact_id: String = ""

# ===========================================
# СОХРАНЁННЫЕ СТАТЫ ИГРОКА
# ===========================================

var saved_health: int = -1
var saved_mana: int = -1
var saved_armor: int = -1

# ===========================================
# ТОЧКА СПАВНА (от двери)
# ===========================================

var spawn_point_id: String = ""

# ===========================================
# СТАТИСТИКА
# ===========================================

var stats: Dictionary = {}


func _ready():
	print("🎮 GameState v2.1 loaded")
	_reset_stats()


func _reset_stats():
	stats = {
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


# ===========================================
# УПРАВЛЕНИЕ ЗАБЕГОМ
# ===========================================

func start_new_run():
	print("🎮 ═══════════════════════════════")
	print("🎮 НОВЫЙ ЗАБЕГ")
	print("🎮 ═══════════════════════════════")
	
	is_run_active = true
	
	# Очищаем состояния
	collected_pickups.clear()
	killed_enemies.clear()
	opened_doors.clear()
	opened_chests.clear()
	
	# Очищаем ключи
	for color in keys:
		keys[color] = 0
	keys_changed.emit(keys)
	
	# Очищаем артефакты
	collected_artifacts.clear()
	revival_artifact_id = ""
	
	# Очищаем сохранённые статы
	clear_saved_stats()
	spawn_point_id = ""
	
	# Сбрасываем статистику
	_reset_stats()
	stats["start_time"] = Time.get_unix_time_from_system()
	
	run_started.emit()


func end_run(reason: String = ""):
	print("🎮 ЗАБЕГ ЗАВЕРШЁН: %s" % reason)
	is_run_active = false
	stats["death_reason"] = reason
	run_ended.emit()


func set_current_level(level_path: String):
	current_level_path = level_path


# ===========================================
# РЕГИСТРАЦИЯ ОБЪЕКТОВ (только по имени!)
# ===========================================

func register_pickup(object_name: String):
	collected_pickups[object_name] = true
	print("📦 Pickup: %s" % object_name)


func register_enemy_killed(enemy_name: String):
	killed_enemies[enemy_name] = true
	stats["enemies_killed"] += 1
	print("💀 Enemy: %s" % enemy_name)


func register_door_opened(door_name: String):
	opened_doors[door_name] = true
	print("🚪 Door: %s" % door_name)


func register_chest_opened(chest_name: String):
	opened_chests[chest_name] = true
	print("📦 Chest: %s" % chest_name)


# ===========================================
# ПРОВЕРКА СОСТОЯНИЯ
# ===========================================

func is_pickup_collected(object_name: String) -> bool:
	return collected_pickups.has(object_name)


func is_enemy_killed(enemy_name: String) -> bool:
	return killed_enemies.has(enemy_name)


func is_door_opened(door_name: String) -> bool:
	return opened_doors.has(door_name)


func is_chest_opened(chest_name: String) -> bool:
	return opened_chests.has(chest_name)


# ===========================================
# КЛЮЧИ
# ===========================================

func add_key(color: int, amount: int = 1):
	if not keys.has(color):
		keys[color] = 0
	keys[color] += amount
	stats["keys_collected"] += amount
	print("🔑 +%d ключ цвет %d (всего: %d)" % [amount, color, keys[color]])
	keys_changed.emit(keys)


func remove_key(color: int, amount: int = 1) -> bool:
	if keys.get(color, 0) < amount:
		print("🔑 ❌ Нет ключа цвет %d" % color)
		return false
	keys[color] -= amount
	print("🔑 -%d ключ цвет %d (осталось: %d)" % [amount, color, keys[color]])
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

func collect_artifact(artifact_id: String) -> bool:
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


func has_revival_artifact() -> bool:
	return revival_artifact_id != ""


func use_revival_artifact() -> String:
	var used = revival_artifact_id
	revival_artifact_id = ""
	collected_artifacts.erase(used)
	return used


# ===========================================
# СОХРАНЕНИЕ СТАТОВ ИГРОКА
# ===========================================

func save_player_stats(health: int, mana: int = -1, armor: int = -1):
	saved_health = health
	saved_mana = mana
	saved_armor = armor
	print("💾 Saved: HP=%d, Mana=%d, Armor=%d" % [health, mana, armor])


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
	if stats["start_time"] > 0:
		stats["play_time"] = Time.get_unix_time_from_system() - stats["start_time"]
	return stats.duplicate()


# ===========================================
# ОТЛАДКА
# ===========================================

func debug_print():
	print("═══════════════════════════════════")
	print("GAMESTATE DEBUG")
	print("═══════════════════════════════════")
	print("Run: %s" % is_run_active)
	print("Level: %s" % current_level_path)
	print("Spawn: '%s'" % spawn_point_id)
	print("Keys: %s" % keys)
	print("Pickups: %d" % collected_pickups.size())
	print("Enemies: %d" % killed_enemies.size())
	print("Doors: %d" % opened_doors.size())
	print("Chests: %d" % opened_chests.size())
	print("Saved HP: %d" % saved_health)
	print("═══════════════════════════════════")
