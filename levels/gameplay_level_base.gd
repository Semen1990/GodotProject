extends Node2D

const DEFAULT_GAME_UI_SCENE := preload("res://scenes/Ui/game_ui.tscn")
const CONSUMABLE_USE_CONTROLLER_SCRIPT := preload("res://scripts/consumables/consumable_use_controller.gd")
const DEFAULT_ITEM_DATABASE_PATH := "res://data/items/demo_database.tres"
const ARMOR_POLL_INTERVAL := 0.1

const WORLD_ROOT_PATH := "World"
const GEOMETRY_ROOT_PATH := "World/Geometry"
const MARKERS_ROOT_PATH := "World/Markers"
const PLAYER_SPAWN_PATH := "World/Markers/PlayerSpawn"
const ENTITIES_ROOT_PATH := "World/Entities"
const ENCOUNTERS_ROOT_PATH := "World/Encounters"
const OBJECTS_ROOT_PATH := "World/Objects"
const UI_ROOT_PATH := "UI"
const POTION_KIND_HP := "hp"
const POTION_KIND_MANA := "mana"
const POTION_USE_DURATION := 0.8
const POTION_GLOBAL_COOLDOWN := 2.0
const POTION_MOVE_SPEED_MULTIPLIER := 0.35
const ENCOUNTER_ENEMY_GROUP := "encounter_enemy"
const ENCOUNTER_ZONE_FALLBACK_DISTANCE := 320.0
const MADNESS_RELIEF_ON_NEW_ROOM := 1

@export var item_database_path: String = DEFAULT_ITEM_DATABASE_PATH
@export var camera_limit_left: int = 0
@export var camera_limit_right: int = 2000
@export var camera_limit_top: int = 0
@export var camera_limit_bottom: int = 1200

var player_spawn: Node2D = null

var game_ui: CanvasLayer = null
var current_player: Node = null
var armor_watch_timer: Timer = null
var last_armor_value: int = -1
var inventory_ui: InventoryUI = null
var hotbar_ui: HotbarUI = null
var consumable_use_controller = null
var pending_consumable_item: InventoryItem = null
var pending_consumable_hotbar_index: int = -1
var current_encounter_zone: CombatEncounterZone = null
var fallback_used_instant_potions: Dictionary = {
	POTION_KIND_HP: false,
	POTION_KIND_MANA: false,
}
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
var current_enemy_ui_target: Node = null


func _ready() -> void:
	if CombatRuntimeLogger:
		CombatRuntimeLogger.begin_session("level=%s" % _get_room_progression_id())

	_cache_level_structure()
	_validate_level_structure()
	_set_current_level()

	var is_new_game: bool = not (Global and Global.run_started)
	if is_new_game:
		_start_new_run()
		_register_room_visit(true)
	else:
		_register_room_visit(false)
		await _remove_persisted_scene_objects()

	_initialize_inventory()
	await get_tree().process_frame

	_ensure_game_ui()
	_ensure_inventory_ui()
	_setup_level_before_player_spawn()
	_spawn_selected_character()
	_setup_level_after_player_spawn()
	_setup_encounter_zones()
	_setup_enemy_target_ui_tracking()

	if Global and game_ui:
		Global.register_game_ui(game_ui)

	_on_level_ready()


func _cache_level_structure() -> void:
	player_spawn = _find_player_spawn()


func _validate_level_structure() -> void:
	if get_markers_root() == self:
		push_warning("GameplayLevelBase: missing 'World/Markers' container, using scene root fallback")
	if player_spawn == null:
		push_warning("GameplayLevelBase: missing 'World/Markers/PlayerSpawn' marker")
	if get_entities_root() == self:
		push_warning("GameplayLevelBase: missing 'World/Entities' container, using scene root fallback")
	if get_encounters_root() == self:
		push_warning("GameplayLevelBase: missing 'World/Encounters' container, using scene root fallback")
	if get_objects_root() == self:
		push_warning("GameplayLevelBase: missing 'World/Objects' container, using scene root fallback")
	if get_ui_root() == self:
		push_warning("GameplayLevelBase: missing 'UI' container, using scene root fallback")


