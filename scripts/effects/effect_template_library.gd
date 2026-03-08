extends RefCounted
class_name EffectTemplateLibrary

const EFFECT_TEMPLATES_PATH: String = "res://data/effect_templates.json"

static var _templates_cache: Dictionary = {}
static var _is_loaded: bool = false


static func get_template(effect_id: String) -> Dictionary:
	_ensure_loaded()
	if _templates_cache.has(effect_id):
		var template_variant: Variant = _templates_cache.get(effect_id, {})
		if template_variant is Dictionary:
			return (template_variant as Dictionary).duplicate(true)
	return {}


static func _ensure_loaded() -> void:
	if _is_loaded:
		return

	_is_loaded = true
	_templates_cache.clear()

	if not FileAccess.file_exists(EFFECT_TEMPLATES_PATH):
		push_warning("EffectTemplateLibrary: file not found: %s" % EFFECT_TEMPLATES_PATH)
		return

	var file: FileAccess = FileAccess.open(EFFECT_TEMPLATES_PATH, FileAccess.READ)
	if file == null:
		push_warning("EffectTemplateLibrary: failed to open %s" % EFFECT_TEMPLATES_PATH)
		return

	var raw_text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw_text)
	if not (parsed is Dictionary):
		push_warning("EffectTemplateLibrary: invalid JSON root in %s" % EFFECT_TEMPLATES_PATH)
		return

	var root: Dictionary = parsed as Dictionary
	var templates_variant: Variant = root.get("effect_templates", [])
	if not (templates_variant is Array):
		push_warning("EffectTemplateLibrary: 'effect_templates' must be an array")
		return

	for template_variant in (templates_variant as Array):
		if not (template_variant is Dictionary):
			continue

		var template: Dictionary = template_variant as Dictionary
		var template_id: String = String(template.get("id", "")).strip_edges()
		if template_id.is_empty():
			continue

		_templates_cache[template_id] = template.duplicate(true)