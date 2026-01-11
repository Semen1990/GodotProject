extends Node2D

@onready var player_spawn = $PlayerSpawn
@onready var game_ui = $GameUI

var current_player = null

func _ready():
	print("🎮 Level 1 loaded!")
	print("Global.selected_character: ", Global.selected_character)
	
	# === КРИТИЧЕСКИ ВАЖНО: Начинаем новый забег ===
	if Global and Global.has_method("start_run"):
		Global.start_run()
		print("📊 Новый забег начат!")
	
	# Ждем полной загрузки
	await get_tree().process_frame
	
	# Спавним персонажа
	spawn_selected_character()
	
	# Регистрируем UI
	if Global and game_ui:
		Global.register_game_ui(game_ui)
		print("✅ Game UI registered")

func spawn_selected_character():
	print("🔄 Attempting to spawn character...")
	
	# Если персонаж не выбран, используем воина по умолчанию
	if not Global.selected_character:
		print("❌ No character selected in Global! Using default warrior.")
		Global.selected_character = "warrior"
	
	print("🔄 Spawning character: ", Global.selected_character)
	
	# Получаем путь к сцене персонажа
	var character_scene_path = Global.character_player_scenes.get(Global.selected_character)
	
	if character_scene_path and ResourceLoader.exists(character_scene_path):
		var character_scene = load(character_scene_path)
		current_player = character_scene.instantiate()
		
		# Размещаем персонажа в точке спавна
		if player_spawn:
			current_player.global_position = player_spawn.global_position
			add_child(current_player)
			print("✅ Player spawned: ", Global.selected_character)
			
			# Регистрируем игрока в Global
			Global.register_player(current_player)
			
			# ИСПРАВЛЕНО: Подключаем UI ПОСЛЕ регистрации
			setup_player_ui()
			
			# Настраиваем камеру
			setup_player_camera()
		else:
			current_player.global_position = Vector2(100, 100)
			add_child(current_player)
	else:
		print("❌ Character scene not found")
		create_fallback_player()

func setup_player_ui():
	"""ИСПРАВЛЕНО: Подключает UI к персонажу"""
	if not current_player or not game_ui:
		print("⚠️ Нет игрока или UI для подключения")
		return
	
	print("\n=== 🔗 ПОДКЛЮЧЕНИЕ UI К ПЕРСОНАЖУ ===")
	
	# Получаем характеристики персонажа
	var stats = {
		"health": current_player.current_health,
		"max_health": current_player.max_health,
		"mana": current_player.current_mana,
		"max_mana": current_player.max_mana,
		"armor": current_player.armor
	}
	
	print("📊 Статы персонажа:")
	print("  HP: ", stats["health"], "/", stats["max_health"])
	print("  MP: ", stats["mana"], "/", stats["max_mana"])
	print("  ARM: ", stats["armor"])
	
	# Настраиваем UI
	game_ui.setup_character_ui(stats)
	
	# ВАЖНО: Подключаем сигналы
	if current_player.has_signal("health_changed"):
		current_player.health_changed.connect(_on_player_health_changed)
		print("✅ Сигнал health_changed подключён")
	
	if current_player.has_signal("mana_changed"):
		current_player.mana_changed.connect(_on_player_mana_changed)
		print("✅ Сигнал mana_changed подключён")
	
	# Подключаем обновление брони (через таймер, так как нет сигнала)
	var armor_timer = Timer.new()
	armor_timer.wait_time = 0.1  # Проверяем каждые 0.1 сек
	armor_timer.timeout.connect(_check_armor_changed)
	add_child(armor_timer)
	armor_timer.start()
	
	print("=== ✅ UI ПОДКЛЮЧЕН ===\n")

var last_armor_value: int = 0

func _check_armor_changed():
	"""Проверяет изменение брони и обновляет UI"""
	if not current_player:
		return
	
	if current_player.armor != last_armor_value:
		last_armor_value = current_player.armor
		_on_player_armor_changed(current_player.armor)

func _on_player_health_changed(new_health):
	"""Обработчик изменения здоровья"""
	print("💖 UI: HP изменено на ", new_health)
	if game_ui:
		game_ui.update_health(new_health)

func _on_player_mana_changed(new_mana):
	"""Обработчик изменения маны"""
	print("💙 UI: MP изменена на ", new_mana)
	if game_ui:
		game_ui.update_mana(new_mana)

func _on_player_armor_changed(new_armor):
	"""Обработчик изменения брони"""
	print("🛡️ UI: ARM изменена на ", new_armor)
	if game_ui:
		game_ui.update_armor(new_armor)

func setup_player_camera():
	if not current_player:
		return
	
	# Ищем или создаем камеру
	var camera = current_player.get_node_or_null("Camera2D")
	if not camera:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		camera.zoom = Vector2(1.5, 1.5)
		current_player.add_child(camera)
	
	# Устанавливаем лимиты
	camera.limit_left = 0
	camera.limit_right = 2000
	camera.limit_top = 0
	camera.limit_bottom = 1200
	
	camera.make_current()

func create_fallback_player():
	print("🔄 Creating fallback player...")
	
	var player = CharacterBody2D.new()
	player.name = "FallbackPlayer"
	
	# Коллайдер
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(30, 50)
	collision.shape = shape
	player.add_child(collision)
	
	# Спрайт
	var sprite = Sprite2D.new()
	sprite.texture = preload("res://icon.svg")
	sprite.modulate = Color.RED
	player.add_child(sprite)
	
	# Скрипт
	var player_script = load("res://scripts/game_characters/base_game_character.gd")
	if player_script:
		player.set_script(player_script)
	
	# Позиция
	if player_spawn:
		player.global_position = player_spawn.global_position
	else:
		player.global_position = Vector2(100, 100)
	
	add_child(player)
	current_player = player
	print("✅ Fallback player created")
