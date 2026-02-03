extends Node2D
class_name BaseLevel

# ===========================================
# BASE LEVEL v2.1 - ИСПРАВЛЕНО
# ===========================================
# - Исправлен спавн (spawn_point_id работает правильно)
# - Исправлено сохранение HP при переходе
# - Исправлена логика "новая игра vs продолжение"

@export var level_name: String = "Level"
@export var level_path: String = ""

var player_spawn: Marker2D = null
var game_ui: CanvasLayer = null
var current_player: Node = null
var is_initialized: bool = false


func _ready():
	print("")
	print("🎮 ═══════════════════════════════════")
	print("🎮 %s ЗАГРУЖЕН" % level_name.to_upper())
	print("🎮 ═══════════════════════════════════")
	
	if level_path.is_empty():
		level_path = scene_file_path
	
	if GameState:
		GameState.set_current_level(level_path)
	
	_find_nodes()
	
	# ВАЖНО: Проверяем ПЕРЕД спавном игрока
	var is_new_game = not GameState or not GameState.is_run_active
	
	if is_new_game:
		print("🆕 Новый забег")
		_on_level_start_new()
	else:
		print("🔄 Продолжение забега")
		_on_level_continue()
	
	await get_tree().process_frame
	_spawn_player(is_new_game)
	
	call_deferred("_apply_saved_state")
	
	if game_ui and Global:
		Global.register_game_ui(game_ui)
	
	is_initialized = true
	_on_level_ready()
	
	print("🎮 ═══════════════════════════════════")
	print("")


func _find_nodes():
	player_spawn = get_node_or_null("PlayerSpawn")
	game_ui = get_node_or_null("GameUI")
	
	if not player_spawn:
		for child in get_children():
			if child is Marker2D and "spawn" in child.name.to_lower():
				player_spawn = child
				break
	
	print("   PlayerSpawn: %s" % ("✅" if player_spawn else "❌"))
	print("   GameUI: %s" % ("✅" if game_ui else "❌"))


func _on_level_start_new():
	"""Новый забег - очищаем всё"""
	if Inventory:
		Inventory.clear_all()
	if GameState:
		GameState.start_new_run()


func _on_level_continue():
	"""Продолжение - НЕ очищаем инвентарь"""
	pass


func _on_level_ready():
	pass


# ===========================================
# СПАВН ИГРОКА - ИСПРАВЛЕНО!
# ===========================================

func _spawn_player(is_new_game: bool):
	if not Global or not Global.selected_character:
		Global.selected_character = "warrior"
	
	var scene_path = Global.character_player_scenes.get(Global.selected_character)
	if not scene_path or not ResourceLoader.exists(scene_path):
		push_error("❌ Сцена персонажа не найдена: %s" % scene_path)
		return
	
	var scene = load(scene_path)
	current_player = scene.instantiate()
	
	# === ОПРЕДЕЛЯЕМ ПОЗИЦИЮ СПАВНА ===
	var spawn_pos = Vector2(100, 500)
	var spawn_source = "default"
	
	# 1. Приоритет: spawn_point_id от двери
	if GameState and GameState.spawn_point_id != "":
		var spawn_id = GameState.spawn_point_id
		var spawn_node = _find_spawn_point(spawn_id)
		
		if spawn_node:
			spawn_pos = spawn_node.global_position
			spawn_source = "spawn_point: " + spawn_id
			print("   ✅ Найден spawn: '%s' → %s" % [spawn_id, spawn_pos])
		else:
			print("   ⚠️ Spawn '%s' не найден!" % spawn_id)
			# Fallback на PlayerSpawn
			if player_spawn:
				spawn_pos = player_spawn.global_position
				spawn_source = "PlayerSpawn (fallback)"
		
		# Сбрасываем ПОСЛЕ использования
		GameState.spawn_point_id = ""
	
	# 2. Если нет spawn_point_id - используем PlayerSpawn
	elif player_spawn:
		spawn_pos = player_spawn.global_position
		spawn_source = "PlayerSpawn"
	
	print("   📍 Спавн: %s [%s]" % [spawn_pos, spawn_source])
	
	current_player.global_position = spawn_pos
	add_child(current_player)
	
	if Global:
		Global.register_player(current_player)
	
	if current_player.has_signal("died"):
		current_player.died.connect(_on_player_died)
	
	# === ВОССТАНАВЛИВАЕМ HP ТОЛЬКО ПРИ ПРОДОЛЖЕНИИ ===
	if not is_new_game and GameState and GameState.has_saved_stats():
		_restore_player_stats()
	
	_setup_camera()
	_setup_ui()
	
	print("   ✅ Игрок: %s, HP: %d/%d" % [
		Global.selected_character, 
		current_player.current_health,
		current_player.max_health
	])


