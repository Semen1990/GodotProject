extends Node

const LEVEL1_SCENE := preload("res://scenes/levels/level1.tscn")
const LEVEL2_SCENE := preload("res://scenes/levels/level2.tscn")
const REPORT_PATH := "user://enemy_visibility_probe_report.txt"

var _report_lines: PackedStringArray = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")


func _run() -> void:
	await _probe_level1_damage_aggro()
	await _probe_level1_attack_loop()
	await _probe_level1_damage_exchange()
	await _probe_level2_vertical_visibility()
	await _probe_level2_spawn_to_under_enemy()
	_write_report()
	get_tree().quit()


func _probe_level1_damage_aggro() -> void:
	_report("=== ENEMY VISIBILITY PROBE ===")
	_report("")
	_report("[LEVEL1] same-level detection")

	if Inventory:
		Inventory.clear_all()
	if Global:
		Global.full_reset()
		Global.selected_character = "warrior"

	var detect_level: Node = LEVEL1_SCENE.instantiate()
	add_child(detect_level)
	await _wait_frames(120)

	var detect_player: Node2D = detect_level.get("current_player")
	var detect_lizard: Node2D = detect_level.get_node_or_null("World/Entities/Lizard")
	if detect_player == null or detect_lizard == null:
		_report("failed to resolve player or lizard for detection probe")
	else:
		detect_player.global_position = detect_lizard.global_position + Vector2(-72.0, 0.0)
		detect_player.set("velocity", Vector2.ZERO)
		await _wait_frames(20)
		_report("same-level near: detect=%s los=%s same_lane=%s use_lane=%s dy=%.1f state=%s engaged=%s" % [
			str(detect_lizard.call("_can_detect_player_before_engage", detect_player)),
			str(detect_lizard.call("_has_line_of_sight_to", detect_player)),
			str(detect_lizard.call("_is_same_combat_lane", detect_player)),
			str(bool(detect_lizard.get("use_combat_lane_before_engage"))),
			absf(detect_player.global_position.y - detect_lizard.global_position.y),
			_lizard_state_name(detect_lizard),
			str(bool(detect_lizard.get("has_engaged_player")))
		])

	detect_level.queue_free()
	await _wait_frames(5)

	_report("")
	_report("[LEVEL1] damage -> aggro")

	if Inventory:
		Inventory.clear_all()
	if Global:
		Global.full_reset()
		Global.selected_character = "warrior"

	var level: Node = LEVEL1_SCENE.instantiate()
	add_child(level)
	await _wait_frames(120)

	var player: Node2D = level.get("current_player")
	var lizard: Node2D = level.get_node_or_null("World/Entities/Lizard")
	if player == null or lizard == null:
		_report("failed to resolve player or lizard")
		level.queue_free()
		return

	_report("initial: state=%s engaged=%s target=%s" % [
		_lizard_state_name(lizard),
		str(bool(lizard.get("has_engaged_player"))),
		str(lizard.get("target"))
	])

	lizard.call("take_damage", 1, "physical")
	await _wait_frames(20)

	_report("after damage: state=%s engaged=%s target_valid=%s" % [
		_lizard_state_name(lizard),
		str(bool(lizard.get("has_engaged_player"))),
		str(is_instance_valid(lizard.get("target")))
	])

	await _wait_frames(80)
	_report("after settle: state=%s engaged=%s target_valid=%s" % [
		_lizard_state_name(lizard),
		str(bool(lizard.get("has_engaged_player"))),
		str(is_instance_valid(lizard.get("target")))
	])

	level.queue_free()
	await _wait_frames(5)