func get_world_root() -> Node:
	return _resolve_level_node([WORLD_ROOT_PATH], self)


func get_geometry_root() -> Node:
	return _resolve_level_node([GEOMETRY_ROOT_PATH, "Geometry"], self)


func get_markers_root() -> Node:
	return _resolve_level_node([MARKERS_ROOT_PATH, "Markers"], self)


func get_entities_root() -> Node:
	return _resolve_level_node([ENTITIES_ROOT_PATH, "Entities"], self)


func get_encounters_root() -> Node:
	return _resolve_level_node([ENCOUNTERS_ROOT_PATH, "Encounters"], self)


func get_objects_root() -> Node:
	return _resolve_level_node([OBJECTS_ROOT_PATH, "Objects"], self)


func get_ui_root() -> Node:
	return _resolve_level_node([UI_ROOT_PATH], self)


func _resolve_level_node(paths: Array[String], fallback: Node) -> Node:
	for path in paths:
		var candidate: Node = get_node_or_null(path)
		if candidate != null:
			return candidate
	return fallback


func _find_player_spawn() -> Node2D:
	var spawn: Node2D = get_node_or_null(PLAYER_SPAWN_PATH) as Node2D
	if spawn == null:
		spawn = get_node_or_null("PlayerSpawn") as Node2D
	return spawn


func _set_current_level() -> void:
	if not Global:
		return

	Global.set_current_level(_get_room_progression_id())


func _get_room_progression_id() -> String:
	return scene_file_path if not scene_file_path.is_empty() else name


func _register_room_visit(is_new_game: bool) -> void:
	var room_id: String = _get_room_progression_id()
	if room_id.is_empty():
		return

	if Global:
		Global.last_room_path = room_id

	var already_visited: bool = RunState != null and RunState.is_room_visited(room_id)
	var is_new_room: bool = is_new_game or not already_visited
	if RunCombatTelemetry:
		RunCombatTelemetry.record_room_visit(room_id, is_new_room)
	if EnemyAdaptationDirector:
		EnemyAdaptationDirector.refresh_for_room(room_id)

	if RunState == null:
		return

	if is_new_game:
		RunState.mark_room_visited(room_id)
		return

	if already_visited:
		return

	RunState.mark_room_visited(room_id)
	if Global:
		Global.add_room_visited()
		if Global.saved_player_madness_stacks > 0:
			Global.saved_player_madness_stacks = maxi(0, Global.saved_player_madness_stacks - MADNESS_RELIEF_ON_NEW_ROOM)


func _start_new_run() -> void:
	if Inventory:
		Inventory.clear_all()
	if RunCombatTelemetry:
		RunCombatTelemetry.reset_run()
	if EnemyAdaptationDirector:
		EnemyAdaptationDirector.reset_run()
	if Global:
		Global.start_run()


func _remove_persisted_scene_objects() -> void:
	await get_tree().process_frame

	for child in _get_persistent_scene_nodes():
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


func _get_persistent_scene_nodes() -> Array[Node]:
	var nodes: Array[Node] = []

	for container in [get_entities_root(), get_objects_root()]:
		if container == null or container == self:
			continue
		for child in container.get_children():
			nodes.append(child)

	if not nodes.is_empty():
		return nodes

	for child in get_children():
		if child == get_world_root() or child == get_ui_root():
			continue
		nodes.append(child)

	return nodes


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
	game_ui = _find_existing_game_ui()
	if game_ui == null and DEFAULT_GAME_UI_SCENE:
		game_ui = DEFAULT_GAME_UI_SCENE.instantiate() as CanvasLayer
		if game_ui:
			game_ui.name = "GameUI"
			get_ui_root().add_child(game_ui)

	if game_ui:
		game_ui.visible = true

	if game_ui and game_ui.has_method("rebuild_ui"):
		game_ui.rebuild_ui()
		if game_ui.has_method("hide_enemy_target"):
			game_ui.hide_enemy_target()


