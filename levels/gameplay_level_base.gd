extends Node2D
class_name GameplayLevelBase

const DEFAULT_GAME_UI_SCENE := preload("res://scenes/Ui/game_ui.tscn")
const DEFAULT_ITEM_DATABASE_PATH := "res://data/items/demo_database.tres"
const ARMOR_POLL_INTERVAL := 0.1

@export var item_database_path: String = DEFAULT_ITEM_DATABASE_PATH
@export var camera_limit_left: int = 0
@export var camera_limit_right: int = 2000
@export var camera_limit_top: int = 0
@export var camera_limit_bottom: int = 1200

@onready var player_spawn: Node2D = get_node_or_null("PlayerSpawn")

var game_ui: CanvasLayer = null
var current_player: Node = null
var armor_watch_timer: Timer = null
var last_armor_value: int = -1
var inventory_ui: InventoryUI = null
var hotbar_ui: HotbarUI = null

var base_player_armor: int = 0
var base_player_max_health: int = 0
var base_player_max_mana: int = 0
var base_player_speed: int = 0
var base_player_damage: int = 0

var equipment_bonus_armor: int = 0
var equipment_bonus_hp: int = 0
var equipment_bonus_mana: int = 0
var equipment_bonus_speed: int = 0
var equipment_bonus_damage: int = 0

var potion_bonus_armor: int = 0
var potion_bonus_damage: int = 0


func _ready() -> void:
	_set_current_level()

	var is_new_game: bool = not (Global and Global.run_started)
	if is_new_game:
		_start_new_run()
	else:
		await _remove_persisted_scene_objects()

	_initialize_inventory()
	await get_tree().process_frame

	_ensure_game_ui()
	_ensure_inventory_ui()
	_setup_level_before_player_spawn()
	_spawn_selected_character()
	_setup_level_after_player_spawn()

	if Global and game_ui:
		Global.register_game_ui(game_ui)

	_on_level_ready()


func _set_current_level() -> void:
	if not Global:
		return

	var level_id: String = scene_file_path if not scene_file_path.is_empty() else name
	Global.set_current_level(level_id)


func _start_new_run() -> void:
	if Inventory:
		Inventory.clear_all()
	if Global:
		Global.start_run()


func _remove_persisted_scene_objects() -> void:
	await get_tree().process_frame

	for child in get_children():
		var child_name: String = child.name

		if Global and Global.is_pickup_collected(child_name):
			child.queue_free()
			continue

		if Global and Global.is_enemy_killed(child_name):
			child.queue_free()
			continue

		if Global and Global.is_door_opened(child_name):
			if "is_open" in child:
				child.is_open = true
			if child.has_method("_update_visual"):
				child._update_visual()


func _initialize_inventory() -> void:
	if not Inventory:
		push_error("GameplayLevelBase: Inventory autoload not found")
		return

	if not item_database_path.is_empty() and ResourceLoader.exists(item_database_path):
		var item_db: GameItemDatabase = load(item_database_path) as GameItemDatabase
		if item_db:
			Inventory.set_database(item_db)

	Inventory.set_character_class(_get_character_class())

	if not Inventory.stats_updated.is_connected(_on_equipment_stats_changed):
		Inventory.stats_updated.connect(_on_equipment_stats_changed)
	if not Inventory.equipment_changed.is_connected(_on_equipment_changed):
		Inventory.equipment_changed.connect(_on_equipment_changed)


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


func _ensure_game_ui() -> void:
	var existing_ui: Node = get_node_or_null("GameUI")
	if existing_ui is CanvasLayer:
		game_ui = existing_ui as CanvasLayer
	elif DEFAULT_GAME_UI_SCENE:
		game_ui = DEFAULT_GAME_UI_SCENE.instantiate() as CanvasLayer
		if game_ui:
			game_ui.name = "GameUI"
			add_child(game_ui)

	if game_ui and game_ui.has_method("rebuild_ui"):
		game_ui.rebuild_ui()


func _ensure_inventory_ui() -> void:
	inventory_ui = get_node_or_null("InventoryUI") as InventoryUI
	if inventory_ui == null:
		inventory_ui = InventoryUI.new()
		inventory_ui.name = "InventoryUI"
		inventory_ui.visible = false
		add_child(inventory_ui)

	if inventory_ui and inventory_ui.has_signal("item_used") and not inventory_ui.item_used.is_connected(_on_inventory_item_used):
		inventory_ui.item_used.connect(_on_inventory_item_used)

	hotbar_ui = get_node_or_null("HotbarUI") as HotbarUI
	if hotbar_ui == null:
		hotbar_ui = HotbarUI.new()
		hotbar_ui.name = "HotbarUI"
		add_child(hotbar_ui)

	if hotbar_ui and hotbar_ui.has_signal("hotbar_slot_used") and not hotbar_ui.hotbar_slot_used.is_connected(_on_hotbar_slot_used):
		hotbar_ui.hotbar_slot_used.connect(_on_hotbar_slot_used)