func _probe_level2_vertical_visibility() -> void:
	_report("")
	_report("[LEVEL2] vertical visibility / melee")

	if Inventory:
		Inventory.clear_all()
	if Global:
		Global.full_reset()
		Global.selected_character = "warrior"

	var level: Node = LEVEL2_SCENE.instantiate()
	add_child(level)
	await _wait_frames(180)

	var player: Node2D = level.get("current_player")
	var enemy: Node2D = level.get_node_or_null("World/Entities/Famously")
	if player == null or enemy == null:
		_report("failed to resolve player or famously")
		level.queue_free()
		return

	var enemy_pos: Vector2 = enemy.global_position
	var scenarios: Array[Dictionary] = [
		{"name": "same_level_left", "position": enemy_pos + Vector2(-140.0, 0.0)},
		{"name": "same_x_below", "position": enemy_pos + Vector2(0.0, 140.0)},
		{"name": "same_x_above", "position": enemy_pos + Vector2(0.0, -140.0)},
		{"name": "offset_below_left", "position": enemy_pos + Vector2(-80.0, 140.0)},
		{"name": "offset_above_left", "position": enemy_pos + Vector2(-80.0, -140.0)},
	]

	for scenario in scenarios:
		player.global_position = scenario["position"]
		player.set("velocity", Vector2.ZERO)
		enemy.set("target", null)
		enemy.set("has_engaged_player", false)
		enemy.set("can_attack", true)
		if enemy.has_method("_change_state"):
			enemy.call("_change_state", 0)
		await _wait_frames(8)

		var can_detect: bool = enemy.call("_can_detect_player_before_engage", player)
		var has_los: bool = enemy.call("_has_line_of_sight_to", player)
		var same_lane: bool = enemy.call("_is_same_combat_lane", player)
		var enemy_support_y: float = enemy.call("_get_support_surface_y", enemy)
		var player_support_y: float = enemy.call("_get_support_surface_y", player)
		enemy.set("target", player)
		var can_melee: bool = enemy.call("_can_melee_attack_target")
		enemy.set("target", null)

		_report("%s: player=%s detect=%s los=%s same_lane=%s melee=%s support=(%.1f/%.1f) state=%s" % [
			String(scenario["name"]),
			str((scenario["position"] as Vector2).round()),
			str(can_detect),
			str(has_los),
			str(same_lane),
			str(can_melee),
			enemy_support_y,
			player_support_y,
			_famously_state_name(enemy)
		])

	level.queue_free()
	await _wait_frames(5)


func _probe_level2_spawn_to_under_enemy() -> void:
	_report("")
	_report("[LEVEL2] spawn -> under enemy path")

	if Inventory:
		Inventory.clear_all()
	if Global:
		Global.full_reset()
		Global.selected_character = "warrior"

	var level: Node = LEVEL2_SCENE.instantiate()
	add_child(level)
	await _wait_frames(180)

	var player: Node2D = level.get("current_player")
	var enemy: Node2D = level.get_node_or_null("World/Entities/Famously")
	if player == null or enemy == null:
		_report("failed to resolve player or famously for path probe")
		level.queue_free()
		return

	var checkpoints: Array[Dictionary] = [
		{"name": "spawn", "position": player.global_position},
		{"name": "approach_mid", "position": Vector2(420.0, player.global_position.y)},
		{"name": "approach_near", "position": Vector2(650.0, player.global_position.y)},
		{"name": "under_enemy_same_floor", "position": Vector2(enemy.global_position.x, player.global_position.y)},
	]

	for checkpoint in checkpoints:
		player.global_position = checkpoint["position"]
		player.set("velocity", Vector2.ZERO)
		await _wait_frames(12)

		var vertical_diff: float = absf(player.global_position.y - enemy.global_position.y)
		var horizontal_diff: float = absf(player.global_position.x - enemy.global_position.x)
		var can_detect: bool = enemy.call("_can_detect_player_before_engage", player)
		var has_los: bool = enemy.call("_has_line_of_sight_to", player)
		var same_lane: bool = enemy.call("_is_same_combat_lane", player)
		var enemy_support_y: float = enemy.call("_get_support_surface_y", enemy)
		var player_support_y: float = enemy.call("_get_support_surface_y", player)
		var enemy_grounded: bool = bool(enemy.call("is_on_floor"))
		var player_grounded: bool = bool(player.call("is_on_floor"))
		var lane_tolerance: float = float(enemy.get("combat_lane_tolerance"))
		enemy.set("target", player)
		var can_melee: bool = enemy.call("_can_melee_attack_target")
		enemy.set("target", enemy.get("target"))

		_report("%s: player=%s dx=%.1f dy=%.1f detect=%s los=%s same_lane=%s melee=%s support=(%.1f/%.1f) grounded=(%s/%s) lane_tol=%.1f state=%s engaged=%s" % [
			String(checkpoint["name"]),
			str((checkpoint["position"] as Vector2).round()),
			horizontal_diff,
			vertical_diff,
			str(can_detect),
			str(has_los),
			str(same_lane),
			str(can_melee),
			enemy_support_y,
			player_support_y,
			str(enemy_grounded),
			str(player_grounded),
			lane_tolerance,
			_famously_state_name(enemy),
			str(bool(enemy.get("has_engaged_player")))
		])

	level.queue_free()
	await _wait_frames(5)


