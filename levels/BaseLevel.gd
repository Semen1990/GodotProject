extends Node2D
class_name BaseLevel

# ===========================================
# BASE LEVEL - БАЗОВЫЙ СКРИПТ УРОВНЯ
# ===========================================
# Путь: res://scripts/levels/BaseLevel.gd
#
# Наследуйся от этого скрипта для создания уровней.
# Или просто прикрепи его к сцене уровня.

@export var level_name: String = "Level"
@export var level_path: String = ""  # Автоматически определяется

# Ноды (ищутся автоматически)
var player_spawn: Marker2D = null
var game_ui: CanvasLayer = null
var current_player: Node = null

# Флаг инициализации
var is_initialized: bool = false


func _ready():
	print("")
	print("🎮 ═══════════════════════════════════")
	print("🎮 %s ЗАГРУЖЕН" % level_name.to_upper())
	print("🎮 ═══════════════════════════════════")
	
	# Определяем путь уровня
	if level_path.is_empty():
		level_path = scene_file_path
	
	# Устанавливаем текущий уровень в GameState
	if GameState:
		GameState.set_current_level(level_path)
	
	# Ищем ноды
	_find_nodes()
	
	# Проверяем: новая игра или продолжение?
	if GameState and GameState.is_run_active:
		print("🔄 Продолжение забега")
		_on_level_continue()
	else:
		print("🆕 Новый забег")
		_on_level_start_new()
	
	# Спавним игрока
	await get_tree().process_frame
	_spawn_player()
	
	# Применяем сохранённое состояние
	call_deferred("_apply_saved_state")
	
	# Регистрируем UI
	if game_ui and Global:
		Global.register_game_ui(game_ui)
	
	is_initialized = true
	_on_level_ready()
	
	print("🎮 ═══════════════════════════════════")
	print("")


# ===========================================
# ПОИСК НОД
# ===========================================

func _find_nodes():
	"""Находит важные ноды на уровне"""
	player_spawn = get_node_or_null("PlayerSpawn")
	game_ui = get_node_or_null("GameUI")
	
	if not player_spawn:
		# Ищем любой Marker2D с "spawn" в имени
		for child in get_children():
			if child is Marker2D and "spawn" in child.name.to_lower():
				player_spawn = child
				break
	
	print("   PlayerSpawn: %s" % ("✅" if player_spawn else "❌"))
	print("   GameUI: %s" % ("✅" if game_ui else "❌"))


# ===========================================
# СОБЫТИЯ УРОВНЯ (ПЕРЕОПРЕДЕЛЯЙ!)
# ===========================================

func _on_level_start_new():
	"""Вызывается при новом забеге"""
	# Очищаем инвентарь
	if Inventory:
		Inventory.clear_all()
	
	# Начинаем забег
	if GameState:
		GameState.start_new_run()


func _on_level_continue():
	"""Вызывается при продолжении забега (переход с другого уровня)"""
	pass


func _on_level_ready():
	"""Вызывается когда уровень полностью готов"""
	pass


# ===========================================
# СПАВН ИГРОКА
# ===========================================

func _spawn_player():
	"""Спавнит выбранного персонажа"""
	if not Global or not Global.selected_character:
		Global.selected_character = "warrior"
	
	var scene_path = Global.character_player_scenes.get(Global.selected_character)
	if not scene_path or not ResourceLoader.exists(scene_path):
		push_error("❌ Сцена персонажа не найдена: %s" % scene_path)
		return
	
	var scene = load(scene_path)
	current_player = scene.instantiate()
	
	# Позиция спавна
	var spawn_pos = Vector2(100, 500)
	
	# Ищем точку спавна по ID
	if GameState and not GameState.spawn_point_id.is_empty():
		var spawn_node = _find_spawn_point(GameState.spawn_point_id)
		if spawn_node:
			spawn_pos = spawn_node.global_position
			print("   Спавн: %s (%s)" % [GameState.spawn_point_id, spawn_pos])
		GameState.spawn_point_id = ""  # Сбрасываем
	elif player_spawn:
		spawn_pos = player_spawn.global_position
	
	current_player.global_position = spawn_pos
	add_child(current_player)
	
	# Регистрируем
	if Global:
		Global.register_player(current_player)
	
	# Подключаем сигналы
	if current_player.has_signal("died"):
		current_player.died.connect(_on_player_died)
	
	# Восстанавливаем статы
	if GameState and GameState.has_saved_stats():
		_restore_player_stats()
	
	_setup_camera()
	_setup_ui()
	
	print("   ✅ Игрок создан: %s" % Global.selected_character)