func _find_existing_game_ui() -> CanvasLayer:
	for path in ["%s/GameUI" % UI_ROOT_PATH, "GameUI"]:
		var existing_ui: Node = get_node_or_null(path)
		if existing_ui is CanvasLayer:
			return existing_ui as CanvasLayer
	return null


func _ensure_inventory_ui() -> void:
	inventory_ui = get_node_or_null("%s/InventoryUI" % UI_ROOT_PATH) as InventoryUI
	if inventory_ui == null:
		inventory_ui = get_node_or_null("InventoryUI") as InventoryUI
	if inventory_ui == null:
		inventory_ui = InventoryUI.new()
		inventory_ui.name = "InventoryUI"
		inventory_ui.visible = false
		get_ui_root().add_child(inventory_ui)

	if inventory_ui and inventory_ui.has_signal("item_used") and not inventory_ui.item_used.is_connected(_on_inventory_item_used):
		inventory_ui.item_used.connect(_on_inventory_item_used)

	hotbar_ui = get_node_or_null("%s/HotbarUI" % UI_ROOT_PATH) as HotbarUI
	if hotbar_ui == null:
		hotbar_ui = get_node_or_null("HotbarUI") as HotbarUI
	if hotbar_ui == null:
		hotbar_ui = HotbarUI.new()
		hotbar_ui.name = "HotbarUI"
		get_ui_root().add_child(hotbar_ui)

	if hotbar_ui and hotbar_ui.has_signal("hotbar_slot_used") and not hotbar_ui.hotbar_slot_used.is_connected(_on_hotbar_slot_used):
		hotbar_ui.hotbar_slot_used.connect(_on_hotbar_slot_used)


func _setup_encounter_zones() -> void:
	for zone in _get_encounter_zones():
		if not zone.player_entered_encounter.is_connected(_on_player_entered_encounter):
			zone.player_entered_encounter.connect(_on_player_entered_encounter)
		if not zone.player_exited_encounter.is_connected(_on_player_exited_encounter):
			zone.player_exited_encounter.connect(_on_player_exited_encounter)
		if not zone.instant_potion_restrictions_changed.is_connected(_on_encounter_restrictions_changed):
			zone.instant_potion_restrictions_changed.connect(_on_encounter_restrictions_changed)

		if zone.has_method("_refresh_overlap_state"):
			zone.call_deferred("_refresh_overlap_state")

	call_deferred("_refresh_current_encounter_zone")


func _get_encounter_zones() -> Array[CombatEncounterZone]:
	var zones: Array[CombatEncounterZone] = []
	var encounters_root: Node = get_encounters_root()

	if encounters_root != null and encounters_root != self:
		_collect_encounter_zones(encounters_root, zones)
		if not zones.is_empty():
			return zones

	var tree: SceneTree = get_tree()
	if tree == null:
		return zones

	for node in tree.get_nodes_in_group("combat_encounter_zones"):
		var zone: CombatEncounterZone = node as CombatEncounterZone
		if zone == null:
			continue
		if self.is_ancestor_of(zone):
			zones.append(zone)

	return zones


func _collect_encounter_zones(root: Node, zones: Array[CombatEncounterZone]) -> void:
	for child in root.get_children():
		var zone: CombatEncounterZone = child as CombatEncounterZone
		if zone != null:
			zones.append(zone)

		_collect_encounter_zones(child, zones)


func _refresh_current_encounter_zone() -> void:
	if not is_inside_tree():
		return

	current_encounter_zone = _resolve_encounter_zone_for_player()
	_sync_instant_potion_repeat_blocks()


func _resolve_encounter_zone_for_player() -> CombatEncounterZone:
	var player_body: Node2D = current_player as Node2D
	if player_body == null:
		return null

	if current_encounter_zone != null and current_encounter_zone.has_method("contains_world_point"):
		if bool(current_encounter_zone.call("contains_world_point", player_body.global_position)):
			return current_encounter_zone

	var nearest_zone: CombatEncounterZone = null
	var nearest_distance: float = INF
	for zone in _get_encounter_zones():
		if zone == null:
			continue
		if zone.has_player(current_player) or zone.overlaps_body(current_player):
			return zone
		if zone.has_method("contains_world_point"):
			if bool(zone.call("contains_world_point", player_body.global_position)):
				return zone

		var blocker_distance: float = _get_nearest_blocking_enemy_distance_to_player(zone, player_body.global_position)
		if blocker_distance < nearest_distance:
			nearest_distance = blocker_distance
			nearest_zone = zone

	if nearest_zone != null and nearest_distance <= ENCOUNTER_ZONE_FALLBACK_DISTANCE:
		return nearest_zone

	return null


