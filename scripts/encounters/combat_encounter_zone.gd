extends Area2D
class_name CombatEncounterZone

signal player_entered_encounter(zone)
signal player_exited_encounter(zone)
signal instant_potion_restrictions_changed(zone)

const PERSISTENCE_COMPONENT := preload("res://scripts/persistence/persistence_component.gd")
const POTION_KIND_HP: String = "hp"
const POTION_KIND_MANA: String = "mana"
const PLAYER_GROUP: String = "player"
const ENEMY_GROUP: String = "encounter_enemy"

@export var persistent_id: String = ""
@export var zone_label: String = ""
@export var zone_size: Vector2 = Vector2(480.0, 320.0)

var persistence: PersistenceComponent = null
var tracked_enemies: Dictionary = {}
var blocking_enemy_ids: Dictionary = {}
var players_inside: Dictionary = {}
var is_refreshing_overlap_state: bool = false
var used_instant_potions: Dictionary = {
	POTION_KIND_HP: false,
	POTION_KIND_MANA: false,
}

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 0
	collision_mask = 6
	add_to_group("combat_encounter_zones")

	_update_collision_shape()
	_ensure_persistence()
	_configure_persistence()
	_load_saved_state()

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

	call_deferred("_refresh_overlap_state")


func capture_persistent_state() -> Dictionary:
	return {
		"used_instant_potions": used_instant_potions.duplicate(true),
	}


func apply_persistent_state(state: Dictionary) -> void:
	var saved_usage_variant: Variant = state.get("used_instant_potions", {})
	var saved_usage: Dictionary = {}
	if saved_usage_variant is Dictionary:
		saved_usage = saved_usage_variant

	used_instant_potions = {
		POTION_KIND_HP: bool(saved_usage.get(POTION_KIND_HP, false)),
		POTION_KIND_MANA: bool(saved_usage.get(POTION_KIND_MANA, false)),
	}


func can_use_instant_potion(potion_kind: String) -> bool:
	_refresh_overlap_state()
	if not _has_active_blockers():
		return true

	return not bool(used_instant_potions.get(potion_kind, false))


func register_instant_potion_use(potion_kind: String) -> void:
	if not _has_active_blockers():
		return
	if bool(used_instant_potions.get(potion_kind, false)):
		return

	used_instant_potions[potion_kind] = true
	_save_state()
	instant_potion_restrictions_changed.emit(self)


func get_instant_potion_blocks() -> Dictionary:
	_refresh_overlap_state()
	return {
		POTION_KIND_HP: _has_active_blockers() and bool(used_instant_potions.get(POTION_KIND_HP, false)),
		POTION_KIND_MANA: _has_active_blockers() and bool(used_instant_potions.get(POTION_KIND_MANA, false)),
	}


func has_player(player: Node) -> bool:
	if player == null:
		return false

	_refresh_overlap_state()
	if players_inside.has(player.get_instance_id()) or overlaps_body(player):
		return true

	var player_body: Node2D = player as Node2D
	return player_body != null and contains_world_point(player_body.global_position)


func contains_world_point(world_point: Vector2) -> bool:
	var local_point: Vector2 = to_local(world_point)
	return _contains_local_point(local_point)


func _contains_local_point(local_point: Vector2) -> bool:
	if collision_shape != null and collision_shape.shape != null:
		var shape_local_point: Vector2 = local_point - collision_shape.position
		if collision_shape.shape is RectangleShape2D:
			var rectangle: RectangleShape2D = collision_shape.shape as RectangleShape2D
			var half_size: Vector2 = rectangle.size * 0.5
			return absf(shape_local_point.x) <= half_size.x and absf(shape_local_point.y) <= half_size.y
		if collision_shape.shape is CircleShape2D:
			var circle: CircleShape2D = collision_shape.shape as CircleShape2D
			return shape_local_point.length() <= circle.radius
		if collision_shape.shape is CapsuleShape2D:
			var capsule: CapsuleShape2D = collision_shape.shape as CapsuleShape2D
			var radius: float = capsule.radius
			var body_half_height: float = maxf(capsule.height * 0.5 - radius, 0.0)
			var clamped_y: float = clampf(shape_local_point.y, -body_half_height, body_half_height)
			var closest_point := Vector2(0.0, clamped_y)
			return shape_local_point.distance_to(closest_point) <= radius

	var fallback_half_size: Vector2 = zone_size * 0.5
	return absf(local_point.x) <= fallback_half_size.x and absf(local_point.y) <= fallback_half_size.y


func _refresh_overlap_state() -> void:
	if not is_inside_tree() or is_refreshing_overlap_state:
		return

	is_refreshing_overlap_state = true
	_bootstrap_overlaps()
	_sync_group_members_by_position()
	is_refreshing_overlap_state = false


