extends Node2D
class_name BaseLevel

# ===========================================
# BASE LEVEL v2.1 - Р ВР РЋР СџР В Р С’Р вЂ™Р вЂєР вЂўР СњР С›
# ===========================================
# - Р ВРЎРѓР С—РЎР‚Р В°Р Р†Р В»Р ВµР Р… РЎРѓР С—Р В°Р Р†Р Р… (spawn_point_id РЎР‚Р В°Р В±Р С•РЎвЂљР В°Р ВµРЎвЂљ Р С—РЎР‚Р В°Р Р†Р С‘Р В»РЎРЉР Р…Р С•)
# - Р ВРЎРѓР С—РЎР‚Р В°Р Р†Р В»Р ВµР Р…Р С• РЎРѓР С•РЎвЂ¦РЎР‚Р В°Р Р…Р ВµР Р…Р С‘Р Вµ HP Р С—РЎР‚Р С‘ Р С—Р ВµРЎР‚Р ВµРЎвЂ¦Р С•Р Т‘Р Вµ
# - Р ВРЎРѓР С—РЎР‚Р В°Р Р†Р В»Р ВµР Р…Р В° Р В»Р С•Р С–Р С‘Р С”Р В° "Р Р…Р С•Р Р†Р В°РЎРЏ Р С‘Р С–РЎР‚Р В° vs Р С—РЎР‚Р С•Р Т‘Р С•Р В»Р В¶Р ВµР Р…Р С‘Р Вµ"

@export var level_name: String = "Level"
@export var level_path: String = ""

var player_spawn: Marker2D = null
var game_ui: CanvasLayer = null
var current_player: Node = null
var is_initialized: bool = false


func _ready():
	print("")
	print("СЂСџР‹В® РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’")
	print("СЂСџР‹В® %s Р вЂ”Р С’Р вЂњР В Р Р€Р вЂ“Р вЂўР Сњ" % level_name.to_upper())
	print("СЂСџР‹В® РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’")
	
	if level_path.is_empty():
		level_path = scene_file_path
	
	if GameState:
	GameState.set_current_level(level_path)
	if RunState:
		RunState.set_current_level(level_path)
	
	_find_nodes()
	
	# Р вЂ™Р С’Р вЂ“Р СњР С›: Р СџРЎР‚Р С•Р Р†Р ВµРЎР‚РЎРЏР ВµР С Р СџР вЂўР В Р вЂўР вЂќ РЎРѓР С—Р В°Р Р†Р Р…Р С•Р С Р С‘Р С–РЎР‚Р С•Р С”Р В°
	var is_new_game = not GameState or not GameState.is_run_active
	
	if is_new_game:
		print("СЂСџвЂ вЂў Р СњР С•Р Р†РЎвЂ№Р в„– Р В·Р В°Р В±Р ВµР С–")
		_on_level_start_new()
	else:
		print("СЂСџвЂќвЂћ Р СџРЎР‚Р С•Р Т‘Р С•Р В»Р В¶Р ВµР Р…Р С‘Р Вµ Р В·Р В°Р В±Р ВµР С–Р В°")
		_on_level_continue()
	
	await get_tree().process_frame
	_spawn_player(is_new_game)
	
	call_deferred("_apply_saved_state")
	
	if game_ui and Global:
		Global.register_game_ui(game_ui)
	
	is_initialized = true
	_on_level_ready()
	
	print("СЂСџР‹В® РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’")
	print("")


func _find_nodes():
	player_spawn = get_node_or_null("PlayerSpawn")
	game_ui = get_node_or_null("GameUI")
	
	if not player_spawn:
		for child in get_children():
			if child is Marker2D and "spawn" in child.name.to_lower():
				player_spawn = child
				break
	
	print("   PlayerSpawn: %s" % ("РІСљвЂ¦" if player_spawn else "РІСњРЉ"))
	print("   GameUI: %s" % ("РІСљвЂ¦" if game_ui else "РІСњРЉ"))