func _get_nearest_blocking_enemy_distance_to_player(zone: CombatEncounterZone, player_position: Vector2) -> float:
	if not is_inside_tree():
		return INF
	if zone == null:
		return INF

	var tree: SceneTree = get_tree()
	if tree == null:
		return INF

	var nearest_distance: float = INF
	for node in tree.get_nodes_in_group(ENCOUNTER_ENEMY_GROUP):
		var enemy_body: Node2D = node as Node2D
		if enemy_body == null:
			continue
		if not is_instance_valid(enemy_body) or not enemy_body.is_inside_tree():
			continue
		if not zone.contains_world_point(enemy_body.global_position):
			continue

		var is_blocking: bool = enemy_body.is_in_group(ENCOUNTER_ENEMY_GROUP)
		if enemy_body.has_method("is_repeat_potion_blocker"):
			is_blocking = bool(enemy_body.call("is_repeat_potion_blocker"))
		if not is_blocking:
			continue

		nearest_distance = minf(nearest_distance, player_position.distance_to(enemy_body.global_position))

	return nearest_distance


func _sync_instant_potion_repeat_blocks() -> void:
	if not Inventory or not Inventory.has_method("set_instant_potion_repeat_block"):
		return

	fallback_used_instant_potions[POTION_KIND_HP] = false
	fallback_used_instant_potions[POTION_KIND_MANA] = false
	Inventory.set_instant_potion_repeat_block(POTION_KIND_HP, false)
	Inventory.set_instant_potion_repeat_block(POTION_KIND_MANA, false)


func _on_player_entered_encounter(_zone: CombatEncounterZone) -> void:
	_refresh_current_encounter_zone()


func _on_player_exited_encounter(_zone: CombatEncounterZone) -> void:
	_refresh_current_encounter_zone()


func _on_encounter_restrictions_changed(_zone: CombatEncounterZone) -> void:
	if not is_inside_tree():
		return
	_refresh_current_encounter_zone()


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
	get_entities_root().add_child(current_player)
	current_player.global_position = _resolve_spawn_position()
	if CombatRuntimeLogger:
		CombatRuntimeLogger.log_event("player", "GameplayLevelBase", "spawned_player", {
			"selected_character": Global.selected_character,
			"scene": character_scene_path,
			"player_name": current_player.name,
			"position": current_player.global_position,
		})

	if Global:
		Global.register_player(current_player)

	_save_base_stats()
	_apply_current_equipment_state()
	_setup_camera()
	_setup_ui()
	_connect_player_lifecycle_signals()
	_setup_consumable_use_controller()
	_after_player_spawned()
	call_deferred("_refresh_adaptation_state")
	call_deferred("_restore_player_stats")


func _resolve_spawn_position() -> Vector2:
	var spawn_pos: Vector2 = player_spawn.global_position if player_spawn else Vector2(100, 100)

	if Global and not Global.spawn_point.is_empty():
		var spawn_node: Node2D = _find_spawn_point(Global.spawn_point)
		if spawn_node:
			spawn_pos = spawn_node.global_position
		Global.spawn_point = ""

	return spawn_pos


func _find_spawn_point(spawn_point_id: String) -> Node2D:
	if spawn_point_id.is_empty():
		return null

	var markers_root: Node = get_markers_root()
	if markers_root != null and markers_root != self:
		var marker_spawn: Node2D = _find_spawn_point_in_branch(markers_root, spawn_point_id)
		if marker_spawn:
			return marker_spawn

	return _find_spawn_point_in_branch(self, spawn_point_id)


