extends Node

signal run_started
signal run_cleared
signal object_state_saved(level_id: String, persistent_id: String, state: Dictionary)

const PERSISTENT_GROUP: StringName = &"persistent_objects"

var is_run_active: bool = false
var current_level_id: String = ""
var object_states: Dictionary = {}
var visited_rooms: Dictionary = {}
var last_safe_room_id: String = ""
var last_safe_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	print("RunState loaded")


func start_new_run() -> void:
	is_run_active = true
	current_level_id = ""
	object_states.clear()
	visited_rooms.clear()
	last_safe_room_id = ""
	last_safe_position = Vector2.ZERO
	run_started.emit()


func clear_run() -> void:
	is_run_active = false
	current_level_id = ""
	object_states.clear()
	visited_rooms.clear()
	last_safe_room_id = ""
	last_safe_position = Vector2.ZERO
	run_cleared.emit()


func set_current_level(level_id: String) -> void:
	current_level_id = _normalize_level_id(level_id)
	if not current_level_id.is_empty():
		is_run_active = true


func resolve_level_id(context: Node = null) -> String:
	if context != null:
		var tree: SceneTree = context.get_tree()
		if tree != null:
			var scene: Node = tree.current_scene
			if scene != null:
				var scene_path: String = scene.scene_file_path
				if not scene_path.is_empty():
					return _normalize_level_id(scene_path)
				return _normalize_level_id(scene.name)

	if not current_level_id.is_empty():
		return current_level_id

	return "unknown_level"


func build_object_key(level_id: String, persistent_id: String) -> String:
	return "%s::%s" % [_normalize_level_id(level_id), persistent_id.strip_edges()]


func has_object_state(level_id: String, persistent_id: String) -> bool:
	var level_key: String = _normalize_level_id(level_id)
	var object_id: String = persistent_id.strip_edges()

	if object_id.is_empty():
		return false
	if not object_states.has(level_key):
		return false

	var states_for_level: Dictionary = object_states[level_key]
	return states_for_level.has(object_id)


func get_object_state(level_id: String, persistent_id: String) -> Dictionary:
	var level_key: String = _normalize_level_id(level_id)
	var object_id: String = persistent_id.strip_edges()

	if object_id.is_empty():
		return {}
	if not object_states.has(level_key):
		return {}

	var states_for_level: Dictionary = object_states[level_key]
	if not states_for_level.has(object_id):
		return {}

	var stored_state: Dictionary = states_for_level[object_id]
	return stored_state.duplicate(true)


func get_level_states(level_id: String) -> Dictionary:
	var level_key: String = _normalize_level_id(level_id)
	if not object_states.has(level_key):
		return {}

	var states_for_level: Dictionary = object_states[level_key]
	return states_for_level.duplicate(true)


func save_object_state(level_id: String, persistent_id: String, state: Dictionary) -> Dictionary:
	var level_key: String = _normalize_level_id(level_id)
	var object_id: String = persistent_id.strip_edges()

	if object_id.is_empty():
		push_warning("RunState.save_object_state called without persistent_id")
		return {}

	var states_for_level: Dictionary = {}
	if object_states.has(level_key):
		states_for_level = object_states[level_key]

	var normalized_state: Dictionary = state.duplicate(true)
	normalized_state["persistent_id"] = object_id
	normalized_state["level_id"] = level_key

	if not normalized_state.has("object_type"):
		normalized_state["object_type"] = "generic"
	if not normalized_state.has("consumed"):
		normalized_state["consumed"] = false

	states_for_level[object_id] = normalized_state
	object_states[level_key] = states_for_level
	object_state_saved.emit(level_key, object_id, normalized_state.duplicate(true))
	return normalized_state.duplicate(true)


func remove_object_state(level_id: String, persistent_id: String) -> void:
	var level_key: String = _normalize_level_id(level_id)
	var object_id: String = persistent_id.strip_edges()

	if object_id.is_empty():
		return
	if not object_states.has(level_key):
		return

	var states_for_level: Dictionary = object_states[level_key]
	states_for_level.erase(object_id)

	if states_for_level.is_empty():
		object_states.erase(level_key)
	else:
		object_states[level_key] = states_for_level


func mark_object_consumed(level_id: String, persistent_id: String, extra_state: Dictionary = {}) -> Dictionary:
	var state: Dictionary = get_object_state(level_id, persistent_id)

	if state.is_empty():
		state = {}

	var extra_keys: Array = extra_state.keys()
	for key_variant in extra_keys:
		state[key_variant] = extra_state[key_variant]

	state["consumed"] = true
	return save_object_state(level_id, persistent_id, state)


func is_object_consumed(level_id: String, persistent_id: String) -> bool:
	var state: Dictionary = get_object_state(level_id, persistent_id)
	if state.is_empty():
		return false

	return bool(state.get("consumed", false))


func get_object_flag(level_id: String, persistent_id: String, flag_name: String) -> bool:
	var state: Dictionary = get_object_state(level_id, persistent_id)
	if state.is_empty():
		return false

	return bool(state.get(flag_name, false))


func get_object_flag_any_level(persistent_id: String, flag_name: String) -> bool:
	var object_id: String = persistent_id.strip_edges()
	if object_id.is_empty():
		return false

	var level_keys: Array = object_states.keys()
	for level_key_variant in level_keys:
		var level_key: String = String(level_key_variant)
		if get_object_flag(level_key, object_id, flag_name):
			return true

	return false


func capture_scene_state(root: Node) -> void:
	if root == null:
		return

	var tree: SceneTree = root.get_tree()
	if tree == null:
		return

	var nodes: Array = tree.get_nodes_in_group(PERSISTENT_GROUP)
	for node_variant in nodes:
		var node: Node = node_variant as Node
		if node == null:
			continue
		if node != root and not root.is_ancestor_of(node):
			continue

		var component: PersistenceComponent = _resolve_component(node)
		if component != null:
			component.save_from_owner()


func mark_room_visited(room_id: String) -> void:
	var normalized_room_id: String = room_id.strip_edges()
	if normalized_room_id.is_empty():
		return

	visited_rooms[normalized_room_id] = true


func is_room_visited(room_id: String) -> bool:
	var normalized_room_id: String = room_id.strip_edges()
	if normalized_room_id.is_empty():
		return false

	return visited_rooms.has(normalized_room_id)


func save_safe_position(room_id: String, position: Vector2) -> void:
	last_safe_room_id = room_id.strip_edges()
	last_safe_position = position


func get_safe_position_data() -> Dictionary:
	return {
		"room_id": last_safe_room_id,
		"position": last_safe_position,
	}


func _normalize_level_id(level_id: String) -> String:
	var normalized: String = level_id.strip_edges()
	if normalized.is_empty():
		return "unknown_level"

	return normalized.replace("\\", "/")


func _resolve_component(node: Node) -> PersistenceComponent:
	var meta_value: Variant = node.get_meta("persistence_component", null)
	if meta_value is PersistenceComponent:
		return meta_value

	var component: PersistenceComponent = node.get_node_or_null("Persistence") as PersistenceComponent
	return component
