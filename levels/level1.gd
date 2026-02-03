extends Node2D

# ===========================================
# LEVEL 1 - ВЕРСИЯ v8.0 - ВСЕ ИСПРАВЛЕНИЯ
# ===========================================
# 
# ИЗМЕНЕНИЯ:
# 1. Артефакты НЕ активируются автоматически
# 2. Сундуки спавнят предметы на землю
# 3. Перо Феникса работает ТОЛЬКО из слота артефакта
# 4. HP сохраняется между уровнями

@onready var player_spawn = $PlayerSpawn
@onready var game_ui = $GameUI

var current_player = null
var last_armor_value: int = 0

var inventory_ui: InventoryUI = null
var hotbar_ui: HotbarUI = null

# === БАЗОВЫЕ СТАТЫ ===
var base_player_armor: int = 0
var base_player_max_health: int = 0
var base_player_max_mana: int = 0
var base_player_speed: int = 0
var base_player_damage: int = 0

# === БОНУСЫ ===
var equipment_bonus_armor: int = 0
var equipment_bonus_hp: int = 0
var equipment_bonus_mana: int = 0
var equipment_bonus_speed: int = 0
var equipment_bonus_damage: int = 0

var potion_bonus_armor: int = 0
var potion_bonus_damage: int = 0


func _ready():
	print("")
	print("🎮 ========== LEVEL 1 v8.0 ==========")
	print("   run_started: %s" % Global.run_started)
	print("   spawn_point: '%s'" % Global.spawn_point)
	
	var is_new_game = not Global.run_started
	
	if is_new_game:
		print("🆕 НОВАЯ ИГРА")
		if Inventory:
			Inventory.clear_all()
		Global.start_run()
	else:
		print("🔄 ВОЗВРАТ")
		call_deferred("_remove_collected_objects")
	
	_initialize_inventory()
	_create_inventory_ui()
	
	await get_tree().process_frame
	
	spawn_selected_character(is_new_game)
	_setup_chests()
	
	if Global and game_ui:
		Global.register_game_ui(game_ui)
	
	print("🎮 ========== LEVEL 1 READY ==========")
	print("")


func _remove_collected_objects():
	await get_tree().process_frame
	
	print("📂 Удаляем собранные объекты...")
	
	for child in get_children():
		var child_name = child.name
		
		if Global.is_pickup_collected(child_name):
			print("   🗑️ %s" % child_name)
			child.queue_free()
			continue
		
		if Global.is_enemy_killed(child_name):
			print("   💀 %s" % child_name)
			child.queue_free()
			continue
		
		if Global.is_door_opened(child_name):
			if "is_open" in child:
				child.is_open = true
			if child.has_method("_update_visual"):
				child._update_visual()


func save_before_transition():
	"""Вызывается дверью перед переходом"""
	if not current_player:
		return
	
	Global.saved_player_health = current_player.current_health
	if "current_mana" in current_player:
		Global.saved_player_mana = current_player.current_mana
	else:
		Global.saved_player_mana = -1
	
	print("💾 ═══════════════════════════════")
	print("💾 СОХРАНЕНО: HP=%d Mana=%d" % [Global.saved_player_health, Global.saved_player_mana])
	print("💾 ═══════════════════════════════")


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
	
	setup_player_ui()
	Global.clear_saved_stats()


# ===========================================
# ИНВЕНТАРЬ
# ===========================================

func _initialize_inventory():
	print("=== 🎒 ИНИЦИАЛИЗАЦИЯ ИНВЕНТАРЯ ===")
	
	if not Inventory:
		push_error("❌ Inventory не найден!")
		return
	
	var db_path = "res://data/items/demo_database.tres"
	
	if not ResourceLoader.exists(db_path):
		push_warning("⚠️ База данных не найдена")
		return
	
	var item_db = load(db_path) as GameItemDatabase
	
	if item_db:
		Inventory.set_database(item_db)
		print("✅ База данных: %d предметов" % item_db.items.size())
		
		var char_class = _get_character_class()
		Inventory.set_character_class(char_class)
		
		if not Inventory.stats_updated.is_connected(_on_equipment_stats_changed):
			Inventory.stats_updated.connect(_on_equipment_stats_changed)
		if not Inventory.equipment_changed.is_connected(_on_equipment_changed):
			Inventory.equipment_changed.connect(_on_equipment_changed)
	
	print("=== ✅ ИНВЕНТАРЬ ГОТОВ ===")