func _find_spawn_point_in_branch(root: Node, spawn_point_id: String) -> Node2D:
	for child in root.get_children():
		var node_2d: Node2D = child as Node2D
		if node_2d and _matches_spawn_point(node_2d, spawn_point_id):
			return node_2d

		var nested: Node2D = _find_spawn_point_in_branch(child, spawn_point_id)
		if nested:
			return nested

	return null


func _matches_spawn_point(node: Node2D, spawn_point_id: String) -> bool:
	if node.name == spawn_point_id:
		return true
	if "spawn_point_id" in node:
		return str(node.spawn_point_id) == spawn_point_id
	return false


func _connect_player_lifecycle_signals() -> void:
	if not current_player:
		return

	if current_player.has_signal("died") and not current_player.died.is_connected(_on_player_died):
		current_player.died.connect(_on_player_died)

	if current_player.has_signal("revived") and not current_player.revived.is_connected(_on_player_revived):
		current_player.revived.connect(_on_player_revived)

	if current_player.has_signal("damage_received") and not current_player.damage_received.is_connected(_on_player_damage_received):
		current_player.damage_received.connect(_on_player_damage_received)

	if current_player.has_signal("combat_action_performed") and not current_player.combat_action_performed.is_connected(_on_player_combat_action_performed):
		current_player.combat_action_performed.connect(_on_player_combat_action_performed)


func _setup_enemy_target_ui_tracking() -> void:
	_clear_current_enemy_ui_target()
	for enemy in _get_scene_enemies_for_ui():
		_connect_enemy_ui_signals(enemy)


func _get_scene_enemies_for_ui() -> Array[Node]:
	var enemies: Array[Node] = []
	var tree: SceneTree = get_tree()
	if tree == null:
		return enemies

	for node in tree.get_nodes_in_group(ENCOUNTER_ENEMY_GROUP):
		var enemy: Node = node as Node
		if enemy == null:
			continue
		if not is_instance_valid(enemy) or not enemy.is_inside_tree():
			continue
		if not self.is_ancestor_of(enemy):
			continue
		enemies.append(enemy)

	return enemies


func _connect_enemy_ui_signals(enemy: Node) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return

	if enemy.has_signal("ui_target_requested") and not enemy.ui_target_requested.is_connected(_on_enemy_ui_target_requested):
		enemy.ui_target_requested.connect(_on_enemy_ui_target_requested)

	if enemy.has_signal("enemy_ui_changed"):
		var changed_callback := Callable(self, "_on_enemy_ui_changed").bind(enemy)
		if not enemy.enemy_ui_changed.is_connected(changed_callback):
			enemy.enemy_ui_changed.connect(changed_callback)

	if enemy.has_signal("died"):
		var died_callback := Callable(self, "_on_enemy_ui_target_died").bind(enemy)
		if not enemy.died.is_connected(died_callback):
			enemy.died.connect(died_callback)


func _on_enemy_ui_target_requested(enemy: Node) -> void:
	_set_current_enemy_ui_target(enemy)


func _on_enemy_ui_changed(_snapshot: Dictionary, enemy: Node) -> void:
	if enemy != current_enemy_ui_target:
		return
	_refresh_enemy_target_ui()


func _on_enemy_ui_target_died(enemy: Node) -> void:
	if enemy == current_enemy_ui_target:
		_clear_current_enemy_ui_target()


func _set_current_enemy_ui_target(enemy: Node) -> void:
	if not _is_valid_enemy_ui_target(enemy):
		return
	current_enemy_ui_target = enemy
	_refresh_enemy_target_ui()


func _clear_current_enemy_ui_target() -> void:
	current_enemy_ui_target = null
	if game_ui and game_ui.has_method("hide_enemy_target"):
		game_ui.hide_enemy_target()


func _refresh_enemy_target_ui() -> void:
	if game_ui == null or not game_ui.has_method("show_enemy_target"):
		return
	if not _is_valid_enemy_ui_target(current_enemy_ui_target):
		_clear_current_enemy_ui_target()
		return
	if not current_enemy_ui_target.has_method("get_enemy_ui_snapshot"):
		return

	var snapshot: Dictionary = current_enemy_ui_target.get_enemy_ui_snapshot()
	game_ui.show_enemy_target(snapshot, _should_show_exact_enemy_health())


