extends Node

const LEVEL_SCENE := preload("res://scenes/levels/level1.tscn")

const LIZARD_STATE_NAMES := {
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

const WARRIOR_BLOCK_PHASE_NAMES := {
	0: "NONE",
	1: "STARTUP",
	2: "ACTIVE",
	3: "RECOVERY",
}

var current_level: Node = null
var player: Node = null
var lizard: Node = null
var scenario_started_at: float = 0.0
var current_scenario_name: String = ""
var last_player_snapshot: Dictionary = {}
var last_lizard_snapshot: Dictionary = {}
var current_events: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run_probe")


func _run_probe() -> void:
	await _run_all_scenarios()
	get_tree().quit()


func _physics_process(_delta: float) -> void:
	if player == null or lizard == null:
		return
	if not is_instance_valid(player) or not is_instance_valid(lizard):
		return

	_poll_player_snapshot()
	_poll_lizard_snapshot()


func _run_all_scenarios() -> void:
	var reports: Array[Dictionary] = []

	reports.append(await _run_scenario("approach_pressure", _scenario_approach_pressure))
	reports.append(await _run_scenario("block_counter", _scenario_block_counter))
	reports.append(await _run_scenario("parry_window", _scenario_parry_window))
	reports.append(await _run_scenario("slide_cross", _scenario_slide_cross))
	reports.append(await _run_scenario("back_hit_heavy", _scenario_back_hit_heavy))
	reports.append(await _run_scenario("sneak_backstab", _scenario_sneak_backstab))

	print("")
	print("=== DUEL PROBE SUMMARY ===")
	for report in reports:
		_print_report(report)
	print("=== DUEL PROBE END ===")
	_write_report_to_file(reports)


func _run_scenario(name: String, action: Callable) -> Dictionary:
	await _load_fresh_level()
	current_scenario_name = name
	current_events.clear()
	last_player_snapshot.clear()
	last_lizard_snapshot.clear()
	scenario_started_at = Time.get_ticks_msec() / 1000.0

	_log_event("START scenario")
	var report: Dictionary = await action.call()
	report["name"] = name
	report["events"] = current_events.duplicate()
	_log_event("END scenario")
	return report


func _load_fresh_level() -> void:
	_clear_inputs()

	if current_level and is_instance_valid(current_level):
		current_level.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame

	if Inventory:
		Inventory.clear_all()
	if Global:
		Global.full_reset()
		Global.selected_character = "warrior"

	current_level = LEVEL_SCENE.instantiate()
	add_child(current_level)

	for _i in range(120):
		await get_tree().process_frame
		player = current_level.get("current_player")
		lizard = current_level.get_node_or_null("World/Entities/Lizard")
		if player != null and lizard != null:
			break

	if player == null or lizard == null:
		push_error("Level1DuelProbe: failed to resolve player or lizard")
		return

	await get_tree().physics_frame
	await get_tree().physics_frame


func _scenario_approach_pressure() -> Dictionary:
	_place_player_relative_to_lizard(-220.0)
	await _observe_for(4.2)

	return {
		"player_hp": _get_player_health(),
		"lizard_hp": _get_lizard_health(),
		"player_x": snapped(player.global_position.x, 0.1),
		"lizard_x": snapped(lizard.global_position.x, 0.1),
	}


func _scenario_block_counter() -> Dictionary:
	_place_player_relative_to_lizard(-112.0)
	await _observe_for(0.35)

	var attacked: bool = await _wait_for_lizard_state("ATTACK", 2.5)
	if attacked:
		player.use_special_ability()
		_log_event("probe -> warrior.use_special_ability()")
		await _observe_for(0.45)
		if bool(player.get("is_counter_attack_ready")):
			player.attack()
			_log_event("probe -> warrior.attack() counter")
			await _observe_for(1.2)
	else:
		_log_event("probe -> lizard never entered ATTACK in block scenario")

	return {
		"attacked": attacked,
		"counter_ready_end": bool(player.get("is_counter_attack_ready")),
		"player_hp": _get_player_health(),
		"lizard_hp": _get_lizard_health(),
	}


func _scenario_parry_window() -> Dictionary:
	_place_player_relative_to_lizard(-102.0)
	await _observe_for(0.45)

	for attempt in range(4):
		player.attack()
		_log_event("probe -> warrior.attack() parry attempt %d" % (attempt + 1))
		await _observe_for(0.8)

	return {
		"player_hp": _get_player_health(),
		"lizard_hp": _get_lizard_health(),
		"lizard_state_end": _lizard_state_name(),
		"lizard_anim_end": _get_lizard_animation(),
	}


func _scenario_slide_cross() -> Dictionary:
	_place_player_relative_to_lizard(-96.0)
	await _observe_for(0.25)
	player.slide()
	_log_event("probe -> warrior.slide()")
	await _observe_for(1.1)

	var crossed: bool = player.global_position.x > lizard.global_position.x + 12.0
	return {
		"crossed_lizard": crossed,
		"player_x": snapped(player.global_position.x, 0.1),
		"lizard_x": snapped(lizard.global_position.x, 0.1),
		"distance": snapped(player.global_position.distance_to(lizard.global_position), 0.1),
	}


func _scenario_back_hit_heavy() -> Dictionary:
	_place_player_relative_to_lizard(96.0)
	var animated_sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D")
	if animated_sprite:
		animated_sprite.flip_h = false
	_log_event("probe -> force warrior facing right for back-hit check")
	var player_start_x: float = player.global_position.x
	await _observe_for(2.2)

	return {
		"player_hp": _get_player_health(),
		"player_x": snapped(player.global_position.x, 0.1),
		"player_start_x": snapped(player_start_x, 0.1),
		"player_knockback_delta": snapped(player.global_position.x - player_start_x, 0.1),
		"lizard_x": snapped(lizard.global_position.x, 0.1),
	}


func _scenario_sneak_backstab() -> Dictionary:
	_place_player_relative_to_lizard(-70.0)
	Input.action_press("sneak_toggle")
	Input.action_release("sneak_toggle")
	await get_tree().physics_frame
	Input.action_press("move_right")
	_log_event("probe -> toggle sneak + move_right")
	await _observe_for(0.42)
	Input.action_release("move_right")
	player.attack()
	_log_event("probe -> warrior.attack() from sneak")
	await _observe_for(1.5)

	return {
		"lizard_state_end": _lizard_state_name(),
		"lizard_hp": _get_lizard_health(),
		"player_hp": _get_player_health(),
		"lizard_anim": _get_lizard_animation(),
	}


func _observe_for(duration: float) -> void:
	var elapsed: float = 0.0
	while elapsed < duration:
		await get_tree().physics_frame
		elapsed += 1.0 / maxf(Engine.physics_ticks_per_second, 1.0)


func _wait_for_lizard_state(state_name: String, timeout: float) -> bool:
	var elapsed: float = 0.0
	while elapsed < timeout:
		await get_tree().physics_frame
		if _lizard_state_name() == state_name:
			return true
		elapsed += 1.0 / maxf(Engine.physics_ticks_per_second, 1.0)
	return false


func _place_player_relative_to_lizard(offset_x: float) -> void:
	if player == null or lizard == null:
		return

	_clear_inputs()
	player.velocity = Vector2.ZERO
	player.global_position = Vector2(
		lizard.global_position.x + offset_x,
		player.global_position.y
	)

	var animated_sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D")
	if animated_sprite:
		animated_sprite.flip_h = offset_x > 0.0

	_log_event("probe -> place player at x offset %.1f" % offset_x)


func _clear_inputs() -> void:
	for action in ["move_left", "move_right", "crouch", "jump", "attack", "special_ability", "slide", "sneak_toggle"]:
		Input.action_release(action)


func _poll_player_snapshot() -> void:
	var snapshot: Dictionary = {
		"hp": _get_player_health(),
		"is_sliding": bool(player.get("is_sliding")),
		"slide_iframe": bool(player.get("slide_iframe_active")),
		"is_sneaking": bool(player.get("is_sneaking")),
		"is_attacking": bool(player.get("is_attacking")),
		"is_hurt": bool(player.get("is_hurt")),
		"block_phase": WARRIOR_BLOCK_PHASE_NAMES.get(int(player.get("block_phase")), str(player.get("block_phase"))),
		"counter_ready": bool(player.get("is_counter_attack_ready")),
		"x": snapped(player.global_position.x, 0.1),
	}

	if last_player_snapshot.is_empty():
		last_player_snapshot = snapshot
		_log_event("player init %s" % JSON.stringify(snapshot))
		return

	for key in snapshot.keys():
		if last_player_snapshot.get(key) != snapshot[key]:
			_log_event("player %s: %s -> %s" % [key, str(last_player_snapshot.get(key)), str(snapshot[key])])

	last_player_snapshot = snapshot


func _poll_lizard_snapshot() -> void:
	var parry_timer_value: Variant = lizard.get("parry_timer")
	var recover_timer_value: Variant = lizard.get("recover_timer")
	var retreat_timer_value: Variant = lizard.get("retreat_timer")
	var knockdown_timer_value: Variant = lizard.get("knockdown_timer")

	var snapshot: Dictionary = {
		"hp": _get_lizard_health(),
		"state": _lizard_state_name(),
		"anim": _get_lizard_animation(),
		"can_attack": bool(lizard.get("can_attack")),
		"combo": int(lizard.get("combo_hits_remaining")),
		"parry_timer": snapped(_variant_to_float(parry_timer_value), 0.01),
		"recover_timer": snapped(_variant_to_float(recover_timer_value), 0.01),
		"retreat_timer": snapped(_variant_to_float(retreat_timer_value), 0.01),
		"knockdown_timer": snapped(_variant_to_float(knockdown_timer_value), 0.01),
		"x": snapped(lizard.global_position.x, 0.1),
		"vx": snapped(lizard.velocity.x, 0.1),
	}

	if last_lizard_snapshot.is_empty():
		last_lizard_snapshot = snapshot
		_log_event("lizard init %s" % JSON.stringify(snapshot))
		return

	for key in snapshot.keys():
		if last_lizard_snapshot.get(key) != snapshot[key]:
			_log_event("lizard %s: %s -> %s" % [key, str(last_lizard_snapshot.get(key)), str(snapshot[key])])

	last_lizard_snapshot = snapshot


func _variant_to_float(value: Variant) -> float:
	match typeof(value):
		TYPE_FLOAT:
			return value
		TYPE_INT:
			return float(value)
		_:
			return 0.0


func _lizard_state_name() -> String:
	return LIZARD_STATE_NAMES.get(int(lizard.get("current_state")), str(lizard.get("current_state")))


func _get_lizard_animation() -> String:
	var sprite: AnimatedSprite2D = lizard.get_node_or_null("AnimatedSprite2D")
	return sprite.animation if sprite else ""


func _get_player_health() -> int:
	return int(player.get("current_health"))


func _get_lizard_health() -> int:
	return int(lizard.get("current_health"))


func _log_event(message: String) -> void:
	var timestamp: float = (Time.get_ticks_msec() / 1000.0) - scenario_started_at
	var line: String = "[%s][%05.2f] %s" % [current_scenario_name, timestamp, message]
	current_events.append(line)
	print(line)


func _print_report(report: Dictionary) -> void:
	print("- %s" % report.get("name", "unknown"))
	for key in report.keys():
		if key == "events" or key == "name":
			continue
		print("  %s: %s" % [key, str(report[key])])


func _write_report_to_file(reports: Array[Dictionary]) -> void:
	var lines: PackedStringArray = []
	lines.append("=== DUEL PROBE SUMMARY ===")
	for report in reports:
		lines.append("- %s" % report.get("name", "unknown"))
		for key in report.keys():
			if key == "name":
				continue
			if key == "events":
				lines.append("  events:")
				for event_line in report["events"]:
					lines.append("    %s" % event_line)
				continue
			lines.append("  %s: %s" % [key, str(report[key])])
	lines.append("=== DUEL PROBE END ===")

	var file := FileAccess.open("user://duel_probe_report.txt", FileAccess.WRITE)
	if file:
		for line in lines:
			file.store_line(line)
		file.close()
