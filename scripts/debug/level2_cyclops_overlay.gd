extends Label

const STATE_NAMES := {
	0: "IDLE",
	1: "PATROL",
	2: "CHASE",
	3: "ATTACK",
	4: "HURT",
	5: "DEAD",
}

@export var refresh_interval: float = 0.1

var _time_until_refresh: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_color_override("font_color", Color(0.96, 0.98, 1.0, 1.0))
	add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	add_theme_constant_override("outline_size", 3)
	visible = true
	_refresh_text()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F8:
		visible = not visible


func _process(delta: float) -> void:
	_time_until_refresh -= delta
	if _time_until_refresh > 0.0:
		return
	_time_until_refresh = refresh_interval
	_refresh_text()


func _refresh_text() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		text = "Level2 debug: no scene"
		return

	var player: Node = scene.get("current_player")
	var enemy: Node = scene.get_node_or_null("World/Entities/Famously")
	if player == null or enemy == null:
		text = "Level2 debug: player or cyclops not found"
		return

	var enemy_current_floor: int = _call_int(enemy, "get_current_combat_floor_id")
	var enemy_effective_floor: int = _call_int(enemy, "get_effective_combat_floor_id")
	var player_current_floor: int = _call_int(player, "get_current_combat_floor_id")
	var player_effective_floor: int = _call_int(player, "get_effective_combat_floor_id")
	var enemy_probe: Vector2 = _call_vec2(enemy, "_get_combat_floor_probe_world_point")
	var player_probe: Vector2 = _call_vec2(player, "_get_combat_floor_probe_world_point")

	var floor_delta: int = 999
	var chosen_spell: String = "-"
	var active_spell: String = "-"
	var magic_locked: bool = false
	var spell0_ready: bool = false
	var magic_controller: Variant = enemy.get("magic_controller")
	if magic_controller != null:
		var planar_distance: float = (enemy as Node2D).global_position.distance_to((player as Node2D).global_position)
		var retreat_cast_distance: float = float(enemy.get("retreat_cast_distance"))
		floor_delta = int(magic_controller.call("get_floor_delta_to_target", player))
		chosen_spell = str(magic_controller.call("choose_spell_for_target", player, planar_distance, retreat_cast_distance))
		active_spell = str(magic_controller.call("get_active_spell_id"))
		magic_locked = bool(magic_controller.call("is_magic_locked"))
		spell0_ready = bool(magic_controller.call("can_begin_spell0", player, planar_distance, retreat_cast_distance))

	var detect: bool = false
	if enemy.has_method("_can_detect_player_before_engage"):
		detect = bool(enemy.call("_can_detect_player_before_engage", player))

	var previous_target: Variant = enemy.get("target")
	var can_melee: bool = false
	var same_lane: bool = false
	if enemy.has_method("_is_same_combat_lane"):
		same_lane = bool(enemy.call("_is_same_combat_lane", player))
	if enemy.has_method("_can_melee_attack_target"):
		enemy.set("target", player)
		can_melee = bool(enemy.call("_can_melee_attack_target"))
		enemy.set("target", previous_target)

	var state_name: String = String(STATE_NAMES.get(int(enemy.get("current_state")), "UNKNOWN"))
	text = "\n".join([
		"F8: hide/show cyclops debug",
		"Enemy floor cur/eff: %d / %d" % [enemy_current_floor, enemy_effective_floor],
		"Player floor cur/eff: %d / %d" % [player_current_floor, player_effective_floor],
		"Floor delta: %d" % floor_delta,
		"Detect: %s   Melee: %s   Same lane: %s" % [str(detect), str(can_melee), str(same_lane)],
		"Chosen spell: %s   Active spell: %s" % [chosen_spell, active_spell],
		"Spell0 ready: %s   Magic locked: %s" % [str(spell0_ready), str(magic_locked)],
		"State: %s   Engaged: %s" % [state_name, str(bool(enemy.get("has_engaged_player")))],
		"Enemy pos/probe: %s / %s" % [str((enemy as Node2D).global_position.round()), str(enemy_probe.round())],
		"Player pos/probe: %s / %s" % [str((player as Node2D).global_position.round()), str(player_probe.round())],
	])


func _call_int(node: Node, method_name: String) -> int:
	if node == null or not node.has_method(method_name):
		return -1
	return int(node.call(method_name))


func _call_vec2(node: Node, method_name: String) -> Vector2:
	if node == null or not node.has_method(method_name):
		return Vector2.ZERO
	var result: Variant = node.call(method_name)
	return result if result is Vector2 else Vector2.ZERO