func _probe_level1_attack_loop() -> void:
	_report("")
	_report("[LEVEL1] same-level attack loop")

	if Inventory:
		Inventory.clear_all()
	if Global:
		Global.full_reset()
		Global.selected_character = "warrior"

	var level: Node = LEVEL1_SCENE.instantiate()
	add_child(level)
	await _wait_frames(120)

	var player: Node2D = level.get("current_player")
	var lizard: Node2D = level.get_node_or_null("World/Entities/Lizard")
	if player == null or lizard == null:
		_report("failed to resolve player or lizard for attack loop")
		level.queue_free()
		return

	player.global_position = lizard.global_position + Vector2(-86.0, 0.0)
	player.set("velocity", Vector2.ZERO)
	lizard.call("force_alert", player)
	await _wait_frames(10)

	for step in range(8):
		await _wait_frames(20)
		lizard.set("target", player)
		var can_melee: bool = lizard.call("_can_melee_attack_target")
		var same_lane: bool = lizard.call("_is_same_combat_lane", player)
		_report("step_%d: state=%s pos=%s player=%s can_melee=%s same_lane=%s dist=%.1f" % [
			step,
			_lizard_state_name(lizard),
			str((lizard.global_position as Vector2).round()),
			str((player.global_position as Vector2).round()),
			str(can_melee),
			str(same_lane),
			lizard.global_position.distance_to(player.global_position)
		])

	level.queue_free()
	await _wait_frames(5)


func _probe_level1_damage_exchange() -> void:
	_report("")
	_report("[LEVEL1] damage exchange")

	if Inventory:
		Inventory.clear_all()
	if Global:
		Global.full_reset()
		Global.selected_character = "warrior"

	var level: Node = LEVEL1_SCENE.instantiate()
	add_child(level)
	await _wait_frames(120)

	var player: Node2D = level.get("current_player")
	var lizard: Node2D = level.get_node_or_null("World/Entities/Lizard")
	if player == null or lizard == null:
		_report("failed to resolve player or lizard for damage exchange")
		level.queue_free()
		return

	player.global_position = lizard.global_position + Vector2(-54.0, 0.0)
	player.set("velocity", Vector2.ZERO)
	var warrior_hits: Array[String] = _collect_warrior_attack_hits(player)
	if player.has_method("handle_attack"):
		player.call("handle_attack")
	await _wait_frames(40)
	_report("warrior_attack: player_hp=%s lizard_hp=%s lizard_state=%s hits=%s" % [
		str(player.get("current_health")),
		str(lizard.get("current_health")),
		_lizard_state_name(lizard),
		str(warrior_hits)
	])
	var response_min_hp: int = int(player.get("current_health"))
	var response_states: Array[String] = []
	var response_damage_debug: String = ""
	for _frame in range(180):
		await _wait_frames(1)
		var frame_hp: int = int(player.get("current_health"))
		response_min_hp = mini(response_min_hp, frame_hp)
		var state_name: String = _lizard_state_name(lizard)
		if response_states.is_empty() or response_states.back() != state_name:
			response_states.append(state_name)
		var damage_debug: Dictionary = lizard.get("last_damage_attempt_info")
		if not damage_debug.is_empty() and response_damage_debug.is_empty():
			response_damage_debug = str(damage_debug)
	_report("warrior_attack_response: final_player_hp=%s min_player_hp=%s lizard_state=%s states=%s damage_debug=%s" % [
		str(player.get("current_health")),
		str(response_min_hp),
		_lizard_state_name(lizard),
		str(response_states),
		response_damage_debug
	])

	player.set("current_health", player.get("max_health"))
	lizard.set("current_health", lizard.get("max_health"))
	lizard.emit_signal("health_changed", lizard.get("current_health"))
	lizard.set("parry_cooldown", 999.0)
	lizard.set("target", null)
	lizard.set("has_engaged_player", false)
	if lizard.has_method("_change_state"):
		lizard.call("_change_state", 1)
	player.global_position = lizard.global_position + Vector2(-48.0, 0.0)
	player.set("velocity", Vector2.ZERO)
	if player.has_method("_deal_damage_to_enemies"):
		player.call("_deal_damage_to_enemies")
	await _wait_frames(3)
	_report("warrior_direct_damage: player_hp=%s lizard_hp=%s lizard_state=%s" % [
		str(player.get("current_health")),
		str(lizard.get("current_health")),
		_lizard_state_name(lizard)
	])

	player.set("current_health", player.get("max_health"))
	lizard.set("current_health", lizard.get("max_health"))
	lizard.emit_signal("health_changed", lizard.get("current_health"))
	if player.has_method("update_ui"):
		player.call("update_ui")
	player.global_position = lizard.global_position + Vector2(-86.0, 0.0)
	player.set("velocity", Vector2.ZERO)
	lizard.call("force_alert", player)
	lizard.set("last_damage_attempt_info", {})
	await _wait_frames(5)
	var lizard_direct_damage_result = lizard.call("_deal_damage")
	await _wait_frames(3)
	_report("lizard_direct_damage: player_hp=%s lizard_hp=%s lizard_state=%s applied=%s debug=%s" % [
		str(player.get("current_health")),
		str(lizard.get("current_health")),
		_lizard_state_name(lizard),
		str(lizard_direct_damage_result),
		str(lizard.get("last_damage_attempt_info"))
	])

	player.set("current_health", player.get("max_health"))
	lizard.set("current_health", lizard.get("max_health"))
	lizard.emit_signal("health_changed", lizard.get("current_health"))
	if player.has_method("update_ui"):
		player.call("update_ui")
	player.global_position = lizard.global_position + Vector2(-86.0, 0.0)
	player.set("velocity", Vector2.ZERO)
	lizard.call("force_alert", player)
	lizard.set("last_damage_attempt_info", {})
	await _wait_frames(90)
	_report("lizard_attack: player_hp=%s lizard_hp=%s lizard_state=%s debug=%s" % [
		str(player.get("current_health")),
		str(lizard.get("current_health")),
		_lizard_state_name(lizard),
		str(lizard.get("last_damage_attempt_info"))
	])

	level.queue_free()
	await _wait_frames(5)


