extends Node

signal use_started(payload: Dictionary)
signal use_completed(payload: Dictionary)
signal use_interrupted(payload: Dictionary)

const HP_KIND := "hp"
const MANA_KIND := "mana"
const OUTLINE_SHADER := preload("res://shaders/sprite_outline.gdshader")

var player: Node = null
var active_payload: Dictionary = {}
var use_time_remaining: float = 0.0
var is_using: bool = false
var aura_pulse_time: float = 0.0
var marker_spawn_timer: float = 0.0

var effect_root: Node2D = null
var source_sprite: AnimatedSprite2D = null
var outline_sprite: AnimatedSprite2D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	set_process(false)


func setup(owner_player: Node) -> void:
	if player == owner_player:
		return

	var damage_callable := Callable(self, "_on_player_damage_received")
	var died_callable := Callable(self, "_on_player_died")

	if player != null and is_instance_valid(player):
		if player.has_signal("damage_received") and player.is_connected("damage_received", damage_callable):
			player.disconnect("damage_received", damage_callable)
		if player.has_signal("died") and player.is_connected("died", died_callable):
			player.disconnect("died", died_callable)

	player = owner_player
	if player == null:
		return

	if player.has_signal("damage_received") and not player.is_connected("damage_received", damage_callable):
		player.connect("damage_received", damage_callable)
	if player.has_signal("died") and not player.is_connected("died", died_callable):
		player.connect("died", died_callable)

	_ensure_effect_root()


func is_busy() -> bool:
	return is_using


func start_use(payload: Dictionary) -> bool:
	if player == null or not is_instance_valid(player) or is_using:
		return false

	var duration: float = maxf(0.05, float(payload.get("duration", 0.65)))
	active_payload = payload
	use_time_remaining = duration
	is_using = true
	aura_pulse_time = 0.0
	marker_spawn_timer = 0.0
	_set_player_use_state(true, float(payload.get("move_multiplier", 0.35)))
	_update_effect_root_position()
	_create_visuals(str(payload.get("instant_kind", "")))
	set_process(true)
	use_started.emit(active_payload)
	return true


func interrupt_use(reason: String = "interrupted") -> void:
	if not is_using:
		return

	var payload: Dictionary = active_payload
	_clear_state()
	payload["interrupt_reason"] = reason
	use_interrupted.emit(payload)


func _process(delta: float) -> void:
	if not is_using:
		return

	use_time_remaining = maxf(0.0, use_time_remaining - delta)
	aura_pulse_time += delta
	_update_outline_visual()
	_update_markers(delta)

	if use_time_remaining <= 0.0:
		_complete_use()


func _complete_use() -> void:
	if not is_using:
		return

	var payload: Dictionary = active_payload
	_clear_state()
	use_completed.emit(payload)


func _clear_state() -> void:
	is_using = false
	use_time_remaining = 0.0
	aura_pulse_time = 0.0
	marker_spawn_timer = 0.0
	active_payload = {}
	set_process(false)
	_set_player_use_state(false, 1.0)
	_clear_visuals()


func _set_player_use_state(active: bool, move_multiplier: float) -> void:
	if player == null or not is_instance_valid(player):
		return

	if "is_casting" in player:
		player.set("is_casting", active)
	if player.has_method("set_consumable_use_state"):
		player.call("set_consumable_use_state", active, move_multiplier)


func _ensure_effect_root() -> void:
	if player == null or not is_instance_valid(player):
		return

	if effect_root == null or not is_instance_valid(effect_root):
		effect_root = Node2D.new()
		effect_root.name = "ConsumableEffectRoot"
		player.add_child(effect_root)
	_update_effect_root_position()


func _create_visuals(kind: String) -> void:
	_ensure_effect_root()
	_clear_visuals()

	if effect_root == null:
		return

	_create_outline_visual(kind)
	_update_outline_visual()


func _clear_visuals() -> void:
	var current_outline := outline_sprite
	if outline_sprite != null and is_instance_valid(outline_sprite):
		outline_sprite.queue_free()
	outline_sprite = null

	if effect_root == null or not is_instance_valid(effect_root):
		return

	for child in effect_root.get_children():
		if child == current_outline:
			continue
		child.queue_free()


func _update_outline_visual() -> void:
	if outline_sprite == null or not is_instance_valid(outline_sprite):
		return

	_sync_outline_sprite()

	var material := outline_sprite.material as ShaderMaterial
	if material != null:
		var color: Color = material.get_shader_parameter("outline_color")
		color.a = 0.52 + 0.18 * (0.5 + 0.5 * sin(aura_pulse_time * 8.0))
		material.set_shader_parameter("outline_color", color)


func _create_outline_visual(kind: String) -> void:
	source_sprite = _get_source_sprite()
	if source_sprite == null or source_sprite.sprite_frames == null:
		return

	outline_sprite = AnimatedSprite2D.new()
	outline_sprite.name = "ConsumableOutline"
	outline_sprite.z_index = -1
	outline_sprite.centered = source_sprite.centered
	outline_sprite.offset = source_sprite.offset
	outline_sprite.scale = source_sprite.scale
	outline_sprite.flip_h = source_sprite.flip_h
	outline_sprite.position = Vector2.ZERO
	outline_sprite.sprite_frames = source_sprite.sprite_frames

	var material := ShaderMaterial.new()
	material.shader = OUTLINE_SHADER
	material.set_shader_parameter("outline_color", _get_outline_color(kind))
	material.set_shader_parameter("outline_size", 2.0)
	outline_sprite.material = material

	effect_root.add_child(outline_sprite)
	_sync_outline_sprite()


