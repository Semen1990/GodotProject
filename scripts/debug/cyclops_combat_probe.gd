extends Node

const LEVEL2_SCENE := preload("res://scenes/levels/level2.tscn")
const REPORT_PATH := "user://cyclops_combat_probe_report.txt"

var _lines: PackedStringArray = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")


func _run() -> void:
	if Inventory:
		Inventory.clear_all()
	if Global:
		Global.full_reset()
		Global.selected_character = "warrior"

	await _probe_same_floor_close()
	await _probe_one_floor_below()
	_write_report()
	get_tree().quit()


func _probe_same_floor_close() -> void:
	_report("[same_floor_close]")
	var level: Node = LEVEL2_SCENE.instantiate()
	add_child(level)
	await _wait_frames(180)

	var player: Node2D = level.get("current_player")
	var enemy: Node2D = level.get_node_or_null("World/Entities/Famously")
	if player == null or enemy == null:
		_report("failed to resolve player or enemy")
		level.queue_free()
		await _wait_frames(5)
		return

	player.global_position = Vector2(enemy.global_position.x - 96.0, 780.0)
	player.set("velocity", Vector2.ZERO)
	await _wait_frames(4)

	for step in range(12):
		await _wait_frames(10)
		_log_step("same_floor", step, enemy, player)

	level.queue_free()
	await _wait_frames(5)


func _probe_one_floor_below() -> void:
	_report("")
	_report("[one_floor_below]")
	var level: Node = LEVEL2_SCENE.instantiate()
	add_child(level)
	await _wait_frames(180)

	var player: Node2D = level.get("current_player")
	var enemy: Node2D = level.get_node_or_null("World/Entities/Famously")
	if player == null or enemy == null:
		_report("failed to resolve player or enemy")
		level.queue_free()
		await _wait_frames(5)
		return

	player.global_position = Vector2(enemy.global_position.x - 64.0, 892.0)
	player.set("velocity", Vector2.ZERO)
	await _wait_frames(4)

	for step in range(12):
		await _wait_frames(10)
		_log_step("one_floor", step, enemy, player)

	level.queue_free()
	await _wait_frames(5)


func _log_step(label: String, step: int, enemy: Node, player: Node) -> void:
	var magic_controller = enemy.get("magic_controller")
	var spell_choice: String = "<none>"
	var floor_delta: int = 999
	var magic_locked: bool = false
	if magic_controller != null:
		floor_delta = int(magic_controller.call("get_floor_delta_to_target", player))
		magic_locked = bool(magic_controller.call("is_magic_locked"))
		spell_choice = str(magic_controller.call(
			"choose_spell_for_target",
			player,
			(enemy as Node2D).global_position.distance_to((player as Node2D).global_position),
			float(enemy.get("retreat_cast_distance"))
		))

	_report("%s step=%d state=%s target=%s engaged=%s enemy_floor=%s player_floor=%s floor_delta=%s can_melee=%s detect=%s spell_choice=%s magic_locked=%s enemy_pos=%s player_pos=%s anim=%s" % [
		label,
		step,
		_state_name(enemy),
		enemy.get("target").name if enemy.get("target") != null and is_instance_valid(enemy.get("target")) else "<null>",
		str(bool(enemy.get("has_engaged_player"))),
		str(int(enemy.call("get_effective_combat_floor_id"))),
		str(int(player.call("get_effective_combat_floor_id"))),
		str(floor_delta),
		str(bool(enemy.call("_can_melee_attack_target")) if enemy.get("target") != null else false),
		str(bool(enemy.call("_can_detect_player_before_engage", player))),
		spell_choice,
		str(magic_locked),
		str((enemy as Node2D).global_position.round()),
		str((player as Node2D).global_position.round()),
		String(enemy.get_node("AnimatedSprite2D").animation)
	])


func _state_name(enemy: Node) -> String:
	var names := {
		0: "IDLE",
		1: "PATROL",
		2: "CHASE",
		3: "ATTACK",
		4: "HURT",
		5: "DEAD",
	}
	return String(names.get(int(enemy.get("current_state")), "UNKNOWN"))


func _wait_frames(count: int) -> void:
	for _i in range(count):
		await get_tree().process_frame


func _report(line: String) -> void:
	_lines.append(line)
	print(line)


func _write_report() -> void:
	var file: FileAccess = FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write cyclops probe report: %s" % REPORT_PATH)
		return
	for line in _lines:
		file.store_line(line)
	file.close()