func _on_level_start_new():
	"""Р СњР С•Р Р†РЎвЂ№Р в„– Р В·Р В°Р В±Р ВµР С– - Р С•РЎвЂЎР С‘РЎвЂ°Р В°Р ВµР С Р Р†РЎРѓРЎвЂ"""
	if Inventory:
		Inventory.clear_all()
	if GameState:
		GameState.start_new_run()
	if RunState:
		RunState.start_new_run()
		RunState.set_current_level(level_path)


func _on_level_continue():
	"""Р СџРЎР‚Р С•Р Т‘Р С•Р В»Р В¶Р ВµР Р…Р С‘Р Вµ - Р СњР вЂў Р С•РЎвЂЎР С‘РЎвЂ°Р В°Р ВµР С Р С‘Р Р…Р Р†Р ВµР Р…РЎвЂљР В°РЎР‚РЎРЉ"""
	pass


func _on_level_ready():
	pass


# ===========================================
# Р РЋР СџР С’Р вЂ™Р Сњ Р ВР вЂњР В Р С›Р С™Р С’ - Р ВР РЋР СџР В Р С’Р вЂ™Р вЂєР вЂўР СњР С›!
# ===========================================

func _spawn_player(is_new_game: bool):
	if not Global or not Global.selected_character:
		Global.selected_character = "warrior"
	
	var scene_path = Global.character_player_scenes.get(Global.selected_character)
	if not scene_path or not ResourceLoader.exists(scene_path):
		push_error("РІСњРЉ Р РЋРЎвЂ Р ВµР Р…Р В° Р С—Р ВµРЎР‚РЎРѓР С•Р Р…Р В°Р В¶Р В° Р Р…Р Вµ Р Р…Р В°Р в„–Р Т‘Р ВµР Р…Р В°: %s" % scene_path)
		return
	
	var scene = load(scene_path)
	current_player = scene.instantiate()
	
	# === Р С›Р СџР В Р вЂўР вЂќР вЂўР вЂєР Р‡Р вЂўР Сљ Р СџР С›Р вЂ”Р ВР В¦Р ВР В® Р РЋР СџР С’Р вЂ™Р СњР С’ ===
	var spawn_pos = Vector2(100, 500)
	var spawn_source = "default"
	
	# 1. Р СџРЎР‚Р С‘Р С•РЎР‚Р С‘РЎвЂљР ВµРЎвЂљ: spawn_point_id Р С•РЎвЂљ Р Т‘Р Р†Р ВµРЎР‚Р С‘
	if GameState and GameState.spawn_point_id != "":
		var spawn_id = GameState.spawn_point_id
		var spawn_node = _find_spawn_point(spawn_id)
		
		if spawn_node:
			spawn_pos = spawn_node.global_position
			spawn_source = "spawn_point: " + spawn_id
			print("   РІСљвЂ¦ Р СњР В°Р в„–Р Т‘Р ВµР Р… spawn: '%s' РІвЂ вЂ™ %s" % [spawn_id, spawn_pos])
		else:
			print("   РІС™В РїС‘РЏ Spawn '%s' Р Р…Р Вµ Р Р…Р В°Р в„–Р Т‘Р ВµР Р…!" % spawn_id)
			# Fallback Р Р…Р В° PlayerSpawn
			if player_spawn:
				spawn_pos = player_spawn.global_position
				spawn_source = "PlayerSpawn (fallback)"
		
		# Р РЋР В±РЎР‚Р В°РЎРѓРЎвЂ№Р Р†Р В°Р ВµР С Р СџР С›Р РЋР вЂєР вЂў Р С‘РЎРѓР С—Р С•Р В»РЎРЉР В·Р С•Р Р†Р В°Р Р…Р С‘РЎРЏ
		GameState.spawn_point_id = ""
	
	# 2. Р вЂўРЎРѓР В»Р С‘ Р Р…Р ВµРЎвЂљ spawn_point_id - Р С‘РЎРѓР С—Р С•Р В»РЎРЉР В·РЎС“Р ВµР С PlayerSpawn
	elif player_spawn:
		spawn_pos = player_spawn.global_position
		spawn_source = "PlayerSpawn"
	
	print("   СЂСџвЂњРЊ Р РЋР С—Р В°Р Р†Р Р…: %s [%s]" % [spawn_pos, spawn_source])
	
	current_player.global_position = spawn_pos
	add_child(current_player)
	
	if Global:
		Global.register_player(current_player)
	
	if current_player.has_signal("died"):
		current_player.died.connect(_on_player_died)
	
	# === Р вЂ™Р С›Р РЋР РЋР СћР С’Р СњР С’Р вЂ™Р вЂєР ВР вЂ™Р С’Р вЂўР Сљ HP Р СћР С›Р вЂєР В¬Р С™Р С› Р СџР В Р В Р СџР В Р С›Р вЂќР С›Р вЂєР вЂ“Р вЂўР СњР ВР В ===
	if not is_new_game and GameState and GameState.has_saved_stats():
		_restore_player_stats()
	
	_setup_camera()
	_setup_ui()
	
	print("   РІСљвЂ¦ Р ВР С–РЎР‚Р С•Р С”: %s, HP: %d/%d" % [
		Global.selected_character, 
		current_player.current_health,
		current_player.max_health
	])


