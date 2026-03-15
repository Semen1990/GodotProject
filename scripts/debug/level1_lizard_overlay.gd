extends Label

const STATE_NAMES := {
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
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F7:
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
		text = "Level1 debug: no scene"
		return

	var player: Node = scene.get("current_player")
	var enemy: Node = scene.get_node_or_null("World/Entities/Lizard")
	if player == null or enemy == null:
		text = "Level1 debug: player or lizard not found"
		return

	var enemy_current_floor: int = _call_int(enemy, "get_current_combat_floor_id")
	var enemy_effective_floor: int = _call_int(enemy, "get_effective_combat_floor_id")
	var player_current_floor: int = _call_int(player, "get_current_combat_floor_id")
	var player_effective_floor: int = _call_int(player, "get_effective_combat_floor_id")
	var enemy_probe: Vector2 = _call_vec2(enemy, "_get_combat_floor_probe_world_point")
	var player_probe: Vector2 = _call_vec2(player, "_get_combat_floor_probe_world_point")

	var detect: bool = false
	if enemy.has_method("_can_detect_player_before_engage"):
		detect = bool(enemy.call("_can_detect_player_before_engage", player))

	var previous_target: Variant = enemy.get("target")
	var can_melee: bool = false
	if enemy.has_method("_can_melee_attack_target"):
		enemy.set("target", player)
		can_melee = bool(enemy.call("_can_melee_attack_target"))
		enemy.set("target", previous_target)

	var same_lane: bool = false
	if enemy.has_method("_is_same_combat_lane"):
		same_lane = bool(enemy.call("_is_same_combat_lane", player))

	var enemy_support_y: float = INF
	var player_support_y: float = INF
	if enemy.has_method("_get_support_surface_y"):
		enemy_support_y = float(enemy.call("_get_support_surface_y", enemy))
		player_support_y = float(enemy.call("_get_support_surface_y", player))

	var enemy_state_name: String = String(STATE_NAMES.get(int(enemy.get("current_state")), "UNKNOWN"))
	var combo_hits_remaining: int = int(enemy.get("combo_hits_remaining"))
	var can_attack: bool = bool(enemy.get("can_attack"))
	var engaged: bool = bool(enemy.get("has_engaged_player"))
	var parry_timer: float = float(enemy.get("parry_timer"))
	var recover_timer: float = float(enemy.get("recover_timer"))
	var retreat_timer: float = float(enemy.get("retreat_timer"))
	var knockdown_timer: float = float(enemy.get("knockdown_timer"))
	var floor_delta: int = -1
	if enemy_effective_floor >= 0 and player_effective_floor >= 0:
		floor_delta = abs(enemy_effective_floor - player_effective_floor)

	text = "\n".join([
		"F7: hide/show lizard debug",
		"Enemy floor cur/eff: %d / %d" % [enemy_current_floor, enemy_effective_floor],
		"Player floor cur/eff: %d / %d" % [player_current_floor, player_effective_floor],
		"Floor delta: %d" % floor_delta,
		"Detect: %s   Melee: %s   Same lane: %s" % [str(detect), str(can_melee), str(same_lane)],
		"State: %s   Engaged: %s   Can attack: %s" % [enemy_state_name, str(engaged), str(can_attack)],
		"Combo left: %d   Parry: %s" % [combo_hits_remaining, _fmt_float(parry_timer)],
		"Recover: %s   Retreat: %s   Knockdown: %s" % [_fmt_float(recover_timer), _fmt_float(retreat_timer), _fmt_float(knockdown_timer)],
		"Enemy support/probe: %s / %s" % [_fmt_float(enemy_support_y), str(enemy_probe.round())],
		"Player support/probe: %s / %s" % [_fmt_float(player_support_y), str(player_probe.round())],
		"Enemy pos: %s" % str((enemy as Node2D).global_position.round()),
		"Player pos: %s" % str((player as Node2D).global_position.round()),
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


func _fmt_float(value: float) -> String:
	if is_inf(value):
		return "inf"
	return "%.2f" % value
