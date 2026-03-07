extends Node2D

const GAME_UI_SCENE := preload("res://scenes/Ui/game_ui.tscn")
const ARMOR_POLL_INTERVAL := 0.1

@onready var player_spawn = $PlayerSpawn

var game_ui: CanvasLayer = null
var current_player = null
var armor_watch_timer: Timer = null
var last_armor_value: int = -1


func _ready():
	print("\n=== LEVEL 2 v3.1 ===")
	if Global:
		Global.set_current_level("level2")

	await get_tree().process_frame
	_create_game_ui()
	_create_inventory_ui()
	spawn_selected_character()

	if Global and game_ui:
		Global.register_game_ui(game_ui)

	print("Level 2 ready")


func _create_game_ui():
	var existing_ui = get_node_or_null("GameUI")
	if existing_ui:
		game_ui = existing_ui
		if game_ui.has_method("rebuild_ui"):
			game_ui.rebuild_ui()
		print("Reused existing GameUI")
		return

	game_ui = GAME_UI_SCENE.instantiate()
	game_ui.name = "GameUI"
	add_child(game_ui)
	print("Created GameUI from scene")


func spawn_selected_character():
	if not Global.selected_character:
		Global.selected_character = "warrior"

	var character_scene_path = Global.character_player_scenes.get(Global.selected_character)
	if not character_scene_path or not ResourceLoader.exists(character_scene_path):
		print("Character scene not found")
		return

	var character_scene = load(character_scene_path)
	current_player = character_scene.instantiate()

	var spawn_pos = player_spawn.global_position if player_spawn else Vector2(100, 100)
	var spawn_source = "PlayerSpawn"

	if Global.spawn_point != "":
		var spawn_node = get_node_or_null(Global.spawn_point)
		if spawn_node:
			spawn_pos = spawn_node.global_position
			spawn_source = Global.spawn_point
		else:
			print("SpawnPoint '%s' not found" % Global.spawn_point)
		Global.spawn_point = ""

	print("Spawn: %s [%s]" % [spawn_pos, spawn_source])
	current_player.global_position = spawn_pos
	add_child(current_player)
	Global.register_player(current_player)

	if current_player.has_signal("died"):
		current_player.died.connect(_on_player_died)

	call_deferred("_restore_player_stats")
	_setup_camera()
	_setup_ui()
	print("Player spawned")


func _create_inventory_ui():
	var existing_inv = get_node_or_null("InventoryUI")
	if not existing_inv:
		var inv_ui = InventoryUI.new()
		inv_ui.name = "InventoryUI"
		add_child(inv_ui)
		print("InventoryUI created")

	var existing_hotbar = get_node_or_null("HotbarUI")
	if not existing_hotbar:
		var hotbar = HotbarUI.new()
		hotbar.name = "HotbarUI"
		add_child(hotbar)
		print("HotbarUI created")


func _restore_player_stats():
	if not current_player:
		return

	if Global.saved_player_health > 0:
		current_player.current_health = mini(Global.saved_player_health, current_player.max_health)
		if current_player.has_signal("health_changed"):
			current_player.health_changed.emit(current_player.current_health)

	if Global.saved_player_mana >= 0 and "current_mana" in current_player:
		current_player.current_mana = Global.saved_player_mana
		if current_player.has_signal("mana_changed"):
			current_player.mana_changed.emit(current_player.current_mana)

	_setup_ui()
	Global.clear_saved_stats()


func save_before_transition():
	if not current_player:
		return

	Global.saved_player_health = current_player.current_health
	if "current_mana" in current_player:
		Global.saved_player_mana = current_player.current_mana

	print("Saved: HP=%d, Mana=%d" % [Global.saved_player_health, Global.saved_player_mana])


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
			"armor": current_player.armor if "armor" in current_player else 0,
		}
		game_ui.setup_character_ui(stats)

	if current_player.has_signal("health_changed") and not current_player.health_changed.is_connected(_on_health_changed):
		current_player.health_changed.connect(_on_health_changed)

	if current_player.has_signal("mana_changed") and not current_player.mana_changed.is_connected(_on_mana_changed):
		current_player.mana_changed.connect(_on_mana_changed)

	_setup_armor_watch()


func _setup_armor_watch():
	last_armor_value = current_player.armor if "armor" in current_player else 0

	if armor_watch_timer == null:
		armor_watch_timer = Timer.new()
		armor_watch_timer.name = "ArmorWatchTimer"
		armor_watch_timer.wait_time = ARMOR_POLL_INTERVAL
		armor_watch_timer.timeout.connect(_check_armor_changed)
		add_child(armor_watch_timer)

	if armor_watch_timer.is_stopped():
		armor_watch_timer.start()


func _check_armor_changed():
	if not current_player or not game_ui or not ("armor" in current_player):
		return

	if current_player.armor != last_armor_value:
		last_armor_value = current_player.armor
		if game_ui.has_method("update_armor"):
			game_ui.update_armor(last_armor_value)


func _on_health_changed(value):
	if game_ui and game_ui.has_method("update_health"):
		game_ui.update_health(value)


func _on_mana_changed(value):
	if game_ui and game_ui.has_method("update_mana"):
		game_ui.update_mana(value)


func _on_player_died():
	print("Player died on Level 2")