func _find_spawn_point(spawn_id: String) -> Node2D:
	"""Р ВРЎвЂ°Р ВµРЎвЂљ РЎвЂљР С•РЎвЂЎР С”РЎС“ РЎРѓР С—Р В°Р Р†Р Р…Р В° Р С—Р С• ID"""
	# Р СџРЎР‚РЎРЏР СР С•Р в„– Р С—Р С•Р С‘РЎРѓР С” Р С—Р С• Р С‘Р СР ВµР Р…Р С‘
	var node = get_node_or_null(spawn_id)
	if node:
		return node
	
	# Р СџР С•Р С‘РЎРѓР С” РЎРѓРЎР‚Р ВµР Т‘Р С‘ Р Т‘Р ВµРЎвЂљР ВµР в„–
	for child in get_children():
		if child.name == spawn_id:
			return child
		if child.get("spawn_point_id") == spawn_id:
			return child
	
	return null


func _restore_player_stats():
	"""Р вЂ™Р С•РЎРѓРЎРѓРЎвЂљР В°Р Р…Р В°Р Р†Р В»Р С‘Р Р†Р В°Р ВµРЎвЂљ HP/Mana Р С—Р С•РЎРѓР В»Р Вµ Р С—Р ВµРЎР‚Р ВµРЎвЂ¦Р С•Р Т‘Р В°"""
	if not current_player or not GameState:
		return
	
	var stats = GameState.get_saved_stats()
	
	if stats["health"] > 0:
		current_player.current_health = stats["health"]
		print("   СЂСџвЂ™С• HP Р Р†Р С•РЎРѓРЎРѓРЎвЂљР В°Р Р…Р С•Р Р†Р В»Р ВµР Р…Р С•: %d" % stats["health"])
	
	if stats["mana"] >= 0 and "current_mana" in current_player:
		current_player.current_mana = stats["mana"]
		print("   СЂСџвЂ™С• Mana Р Р†Р С•РЎРѓРЎРѓРЎвЂљР В°Р Р…Р С•Р Р†Р В»Р ВµР Р…Р В°: %d" % stats["mana"])
	
	# Р С›РЎвЂЎР С‘РЎвЂ°Р В°Р ВµР С РЎРѓР С•РЎвЂ¦РЎР‚Р В°Р Р…РЎвЂР Р…Р Р…РЎвЂ№Р Вµ РЎРѓРЎвЂљР В°РЎвЂљРЎвЂ№
	GameState.clear_saved_stats()
	
	# Р С›Р В±Р Р…Р С•Р Р†Р В»РЎРЏР ВµР С UI
	await get_tree().process_frame
	if current_player.has_signal("health_changed"):
		current_player.health_changed.emit(current_player.current_health)
	if current_player.has_signal("mana_changed") and "current_mana" in current_player:
		current_player.mana_changed.emit(current_player.current_mana)


# ===========================================
# Р СџР В Р ВР СљР вЂўР СњР вЂўР СњР ВР вЂў Р РЋР С›Р ТђР В Р С’Р СњР РѓР СњР СњР С›Р вЂњР С› Р РЋР С›Р РЋР СћР С›Р Р‡Р СњР ВР Р‡
# ===========================================

