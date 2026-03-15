extends Area2D
class_name KeyPickup

signal collected(key_color: int)

enum KeyColor {
	GOLD = 0,
	SILVER = 1,
	RED = 2,
	BLUE = 3,
	GREEN = 4,
	PURPLE = 5
}

const PERSISTENCE_COMPONENT := preload("res://scripts/persistence/persistence_component.gd")
const COLOR_NAMES := {
	KeyColor.GOLD: "\u0417\u043e\u043b\u043e\u0442\u043e\u0439",
	KeyColor.SILVER: "\u0421\u0435\u0440\u0435\u0431\u0440\u044f\u043d\u044b\u0439",
	KeyColor.RED: "\u041a\u0440\u0430\u0441\u043d\u044b\u0439",
	KeyColor.BLUE: "\u0421\u0438\u043d\u0438\u0439",
	KeyColor.GREEN: "\u0417\u0435\u043b\u0451\u043d\u044b\u0439",
	KeyColor.PURPLE: "\u0424\u0438\u043e\u043b\u0435\u0442\u043e\u0432\u044b\u0439",
}
const KEY_SPRITE_FRAMES := {
	KeyColor.GOLD: preload("res://resources/items/keys_game/key_pickup_frames_gold.tres"),
	KeyColor.SILVER: preload("res://resources/items/keys_game/key_pickup_frames_silver.tres"),
	KeyColor.RED: preload("res://resources/items/keys_game/key_pickup_frames_red.tres"),
	KeyColor.BLUE: preload("res://resources/items/keys_game/key_pickup_frames_blue.tres"),
	KeyColor.GREEN: preload("res://resources/items/keys_game/key_pickup_frames_green.tres"),
	KeyColor.PURPLE: preload("res://resources/items/keys_game/key_pickup_frames_purple.tres"),
}

@export var key_color: KeyColor = KeyColor.GOLD
@export var float_height: float = 4.0
@export var float_speed: float = 2.5
@export var auto_collect: bool = false
@export var sprite_scale: float = 2.0
@export var animation_speed: float = 12.0

var animated_sprite: AnimatedSprite2D = null
var hint_label: Label = null
var persistence: PersistenceComponent = null

var initial_y: float = 0.0
var time: float = 0.0
var player_in_range: bool = false
var is_collected: bool = false
var pending_persistent_id: String = ""


func _ready() -> void:
	animated_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	hint_label = get_node_or_null("HintLabel")
	initial_y = position.y

	_ensure_persistence()
	_configure_persistence()

	var saved_state: Dictionary = _load_persistent_state()
	if bool(saved_state.get("collected", false)) or bool(saved_state.get("consumed", false)):
		queue_free()
		return

	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(4, true)
	set_collision_mask_value(2, true)
	monitoring = true
	monitorable = true

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

	_setup_sprite()
	_setup_hint()


func set_persistent_id(id: String) -> void:
	pending_persistent_id = id
	if is_node_ready():
		_configure_persistence()


func capture_persistent_state() -> Dictionary:
	return {
		"key_color": int(key_color),
		"collected": is_collected,
		"consumed": is_collected,
	}


func apply_persistent_state(state: Dictionary) -> void:
	if state.has("key_color"):
		key_color = int(state["key_color"])
	is_collected = bool(state.get("collected", false)) or bool(state.get("consumed", false))


func _ensure_persistence() -> void:
	persistence = get_node_or_null("Persistence") as PersistenceComponent
	if persistence != null:
		return

	persistence = PERSISTENCE_COMPONENT.new()
	persistence.name = "Persistence"
	add_child(persistence)


func _configure_persistence() -> void:
	if persistence == null:
		return

	var resolved_id: String = pending_persistent_id
	if resolved_id.is_empty():
		resolved_id = name
	persistence.configure(resolved_id, "pickup", true)


func _load_persistent_state() -> Dictionary:
	if Global and not Global.run_started:
		return {}
	if persistence == null:
		return {}

	var saved_state: Dictionary = persistence.get_saved_state()
	if saved_state.is_empty() and Global and Global.is_pickup_collected(name):
		saved_state = persistence.mark_consumed({
			"key_color": int(key_color),
			"collected": true,
		})

	if not saved_state.is_empty():
		apply_persistent_state(saved_state)

	return saved_state