func _sync_outline_sprite() -> void:
	if outline_sprite == null or not is_instance_valid(outline_sprite):
		return

	source_sprite = _get_source_sprite()
	if source_sprite == null or source_sprite.sprite_frames == null:
		outline_sprite.visible = false
		return

	outline_sprite.visible = true
	outline_sprite.sprite_frames = source_sprite.sprite_frames
	outline_sprite.position = Vector2.ZERO
	outline_sprite.centered = source_sprite.centered
	outline_sprite.offset = source_sprite.offset
	outline_sprite.scale = source_sprite.scale
	outline_sprite.rotation = source_sprite.rotation
	outline_sprite.flip_h = source_sprite.flip_h

	if outline_sprite.animation != source_sprite.animation:
		outline_sprite.animation = source_sprite.animation
	outline_sprite.frame = source_sprite.frame
	outline_sprite.frame_progress = source_sprite.frame_progress


func _update_markers(delta: float) -> void:
	if effect_root == null or not is_instance_valid(effect_root):
		return

	var kind: String = str(active_payload.get("instant_kind", ""))
	if kind.is_empty():
		return

	marker_spawn_timer -= delta
	if marker_spawn_timer > 0.0:
		return

	match kind:
		HP_KIND:
			marker_spawn_timer = 0.14
			_spawn_plus_marker(Color(0.45, 1.0, 0.45, 0.95))
		MANA_KIND:
			marker_spawn_timer = 0.1
			_spawn_diamond_marker(Color(0.45, 0.75, 1.0, 0.95))
		_:
			marker_spawn_timer = 0.18


func _spawn_plus_marker(color: Color) -> void:
	var marker := Polygon2D.new()
	marker.polygon = PackedVector2Array([
		Vector2(-1, -5),
		Vector2(1, -5),
		Vector2(1, -1),
		Vector2(5, -1),
		Vector2(5, 1),
		Vector2(1, 1),
		Vector2(1, 5),
		Vector2(-1, 5),
		Vector2(-1, 1),
		Vector2(-5, 1),
		Vector2(-5, -1),
		Vector2(-1, -1),
	])
	marker.color = color
	marker.position = Vector2(randf_range(-18.0, 18.0), randf_range(-14.0, 14.0))
	marker.rotation = randf_range(-0.15, 0.15)
	effect_root.add_child(marker)

	var tween := create_tween()
	tween.tween_property(marker, "position:y", marker.position.y - 18.0, 0.4)
	tween.parallel().tween_property(marker, "modulate:a", 0.0, 0.4)
	tween.parallel().tween_property(marker, "scale", Vector2.ONE * 1.2, 0.4)
	tween.finished.connect(marker.queue_free)


func _spawn_diamond_marker(color: Color) -> void:
	var marker := Polygon2D.new()
	marker.polygon = PackedVector2Array([
		Vector2(0, -6),
		Vector2(4, 0),
		Vector2(0, 6),
		Vector2(-4, 0),
	])
	marker.color = color
	marker.position = Vector2(randf_range(-20.0, 20.0), randf_range(-14.0, 14.0))
	marker.rotation = randf_range(0.0, PI)
	effect_root.add_child(marker)

	var tween := create_tween()
	tween.tween_property(marker, "position:y", marker.position.y - 22.0, 0.36)
	tween.parallel().tween_property(marker, "modulate:a", 0.0, 0.36)
	tween.parallel().tween_property(marker, "rotation", marker.rotation + 1.4, 0.36)
	tween.finished.connect(marker.queue_free)


func _get_outline_color(kind: String) -> Color:
	match kind:
		HP_KIND:
			return Color(0.35, 1.0, 0.48, 0.68)
		MANA_KIND:
			return Color(0.35, 0.72, 1.0, 0.68)
		_:
			return Color(1.0, 1.0, 1.0, 0.45)


func _update_effect_root_position() -> void:
	if effect_root == null or not is_instance_valid(effect_root) or player == null or not is_instance_valid(player):
		return

	var anchor_position := Vector2.ZERO
	if "animated_sprite" in player:
		var sprite_value = player.get("animated_sprite")
		if sprite_value is Node2D and is_instance_valid(sprite_value):
			anchor_position = sprite_value.position
		else:
			var sprite_node := player.get_node_or_null("AnimatedSprite2D") as Node2D
			if sprite_node != null:
				anchor_position = sprite_node.position
	else:
		var fallback_sprite := player.get_node_or_null("AnimatedSprite2D") as Node2D
		if fallback_sprite != null:
			anchor_position = fallback_sprite.position

	effect_root.position = anchor_position


func _get_source_sprite() -> AnimatedSprite2D:
	if player == null or not is_instance_valid(player):
		return null

	if "animated_sprite" in player:
		var sprite_value = player.get("animated_sprite")
		if sprite_value is AnimatedSprite2D and is_instance_valid(sprite_value):
			return sprite_value

	return player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D


func _on_player_damage_received(_final_damage: int, reaction_tag: String) -> void:
	if reaction_tag == "hurt" or reaction_tag == "heavy":
		interrupt_use("damaged")


func _on_player_died() -> void:
	interrupt_use("died")