func _find_spawn_point(spawn_id: String) -> Node2D:
	"""Ищет точку спавна по ID"""
	for child in get_children():
		if child.name == spawn_id:
			return child
		if child is Marker2D and child.get("spawn_point_id") == spawn_id:
			return child
	return null


func _restore_player_stats():
	"""Восстанавливает HP/Mana после перехода"""
	if not current_player:
		return
	
	var stats = GameState.get_saved_stats()
	
	if stats["health"] > 0:
		current_player.current_health = stats["health"]
	if stats["mana"] >= 0 and "current_mana" in current_player:
		current_player.current_mana = stats["mana"]
	
	print("   💾 Статы восстановлены: HP=%d" % stats["health"])
	
	# Обновляем UI
	if current_player.has_signal("health_changed"):
		current_player.health_changed.emit(current_player.current_health)


# ===========================================
# ПРИМЕНЕНИЕ СОХРАНЁННОГО СОСТОЯНИЯ
# ===========================================

func _apply_saved_state():
	"""Удаляет собранные объекты и убитых врагов"""
	if not GameState or not GameState.is_run_active:
		return
	
	await get_tree().process_frame
	
	print("📂 Применяем сохранённое состояние...")
	
	for child in get_children():
		var child_name = child.name
		
		# Собранные пикапы
		if GameState.is_pickup_collected(child_name):
			print("   🗑️ Удаляем pickup: %s" % child_name)
			child.queue_free()
			continue
		
		# Убитые враги
		if GameState.is_enemy_killed(child_name):
			print("   💀 Враг мёртв: %s" % child_name)
			child.queue_free()
			continue
		
		# Открытые сундуки
		if GameState.is_chest_opened(child_name):
			if child.has_method("set_opened"):
				child.set_opened(true)
			else:
				child.queue_free()
			continue
		
		# Открытые двери
		if GameState.is_door_opened(child_name):
			if "is_open" in child:
				child.is_open = true
			if child.has_method("update_visual"):
				child.update_visual()


# ===========================================
# СОХРАНЕНИЕ ПЕРЕД ПЕРЕХОДОМ
# ===========================================

func save_before_transition():
	"""Вызывается дверью перед переходом"""
	if not current_player or not GameState:
		return
	
	var mana = current_player.current_mana if "current_mana" in current_player else -1
	var armor = current_player.armor if "armor" in current_player else -1
	
	GameState.save_player_stats(
		current_player.current_health,
		mana,
		armor
	)


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
	
	# Лимиты камеры (переопредели для своего уровня)
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
	
	# Подключаем сигналы
	if current_player.has_signal("health_changed"):
		current_player.health_changed.connect(_on_health_changed)
	if current_player.has_signal("mana_changed"):
		current_player.mana_changed.connect(_on_mana_changed)


func _on_health_changed(value):
	if game_ui and game_ui.has_method("update_health"):
		game_ui.update_health(value)


func _on_mana_changed(value):
	if game_ui and game_ui.has_method("update_mana"):
		game_ui.update_mana(value)


# ===========================================
# СМЕРТЬ ИГРОКА
# ===========================================

func _on_player_died():
	print("💀 Игрок погиб на %s" % level_name)
	
	# Меню смерти покажется автоматически через death_menu.gd
