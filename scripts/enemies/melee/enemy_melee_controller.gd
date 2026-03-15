extends RefCounted
class_name EnemyMeleeController

var owner: Node2D
var profile: EnemyMeleeProfile


func setup(owner_node: Node2D, melee_profile: EnemyMeleeProfile) -> EnemyMeleeController:
	owner = owner_node
	profile = melee_profile
	return self


func can_detect_player_before_engage(player_body: Node2D) -> Dictionary:
	if player_body == null or not is_instance_valid(player_body):
		return {"result": false, "reason": "invalid_target", "data": {}}

	if _uses_explicit_combat_floors(player_body):
		if not is_on_same_combat_floor(player_body):
			return {
				"result": false,
				"reason": "floor_mismatch",
				"data": {
					"enemy_floor": _get_owner_effective_floor_id(),
					"target_floor": _get_node_effective_floor_id(player_body),
				},
			}
	elif profile.use_combat_lane_before_engage:
		var same_lane: bool = is_same_combat_lane(player_body)
		if not same_lane:
			return {
				"result": false,
				"reason": "lane_mismatch",
				"data": {"same_lane": same_lane},
			}
	elif absf(player_body.global_position.y - owner.global_position.y) > profile.pre_engage_vertical_tolerance:
		return {
			"result": false,
			"reason": "vertical_mismatch",
			"data": {"dy": absf(player_body.global_position.y - owner.global_position.y)},
		}

	if not profile.require_line_of_sight_before_engage:
		return {"result": true, "reason": "ok_no_los", "data": {}}

	var has_los: bool = has_line_of_sight_to(player_body)
	return {
		"result": has_los,
		"reason": "ok" if has_los else "los_blocked",
		"data": {},
	}


func can_melee_attack_target(target_node: Node2D) -> Dictionary:
	if target_node == null or not is_instance_valid(target_node):
		return {"result": false, "reason": "invalid_target", "data": {}}
	if target_node.get("is_dead") == true:
		return {"result": false, "reason": "target_dead", "data": {}}

	if _uses_explicit_combat_floors(target_node):
		if not is_on_same_combat_floor(target_node):
			return {
				"result": false,
				"reason": "floor_mismatch",
				"data": {
					"enemy_floor": _get_owner_effective_floor_id(),
					"target_floor": _get_node_effective_floor_id(target_node),
				},
			}
	elif profile.use_combat_lane_for_melee:
		var same_lane: bool = is_same_combat_lane(target_node)
		if not same_lane:
			return {
				"result": false,
				"reason": "lane_mismatch",
				"data": {"same_lane": same_lane},
			}
	elif absf(target_node.global_position.y - owner.global_position.y) > profile.melee_vertical_tolerance:
		return {
			"result": false,
			"reason": "vertical_mismatch",
			"data": {"dy": absf(target_node.global_position.y - owner.global_position.y)},
		}

	if not profile.require_line_of_sight_for_melee:
		return {"result": true, "reason": "ok_no_los", "data": {}}

	var has_los: bool = has_line_of_sight_to(target_node)
	return {
		"result": has_los,
		"reason": "ok" if has_los else "los_blocked",
		"data": {},
	}


func is_target_in_pressure_lane(target_node: Node2D) -> bool:
	if target_node == null or not is_instance_valid(target_node):
		return false
	if _uses_explicit_combat_floors(target_node):
		return is_on_same_combat_floor(target_node)
	if profile.use_combat_lane_for_melee:
		return is_same_combat_lane(target_node)
	return absf(target_node.global_position.y - owner.global_position.y) <= profile.melee_vertical_tolerance


func can_confirm_committed_melee_hit(target_node: Node2D) -> bool:
	if target_node == null or not is_instance_valid(target_node):
		return false
	if target_node.get("is_dead") == true:
		return false
	if _uses_explicit_combat_floors(target_node):
		return is_on_same_combat_floor(target_node)
	if profile.use_combat_lane_for_melee:
		return is_same_combat_lane(target_node)
	return absf(target_node.global_position.y - owner.global_position.y) <= profile.melee_vertical_tolerance


func is_on_same_combat_floor(target_node: Node) -> bool:
	if target_node == null or not is_instance_valid(target_node):
		return false
	var owner_floor: int = _get_owner_comparable_floor_id()
	var target_floor: int = _get_node_comparable_floor_id(target_node)
	return owner_floor != -1 and owner_floor == target_floor


func is_same_combat_lane(target_node: Node2D) -> bool:
	if target_node == null or not is_instance_valid(target_node):
		return false

	var own_support_y: float = get_support_surface_y(owner)
	var target_support_y: float = get_support_surface_y(target_node)
	if is_inf(own_support_y) or is_inf(target_support_y):
		if _is_node_grounded(owner) and _is_node_grounded(target_node):
			return absf(target_node.global_position.y - owner.global_position.y) <= profile.combat_lane_tolerance
		return false

	return absf(own_support_y - target_support_y) <= profile.combat_lane_tolerance


