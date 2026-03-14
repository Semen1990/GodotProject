extends SceneTree

const LEVEL1_SCENE := preload("res://scenes/levels/level1.tscn")
const LEVEL2_SCENE := preload("res://scenes/levels/level2.tscn")

const REPORT_PATH := "res://debug_reports/enemy_visibility_probe_report.txt"

var _report_lines: PackedStringArray = []


func _initialize() -> void:
	await _run()
	quit()


func _run() -> void:
	_report("=== ENEMY VISIBILITY PROBE ===")
	await _probe_level1_damage_aggro()
	await _probe_level2_vertical_visibility()
	_write_report()


func _probe_level1_damage_aggro() -> void:
	_report("")
	_report("[LEVEL1] damage -> aggro")

	if Inventory:
		Inventory.clear_all()
	if Global:
		Global.full_reset()
		Global.selected_character = "warrior"

	var level: Node = LEVEL1_SCENE.instantiate()
	root.add_child(level)
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
	root.add_child(level)
	await _wait_frames(160)

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
		if enemy.has_method("_change_state"):
			enemy.call("_change_state", 0)
		await _wait_frames(8)

		var can_detect: bool = enemy.call("_can_detect_player_before_engage", player)
		var has_los: bool = enemy.call("_has_line_of_sight_to", player)
		enemy.set("target", player)
		var can_melee: bool = enemy.call("_can_melee_attack_target")
		enemy.set("target", null)

		_report("%s: player=%s detect=%s los=%s melee=%s enemy_state=%s" % [
			String(scenario["name"]),
			str((scenario["position"] as Vector2).round()),
			str(can_detect),
			str(has_los),
			str(can_melee),
			_famously_state_name(enemy)
		])

	level.queue_free()
	await _wait_frames(5)


func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame


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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://debug_reports"))
	var file: FileAccess = FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write probe report: %s" % REPORT_PATH)
		return
	for line in _report_lines:
		file.store_line(line)
	file.close()