func _is_valid_enemy_ui_target(enemy: Node) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false
	if not enemy.is_inside_tree():
		return false
	if not self.is_ancestor_of(enemy):
		return false
	if "is_alive" in enemy and not bool(enemy.is_alive):
		return false
	return true


func _should_show_exact_enemy_health() -> bool:
	return false


func _setup_consumable_use_controller() -> void:
	consumable_use_controller = null
	_clear_pending_consumable_use()

	if not current_player or CONSUMABLE_USE_CONTROLLER_SCRIPT == null:
		return

	consumable_use_controller = CONSUMABLE_USE_CONTROLLER_SCRIPT.new()
	consumable_use_controller.name = "ConsumableUseController"
	current_player.add_child(consumable_use_controller)
	consumable_use_controller.setup(current_player)

	if consumable_use_controller.has_signal("use_completed") and not consumable_use_controller.use_completed.is_connected(_on_consumable_use_completed):
		consumable_use_controller.use_completed.connect(_on_consumable_use_completed)
	if consumable_use_controller.has_signal("use_interrupted") and not consumable_use_controller.use_interrupted.is_connected(_on_consumable_use_interrupted):
		consumable_use_controller.use_interrupted.connect(_on_consumable_use_interrupted)


func _clear_pending_consumable_use() -> void:
	pending_consumable_item = null
	pending_consumable_hotbar_index = -1


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

	if "max_madness_stacks" in current_player:
		current_player.max_madness_stacks = Global.saved_player_max_madness_stacks
	if current_player.has_method("set_madness_stacks"):
		current_player.set_madness_stacks(Global.saved_player_madness_stacks)

	_refresh_resource_ui()
	Global.clear_saved_stats()


func save_before_transition() -> void:
	if not current_player or not Global:
		return

	if consumable_use_controller != null and is_instance_valid(consumable_use_controller) and consumable_use_controller.has_method("interrupt_use"):
		consumable_use_controller.interrupt_use("transition")

	Global.saved_player_health = current_player.current_health
	if "current_mana" in current_player:
		Global.saved_player_mana = current_player.current_mana
	else:
		Global.saved_player_mana = -1

	if "madness_stacks" in current_player:
		Global.saved_player_madness_stacks = int(current_player.madness_stacks)
	else:
		Global.saved_player_madness_stacks = 0

	if "max_madness_stacks" in current_player:
		Global.saved_player_max_madness_stacks = int(current_player.max_madness_stacks)
	else:
		Global.saved_player_max_madness_stacks = 9

	_clear_level_potion_effects()
	if RunState:
		RunState.capture_scene_state(self)

	current_encounter_zone = null
	_sync_instant_potion_repeat_blocks()


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
			"madness": current_player.madness_stacks if "madness_stacks" in current_player else 0,
			"max_madness": current_player.max_madness_stacks if "max_madness_stacks" in current_player else 9,
		}
		game_ui.setup_character_ui(stats)

	if current_player.has_signal("health_changed") and not current_player.health_changed.is_connected(_on_health_changed):
		current_player.health_changed.connect(_on_health_changed)

	if current_player.has_signal("mana_changed") and not current_player.mana_changed.is_connected(_on_mana_changed):
		current_player.mana_changed.connect(_on_mana_changed)

	if current_player.has_signal("madness_changed") and not current_player.madness_changed.is_connected(_on_madness_changed):
		current_player.madness_changed.connect(_on_madness_changed)

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

	_try_use_potion_item(item, -1)


func _on_hotbar_slot_used(index: int) -> void:
	if not current_player or not Inventory:
		return

	var item: InventoryItem = Inventory.get_hotbar_item(index)
	if not item or not item.data:
		return

	_try_use_potion_item(item, index)


