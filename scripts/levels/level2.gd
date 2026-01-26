extends Node2D

# ===========================================
# LEVEL 2 - БАЗОВЫЙ ШАБЛОН
# ===========================================
# Путь: res://scripts/levels/level2.gd
#
# Этот уровень НЕ сбрасывает инвентарь!
# Игрок переносится на позицию SpawnPoint

@onready var player_spawn = $PlayerSpawn  # Запасная точка
@onready var game_ui = $GameUI

var current_player = null
var last_armor_value: int = 0

# UI Инвентаря
var inventory_ui: InventoryUI = null
var hotbar_ui: HotbarUI = null


func _ready():
	print("")
	print("🎮 Level 2 loaded!")
	print("   spawn_point: '%s'" % Global.spawn_point)
	
	# НЕ очищаем инвентарь - это продолжение игры!
	
	_create_inventory_ui()
	
	await get_tree().process_frame
	
	spawn_selected_character()
	
	if Global and game_ui:
		Global.register_game_ui(game_ui)
	
	# Добавляем посещённую комнату в статистику
	if Global and Global.has_method("add_room_visited"):
		Global.add_room_visited()
	
	print("✅ Level 2 готов!")
	print("")


# ===========================================
# СОЗДАНИЕ UI ИНВЕНТАРЯ
# ===========================================

func _create_inventory_ui():
	# InventoryUI
	inventory_ui = InventoryUI.new()
	inventory_ui.name = "InventoryUI"
	add_child(inventory_ui)
	inventory_ui.visible = false
	
	inventory_ui.item_used.connect(_on_inventory_item_used)
	
	# HotbarUI
	hotbar_ui = HotbarUI.new()
	hotbar_ui.name = "HotbarUI"
	add_child(hotbar_ui)
	
	if hotbar_ui.has_signal("hotbar_slot_used"):
		hotbar_ui.hotbar_slot_used.connect(_on_hotbar_slot_used)


# ===========================================
# СПАВН ПЕРСОНАЖА
# ===========================================

func spawn_selected_character():
	if not Global.selected_character:
		Global.selected_character = "warrior"
	
	print("🔄 Spawning: ", Global.selected_character)
	
	var character_scene_path = Global.character_player_scenes.get(Global.selected_character)
	
	if character_scene_path and ResourceLoader.exists(character_scene_path):
		var character_scene = load(character_scene_path)
		current_player = character_scene.instantiate()
		
		# Начальная позиция (будет изменена SpawnPoint)
		if player_spawn:
			current_player.global_position = player_spawn.global_position
		else:
			current_player.global_position = Vector2(100, 100)
		
		add_child(current_player)
		print("✅ Player spawned at: %s" % current_player.global_position)
		
		Global.register_player(current_player)
		
		setup_player_ui()
		setup_player_camera()
		
		# Подключаем сигналы
		if current_player.has_signal("died"):
			current_player.died.connect(_on_player_died)
		if current_player.has_signal("revived"):
			current_player.revived.connect(_on_player_revived)
	else:
		print("❌ Character scene not found")


# ===========================================
# UI
# ===========================================

func setup_player_ui():
	if not current_player or not game_ui:
		return
	
	var stats = {
		"health": current_player.current_health,
		"max_health": current_player.max_health,
		"mana": current_player.current_mana,
		"max_mana": current_player.max_mana,
		"armor": current_player.armor
	}
	
	game_ui.setup_character_ui(stats)
	
	if current_player.has_signal("health_changed"):
		if not current_player.health_changed.is_connected(_on_player_health_changed):
			current_player.health_changed.connect(_on_player_health_changed)
	
	if current_player.has_signal("mana_changed"):
		if not current_player.mana_changed.is_connected(_on_player_mana_changed):
			current_player.mana_changed.connect(_on_player_mana_changed)
	
	# Таймер проверки брони
	var armor_timer = Timer.new()
	armor_timer.wait_time = 0.1
	armor_timer.timeout.connect(_check_armor_changed)
	add_child(armor_timer)
	armor_timer.start()


func _check_armor_changed():
	if not current_player:
		return
	
	if current_player.armor != last_armor_value:
		last_armor_value = current_player.armor
		if game_ui:
			game_ui.update_armor(current_player.armor)


func _on_player_health_changed(new_health):
	if game_ui:
		game_ui.update_health(new_health)


func _on_player_mana_changed(new_mana):
	if game_ui:
		game_ui.update_mana(new_mana)


# ===========================================
# КАМЕРА
# ===========================================

func setup_player_camera():
	if not current_player:
		return
	
	var camera = current_player.get_node_or_null("Camera2D")
	if not camera:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		camera.zoom = Vector2(1.5, 1.5)
		current_player.add_child(camera)
	
	# Установи свои лимиты для level2!
	camera.limit_left = 0
	camera.limit_right = 2000
	camera.limit_top = 0
	camera.limit_bottom = 1200
	camera.make_current()


# ===========================================
# СМЕРТЬ / ВОЗРОЖДЕНИЕ
# ===========================================

func _on_player_died():
	print("💀 Игрок погиб на Level 2")


func _on_player_revived():
	print("✨ Игрок возродился на Level 2")


# ===========================================
# ИСПОЛЬЗОВАНИЕ ПРЕДМЕТОВ
# ===========================================

func _on_inventory_item_used(item: InventoryItem):
	if not current_player or not item or not item.data:
		return
	
	var item_id = item.get_item_id()
	
	if Inventory.is_potion_used(item_id):
		print("⚠️ Зелье уже использовано!")
		return
	
	print("🧪 Используем: %s" % item.get_display_name())
	Inventory.mark_potion_used(item_id)
	
	for effect in item.data.effects:
		_apply_effect(effect)


func _on_hotbar_slot_used(index: int):
	if not current_player or not Inventory:
		return
	
	var item = Inventory.get_hotbar_item(index)
	if not item or not item.data:
		return
	
	var item_id = item.get_item_id()
	
	if Inventory.is_potion_used(item_id):
		print("⚠️ Зелье уже использовано!")
		return
	
	print("🧪 Быстрый слот %d: %s" % [index + 1, item.get_display_name()])
	Inventory.mark_potion_used(item_id)
	
	for effect in item.data.effects:
		_apply_effect(effect)


func _apply_effect(effect: Dictionary):
	if not current_player:
		return
	
	var effect_type = effect.get("type", InventoryEnums.EffectType.NONE)
	var value = effect.get("value", 0.0)
	
	match effect_type:
		InventoryEnums.EffectType.INSTANT_HEAL_HP:
			var heal = int(value)
			var old_hp = current_player.current_health
			current_player.current_health = mini(old_hp + heal, current_player.max_health)
			
			if current_player.has_signal("health_changed"):
				current_player.health_changed.emit(current_player.current_health)
			
			print("💚 +%d HP" % (current_player.current_health - old_hp))
		
		InventoryEnums.EffectType.INSTANT_HEAL_MANA:
			var mana = int(value)
			var old_mana = current_player.current_mana
			current_player.current_mana = mini(old_mana + mana, current_player.max_mana)
			
			if current_player.has_signal("mana_changed"):
				current_player.mana_changed.emit(current_player.current_mana)
			
			print("💙 +%d маны" % (current_player.current_mana - old_mana))
		
		InventoryEnums.EffectType.BUFF_ARMOR:
			current_player.armor += int(value)
			print("🛡️ +%d брони" % int(value))
		
		InventoryEnums.EffectType.BUFF_DAMAGE:
			if "current_damage" in current_player:
				current_player.current_damage += int(value)
			print("⚔️ +%d урона" % int(value))