func _spawn_selected_character() -> void:
	if not Global.selected_character:
		Global.selected_character = "warrior"

	var character_scene_path: String = Global.character_player_scenes.get(Global.selected_character, "")
	if character_scene_path.is_empty() or not ResourceLoader.exists(character_scene_path):
		push_error("GameplayLevelBase: character scene not found for '%s'" % Global.selected_character)
		_create_fallback_player()
		return

	var character_scene: PackedScene = load(character_scene_path) as PackedScene
	if character_scene == null:
		push_error("GameplayLevelBase: failed to load character scene '%s'" % character_scene_path)
		_create_fallback_player()
		return

	current_player = character_scene.instantiate()
	current_player.global_position = _resolve_spawn_position()
	add_child(current_player)

	if Global:
		Global.register_player(current_player)

	_save_base_stats()
	_apply_current_equipment_state()
	_setup_camera()
	_setup_ui()
	_connect_player_lifecycle_signals()
	_after_player_spawned()
	call_deferred("_restore_player_stats")


func _resolve_spawn_position() -> Vector2:
	var spawn_pos: Vector2 = player_spawn.global_position if player_spawn else Vector2(100, 100)

	if Global and not Global.spawn_point.is_empty():
		var spawn_node: Node2D = get_node_or_null(Global.spawn_point) as Node2D
		if spawn_node:
			spawn_pos = spawn_node.global_position
		Global.spawn_point = ""

	return spawn_pos


func _connect_player_lifecycle_signals() -> void:
	if not current_player:
		return

	if current_player.has_signal("died") and not current_player.died.is_connected(_on_player_died):
		current_player.died.connect(_on_player_died)

	if current_player.has_signal("revived") and not current_player.revived.is_connected(_on_player_revived):
		current_player.revived.connect(_on_player_revived)


func _save_base_stats() -> void:
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


func _apply_current_equipment_state() -> void:
	if not current_player or not Inventory:
		return

	if Inventory.has_method("emit_current_stats"):
		Inventory.emit_current_stats()
	else:
		var stats: Dictionary = Inventory.get_equipment_stats()
		_on_equipment_stats_changed(stats)

	_on_equipment_changed()


func _restore_player_stats() -> void:
	if not current_player or not Global:
		return

	if Global.saved_player_health > 0:
		current_player.current_health = mini(Global.saved_player_health, current_player.max_health)
		if current_player.has_signal("health_changed"):
			current_player.health_changed.emit(current_player.current_health)

	if Global.saved_player_mana >= 0 and "current_mana" in current_player:
		current_player.current_mana = mini(Global.saved_player_mana, current_player.max_mana)
		if current_player.has_signal("mana_changed"):
			current_player.mana_changed.emit(current_player.current_mana)

	_refresh_resource_ui()
	Global.clear_saved_stats()


func save_before_transition() -> void:
	if not current_player or not Global:
		return

	Global.saved_player_health = current_player.current_health
	if "current_mana" in current_player:
		Global.saved_player_mana = current_player.current_mana
	else:
		Global.saved_player_mana = -1

	if RunState:
		RunState.capture_scene_state(self)


func _setup_camera() -> void:
	if not current_player:
		return

	var camera: Camera2D = current_player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		camera.zoom = Vector2(1.5, 1.5)
		current_player.add_child(camera)

	camera.limit_left = camera_limit_left
	camera.limit_right = camera_limit_right
	camera.limit_top = camera_limit_top
	camera.limit_bottom = camera_limit_bottom
	camera.make_current()