func _try_use_potion_item(item: InventoryItem, source_hotbar_index: int = -1) -> bool:
	if not current_player or not Inventory or not item or not item.data or consumable_use_controller == null:
		return false
	if not Inventory.is_potion_item(item):
		return false

	if not Inventory.can_use_item_instance(item):
		return false

	if consumable_use_controller.has_method("is_busy") and consumable_use_controller.is_busy():
		return false

	var payload: Dictionary = {
		"item": item,
		"item_id": item.get_item_id(),
		"item_data": item.data,
		"effects": item.data.effects.duplicate(true),
		"consumable_type": int(item.data.consumable_type),
		"instant_kind": _get_instant_potion_kind(item.data),
		"duration": POTION_USE_DURATION,
		"move_multiplier": POTION_MOVE_SPEED_MULTIPLIER,
		"source_hotbar_index": source_hotbar_index,
	}

	if not consumable_use_controller.start_use(payload):
		return false

	pending_consumable_item = item
	pending_consumable_hotbar_index = source_hotbar_index
	return true


func _on_consumable_use_completed(payload: Dictionary) -> void:
	if not Inventory:
		_clear_pending_consumable_use()
		return

	var item: InventoryItem = payload.get("item", pending_consumable_item) as InventoryItem
	if item == null or item.data == null:
		_clear_pending_consumable_use()
		return

	if not Inventory.consume_item_instance(item, 1):
		_clear_pending_consumable_use()
		return

	for effect in payload.get("effects", []):
		_apply_potion_effect(effect)

	if int(payload.get("consumable_type", -1)) == int(InventoryEnums.ConsumableType.POTION_BUFF):
		Inventory.mark_potion_used(int(payload.get("item_id", item.get_item_id())), item.data, {
			"effects": item.data.effects.duplicate(true),
			"consumable_type": int(item.data.consumable_type),
		})

	Inventory.set_potion_global_cooldown(POTION_GLOBAL_COOLDOWN)
	if RunCombatTelemetry:
		RunCombatTelemetry.record_potion_use(_get_potion_telemetry_kind(payload), _get_room_progression_id())
	_clear_pending_consumable_use()


func _on_consumable_use_interrupted(_payload: Dictionary) -> void:
	_clear_pending_consumable_use()


func _has_active_blocking_enemy_in_level() -> bool:
	if not is_inside_tree():
		return false
	var tree: SceneTree = get_tree()
	if tree == null:
		return false

	for node in tree.get_nodes_in_group(ENCOUNTER_ENEMY_GROUP):
		var enemy: Node = node as Node
		if enemy == null:
			continue
		if not is_instance_valid(enemy) or not enemy.is_inside_tree():
			continue
		if not self.is_ancestor_of(enemy):
			continue
		if _is_enemy_currently_blocking(enemy):
			return true

	return false


func _is_enemy_currently_blocking(enemy: Node) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false

	if enemy.has_method("is_repeat_potion_blocker"):
		return bool(enemy.call("is_repeat_potion_blocker"))

	return enemy.is_in_group(ENCOUNTER_ENEMY_GROUP)


func _get_instant_potion_kind(item_data: GameItemData) -> String:
	if item_data == null:
		return ""

	match item_data.consumable_type:
		InventoryEnums.ConsumableType.POTION_HP:
			return POTION_KIND_HP
		InventoryEnums.ConsumableType.POTION_MANA:
			return POTION_KIND_MANA
		_:
			return ""


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

	if "madness_stacks" in current_player and game_ui.has_method("update_madness"):
		game_ui.update_madness(current_player.madness_stacks, current_player.max_madness_stacks)


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
		var preserved_health: int = current_player.current_health
		current_player.max_health = new_max_hp
		current_player.current_health = mini(preserved_health, current_player.max_health)

		if game_ui:
			game_ui.update_max_health(current_player.max_health)
			game_ui.update_health(current_player.current_health)

	if "max_mana" in current_player:
		var new_max_mana: int = base_player_max_mana + equipment_bonus_mana
		if current_player.max_mana != new_max_mana:
			var preserved_mana: int = current_player.current_mana
			current_player.max_mana = new_max_mana
			current_player.current_mana = mini(preserved_mana, current_player.max_mana)

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

	call_deferred("_refresh_adaptation_state")


