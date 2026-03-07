extends Node
class_name PersistenceComponent

@export var persistent_id: String = ""
@export var object_type: String = "generic"
@export var destroy_if_consumed: bool = false


func _ready() -> void:
	_register_owner()


func configure(id: String = "", type: String = "", should_destroy_if_consumed: bool = false) -> void:
	if not id.is_empty():
		persistent_id = id
	if not type.is_empty():
		object_type = type

	destroy_if_consumed = should_destroy_if_consumed
	_register_owner()


func get_target_node() -> Node:
	return get_parent()


func get_persistent_id() -> String:
	if not persistent_id.is_empty():
		return persistent_id

	var target: Node = get_target_node()
	if target != null:
		return target.name

	return name


func get_level_id() -> String:
	if RunState == null:
		return "unknown_level"

	return RunState.resolve_level_id(get_target_node())


func has_saved_state() -> bool:
	if RunState == null:
		return false

	return RunState.has_object_state(get_level_id(), get_persistent_id())


func get_saved_state() -> Dictionary:
	if RunState == null:
		return {}

	return RunState.get_object_state(get_level_id(), get_persistent_id())


func save_state(state: Dictionary) -> Dictionary:
	if RunState == null:
		return {}

	var normalized_state: Dictionary = state.duplicate(true)
	normalized_state["object_type"] = object_type
	return RunState.save_object_state(get_level_id(), get_persistent_id(), normalized_state)


func save_from_owner() -> Dictionary:
	var state: Dictionary = capture_from_owner()
	return save_state(state)


func capture_from_owner() -> Dictionary:
	var target: Node = get_target_node()
	if target == null:
		return {}

	if target.has_method("capture_persistent_state"):
		var captured_value: Variant = target.call("capture_persistent_state")
		if captured_value is Dictionary:
			var captured_state: Dictionary = captured_value
			return captured_state.duplicate(true)

	if target.has_method("save_state"):
		var legacy_value: Variant = target.call("save_state")
		if legacy_value is Dictionary:
			var legacy_state: Dictionary = legacy_value
			return legacy_state.duplicate(true)

	return {}


func apply_to_owner(state: Dictionary) -> void:
	var target: Node = get_target_node()
	if target == null:
		return

	var state_copy: Dictionary = state.duplicate(true)

	if target.has_method("apply_persistent_state"):
		target.call("apply_persistent_state", state_copy)
		return

	if target.has_method("load_state"):
		target.call("load_state", state_copy)


func restore_from_saved_state() -> bool:
	var saved_state: Dictionary = get_saved_state()
	if saved_state.is_empty():
		return false

	apply_to_owner(saved_state)
	return true


func mark_consumed(extra_state: Dictionary = {}) -> Dictionary:
	var state: Dictionary = get_saved_state()
	if state.is_empty():
		state = capture_from_owner()

	var extra_keys: Array = extra_state.keys()
	for key_variant in extra_keys:
		state[key_variant] = extra_state[key_variant]

	state["consumed"] = true
	return save_state(state)


func is_consumed() -> bool:
	var state: Dictionary = get_saved_state()
	if state.is_empty():
		return false

	return bool(state.get("consumed", false))


func _register_owner() -> void:
	var target: Node = get_target_node()
	if target == null:
		return

	target.set_meta("persistence_component", self)

	if not target.is_in_group(RunState.PERSISTENT_GROUP):
		target.add_to_group(RunState.PERSISTENT_GROUP)