func _get_character_class() -> InventoryEnums.CharacterClass:
	match Global.selected_character:
		"warrior":
			return InventoryEnums.CharacterClass.WARRIOR
		"paladin":
			return InventoryEnums.CharacterClass.PALADIN
		"rogue":
			return InventoryEnums.CharacterClass.ROGUE
		"berserk":
			return InventoryEnums.CharacterClass.BERSERK
		_:
			return InventoryEnums.CharacterClass.WARRIOR


func _create_inventory_ui():
	inventory_ui = InventoryUI.new()
	inventory_ui.name = "InventoryUI"
	add_child(inventory_ui)
	inventory_ui.visible = false
	
	inventory_ui.item_used.connect(_on_inventory_item_used)
	print("✅ InventoryUI создан")
	
	hotbar_ui = HotbarUI.new()
	hotbar_ui.name = "HotbarUI"
	add_child(hotbar_ui)
	
	if hotbar_ui.has_signal("hotbar_slot_used"):
		hotbar_ui.hotbar_slot_used.connect(_on_hotbar_slot_used)
	print("✅ HotbarUI создан")


# ===========================================
# ИСПОЛЬЗОВАНИЕ ЗЕЛИЙ
# ===========================================

func _on_inventory_item_used(item: InventoryItem):
	if not current_player or not item or not item.data:
		return
	
	var item_id = item.get_item_id()
	
	if Inventory.is_potion_used(item_id):
		print("⚠️ Зелье '%s' уже использовано!" % item.get_display_name())
		return
	
	print("🧪 Используем: %s" % item.get_display_name())
	Inventory.mark_potion_used(item_id)
	
	for effect in item.data.effects:
		_apply_potion_effect(effect)


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
		_apply_potion_effect(effect)


func _apply_potion_effect(effect: Dictionary):
	if not current_player:
		return
	
	var effect_type = effect.get("type", InventoryEnums.EffectType.NONE)
	var value = effect.get("value", 0.0)
	
	match effect_type:
		InventoryEnums.EffectType.INSTANT_HEAL_HP:
			var heal = int(value)
			var old_hp = current_player.current_health
			current_player.current_health = mini(old_hp + heal, current_player.max_health)
			print("💚 +%d HP" % (current_player.current_health - old_hp))
			
			if current_player.has_signal("health_changed"):
				current_player.health_changed.emit(current_player.current_health)
			_show_heal_effect()
		
		InventoryEnums.EffectType.INSTANT_HEAL_MANA:
			var mana = int(value)
			var old_mana = current_player.current_mana
			current_player.current_mana = mini(old_mana + mana, current_player.max_mana)
			print("💙 +%d маны" % (current_player.current_mana - old_mana))
			
			if current_player.has_signal("mana_changed"):
				current_player.mana_changed.emit(current_player.current_mana)
		
		InventoryEnums.EffectType.BUFF_ARMOR:
			var armor = int(value)
			potion_bonus_armor += armor
			current_player.armor += armor
			_update_armor_ui()
			print("🛡️ +%d брони" % armor)
		
		InventoryEnums.EffectType.BUFF_DAMAGE:
			var damage = int(value)
			potion_bonus_damage += damage
			print("⚔️ +%d урона" % damage)
			_recalculate_player_damage()


func _show_heal_effect():
	if not current_player:
		return
	
	var sprite = current_player.get_node_or_null("AnimatedSprite2D")
	if not sprite:
		return
	
	var original = sprite.modulate
	sprite.modulate = Color(0.5, 2.0, 0.5, 1.0)
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", original, 0.3)


# ===========================================
# ЭКИПИРОВКА
# ===========================================

