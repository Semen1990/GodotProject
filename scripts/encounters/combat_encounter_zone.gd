extends Area2D
class_name CombatEncounterZone

signal player_entered_encounter(zone)
signal player_exited_encounter(zone)
signal instant_potion_restrictions_changed(zone)

const PERSISTENCE_COMPONENT := preload("res://scripts/persistence/persistence_component.gd")
const POTION_KIND_HP: String = "hp"
const POTION_KIND_MANA: String = "mana"

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
	return players_inside.has(player.get_instance_id()) or overlaps_body(player)


func _refresh_overlap_state() -> void:
	if not is_inside_tree() or is_refreshing_overlap_state:
		return

	is_refreshing_overlap_state = true
	_bootstrap_overlaps()
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
		if player_body != null:
			_on_body_exited(player_body)
		else:
			players_inside.erase(player_id)

	for enemy_id_variant in tracked_enemies.keys():
		var enemy_id: int = int(enemy_id_variant)
		if overlapping_ids.has(enemy_id):
			continue

		var enemy_body: Node = tracked_enemies.get(enemy_id) as Node
		if enemy_body != null:
			_unregister_enemy(enemy_body)
		else:
			tracked_enemies.erase(enemy_id)
			blocking_enemy_ids.erase(enemy_id)


func _on_body_entered(body: Node2D) -> void:
	if body == null:
		return

	if body.is_in_group("player"):
		var player_id: int = body.get_instance_id()
		var was_present: bool = players_inside.has(player_id)
		players_inside[player_id] = body
		if not was_present and not is_refreshing_overlap_state:
			player_entered_encounter.emit(self)
		return

	if body.is_in_group("encounter_enemy"):
		_register_enemy(body)


func _on_body_exited(body: Node2D) -> void:
	if body == null:
		return

	if body.is_in_group("player"):
		var player_id: int = body.get_instance_id()
		var was_present: bool = players_inside.has(player_id)
		players_inside.erase(player_id)
		if was_present and players_inside.is_empty() and not is_refreshing_overlap_state:
			player_exited_encounter.emit(self)
		return

	if body.is_in_group("encounter_enemy"):
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

	var is_blocking: bool = false
	if enemy.has_method("is_repeat_potion_blocker"):
		is_blocking = bool(enemy.call("is_repeat_potion_blocker"))
	else:
		is_blocking = enemy.is_in_group("encounter_enemy")

	_set_enemy_blocking(enemy.get_instance_id(), is_blocking)


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
	return not blocking_enemy_ids.is_empty()


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

	var rectangle: RectangleShape2D = collision_shape.shape as RectangleShape2D
	if rectangle == null:
		rectangle = RectangleShape2D.new()
		collision_shape.shape = rectangle

	rectangle.size = zone_size
