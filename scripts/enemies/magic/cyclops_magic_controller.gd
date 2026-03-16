extends RefCounted
class_name CyclopsMagicController

const SPELL_NONE: StringName = &""
const SPELL0: StringName = &"spell0"
const SPELL1: StringName = &"spell1"
const SPELL2: StringName = &"spell2"
const SPELL3: StringName = &"spell3"

var owner: Node2D
var profile: CyclopsMagicProfile
var active_spell: Node = null
var active_spell_id: StringName = SPELL_NONE
var next_global_spell_time_msec: int = 0
var next_spell_ready_at_msec: Dictionary = {}


func setup(owner_node: Node2D, magic_profile: CyclopsMagicProfile) -> CyclopsMagicController:
	owner = owner_node
	profile = magic_profile
	_initialize_cooldowns()
	return self


func get_state() -> Dictionary:
	var now_msec: int = Time.get_ticks_msec()
	return {
		"global_spell_pause_remaining_msec": max(0, next_global_spell_time_msec - now_msec),
		"spell_ready_remaining_msec": {
			String(SPELL0): max(0, get_spell_ready_time_msec(SPELL0) - now_msec),
			String(SPELL1): max(0, get_spell_ready_time_msec(SPELL1) - now_msec),
			String(SPELL2): max(0, get_spell_ready_time_msec(SPELL2) - now_msec),
			String(SPELL3): max(0, get_spell_ready_time_msec(SPELL3) - now_msec),
		},
	}


func load_state(state: Dictionary) -> void:
	_initialize_cooldowns()
	var now_msec: int = Time.get_ticks_msec()
	next_global_spell_time_msec = now_msec + int(state.get("global_spell_pause_remaining_msec", 0))

	var saved_ready_times: Dictionary = state.get("spell_ready_remaining_msec", {})
	if saved_ready_times.is_empty():
		return

	for spell_key in saved_ready_times.keys():
		var spell_id: StringName = StringName(String(spell_key))
		next_spell_ready_at_msec[spell_id] = now_msec + int(saved_ready_times[spell_key])


func get_floor_delta_to_target(target_node: Node) -> int:
	if target_node == null or not is_instance_valid(target_node):
		return 999

	var owner_floor: int = _get_node_comparable_floor_id(owner)
	var target_floor: int = _get_node_comparable_floor_id(target_node)
	if owner_floor == -1 or target_floor == -1:
		return 999
	return absi(owner_floor - target_floor)


func can_use_melee(target_node: Node) -> bool:
	return get_floor_delta_to_target(target_node) == 0


func can_use_overhead_spell(target_node: Node) -> bool:
	return get_floor_delta_to_target(target_node) <= profile.max_overhead_spell_floor_delta


func can_use_line_spell(target_node: Node) -> bool:
	return get_floor_delta_to_target(target_node) <= profile.max_line_spell_floor_delta


func can_use_aoe_spell(target_node: Node) -> bool:
	return get_floor_delta_to_target(target_node) <= profile.max_aoe_spell_floor_delta


func is_magic_locked() -> bool:
	if active_spell != null and is_instance_valid(active_spell):
		return true
	return Time.get_ticks_msec() < next_global_spell_time_msec


func get_active_spell_id() -> StringName:
	return active_spell_id


func get_spell_ready_time_msec(spell_id: StringName) -> int:
	return int(next_spell_ready_at_msec.get(spell_id, 0))


func set_spell_ready_time_msec(spell_id: StringName, ready_time_msec: int) -> void:
	next_spell_ready_at_msec[spell_id] = ready_time_msec


func choose_spell_for_target(target_node: Node, distance_to_target: float, max_cast_distance: float) -> StringName:
	if target_node == null or not is_instance_valid(target_node):
		return SPELL_NONE
	if is_magic_locked():
		return SPELL_NONE

	var floor_delta: int = get_floor_delta_to_target(target_node)
	var available_spells: Array[StringName] = []

	if can_begin_spell0(target_node, distance_to_target, max_cast_distance):
		available_spells.append(SPELL0)
	if can_begin_spell1(target_node, distance_to_target, max_cast_distance):
		available_spells.append(SPELL1)
	if can_begin_spell2(target_node, distance_to_target, max_cast_distance):
		available_spells.append(SPELL2)
	if can_begin_spell3(target_node, distance_to_target):
		available_spells.append(SPELL3)

	if available_spells.is_empty():
		return SPELL_NONE

	if floor_delta == 1:
		return _choose_weighted_spell(available_spells, {
			SPELL1: 0.6,
			SPELL0: 0.4,
		})

	return available_spells.pick_random()


func can_begin_spell0(target_node: Node, distance_to_target: float, max_cast_distance: float) -> bool:
	if not _can_begin_spell_common(target_node, SPELL0):
		return false
	var floor_delta: int = get_floor_delta_to_target(target_node)
	if floor_delta > profile.max_overhead_spell_floor_delta:
		return false
	if floor_delta == 0 and distance_to_target < profile.spell0_min_distance:
		return false
	return distance_to_target <= max_cast_distance


func can_begin_spell1(target_node: Node, distance_to_target: float, max_cast_distance: float) -> bool:
	if not _can_begin_spell_common(target_node, SPELL1):
		return false
	if not can_use_overhead_spell(target_node):
		return false
	if distance_to_target < profile.spell1_min_distance:
		return false
	return distance_to_target <= max_cast_distance