func _apply_saved_state():
	if not GameState or not GameState.is_run_active:
		return
	
	await get_tree().process_frame
	print("СЂСџвЂњвЂљ Р СџРЎР‚Р С‘Р СР ВµР Р…РЎРЏР ВµР С РЎРѓР С•РЎвЂ¦РЎР‚Р В°Р Р…РЎвЂР Р…Р Р…Р С•Р Вµ РЎРѓР С•РЎРѓРЎвЂљР С•РЎРЏР Р…Р С‘Р Вµ...")
	
	for child in get_children():
		var child_name = child.name
		
		# Р СџРЎР‚Р С•Р Р†Р ВµРЎР‚РЎРЏР ВµР С pickup (РЎвЂљР С•Р В»РЎРЉР С”Р С• Р С—Р С• Р С‘Р СР ВµР Р…Р С‘)
		if GameState.is_pickup_collected(child_name):
			print("   СЂСџвЂ”вЂРїС‘РЏ Р Р€Р Т‘Р В°Р В»РЎРЏР ВµР С: %s" % child_name)
			child.queue_free()
			continue
		
		# Р СџРЎР‚Р С•Р Р†Р ВµРЎР‚РЎРЏР ВµР С Р Р†РЎР‚Р В°Р С–Р В°
		if GameState.is_enemy_killed(child_name):
			print("   СЂСџвЂ™Р‚ Р вЂ™РЎР‚Р В°Р С–: %s" % child_name)
			child.queue_free()
			continue
		
		# Р СџРЎР‚Р С•Р Р†Р ВµРЎР‚РЎРЏР ВµР С РЎРѓРЎС“Р Р…Р Т‘РЎС“Р С”
		if GameState.is_chest_opened(child_name):
			if child.has_method("set_opened"):
				child.set_opened(true)
			print("   СЂСџвЂњВ¦ Р РЋРЎС“Р Р…Р Т‘РЎС“Р С”: %s" % child_name)
			continue
		
		# Р СџРЎР‚Р С•Р Р†Р ВµРЎР‚РЎРЏР ВµР С Р Т‘Р Р†Р ВµРЎР‚РЎРЉ
		if GameState.is_door_opened(child_name):
			if "is_open" in child:
				child.is_open = true
			if child.has_method("_update_visual"):
				child._update_visual()
			print("   СЂСџС™Р„ Р вЂќР Р†Р ВµРЎР‚РЎРЉ: %s" % child_name)


# ===========================================
# Р РЋР С›Р ТђР В Р С’Р СњР вЂўР СњР ВР вЂў Р СџР вЂўР В Р вЂўР вЂќ Р СџР вЂўР В Р вЂўР ТђР С›Р вЂќР С›Р Сљ
# ===========================================

func save_before_transition():
	"""Р вЂ™РЎвЂ№Р В·РЎвЂ№Р Р†Р В°Р ВµРЎвЂљРЎРѓРЎРЏ Р Т‘Р Р†Р ВµРЎР‚РЎРЉРЎР‹ Р С—Р ВµРЎР‚Р ВµР Т‘ Р С—Р ВµРЎР‚Р ВµРЎвЂ¦Р С•Р Т‘Р С•Р С"""
	if not current_player or not GameState:
		return
	
	var health = current_player.current_health
	var mana = current_player.current_mana if "current_mana" in current_player else -1
	var armor = current_player.armor if "armor" in current_player else -1
	
	print("СЂСџвЂ™С• РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’")
	print("СЂСџвЂ™С• Р РЋР С›Р ТђР В Р С’Р СњР вЂўР СњР ВР вЂў Р СџР вЂўР В Р вЂўР вЂќ Р СџР вЂўР В Р вЂўР ТђР С›Р вЂќР С›Р Сљ")
	print("СЂСџвЂ™С• HP: %d, Mana: %d, Armor: %d" % [health, mana, armor])
	print("СЂСџвЂ™С• РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’РІвЂўС’")
	
	GameState.save_player_stats(health, mana, armor)
	if RunState:
		RunState.capture_scene_state(self)


# ===========================================
# Р С™Р С’Р СљР вЂўР В Р С’
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
	print("СЂСџвЂ™Р‚ Р ВР С–РЎР‚Р С•Р С” Р С—Р С•Р С–Р С‘Р В± Р Р…Р В° %s" % level_name)