func _on_equipment_stats_changed(stats: Dictionary):
	if not current_player:
		return
	
	equipment_bonus_hp = stats.get("max_hp", 0)
	equipment_bonus_mana = stats.get("max_mana", 0)
	equipment_bonus_armor = stats.get("armor", 0)
	equipment_bonus_speed = stats.get("speed_percent", 0)
	equipment_bonus_damage = stats.get("damage", 0)
	
	# HP
	var new_max_hp = base_player_max_health + equipment_bonus_hp
	if current_player.max_health != new_max_hp:
		var hp_diff = new_max_hp - current_player.max_health
		current_player.max_health = new_max_hp
		if hp_diff > 0:
			current_player.current_health += hp_diff
		current_player.current_health = mini(current_player.current_health, current_player.max_health)
		
		if game_ui:
			game_ui.update_max_health(current_player.max_health)
			game_ui.update_health(current_player.current_health)
	
	# Mana
	var new_max_mana = base_player_max_mana + equipment_bonus_mana
	if "max_mana" in current_player and current_player.max_mana != new_max_mana:
		var mana_diff = new_max_mana - current_player.max_mana
		current_player.max_mana = new_max_mana
		if mana_diff > 0:
			current_player.current_mana += mana_diff
		current_player.current_mana = mini(current_player.current_mana, current_player.max_mana)
		
		if game_ui:
			game_ui.update_max_mana(current_player.max_mana)
			game_ui.update_mana(current_player.current_mana)
	
	# Armor
	current_player.armor = base_player_armor + equipment_bonus_armor + potion_bonus_armor
	_update_armor_ui()
	
	# Damage
	_recalculate_player_damage()
	
	# Артефакт возрождения - ТОЛЬКО ИЗ СЛОТА!
	_update_revival_artifact_status()


func _on_equipment_changed(slot = null, old_item = null, new_item = null):
	# Проверяем артефакты при любом изменении экипировки
	_update_revival_artifact_status()
	_update_double_jump_artifact()


func _update_armor_ui():
	if game_ui and current_player:
		game_ui.update_armor(current_player.armor)


func _recalculate_player_damage():
	if not current_player:
		return
	
	var total = base_player_damage + equipment_bonus_damage + potion_bonus_damage
	if "current_damage" in current_player:
		current_player.current_damage = total


func _update_revival_artifact_status():
	"""Перо Феникса работает ТОЛЬКО если экипировано в слот артефакта!"""
	if not Inventory:
		return
	
	var has_phoenix = false
	
	# Проверяем ТОЛЬКО слоты артефактов
	for slot in [
		InventoryEnums.EquipSlot.ARTIFACT_1,
		InventoryEnums.EquipSlot.ARTIFACT_2,
		InventoryEnums.EquipSlot.ARTIFACT_3,
		InventoryEnums.EquipSlot.ARTIFACT_4,
	]:
		var item = Inventory.get_equipped_item(slot)
		if item and item.get_item_id() == 202:  # Phoenix Feather
			has_phoenix = true
			break
	
	if has_phoenix:
		Global.set_revival_artifact("phoenix_feather")
		print("✨ Артефакт возрождения АКТИВЕН (в слоте)")
	else:
		if Global.revival_artifact_id == "phoenix_feather":
			Global.revival_artifact_id = ""
			print("❌ Артефакт возрождения НЕ активен")


func _update_double_jump_artifact():
	"""Крылья Гермеса работают ТОЛЬКО если экипированы"""
	if not Inventory or not current_player:
		return
	
	var has_wings = false
	
	for slot in [
		InventoryEnums.EquipSlot.ARTIFACT_1,
		InventoryEnums.EquipSlot.ARTIFACT_2,
		InventoryEnums.EquipSlot.ARTIFACT_3,
		InventoryEnums.EquipSlot.ARTIFACT_4,
	]:
		var item = Inventory.get_equipped_item(slot)
		if item and item.get_item_id() == 201:  # Hermes Wings
			has_wings = true
			break
	
	if "enable_double_jump" in current_player:
		current_player.enable_double_jump = has_wings
		if has_wings:
			print("✨ Двойной прыжок АКТИВЕН")
		else:
			print("❌ Двойной прыжок НЕ активен")