func _bootstrap_overlaps() -> void:
	var overlapping_bodies: Array[Node2D] = get_overlapping_bodies()
	var overlapping_ids: Dictionary = {}
	for body in overlapping_bodies:
		if body == null:
			continue

		overlapping_ids[body.get_instance_id()] = true
		_on_body_entered(body)

	for player_id_variant in players_inside.keys():
		var player_id: int = int(player_id_variant)
		if overlapping_ids.has(player_id):
			continue

		var player_body: Node2D = players_inside.get(player_id) as Node2D
		if player_body != null and overlaps_body(player_body):
			continue
		if player_body != null:
			_on_body_exited(player_body)
		else:
			players_inside.erase(player_id)

	for enemy_id_variant in tracked_enemies.keys():
		var enemy_id: int = int(enemy_id_variant)
		if overlapping_ids.has(enemy_id):
			continue

		var enemy_body: Node = tracked_enemies.get(enemy_id) as Node
		if enemy_body is Node2D and overlaps_body(enemy_body):
			continue
		if enemy_body != null:
			_unregister_enemy(enemy_body)
		else:
			tracked_enemies.erase(enemy_id)
			blocking_enemy_ids.erase(enemy_id)


func _sync_group_members_by_position() -> void:
	_sync_players_by_position()
	_sync_enemies_by_position()


func _sync_players_by_position() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return

	var seen_player_ids: Dictionary = {}
	for node in tree.get_nodes_in_group(PLAYER_GROUP):
		var player_body: Node2D = node as Node2D
		if player_body == null or not is_instance_valid(player_body) or not player_body.is_inside_tree():
			continue
		if not contains_world_point(player_body.global_position):
			continue

		var player_id: int = player_body.get_instance_id()
		seen_player_ids[player_id] = true
		players_inside[player_id] = player_body

	for player_id_variant in players_inside.keys().duplicate():
		var player_id: int = int(player_id_variant)
		if seen_player_ids.has(player_id):
			continue
		players_inside.erase(player_id)


func _sync_enemies_by_position() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return

	var seen_enemy_ids: Dictionary = {}
	for node in tree.get_nodes_in_group(ENEMY_GROUP):
		var enemy_body: Node2D = node as Node2D
		if enemy_body == null or not is_instance_valid(enemy_body) or not enemy_body.is_inside_tree():
			continue
		if not contains_world_point(enemy_body.global_position):
			continue

		seen_enemy_ids[enemy_body.get_instance_id()] = true
		_register_enemy(enemy_body)

	for enemy_id_variant in tracked_enemies.keys().duplicate():
		var enemy_id: int = int(enemy_id_variant)
		if seen_enemy_ids.has(enemy_id):
			continue
		var enemy_body: Node2D = tracked_enemies.get(enemy_id) as Node2D
		if enemy_body != null and contains_world_point(enemy_body.global_position):
			continue
		if enemy_body != null:
			_unregister_enemy(enemy_body)
		else:
			tracked_enemies.erase(enemy_id)
			blocking_enemy_ids.erase(enemy_id)


func get_active_blocking_enemy_count() -> int:
	var tree: SceneTree = get_tree()
	if tree == null:
		return 0

	var blocker_count: int = 0
	for node in tree.get_nodes_in_group(ENEMY_GROUP):
		var enemy_body: Node2D = node as Node2D
		if enemy_body == null:
			continue
		if not is_instance_valid(enemy_body) or not enemy_body.is_inside_tree():
			continue
		if not contains_world_point(enemy_body.global_position):
			continue
		if _is_enemy_currently_blocking(enemy_body):
			blocker_count += 1

	return blocker_count


func _on_body_entered(body: Node2D) -> void:
	if body == null:
		return

	if body.is_in_group(PLAYER_GROUP):
		var player_id: int = body.get_instance_id()
		var was_present: bool = players_inside.has(player_id)
		players_inside[player_id] = body
		if not was_present and not is_refreshing_overlap_state:
			player_entered_encounter.emit(self)
		return

	if body.is_in_group(ENEMY_GROUP):
		_register_enemy(body)


func _on_body_exited(body: Node2D) -> void:
	if body == null:
		return

	if body.is_in_group(PLAYER_GROUP):
		var player_id: int = body.get_instance_id()
		var was_present: bool = players_inside.has(player_id)
		players_inside.erase(player_id)
		if was_present and players_inside.is_empty() and not is_refreshing_overlap_state:
			player_exited_encounter.emit(self)
		return

	if body.is_in_group(ENEMY_GROUP):
		_unregister_enemy(body)


func _register_enemy(enemy: Node) -> void:
	if enemy == null:
		return

	var enemy_id: int = enemy.get_instance_id()
	if tracked_enemies.has(enemy_id):
		_update_enemy_blocking(enemy)
		return

	tracked_enemies[enemy_id] = enemy

	var died_callable: Callable = Callable(self, "_on_enemy_died").bind(enemy)
	if enemy.has_signal("died") and not enemy.died.is_connected(died_callable):
		enemy.died.connect(died_callable)

	var blocking_callable: Callable = Callable(self, "_on_enemy_blocking_changed").bind(enemy)
	if enemy.has_signal("repeat_potion_blocking_changed") and not enemy.repeat_potion_blocking_changed.is_connected(blocking_callable):
		enemy.repeat_potion_blocking_changed.connect(blocking_callable)

	var tree_exited_callable: Callable = Callable(self, "_on_enemy_tree_exited").bind(enemy)
	if not enemy.tree_exited.is_connected(tree_exited_callable):
		enemy.tree_exited.connect(tree_exited_callable)

	_update_enemy_blocking(enemy)