func _setup_hint() -> void:
	if not hint_label:
		hint_label = Label.new()
		hint_label.name = "HintLabel"
		add_child(hint_label)

	hint_label.text = "[F] \u041f\u043e\u0434\u043e\u0431\u0440\u0430\u0442\u044c"
	hint_label.position = Vector2(-45, -50)
	hint_label.visible = false
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color.WHITE)


func _setup_sprite() -> void:
	if not animated_sprite:
		animated_sprite = AnimatedSprite2D.new()
		animated_sprite.name = "AnimatedSprite2D"
		add_child(animated_sprite)
		move_child(animated_sprite, 0)

	var sprite_frames: SpriteFrames = _get_key_sprite_frames()
	animated_sprite.sprite_frames = sprite_frames
	animated_sprite.scale = Vector2.ONE * sprite_scale
	animated_sprite.play("idle")


func _get_key_sprite_frames() -> SpriteFrames:
	var source_frames: SpriteFrames = KEY_SPRITE_FRAMES.get(key_color, null)
	if source_frames == null:
		return _create_fallback_sprite_frames()

	var frames: SpriteFrames = source_frames.duplicate(true) as SpriteFrames
	if frames == null:
		return _create_fallback_sprite_frames()

	if frames.has_animation("idle"):
		frames.set_animation_speed("idle", animation_speed)
	return frames


func _create_fallback_sprite_frames() -> SpriteFrames:
	var colors: Dictionary = {
		KeyColor.GOLD: Color(1.0, 0.85, 0.0),
		KeyColor.SILVER: Color(0.75, 0.75, 0.8),
		KeyColor.RED: Color(1.0, 0.4, 0.2),
		KeyColor.BLUE: Color(0.3, 0.6, 1.0),
		KeyColor.GREEN: Color(0.3, 0.9, 0.3),
		KeyColor.PURPLE: Color(0.9, 0.3, 0.6),
	}

	var size: int = 32
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var color = colors.get(key_color, Color.YELLOW)

	for x in range(size):
		for y in range(size):
			var cx: float = size * 0.7
			var cy: float = size * 0.3
			var dist: float = sqrt(pow(x - cx, 2) + pow(y - cy, 2))
			if dist < size * 0.25 and dist > size * 0.15:
				image.set_pixel(x, y, color)
			elif x > size * 0.2 and x < size * 0.5 and y > size * 0.25 and y < size * 0.35:
				image.set_pixel(x, y, color)
			elif x < size * 0.3 and y > size * 0.35 and y < size * 0.5:
				image.set_pixel(x, y, color)

	var texture: ImageTexture = ImageTexture.create_from_image(image)
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", 1.0)
	frames.add_frame("idle", texture)
	return frames


func _process(delta: float) -> void:
	if is_collected:
		return

	time += delta * float_speed
	position.y = initial_y + sin(time) * float_height

	if player_in_range and not auto_collect and Input.is_action_just_pressed("interact"):
		_collect()


func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return

	if _is_player(body):
		player_in_range = true
		if auto_collect:
			_collect()
		elif hint_label:
			hint_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if _is_player(body):
		player_in_range = false
		if hint_label:
			hint_label.visible = false


func _is_player(body: Node2D) -> bool:
	return body.is_in_group("player") or body.has_method("take_damage")


func _collect() -> void:
	if is_collected:
		return

	is_collected = true
	var color_int: int = int(key_color)

	if persistence:
		persistence.mark_consumed({
			"key_color": color_int,
			"collected": true,
		})

	if Global:
		Global.register_collected_pickup(name)
		Global.add_key(color_int)

	collected.emit(color_int)
	_play_collect_effect()


func _play_collect_effect() -> void:
	if hint_label:
		hint_label.visible = false

	set_deferred("monitoring", false)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	if animated_sprite:
		tween.tween_property(animated_sprite, "scale", animated_sprite.scale * 1.5, 0.2)
		tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.2)
		tween.tween_property(animated_sprite, "position:y", animated_sprite.position.y - 20.0, 0.2)
	else:
		tween.tween_property(self, "modulate:a", 0.0, 0.2)

	tween.chain().tween_callback(queue_free)
