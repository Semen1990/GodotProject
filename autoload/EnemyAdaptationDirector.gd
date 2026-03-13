extends Node

signal adaptation_changed(summary: Dictionary)

const RULES_PATH := "res://data/adaptation_rules.json"
const DEBUG_LOGGING := false

var adaptation_rules: Dictionary = {}
var current_room_id: String = ""
var current_summary: Dictionary = {}


func _ready() -> void:
	_load_rules()
	_connect_telemetry()
	reset_run()


func reset_run() -> void:
	current_room_id = ""
	current_summary = {
		"room_id": "",
		"new_room_count": 0,
		"dominant_style": "",
		"dominant_score": 0.0,
		"active_styles": [],
		"enemy_tags": [],
		"loot_response_bias": {},
	}
	adaptation_changed.emit(get_debug_summary())


func refresh_for_room(room_id: String) -> Dictionary:
	if room_id.is_empty():
		return get_debug_summary()

	current_room_id = room_id
	_rebuild_summary()
	return get_debug_summary()


func get_current_enemy_tags() -> Array[String]:
	var tags: Array[String] = []
	for tag in current_summary.get("enemy_tags", []):
		tags.append(String(tag))
	return tags


func has_enemy_tag(tag_name: String) -> bool:
	return get_current_enemy_tags().has(tag_name)


func get_loot_response_bias() -> Dictionary:
	return current_summary.get("loot_response_bias", {}).duplicate(true)


func get_loot_bias_weight(bias_name: String) -> float:
	return float(current_summary.get("loot_response_bias", {}).get(bias_name, 0.0))


func get_dominant_style() -> String:
	return String(current_summary.get("dominant_style", ""))


func get_dominant_score() -> float:
	return float(current_summary.get("dominant_score", 0.0))


func get_active_style_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for entry in current_summary.get("active_styles", []):
		if entry is Dictionary:
			entries.append((entry as Dictionary).duplicate(true))
	return entries


func get_debug_summary() -> Dictionary:
	return current_summary.duplicate(true)


func get_debug_text() -> String:
	var dominant_style: String = get_dominant_style()
	var dominant_score: float = get_dominant_score()
	var enemy_tags: Array[String] = get_current_enemy_tags()
	var loot_bias: Dictionary = get_loot_response_bias()
	return "room=%s style=%s(%.2f) tags=%s loot=%s" % [
		String(current_summary.get("room_id", "")),
		dominant_style,
		dominant_score,
		enemy_tags,
		loot_bias,
	]


func _connect_telemetry() -> void:
	if RunCombatTelemetry == null:
		return
	if RunCombatTelemetry.has_signal("telemetry_updated") and not RunCombatTelemetry.telemetry_updated.is_connected(_on_telemetry_updated):
		RunCombatTelemetry.telemetry_updated.connect(_on_telemetry_updated)


func _on_telemetry_updated(_summary: Dictionary) -> void:
	if current_room_id.is_empty():
		return
	_rebuild_summary()


func _load_rules() -> void:
	adaptation_rules.clear()
	if not FileAccess.file_exists(RULES_PATH):
		push_warning("EnemyAdaptationDirector: adaptation rules file not found at %s" % RULES_PATH)
		return

	var file: FileAccess = FileAccess.open(RULES_PATH, FileAccess.READ)
	if file == null:
		push_warning("EnemyAdaptationDirector: failed to open %s" % RULES_PATH)
		return

	var raw_text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("EnemyAdaptationDirector: adaptation rules file is not a Dictionary")
		return

	adaptation_rules = parsed


func _rebuild_summary() -> void:
	var profile: Dictionary = RunCombatTelemetry.get_profile_snapshot() if RunCombatTelemetry != null else {}
	var style_scores: Dictionary = profile.get("style_scores", {})
	var new_room_count: int = int(profile.get("new_room_count", 0))
	var dominant_style: String = String(profile.get("dominant_style", ""))
	var dominant_score: float = float(profile.get("dominant_score", 0.0))

	var enemy_tags: Array[String] = []
	var loot_bias: Dictionary = {}
	var active_styles: Array[Dictionary] = []
	var styles: Dictionary = adaptation_rules.get("styles", {})

	for style_name in styles.keys():
		var rule: Dictionary = styles[style_name]
		var score: float = float(style_scores.get(style_name, 0.0))
		var threshold: float = float(rule.get("threshold", 1.0))
		var activate_after: int = int(rule.get("activate_after_new_rooms", 999))
		if new_room_count < activate_after or score < threshold:
			continue

		var ramp_rooms: float = maxf(1.0, float(rule.get("ramp_rooms", 1)))
		var intensity: float = clampf(float(new_room_count - activate_after + 1) / ramp_rooms, 0.0, 1.0)
		var weighted_intensity: float = clampf(score * intensity, 0.0, 1.0)

		for tag in rule.get("enemy_tags", []):
			var tag_name: String = String(tag)
			if not enemy_tags.has(tag_name):
				enemy_tags.append(tag_name)

		var response_bias: Dictionary = rule.get("loot_bias", {})
		for bias_key in response_bias.keys():
			var added_weight: float = float(response_bias.get(bias_key, 0.0)) * weighted_intensity
			loot_bias[bias_key] = float(loot_bias.get(bias_key, 0.0)) + added_weight

		active_styles.append({
			"style": String(style_name),
			"score": score,
			"intensity": weighted_intensity,
			"enemy_tags": rule.get("enemy_tags", []),
			"loot_bias": response_bias.duplicate(true),
		})

	current_summary = {
		"room_id": current_room_id,
		"new_room_count": new_room_count,
		"dominant_style": dominant_style,
		"dominant_score": dominant_score,
		"active_styles": active_styles,
		"enemy_tags": enemy_tags,
		"loot_response_bias": _normalize_bias_dictionary(loot_bias),
	}

	if DEBUG_LOGGING:
		print("[ADAPT] room=%s dominant=%s tags=%s loot=%s" % [
			current_room_id,
			dominant_style,
			enemy_tags,
			current_summary.get("loot_response_bias", {}),
		])

	adaptation_changed.emit(get_debug_summary())


func _normalize_bias_dictionary(raw_bias: Dictionary) -> Dictionary:
	var total_weight: float = 0.0
	for weight in raw_bias.values():
		total_weight += float(weight)

	if total_weight <= 0.0:
		return {}

	var normalized: Dictionary = {}
	for bias_key in raw_bias.keys():
		normalized[bias_key] = float(raw_bias.get(bias_key, 0.0)) / total_weight
	return normalized