# ===========================================
# СМЕРТЬ / ВОЗРОЖДЕНИЕ
# ===========================================

func _on_player_died():
	print("💀 Игрок погиб")
	
	potion_bonus_armor = 0
	potion_bonus_damage = 0
	
	if current_player and current_player.has_method("reset_potion_bonuses"):
		current_player.reset_potion_bonuses()
	
	_recalculate_player_damage()
	
	if Inventory:
		Inventory.reset_on_death()


func _on_player_revived():
	print("✨ Игрок возродился")
	_consume_revival_artifact()
	_recalculate_player_damage()


func _consume_revival_artifact():
	"""Удаляет использованное Перо Феникса из слота"""
	if not Inventory:
		return
	
	for slot in [
		InventoryEnums.EquipSlot.ARTIFACT_1,
		InventoryEnums.EquipSlot.ARTIFACT_2,
		InventoryEnums.EquipSlot.ARTIFACT_3,
		InventoryEnums.EquipSlot.ARTIFACT_4,
	]:
		var item = Inventory.get_equipped_item(slot)
		if item and item.get_item_id() == 202:
			Inventory.unequip_item(slot)
			Inventory.remove_item_by_id(202, 1)
			print("🔥 Перо Феникса ИСПОЛЬЗОВАНО и удалено!")
			_update_revival_artifact_status()
			break


# ===========================================
# НАСТРОЙКА СУНДУКОВ - НОВАЯ СИСТЕМА!
# ===========================================

func _setup_chests():
	"""Настраивает сундуки - теперь они спавнят предметы НА ЗЕМЛЮ"""
	print("")
	print("=== 📦 НАСТРОЙКА СУНДУКОВ ===")
	
	var chest_count = 0
	
	for child in get_children():
		if child is Chest:
			if Global.is_pickup_collected(child.name):
				print("   📦 %s - уже открыт, удаляем" % child.name)
				child.queue_free()
				continue
			
			chest_count += 1
			_configure_chest(child, chest_count)
	
	if chest_count == 0:
		print("⚠️ Сундуки не найдены!")
	else:
		print("✅ Настроено: %d" % chest_count)
	print("")


func _configure_chest(chest: Chest, index: int):
	"""Настраивает сундук - предметы будут спавниться на земле!"""
	match index:
		1:
			# Сундук с АРТЕФАКТАМИ
			chest.setup_artifacts(["hermes_wings", "phoenix_feather"])
			print("   📦 Сундук #1: Артефакты (падают на землю)")
		
		2:
			# Сундук с ПРЕДМЕТАМИ
			chest.setup_items(
				[1, 2, 3, 4, 101, 102, 103, 104, 105],
				[2, 2, 1, 1, 1, 1, 1, 1, 1]
			)
			print("   📦 Сундук #2: Экипировка и зелья (падают на землю)")
		
		_:
			chest.setup_items([1, 2], [2, 2])
			print("   📦 Сундук #%d: Случайный лут" % index)


# ===========================================
# СПАВН ПЕРСОНАЖА
# ===========================================