func can_begin_spell2(target_node: Node, distance_to_target: float, max_cast_distance: float) -> bool:
	if not _can_begin_spell_common(target_node, SPELL2):
		return false
	if not can_use_line_spell(target_node):
		return false
	if distance_to_target < profile.spell2_min_distance:
		return false
	return distance_to_target <= max_cast_distance


func can_begin_spell3(target_node: Node, distance_to_target: float) -> bool:
	if not _can_begin_spell_common(target_node, SPELL3):
		return false
	if not can_use_aoe_spell(target_node):
		return false
	return distance_to_target <= profile.spell3_max_distance


func register_spell_started(spell_id: StringName, spell_node: Node) -> void:
	if spell_id == SPELL_NONE:
		return

	set_spell_ready_time_msec(
		spell_id,
		Time.get_ticks_msec() + int(_get_spell_cooldown_time(spell_id) * 1000.0)
	)

	active_spell = spell_node
	active_spell_id = spell_id

	if active_spell != null and is_instance_valid(active_spell):
		if not active_spell.tree_exited.is_connected(_on_active_spell_tree_exited):
			active_spell.tree_exited.connect(_on_active_spell_tree_exited)
	else:
		_on_active_spell_tree_exited()


func _can_begin_spell_common(target_node: Node, spell_id: StringName) -> bool:
	if target_node == null or not is_instance_valid(target_node):
		return false
	if not is_spell_enabled(spell_id):
		return false
	if is_magic_locked():
		return false
	return is_spell_ready(spell_id)


func is_spell_enabled(spell_id: StringName) -> bool:
	match spell_id:
		SPELL0:
			return profile.spell0_enabled
		SPELL1:
			return profile.spell1_enabled
		SPELL2:
			return profile.spell2_enabled
		SPELL3:
			return profile.spell3_enabled
		_:
			return false


func is_spell_ready(spell_id: StringName) -> bool:
	return Time.get_ticks_msec() >= get_spell_ready_time_msec(spell_id)


func _get_spell_cooldown_time(spell_id: StringName) -> float:
	match spell_id:
		SPELL0:
			return profile.spell0_cooldown_time
		SPELL1:
			return profile.spell1_cooldown_time
		SPELL2:
			return profile.spell2_cooldown_time
		SPELL3:
			return profile.spell3_cooldown_time
		_:
			return 0.0


func _on_active_spell_tree_exited() -> void:
	active_spell = null
	active_spell_id = SPELL_NONE
	next_global_spell_time_msec = Time.get_ticks_msec() + int(profile.spell_global_pause_time * 1000.0)


func _initialize_cooldowns() -> void:
	next_spell_ready_at_msec = {
		SPELL0: 0,
		SPELL1: 0,
		SPELL2: 0,
		SPELL3: 0,
	}


func _get_node_comparable_floor_id(node: Node) -> int:
	if node == null or not is_instance_valid(node):
		return -1
	if node.has_method("get_current_combat_floor_id"):
		var current_floor: int = int(node.call("get_current_combat_floor_id"))
		if current_floor != -1:
			return current_floor
	if node.has_method("get_effective_combat_floor_id"):
		var effective_floor: int = int(node.call("get_effective_combat_floor_id"))
		if effective_floor != -1:
			return effective_floor
	return _resolve_floor_id_from_world(node)


func _resolve_floor_id_from_world(node: Node) -> int:
	if node == null or not is_instance_valid(node):
		return -1

	var tree: SceneTree = null
	if node is Node:
		tree = node.get_tree()
	if tree == null:
		return -1

	var probe_point: Vector2 = _get_node_floor_probe_world_point(node)
	var best_floor_id: int = -1
	var best_priority: int = -2147483648

	for area_variant in tree.get_nodes_in_group("combat_floor_areas"):
		var area_node: Node = area_variant as Node
		if area_node == null or not is_instance_valid(area_node):
			continue
		if not area_node.has_method("contains_world_point"):
			continue
		if not bool(area_node.call("contains_world_point", probe_point)):
			continue

		var area_priority: int = int(area_node.get("floor_priority"))
		var area_floor_id: int = int(area_node.get("floor_id"))
		if area_priority > best_priority or (area_priority == best_priority and area_floor_id > best_floor_id):
			best_priority = area_priority
			best_floor_id = area_floor_id

	return best_floor_id


func _get_node_floor_probe_world_point(node: Node) -> Vector2:
	if node == null or not is_instance_valid(node):
		return Vector2.ZERO
	if node.has_method("_get_combat_floor_probe_world_point"):
		var probe_point: Variant = node.call("_get_combat_floor_probe_world_point")
		if probe_point is Vector2:
			return probe_point
	if node is Node2D:
		return (node as Node2D).global_position
	return Vector2.ZERO


func _choose_weighted_spell(available_spells: Array[StringName], weights: Dictionary) -> StringName:
	var weighted_options: Array[Dictionary] = []
	var total_weight: float = 0.0

	for spell_id in available_spells:
		var weight: float = float(weights.get(spell_id, 1.0))
		if weight <= 0.0:
			continue
		weighted_options.append({
			"spell_id": spell_id,
			"weight": weight,
		})
		total_weight += weight

	if weighted_options.is_empty():
		return SPELL_NONE
	if weighted_options.size() == 1:
		return weighted_options[0]["spell_id"]

	var roll: float = randf() * total_weight
	for option in weighted_options:
		roll -= float(option["weight"])
		if roll <= 0.0:
			return option["spell_id"]

	return weighted_options[weighted_options.size() - 1]["spell_id"]