func _wait_frames(count: int) -> void:
	for _i in range(count):
		await get_tree().process_frame


func _collect_warrior_attack_hits(player: Node2D) -> Array[String]:
	var hits: Array[String] = []
	if player == null or not is_instance_valid(player):
		return hits

	var attack_range: float = 60.0
	var attack_dir: float = 1.0
	if player.has_method("get_facing_direction"):
		attack_dir = float(player.call("get_facing_direction"))
	var center: Vector2 = player.global_position + Vector2(attack_range * 0.72 * attack_dir, 0.0)
	var shape := CircleShape2D.new()
	shape.radius = attack_range
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, center)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.collision_mask = 4
	query.exclude = [player.get_rid()]

	var space_state: PhysicsDirectSpaceState2D = player.get_world_2d().direct_space_state
	for result in space_state.intersect_shape(query):
		var collider: Node = result.get("collider")
		if collider == null:
			continue
		hits.append("%s:%s" % [collider.name, collider.get_class()])
	return hits


func _lizard_state_name(lizard: Node) -> String:
	var names: Dictionary = {
		0: "IDLE",
		1: "PATROL",
		2: "CHASE",
		3: "ATTACK",
		4: "HURT",
		5: "DEAD",
		6: "RETREAT",
		7: "PARRY",
		8: "KNOCKDOWN",
		9: "PRESSURE",
		10: "RECOVER",
	}
	return String(names.get(int(lizard.get("current_state")), "UNKNOWN"))


func _famously_state_name(enemy: Node) -> String:
	var names: Dictionary = {
		0: "IDLE",
		1: "PATROL",
		2: "CHASE",
		3: "ATTACK",
		4: "HURT",
		5: "DEAD",
	}
	return String(names.get(int(enemy.get("current_state")), "UNKNOWN"))


func _report(line: String) -> void:
	_report_lines.append(line)
	print(line)


func _write_report() -> void:
	var file: FileAccess = FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write probe report: %s" % REPORT_PATH)
		return
	for line in _report_lines:
		file.store_line(line)
	file.close()