func spawn_selected_character(is_new_game: bool = true):
	if not Global.selected_character:
		Global.selected_character = "warrior"
	
	print("🔄 Spawning: ", Global.selected_character)
	
	var scene_path = Global.character_player_scenes.get(Global.selected_character)
	
	if scene_path and ResourceLoader.exists(scene_path):
		var scene = load(scene_path)
		current_player = scene.instantiate()
		
		# Позиция спавна
		var spawn_pos = player_spawn.global_position if player_spawn else Vector2(100, 100)
		var spawn_source = "PlayerSpawn"
		
		if Global.spawn_point != "":
			print("🔍 Ищем SpawnPoint: '%s'" % Global.spawn_point)
			var spawn_node = get_node_or_null(Global.spawn_point)
			if spawn_node:
				spawn_pos = spawn_node.global_position
				spawn_source = Global.spawn_point
				print("✅ SpawnPoint найден: %s" % spawn_pos)
			Global.spawn_point = ""
		
		print("📍 Итоговый спавн: %s [%s]" % [spawn_pos, spawn_source])
		
		current_player.global_position = spawn_pos
		add_child(current_player)
		print("✅ Player spawned")
		
		Global.register_player(current_player)
		
		_save_base_stats()
		setup_player_ui()
		setup_player_camera()
		
		if current_player.has_signal("died"):
			current_player.died.connect(_on_player_died)
		if current_player.has_signal("revived"):
			current_player.revived.connect(_on_player_revived)
		
		# ОТКЛЮЧАЕМ старую систему артефактов!
		if "enable_double_jump" in current_player:
			current_player.enable_double_jump = false
		
		# Восстанавливаем HP при возврате
		if not is_new_game:
			call_deferred("_restore_player_stats")
		
		# Проверяем экипированные артефакты
		call_deferred("_update_revival_artifact_status")
		call_deferred("_update_double_jump_artifact")
	else:
		print("❌ Character scene not found")
		create_fallback_player()


func _save_base_stats():
	if not current_player:
		return
	
	if "armor" in current_player:
		base_player_armor = current_player.armor
	if "max_health" in current_player:
		base_player_max_health = current_player.max_health
	if "max_mana" in current_player:
		base_player_max_mana = current_player.max_mana
	if "current_speed" in current_player:
		base_player_speed = current_player.current_speed
	
	if "BASE_DAMAGE" in current_player:
		base_player_damage = current_player.BASE_DAMAGE
	elif "current_damage" in current_player:
		base_player_damage = current_player.current_damage
	else:
		base_player_damage = 2
	
	print("📊 Базовые статы сохранены (урон: %d)" % base_player_damage)


# ===========================================
# UI
# ===========================================

func setup_player_ui():
	if not current_player or not game_ui:
		return
	
	var stats = {
		"health": current_player.current_health,
		"max_health": current_player.max_health,
		"mana": current_player.current_mana if "current_mana" in current_player else 0,
		"max_mana": current_player.max_mana if "max_mana" in current_player else 0,
		"armor": current_player.armor if "armor" in current_player else 0
	}
	
	game_ui.setup_character_ui(stats)
	
	if current_player.has_signal("health_changed"):
		if not current_player.health_changed.is_connected(_on_player_health_changed):
			current_player.health_changed.connect(_on_player_health_changed)
	
	if current_player.has_signal("mana_changed"):
		if not current_player.mana_changed.is_connected(_on_player_mana_changed):
			current_player.mana_changed.connect(_on_player_mana_changed)
	
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.timeout.connect(_check_armor_changed)
	add_child(timer)
	timer.start()


func _check_armor_changed():
	if not current_player:
		return
	
	if current_player.armor != last_armor_value:
		last_armor_value = current_player.armor
		_on_player_armor_changed(current_player.armor)


func _on_player_health_changed(new_health):
	if game_ui:
		game_ui.update_health(new_health)


func _on_player_mana_changed(new_mana):
	if game_ui:
		game_ui.update_mana(new_mana)


func _on_player_armor_changed(new_armor):
	if game_ui:
		game_ui.update_armor(new_armor)


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
	
	camera.limit_left = 0
	camera.limit_right = 2000
	camera.limit_top = 0
	camera.limit_bottom = 1200
	camera.make_current()


func create_fallback_player():
	var player = CharacterBody2D.new()
	player.name = "FallbackPlayer"
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(30, 50)
	collision.shape = shape
	player.add_child(collision)
	
	var sprite = Sprite2D.new()
	sprite.texture = preload("res://icon.svg")
	sprite.modulate = Color.RED
	player.add_child(sprite)
	
	if player_spawn:
		player.global_position = player_spawn.global_position
	else:
		player.global_position = Vector2(100, 100)
	
	add_child(player)
	current_player = player