func _unregister_enemy(enemy: Node) -> void:
	if enemy == null:
		return

	var enemy_id: int = enemy.get_instance_id()
	if not tracked_enemies.has(enemy_id):
		return

	var was_blocking: bool = blocking_enemy_ids.has(enemy_id)
	tracked_enemies.erase(enemy_id)
	blocking_enemy_ids.erase(enemy_id)

	_disconnect_enemy_signals(enemy)

	if was_blocking:
		_release_limits_if_safe()
		if not is_refreshing_overlap_state:
			instant_potion_restrictions_changed.emit(self)


func _disconnect_enemy_signals(enemy: Node) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return

	var died_callable: Callable = Callable(self, "_on_enemy_died").bind(enemy)
	if enemy.has_signal("died") and enemy.died.is_connected(died_callable):
		enemy.died.disconnect(died_callable)

	var blocking_callable: Callable = Callable(self, "_on_enemy_blocking_changed").bind(enemy)
	if enemy.has_signal("repeat_potion_blocking_changed") and enemy.repeat_potion_blocking_changed.is_connected(blocking_callable):
		enemy.repeat_potion_blocking_changed.disconnect(blocking_callable)

	var tree_exited_callable: Callable = Callable(self, "_on_enemy_tree_exited").bind(enemy)
	if enemy.tree_exited.is_connected(tree_exited_callable):
		enemy.tree_exited.disconnect(tree_exited_callable)


func _update_enemy_blocking(enemy: Node) -> void:
	if enemy == null:
		return

	var is_blocking: bool = _is_enemy_currently_blocking(enemy)
	_set_enemy_blocking(enemy.get_instance_id(), is_blocking)


func _is_enemy_currently_blocking(enemy: Node) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false

	if enemy.has_method("is_repeat_potion_blocker"):
		return bool(enemy.call("is_repeat_potion_blocker"))

	return enemy.is_in_group(ENEMY_GROUP)


func _set_enemy_blocking(enemy_id: int, is_blocking: bool) -> void:
	var was_blocking: bool = blocking_enemy_ids.has(enemy_id)

	if is_blocking:
		blocking_enemy_ids[enemy_id] = true
	else:
		blocking_enemy_ids.erase(enemy_id)

	if was_blocking == is_blocking:
		return

	_release_limits_if_safe()
	if not is_refreshing_overlap_state:
		instant_potion_restrictions_changed.emit(self)


func _on_enemy_died(enemy: Node) -> void:
	if enemy == null:
		return

	_set_enemy_blocking(enemy.get_instance_id(), false)


func _on_enemy_blocking_changed(_is_blocking: bool, enemy: Node) -> void:
	if enemy == null:
		return

	_update_enemy_blocking(enemy)


func _on_enemy_tree_exited(enemy: Node) -> void:
	_unregister_enemy(enemy)


func _has_active_blockers() -> bool:
	return get_active_blocking_enemy_count() > 0


func _release_limits_if_safe() -> void:
	if _has_active_blockers():
		return

	var had_hp_limit: bool = bool(used_instant_potions.get(POTION_KIND_HP, false))
	var had_mana_limit: bool = bool(used_instant_potions.get(POTION_KIND_MANA, false))
	if not had_hp_limit and not had_mana_limit:
		return

	used_instant_potions[POTION_KIND_HP] = false
	used_instant_potions[POTION_KIND_MANA] = false
	_save_state()


func _ensure_persistence() -> void:
	persistence = get_node_or_null("Persistence") as PersistenceComponent
	if persistence != null:
		return

	persistence = PERSISTENCE_COMPONENT.new()
	persistence.name = "Persistence"
	add_child(persistence)


func _configure_persistence() -> void:
	if persistence == null:
		return

	var resolved_id: String = persistent_id if not persistent_id.is_empty() else name
	persistence.configure(resolved_id, "encounter_zone", false)


func _load_saved_state() -> void:
	if Global and not Global.run_started:
		return
	if persistence == null:
		return

	var saved_state: Dictionary = persistence.get_saved_state()
	if saved_state.is_empty():
		return

	apply_persistent_state(saved_state)


func _save_state() -> void:
	if persistence:
		persistence.save_from_owner()


func _update_collision_shape() -> void:
	if collision_shape == null:
		return

	# Shape must stay centered on the encounter node so scene offsets do not break detection.
	collision_shape.position = Vector2.ZERO

	var rectangle: RectangleShape2D = collision_shape.shape as RectangleShape2D
	if rectangle == null:
		rectangle = RectangleShape2D.new()
		collision_shape.shape = rectangle

	rectangle.size = zone_size