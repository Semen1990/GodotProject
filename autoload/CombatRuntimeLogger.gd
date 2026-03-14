extends Node

const LOG_PATH: String = "user://combat_runtime_log.txt"

var enabled: bool = true
var _initialized: bool = false


func _ready() -> void:
	reset_log()


func reset_log() -> void:
	if not enabled:
		return
	var file: FileAccess = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_line("=== COMBAT RUNTIME LOG ===")
	file.store_line("timestamp_ms=%s" % str(Time.get_ticks_msec()))
	file.close()
	_initialized = true


func begin_session(label: String) -> void:
	if not enabled:
		return
	if not _initialized:
		reset_log()
	_append_line("")
	_append_line("=== SESSION: %s ===" % label)


func log_event(category: String, source: String, message: String, data: Dictionary = {}) -> void:
	if not enabled:
		return
	if not _initialized:
		reset_log()

	var line: String = "[%s] [%s] %s: %s" % [
		str(Time.get_ticks_msec()),
		category,
		source,
		message,
	]
	if not data.is_empty():
		line += " " + JSON.stringify(_sanitize_variant(data))
	_append_line(line)


func get_log_path() -> String:
	return ProjectSettings.globalize_path(LOG_PATH)


func _append_line(line: String) -> void:
	var file: FileAccess = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_line(line)
	file.close()


func _sanitize_variant(value: Variant) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			var sanitized_dict: Dictionary = {}
			for key in value.keys():
				sanitized_dict[str(key)] = _sanitize_variant(value[key])
			return sanitized_dict
		TYPE_ARRAY:
			var sanitized_array: Array = []
			for entry in value:
				sanitized_array.append(_sanitize_variant(entry))
			return sanitized_array
		TYPE_VECTOR2:
			var vector: Vector2 = value
			return {"x": snappedf(vector.x, 0.1), "y": snappedf(vector.y, 0.1)}
		TYPE_OBJECT:
			if value == null:
				return "null"
			if value is Node:
				var node: Node = value
				return "%s:%s" % [node.name, node.get_class()]
			return str(value)
		_:
			return value
