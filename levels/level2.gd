extends Node2D

# ===========================================
# LEVEL 2 - БАЗОВЫЙ СКРИПТ
# ===========================================
# Прикрепи этот скрипт к Level2

@onready var player_spawn = $PlayerSpawn
@onready var game_ui = $GameUI

var current_player = null


func _ready():
	print("🎮 Level 2 loaded!")
	
	# Level2 НИКОГДА не начинает новый забег
	# Игрок пришёл с Level1
	
	await get_tree().process_frame
	
	spawn_selected_character()
	
	if Global and game_ui:
		Global.register_game_ui(game_ui)
	
	print("✅ Level 2 готов!")


func spawn_selected_character():
	if not Global.selected_character:
		Global.selected_character = "warrior"
	
	print("🔄 Spawning: ", Global.selected_character)
	
	var character_scene_path = Global.character_player_scenes.get(Global.selected_character)
	
	if not character_scene_path or not ResourceLoader.exists(character_scene_path):
		print("❌ Character scene not found")
		return
	
	var character_scene = load(character_scene_path)
	current_player = character_scene.instantiate()
	
	# === ОПРЕДЕЛЯЕМ ПОЗИЦИЮ СПАВНА ===
	var spawn_pos = player_spawn.global_position if player_spawn else Vector2(100, 100)
	var spawn_source = "PlayerSpawn"
	
	# === ПРОВЕРЯЕМ spawn_point ОТ ДВЕРИ ===
	if Global.spawn_point != "":
		print("🔍 Ищем SpawnPoint: '%s'" % Global.spawn_point)
		var spawn_node = get_node_or_null(Global.spawn_point)
		if spawn_node:
			spawn_pos = spawn_node.global_position
			spawn_source = Global.spawn_point
			print("✅ Найден: %s" % spawn_pos)
		else:
			print("⚠️ SpawnPoint '%s' не найден!" % Global.spawn_point)
		Global.spawn_point = ""
	
	print("📍 Спавн: %s [%s]" % [spawn_pos, spawn_source])
	
	current_player.global_position = spawn_pos
	add_child(current_player)
	
	Global.register_player(current_player)
	
	# Подключаем сигналы
	if current_player.has_signal("died"):
		current_player.died.connect(_on_player_died)
	
	# === ВОССТАНАВЛИВАЕМ HP ===
	call_deferred("_restore_player_stats")
	
	_setup_camera()
	_setup_ui()
	
	print("✅ Player spawned")


func _restore_player_stats():
	if not current_player:
		return
	
	print("💾 Восстанавливаем статы...")
	print("💾 Saved HP: %d" % Global.saved_player_health)
	
	if Global.saved_player_health > 0:
		current_player.current_health = Global.saved_player_health
		print("💾 HP: %d" % current_player.current_health)
		
		if current_player.has_signal("health_changed"):
			current_player.health_changed.emit(current_player.current_health)
	
	if Global.saved_player_mana >= 0 and "current_mana" in current_player:
		current_player.current_mana = Global.saved_player_mana
		print("💾 Mana: %d" % current_player.current_mana)
		
		if current_player.has_signal("mana_changed"):
			current_player.mana_changed.emit(current_player.current_mana)
	
	_setup_ui()
	Global.clear_saved_stats()


func save_before_transition():
	"""Вызывается дверью перед переходом"""
	if not current_player:
		return
	
	Global.saved_player_health = current_player.current_health
	if "current_mana" in current_player:
		Global.saved_player_mana = current_player.current_mana
	
	print("💾 Сохранено: HP=%d, Mana=%d" % [Global.saved_player_health, Global.saved_player_mana])


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
	camera.limit_right = 2000
	camera.limit_top = 0
	camera.limit_bottom = 1200
	camera.make_current()


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
	print("💀 Игрок погиб на Level 2")