func _on_equipment_changed(_slot = null, _old_item = null, _new_item = null) -> void:
	_update_revival_artifact_status()
	_update_double_jump_artifact()
	call_deferred("_refresh_adaptation_state")


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
	if Inventory.has_method("has_special_effect"):
		has_wings = Inventory.has_special_effect(InventoryEnums.EffectType.SPECIAL_DOUBLE_JUMP)

	if current_player.has_method("set_double_jump_enabled"):
		current_player.set_double_jump_enabled(has_wings)
		return

	if "enable_double_jump" in current_player:
		current_player.enable_double_jump = has_wings
	if "can_double_jump" in current_player:
		current_player.can_double_jump = has_wings and current_player.is_on_floor()
	if "has_double_jumped" in current_player:
		current_player.has_double_jumped = false


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


func _on_madness_changed(value, max_value) -> void:
	if game_ui and game_ui.has_method("update_madness"):
		game_ui.update_madness(value, max_value)


func _on_player_died() -> void:
	_clear_level_potion_effects()

	if Inventory:
		Inventory.reset_on_death()

	_apply_current_equipment_state()
	call_deferred("_refresh_current_encounter_zone")
	_on_level_player_died()


func _on_player_revived() -> void:
	_consume_revival_artifact()
	_apply_current_equipment_state()
	call_deferred("_refresh_current_encounter_zone")
	_on_level_player_revived()


func _clear_level_potion_effects() -> void:
	potion_bonus_armor = 0
	potion_bonus_damage = 0

	if Inventory and Inventory.has_method("clear_potion_effects"):
		Inventory.clear_potion_effects()

	if not current_player:
		return

	if "armor" in current_player:
		current_player.armor = base_player_armor + equipment_bonus_armor
		if game_ui and game_ui.has_method("update_armor"):
			game_ui.update_armor(current_player.armor)

	if "current_damage" in current_player:
		current_player.current_damage = base_player_damage + equipment_bonus_damage


func _get_potion_telemetry_kind(payload: Dictionary) -> String:
	if int(payload.get("consumable_type", -1)) == int(InventoryEnums.ConsumableType.POTION_BUFF):
		return "buff"

	match String(payload.get("instant_kind", "")):
		POTION_KIND_HP:
			return "hp"
		POTION_KIND_MANA:
			return "mana"
		_:
			return "buff"


func _on_player_damage_received(final_damage: int, reaction_tag: String) -> void:
	if RunCombatTelemetry:
		RunCombatTelemetry.record_damage_taken("physical", final_damage, reaction_tag, {
			"room_id": _get_room_progression_id(),
		})


func _on_player_combat_action_performed(action_name: String, payload: Dictionary) -> void:
	match action_name:
		"damage_dealt":
			if RunCombatTelemetry:
				RunCombatTelemetry.record_damage_dealt(String(payload.get("damage_type", "physical")), int(payload.get("amount", 0)), payload)
			var target_node: Node = payload.get("target_node", null) as Node
			if target_node != null:
				_set_current_enemy_ui_target(target_node)
		_:
			if RunCombatTelemetry:
				RunCombatTelemetry.record_combat_action(action_name, payload)


func _refresh_adaptation_state() -> void:
	var room_id: String = _get_room_progression_id()
	_capture_current_build_snapshot(room_id)
	if EnemyAdaptationDirector:
		EnemyAdaptationDirector.refresh_for_room(room_id)


func _capture_current_build_snapshot(room_id: String = "") -> void:
	if not current_player or not Inventory or not RunCombatTelemetry:
		return

	var resolved_room_id: String = room_id if not room_id.is_empty() else _get_room_progression_id()
	RunCombatTelemetry.capture_build_snapshot(resolved_room_id, current_player, Inventory)

func _create_fallback_player() -> void:
	var fallback: CharacterBody2D = CharacterBody2D.new()
	fallback.name = "FallbackPlayer"
	fallback.add_to_group("player")

	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(30, 50)
	collision.shape = shape
	fallback.add_child(collision)

	get_entities_root().add_child(fallback)
	fallback.global_position = player_spawn.global_position if player_spawn else Vector2(100, 100)
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
