extends SceneTree

const LEVEL1_SCENE := preload("res://scenes/levels/level1.tscn")
const REPORT_PATH := "user://combat_damage_probe.txt"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
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
		_write_lines(["probe_failed: missing player or lizard"])
		quit()
		return

	var lines: PackedStringArray = []
	player.global_position = lizard.global_position + Vector2(-54.0, 0.0)
	player.set("velocity", Vector2.ZERO)
	lines.append("warrior_before: player_hp=%s lizard_hp=%s" % [str(player.get("current_health")), str(lizard.get("current_health"))])
	player.call("handle_attack")
	await _wait_frames(45)
	lines.append("warrior_after: player_hp=%s lizard_hp=%s attacking=%s" % [
		str(player.get("current_health")),
		str(lizard.get("current_health")),
		str(bool(player.get("is_attacking")))
	])

	player.set("current_health", player.get("max_health"))
	lizard.set("current_health", lizard.get("max_health"))
	lizard.emit_signal("health_changed", lizard.get("current_health"))
	player.global_position = lizard.global_position + Vector2(-86.0, 0.0)
	player.set("velocity", Vector2.ZERO)
	lizard.call("force_alert", player)
	lines.append("lizard_before: player_hp=%s lizard_hp=%s state=%s" % [
		str(player.get("current_health")),
		str(lizard.get("current_health")),
		str(lizard.get("current_state"))
	])
	await _wait_frames(90)
	lines.append("lizard_after: player_hp=%s lizard_hp=%s state=%s" % [
		str(player.get("current_health")),
		str(lizard.get("current_health")),
		str(lizard.get("current_state"))
	])
	_write_lines(lines)

	quit()


func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _write_lines(lines: PackedStringArray) -> void:
	var file: FileAccess = FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		return
	for line in lines:
		file.store_line(line)
	file.close()