func _setup_ui() -> void:
	if not current_player or not game_ui:
		return

	if game_ui.has_method("setup_character_ui"):
		var stats: Dictionary = {
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


func _setup_armor_watch() -> void:
	last_armor_value = current_player.armor if current_player and "armor" in current_player else 0

	if armor_watch_timer == null:
		armor_watch_timer = Timer.new()
		armor_watch_timer.name = "ArmorWatchTimer"
		armor_watch_timer.wait_time = ARMOR_POLL_INTERVAL
		armor_watch_timer.timeout.connect(_check_armor_changed)
		add_child(armor_watch_timer)

	if armor_watch_timer.is_stopped():
		armor_watch_timer.start()


func _check_armor_changed() -> void:
	if not current_player or not game_ui or not ("armor" in current_player):
		return

	if current_player.armor != last_armor_value:
		last_armor_value = current_player.armor
		if game_ui.has_method("update_armor"):
			game_ui.update_armor(last_armor_value)


func _on_inventory_item_used(item: InventoryItem) -> void:
	if not current_player or not item or not item.data:
		return

	var item_id: int = item.get_item_id()
	if Inventory.is_potion_used(item_id):
		return

	Inventory.mark_potion_used(item_id)
	for effect in item.data.effects:
		_apply_potion_effect(effect)


func _on_hotbar_slot_used(index: int) -> void:
	if not current_player or not Inventory:
		return

	var item: InventoryItem = Inventory.get_hotbar_item(index)
	if not item or not item.data:
		return

	var item_id: int = item.get_item_id()
	if Inventory.is_potion_used(item_id):
		return

	Inventory.mark_potion_used(item_id)
	for effect in item.data.effects:
		_apply_potion_effect(effect)


func _apply_potion_effect(effect: Dictionary) -> void:
	if not current_player:
		return

	var effect_type: int = effect.get("type", InventoryEnums.EffectType.NONE)
	var value: float = effect.get("value", 0.0)

	match effect_type:
		InventoryEnums.EffectType.INSTANT_HEAL_HP:
			var heal: int = int(value)
			current_player.current_health = mini(current_player.current_health + heal, current_player.max_health)
			if current_player.has_signal("health_changed"):
				current_player.health_changed.emit(current_player.current_health)
			_refresh_resource_ui()
			_show_heal_effect()

		InventoryEnums.EffectType.INSTANT_HEAL_MANA:
			if "current_mana" in current_player:
				var mana: int = int(value)
				current_player.current_mana = mini(current_player.current_mana + mana, current_player.max_mana)
				if current_player.has_signal("mana_changed"):
					current_player.mana_changed.emit(current_player.current_mana)
				_refresh_resource_ui()

		InventoryEnums.EffectType.BUFF_ARMOR:
			potion_bonus_armor += int(value)
			if "armor" in current_player:
				current_player.armor = base_player_armor + equipment_bonus_armor + potion_bonus_armor
				if game_ui and game_ui.has_method("update_armor"):
					game_ui.update_armor(current_player.armor)

		InventoryEnums.EffectType.BUFF_DAMAGE:
			potion_bonus_damage += int(value)
			if "current_damage" in current_player:
				current_player.current_damage = base_player_damage + equipment_bonus_damage + potion_bonus_damage


func _refresh_resource_ui() -> void:
	if not current_player or not game_ui:
		return

	if game_ui.has_method("update_health"):
		game_ui.update_health(current_player.current_health)

	if "current_mana" in current_player and game_ui.has_method("update_mana"):
		game_ui.update_mana(current_player.current_mana)


func _show_heal_effect() -> void:
	if not current_player:
		return

	var sprite: CanvasItem = current_player.get_node_or_null("AnimatedSprite2D") as CanvasItem
	if not sprite:
		return

	var original: Color = sprite.modulate
	sprite.modulate = Color(0.5, 2.0, 0.5, 1.0)

	var tween: Tween = create_tween()
	tween.tween_property(sprite, "modulate", original, 0.3)


func _on_equipment_stats_changed(stats: Dictionary) -> void:
	if not current_player:
		return

	equipment_bonus_hp = int(stats.get("max_hp", 0))
	equipment_bonus_mana = int(stats.get("max_mana", 0))
	equipment_bonus_armor = int(stats.get("armor", 0))
	equipment_bonus_speed = int(stats.get("speed_percent", 0))
	equipment_bonus_damage = int(stats.get("damage", 0))

	var new_max_hp: int = base_player_max_health + equipment_bonus_hp
	if current_player.max_health != new_max_hp:
		var hp_diff: int = new_max_hp - current_player.max_health
		current_player.max_health = new_max_hp
		if hp_diff > 0:
			current_player.current_health += hp_diff
		current_player.current_health = mini(current_player.current_health, current_player.max_health)

		if game_ui:
			game_ui.update_max_health(current_player.max_health)
			game_ui.update_health(current_player.current_health)

	if "max_mana" in current_player:
		var new_max_mana: int = base_player_max_mana + equipment_bonus_mana
		if current_player.max_mana != new_max_mana:
			var mana_diff: int = new_max_mana - current_player.max_mana
			current_player.max_mana = new_max_mana
			if mana_diff > 0:
				current_player.current_mana += mana_diff
			current_player.current_mana = mini(current_player.current_mana, current_player.max_mana)

			if game_ui:
				game_ui.update_max_mana(current_player.max_mana)
				game_ui.update_mana(current_player.current_mana)

	if "armor" in current_player:
		current_player.armor = base_player_armor + equipment_bonus_armor + potion_bonus_armor
		if game_ui and game_ui.has_method("update_armor"):
			game_ui.update_armor(current_player.armor)

	if "current_damage" in current_player:
		current_player.current_damage = base_player_damage + equipment_bonus_damage + potion_bonus_damage

	if "current_speed" in current_player:
		current_player.current_speed = base_player_speed + int(round(base_player_speed * equipment_bonus_speed / 100.0))


func _on_equipment_changed(_slot = null, _old_item = null, _new_item = null) -> void:
	_update_revival_artifact_status()
	_update_double_jump_artifact()


func _update_revival_artifact_status() -> void:
	if not Inventory:
		return

	var has_phoenix: bool = false
	for slot in [
		InventoryEnums.EquipSlot.ARTIFACT_1,
		InventoryEnums.EquipSlot.ARTIFACT_2,
		InventoryEnums.EquipSlot.ARTIFACT_3,
		InventoryEnums.EquipSlot.ARTIFACT_4,
	]:
		var item: InventoryItem = Inventory.get_equipped_item(slot)
		if item and item.get_item_id() == 202:
			has_phoenix = true
			break

	if has_phoenix:
		Global.set_revival_artifact("phoenix_feather")
	elif Global.revival_artifact_id == "phoenix_feather":
		Global.revival_artifact_id = ""


func _update_double_jump_artifact() -> void:
	if not Inventory or not current_player:
		return

	var has_wings: bool = false
	for slot in [
		InventoryEnums.EquipSlot.ARTIFACT_1,
		InventoryEnums.EquipSlot.ARTIFACT_2,
		InventoryEnums.EquipSlot.ARTIFACT_3,
		InventoryEnums.EquipSlot.ARTIFACT_4,
	]:
		var item: InventoryItem = Inventory.get_equipped_item(slot)
		if item and item.get_item_id() == 201:
			has_wings = true
			break

	if "enable_double_jump" in current_player:
		current_player.enable_double_jump = has_wings


func _consume_revival_artifact() -> void:
	if not Inventory:
		return

	for slot in [
		InventoryEnums.EquipSlot.ARTIFACT_1,
		InventoryEnums.EquipSlot.ARTIFACT_2,
		InventoryEnums.EquipSlot.ARTIFACT_3,
		InventoryEnums.EquipSlot.ARTIFACT_4,
	]:
		var item: InventoryItem = Inventory.get_equipped_item(slot)
		if item and item.get_item_id() == 202:
			Inventory.unequip_item(slot)
			Inventory.remove_item_by_id(202, 1)
			_update_revival_artifact_status()
			break


func _on_health_changed(value) -> void:
	if game_ui and game_ui.has_method("update_health"):
		game_ui.update_health(value)


func _on_mana_changed(value) -> void:
	if game_ui and game_ui.has_method("update_mana"):
		game_ui.update_mana(value)


func _on_player_died() -> void:
	potion_bonus_armor = 0
	potion_bonus_damage = 0

	if Inventory:
		Inventory.reset_on_death()

	_apply_current_equipment_state()
	_on_level_player_died()


func _on_player_revived() -> void:
	_consume_revival_artifact()
	_apply_current_equipment_state()
	_on_level_player_revived()


func _create_fallback_player() -> void:
	var fallback: CharacterBody2D = CharacterBody2D.new()
	fallback.name = "FallbackPlayer"

	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(30, 50)
	collision.shape = shape
	fallback.add_child(collision)

	fallback.global_position = player_spawn.global_position if player_spawn else Vector2(100, 100)
	add_child(fallback)
	current_player = fallback


func _setup_level_before_player_spawn() -> void:
	pass


func _setup_level_after_player_spawn() -> void:
	pass


func _after_player_spawned() -> void:
	pass


func _on_level_player_died() -> void:
	pass


func _on_level_player_revived() -> void:
	pass


func _on_level_ready() -> void:
	pass