func has_line_of_sight_to(target_node: Node2D) -> bool:
	if target_node == null or not is_instance_valid(target_node):
		return false

	var world2d: World2D = owner.get_world_2d()
	if world2d == null:
		return true
	var space_state: PhysicsDirectSpaceState2D = world2d.direct_space_state
	if space_state == null:
		return true

	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		get_line_of_sight_origin(),
		get_line_of_sight_target_position(target_node),
		profile.line_of_sight_collision_mask
	)
	query.exclude = _build_line_of_sight_exclusions(target_node)
	query.collide_with_areas = false
	query.hit_from_inside = false

	var hit: Dictionary = space_state.intersect_ray(query)
	return hit.is_empty()


func get_line_of_sight_origin() -> Vector2:
	return owner.global_position + Vector2(0.0, profile.line_of_sight_height_offset)


func get_line_of_sight_target_position(target_node: Node2D) -> Vector2:
	return target_node.global_position + Vector2(0.0, profile.line_of_sight_height_offset)


func get_support_surface_y(node: Node2D) -> float:
	var world2d: World2D = owner.get_world_2d()
	if world2d == null:
		return INF
	var space_state: PhysicsDirectSpaceState2D = world2d.direct_space_state
	if space_state == null:
		return INF

	var half_height: float = _estimate_body_half_height(node)
	var half_width: float = _estimate_body_half_width(node)
	var base_origin: Vector2 = node.global_position + Vector2(0.0, -half_height + profile.combat_lane_probe_offset_y)
	var best_hit_y: float = INF
	var offsets: Array[float] = [0.0, -half_width * 0.45, half_width * 0.45]

	for offset_x in offsets:
		var origin: Vector2 = base_origin + Vector2(offset_x, 0.0)
		var target_position: Vector2 = origin + Vector2(0.0, profile.combat_lane_probe_depth + half_height)
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
			origin,
			target_position,
			profile.line_of_sight_collision_mask
		)
		query.exclude = _build_lane_probe_exclusions(node)
		query.collide_with_areas = false
		query.hit_from_inside = true

		var hit: Dictionary = space_state.intersect_ray(query)
		if hit.is_empty():
			continue

		var hit_position = hit.get("position", Vector2.ZERO)
		if hit_position is Vector2:
			var support_y: float = (hit_position as Vector2).y
			if support_y < node.global_position.y - 8.0:
				continue
			best_hit_y = minf(best_hit_y, support_y)

	return best_hit_y


func _uses_explicit_combat_floors(target_node: Node) -> bool:
	if not profile.prefer_explicit_combat_floors:
		return false
	return _get_owner_comparable_floor_id() != -1 and _get_node_comparable_floor_id(target_node) != -1


func _get_owner_current_floor_id() -> int:
	return _call_floor_method(owner, "get_current_combat_floor_id")


func _get_owner_effective_floor_id() -> int:
	return _call_floor_method(owner, "get_effective_combat_floor_id")


func _get_owner_comparable_floor_id() -> int:
	var current_floor: int = _get_owner_current_floor_id()
	if current_floor != -1:
		return current_floor
	return _get_owner_effective_floor_id()


func _get_node_effective_floor_id(node: Node) -> int:
	return _call_floor_method(node, "get_effective_combat_floor_id")


func _get_node_comparable_floor_id(node: Node) -> int:
	var current_floor: int = _call_floor_method(node, "get_current_combat_floor_id")
	if current_floor != -1:
		return current_floor
	return _call_floor_method(node, "get_effective_combat_floor_id")


func _call_floor_method(node: Node, method_name: String) -> int:
	if node == null or not is_instance_valid(node):
		return -1
	if not node.has_method(method_name):
		return -1
	return int(node.call(method_name))


func _build_line_of_sight_exclusions(target_node: Node2D) -> Array:
	var exclusions: Array = []
	if owner is CollisionObject2D:
		exclusions.append((owner as CollisionObject2D).get_rid())
	if target_node is CollisionObject2D:
		exclusions.append((target_node as CollisionObject2D).get_rid())
	return exclusions


func _build_lane_probe_exclusions(node: Node) -> Array:
	var exclusions: Array = []
	if owner is CollisionObject2D:
		exclusions.append((owner as CollisionObject2D).get_rid())
	if node is CollisionObject2D and node != owner:
		exclusions.append((node as CollisionObject2D).get_rid())
	return exclusions


func _estimate_body_half_height(node: Node2D) -> float:
	var shape_node: CollisionShape2D = node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or shape_node.shape == null:
		return 24.0

	if shape_node.shape is RectangleShape2D:
		return (shape_node.shape as RectangleShape2D).size.y * 0.5
	if shape_node.shape is CapsuleShape2D:
		var capsule: CapsuleShape2D = shape_node.shape as CapsuleShape2D
		return capsule.height * 0.5 + capsule.radius
	if shape_node.shape is CircleShape2D:
		return (shape_node.shape as CircleShape2D).radius

	return 24.0


func _estimate_body_half_width(node: Node2D) -> float:
	var shape_node: CollisionShape2D = node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or shape_node.shape == null:
		return 14.0

	if shape_node.shape is RectangleShape2D:
		return (shape_node.shape as RectangleShape2D).size.x * 0.5
	if shape_node.shape is CapsuleShape2D:
		return (shape_node.shape as CapsuleShape2D).radius
	if shape_node.shape is CircleShape2D:
		return (shape_node.shape as CircleShape2D).radius

	return 14.0


func _is_node_grounded(node: Node) -> bool:
	if node == null or not node.has_method("is_on_floor"):
		return false
	return bool(node.call("is_on_floor"))