func _find_spawn_point(spawn_id: String) -> Node2D:
	"""Ищет точку спавна по ID"""
	# Прямой поиск по имени
	var node = get_node_or_null(spawn_id)
	if node:
		return node
	
	# Поиск среди детей
	for child in get_children():
		if child.name == spawn_id:
			return child
		if child.get("spawn_point_id") == spawn_id:
			return child
	
	return null


func _restore_player_stats():
	"""Восстанавливает HP/Mana после перехода"""
	if not current_player or not GameState:
		return
	
	var stats = GameState.get_saved_stats()
	
	if stats["health"] > 0:
		current_player.current_health = stats["health"]
		print("   💾 HP восстановлено: %d" % stats["health"])
	
	if stats["mana"] >= 0 and "current_mana" in current_player:
		current_player.current_mana = stats["mana"]
		print("   💾 Mana восстановлена: %d" % stats["mana"])
	
	# Очищаем сохранённые статы
	GameState.clear_saved_stats()
	
	# Обновляем UI
	await get_tree().process_frame
	if current_player.has_signal("health_changed"):
		current_player.health_changed.emit(current_player.current_health)
	if current_player.has_signal("mana_changed") and "current_mana" in current_player:
		current_player.mana_changed.emit(current_player.current_mana)


# ===========================================
# ПРИМЕНЕНИЕ СОХРАНЁННОГО СОСТОЯНИЯ
# ===========================================

func _apply_saved_state():
	if not GameState or not GameState.is_run_active:
		return
	
	await get_tree().process_frame
	print("📂 Применяем сохранённое состояние...")
	
	for child in get_children():
		var child_name = child.name
		
		# Проверяем pickup (только по имени)
		if GameState.is_pickup_collected(child_name):
			print("   🗑️ Удаляем: %s" % child_name)
			child.queue_free()
			continue
		
		# Проверяем врага
		if GameState.is_enemy_killed(child_name):
			print("   💀 Враг: %s" % child_name)
			child.queue_free()
			continue
		
		# Проверяем сундук
		if GameState.is_chest_opened(child_name):
			if child.has_method("set_opened"):
				child.set_opened(true)
			print("   📦 Сундук: %s" % child_name)
			continue
		
		# Проверяем дверь
		if GameState.is_door_opened(child_name):
			if "is_open" in child:
				child.is_open = true
			if child.has_method("_update_visual"):
				child._update_visual()
			print("   🚪 Дверь: %s" % child_name)


# ===========================================
# СОХРАНЕНИЕ ПЕРЕД ПЕРЕХОДОМ
# ===========================================

func save_before_transition():
	"""Вызывается дверью перед переходом"""
	if not current_player or not GameState:
		return
	
	var health = current_player.current_health
	var mana = current_player.current_mana if "current_mana" in current_player else -1
	var armor = current_player.armor if "armor" in current_player else -1
	
	print("💾 ═══════════════════════════════")
	print("💾 СОХРАНЕНИЕ ПЕРЕД ПЕРЕХОДОМ")
	print("💾 HP: %d, Mana: %d, Armor: %d" % [health, mana, armor])
	print("💾 ═══════════════════════════════")
	
	GameState.save_player_stats(health, mana, armor)


# ===========================================
# КАМЕРА
# ===========================================

func _setup_camera():
	if not current_player:
		return
	
	var camera = current_player.get_node_or_null("Camera2D")
	if not camera:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		camera.zoom = Vector2(1.5, 1.5)
		current_player.add_child(camera)
	
	camera.limit_left = 0
	camera.limit_right = 3000
	camera.limit_top = 0
	camera.limit_bottom = 1200
	camera.make_current()


# ===========================================
# UI
# ===========================================

func _setup_ui():
	if not current_player or not game_ui:
		return
	
	if game_ui.has_method("setup_character_ui"):
		var stats = {
			"health": current_player.current_health,
			"max_health": current_player.max_health,
			"mana": current_player.current_mana if "current_mana" in current_player else 0,
			"max_mana": current_player.max_mana if "max_mana" in current_player else 0,
			"armor": current_player.armor if "armor" in current_player else 0
		}
		game_ui.setup_character_ui(stats)
	
	if current_player.has_signal("health_changed"):
		if not current_player.health_changed.is_connected(_on_health_changed):
			current_player.health_changed.connect(_on_health_changed)
	
	if current_player.has_signal("mana_changed"):
		if not current_player.mana_changed.is_connected(_on_mana_changed):
			current_player.mana_changed.connect(_on_mana_changed)


func _on_health_changed(value):
	if game_ui and game_ui.has_method("update_health"):
		game_ui.update_health(value)


func _on_mana_changed(value):
	if game_ui and game_ui.has_method("update_mana"):
		game_ui.update_mana(value)


func _on_player_died():
	print("💀 Игрок погиб на %s" % level_name)
