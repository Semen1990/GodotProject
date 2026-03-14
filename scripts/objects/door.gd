extends Area2D
class_name Door

signal door_opened
signal door_used

enum KeyColor {
	GOLD = 0,
	SILVER = 1,
	RED = 2,
	BLUE = 3,
	GREEN = 4,
	PURPLE = 5,
	NONE = -1
}

const PERSISTENCE_COMPONENT := preload("res://scripts/persistence/persistence_component.gd")
const LOCK_SPRITESHEET_PATH := "res://assets/Lock/Lock-spritesheet.png"
const LOCK_ANIMATION_NAME := &"unlock"
const LOCK_COLUMNS := 5
const LOCK_ROWS := 5
const COLOR_NAMES := {
	KeyColor.GOLD: "золотой",
	KeyColor.SILVER: "серебряный",
	KeyColor.RED: "красный",
	KeyColor.BLUE: "синий",
	KeyColor.GREEN: "зелёный",
	KeyColor.PURPLE: "фиолетовый",
	KeyColor.NONE: "нет",
}
const KEY_COLORS := {
	KeyColor.GOLD: Color(1.0, 0.85, 0.0),
	KeyColor.SILVER: Color(0.75, 0.75, 0.85),
	KeyColor.RED: Color(1.0, 0.25, 0.25),
	KeyColor.BLUE: Color(0.3, 0.5, 1.0),
	KeyColor.GREEN: Color(0.3, 0.85, 0.3),
	KeyColor.PURPLE: Color(0.75, 0.3, 0.9),
}

@export var target_scene: String = ""
@export var spawn_point_id: String = "SpawnPoint"
@export var required_key: KeyColor = KeyColor.GOLD
@export var requires_key: bool = true
@export var consumes_key: bool = true
@export var is_initially_open: bool = false

@export_group("Lock Visual")
@export var lock_offset: Vector2 = Vector2(12.0, -96.0)
@export var lock_scale: Vector2 = Vector2(0.23, 0.23)
@export_range(1.0, 3.0, 0.05) var lock_glow_scale_multiplier: float = 1.45
@export_range(0.0, 1.0, 0.05) var lock_glow_alpha: float = 0.7
@export_range(1.0, 30.0, 0.5) var lock_animation_speed: float = 12.0
@export_range(0.0, 1.0, 0.05) var lock_emblem_tint_strength: float = 0.35

var animated_sprite: AnimatedSprite2D = null
var color_indicator: CanvasItem = null
var hint_label: Label = null
var persistence: PersistenceComponent = null
var lock_emblem: AnimatedSprite2D = null
var lock_glow: AnimatedSprite2D = null
var lock_hide_token: int = 0

var is_open: bool = false
var is_unlocking: bool = false
var is_opening: bool = false
var can_enter_open_door: bool = false
var player_in_range: bool = false


func _ready() -> void:
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	color_indicator = get_node_or_null("ColorIndicator")
	hint_label = get_node_or_null("HintLabel")
	is_open = is_initially_open

	_ensure_lock_visual_nodes()
	_configure_lock_visual_nodes()
	_apply_lock_layout()

	_ensure_persistence()
	_configure_persistence()

	var saved_state: Dictionary = _load_persistent_state()
	if not saved_state.is_empty():
		apply_persistent_state(saved_state)
	elif Global and Global.is_door_opened(name):
		is_open = true
		if persistence:
			persistence.save_from_owner()

	if not requires_key:
		is_open = true

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	if animated_sprite and not animated_sprite.animation_finished.is_connected(_on_door_animation_finished):
		animated_sprite.animation_finished.connect(_on_door_animation_finished)

	can_enter_open_door = is_open

	_update_visual()
	_setup_hint()


func capture_persistent_state() -> Dictionary:
	return {
		"opened": is_open,
		"requires_key": requires_key,
		"required_key": int(required_key),
		"consumed": false,
	}


func apply_persistent_state(state: Dictionary) -> void:
	if state.has("required_key"):
		required_key = int(state["required_key"])
	if state.has("requires_key"):
		requires_key = bool(state["requires_key"])
	is_open = bool(state.get("opened", false)) or is_initially_open or not requires_key


func _ensure_persistence() -> void:
	persistence = get_node_or_null("Persistence") as PersistenceComponent
	if persistence != null:
		return

	persistence = PERSISTENCE_COMPONENT.new()
	persistence.name = "Persistence"
	add_child(persistence)


func _configure_persistence() -> void:
	if persistence:
		persistence.configure(name, "door", false)


func _load_persistent_state() -> Dictionary:
	if Global and not Global.run_started:
		return {}
	if persistence == null:
		return {}

	return persistence.get_saved_state()


func _ensure_lock_visual_nodes() -> void:
	lock_glow = get_node_or_null("LockGlow") as AnimatedSprite2D
	if lock_glow == null:
		lock_glow = AnimatedSprite2D.new()
		lock_glow.name = "LockGlow"
		add_child(lock_glow)

	lock_emblem = get_node_or_null("LockEmblem") as AnimatedSprite2D
	if lock_emblem == null:
		lock_emblem = AnimatedSprite2D.new()
		lock_emblem.name = "LockEmblem"
		add_child(lock_emblem)

	lock_glow.z_index = 1
	lock_emblem.z_index = 2
	lock_glow.visible = false
	lock_emblem.visible = false

	if color_indicator:
		color_indicator.visible = false


func _configure_lock_visual_nodes() -> void:
	var lock_frames: SpriteFrames = _build_lock_sprite_frames()
	if lock_frames == null:
		_hide_lock_visuals()
		return

	lock_glow.sprite_frames = lock_frames
	lock_glow.animation = LOCK_ANIMATION_NAME
	lock_glow.centered = true
	lock_glow.speed_scale = 1.0
	lock_glow.play(LOCK_ANIMATION_NAME)
	lock_glow.stop()
	lock_glow.frame = 0

	lock_emblem.sprite_frames = lock_frames
	lock_emblem.animation = LOCK_ANIMATION_NAME
	lock_emblem.centered = true
	lock_emblem.speed_scale = 1.0
	lock_emblem.play(LOCK_ANIMATION_NAME)
	lock_emblem.stop()
	lock_emblem.frame = 0

	_apply_lock_color()


func _build_lock_sprite_frames() -> SpriteFrames:
	var sheet: Texture2D = load(LOCK_SPRITESHEET_PATH) as Texture2D
	if sheet == null:
		return null

	var frame_width: int = sheet.get_width() / LOCK_COLUMNS
	var frame_height: int = sheet.get_height() / LOCK_ROWS
	if frame_width <= 0 or frame_height <= 0:
		return null

	var sprite_frames := SpriteFrames.new()
	sprite_frames.add_animation(LOCK_ANIMATION_NAME)
	sprite_frames.set_animation_loop(LOCK_ANIMATION_NAME, false)
	sprite_frames.set_animation_speed(LOCK_ANIMATION_NAME, lock_animation_speed)

	for row in range(LOCK_ROWS):
		for col in range(LOCK_COLUMNS):
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(col * frame_width, row * frame_height, frame_width, frame_height)
			sprite_frames.add_frame(LOCK_ANIMATION_NAME, atlas)

	return sprite_frames


func _apply_lock_layout() -> void:
	if lock_emblem:
		lock_emblem.position = lock_offset
		lock_emblem.scale = lock_scale

	if lock_glow:
		lock_glow.position = lock_offset
		lock_glow.scale = lock_scale * lock_glow_scale_multiplier


func _apply_lock_color() -> void:
	var target_color: Color = KEY_COLORS.get(required_key, Color.WHITE)

	if lock_emblem:
		lock_emblem.modulate = Color.WHITE.lerp(target_color, lock_emblem_tint_strength)

	if lock_glow:
		lock_glow.modulate = Color(target_color.r, target_color.g, target_color.b, lock_glow_alpha)


func _show_closed_lock_visuals() -> void:
	if not requires_key or required_key == KeyColor.NONE:
		_hide_lock_visuals()
		return
	if lock_emblem == null or lock_glow == null:
		return
	if lock_emblem.sprite_frames == null or not lock_emblem.sprite_frames.has_animation(LOCK_ANIMATION_NAME):
		_hide_lock_visuals()
		return

	_apply_lock_layout()
	_apply_lock_color()

	lock_glow.visible = true
	lock_emblem.visible = true

	lock_glow.play(LOCK_ANIMATION_NAME)
	lock_glow.stop()
	lock_glow.frame = 0
	lock_glow.frame_progress = 0.0

	lock_emblem.play(LOCK_ANIMATION_NAME)
	lock_emblem.stop()
	lock_emblem.frame = 0
	lock_emblem.frame_progress = 0.0


func _hide_lock_visuals() -> void:
	if lock_glow:
		lock_glow.stop()
		lock_glow.visible = false
	if lock_emblem:
		lock_emblem.stop()
		lock_emblem.visible = false


func _play_unlock_animation() -> void:
	if not requires_key or required_key == KeyColor.NONE:
		_hide_lock_visuals()
		is_unlocking = false
		_start_door_open_sequence()
		return
	if lock_emblem == null or lock_glow == null:
		is_unlocking = false
		_start_door_open_sequence()
		return
	if lock_emblem.sprite_frames == null or not lock_emblem.sprite_frames.has_animation(LOCK_ANIMATION_NAME):
		is_unlocking = false
		_start_door_open_sequence()
		return

	lock_hide_token += 1
	var current_token: int = lock_hide_token

	_apply_lock_layout()
	_apply_lock_color()

	lock_glow.visible = true
	lock_emblem.visible = true
	lock_glow.frame = 0
	lock_glow.frame_progress = 0.0
	lock_emblem.frame = 0
	lock_emblem.frame_progress = 0.0
	lock_glow.play(LOCK_ANIMATION_NAME)
	lock_emblem.play(LOCK_ANIMATION_NAME)

	var tween: Tween = create_tween()
	tween.tween_interval(_get_lock_animation_duration())
	tween.finished.connect(_on_unlock_animation_finished.bind(current_token), CONNECT_ONE_SHOT)


func _get_lock_animation_duration() -> float:
	if lock_emblem == null or lock_emblem.sprite_frames == null:
		return 0.0
	if not lock_emblem.sprite_frames.has_animation(LOCK_ANIMATION_NAME):
		return 0.0

	var frame_count: int = lock_emblem.sprite_frames.get_frame_count(LOCK_ANIMATION_NAME)
	var animation_speed: float = lock_emblem.sprite_frames.get_animation_speed(LOCK_ANIMATION_NAME)
	if frame_count <= 0 or animation_speed <= 0.0:
		return 0.0

	return float(frame_count) / animation_speed + 0.05


func _on_unlock_animation_finished(token: int) -> void:
	if token != lock_hide_token:
		return
	_hide_lock_visuals()
	if is_unlocking:
		is_unlocking = false
		_start_door_open_sequence()


func _setup_hint() -> void:
	if hint_label:
		hint_label.visible = false
		_update_hint_text()


func _update_hint_text() -> void:
	if not hint_label:
		return

	if is_open:
		hint_label.text = "[F] Войти" if can_enter_open_door else "Открывается..."
	elif requires_key:
		var key_name: String = COLOR_NAMES.get(required_key, "ключ")
		hint_label.text = "[F] Открыть (%s ключ)" % key_name
	else:
		hint_label.text = "[F] Открыть"


func _play_door_animation() -> void:
	if not animated_sprite:
		return

	if is_open:
		if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("open"):
			animated_sprite.play("open")
		elif animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("opened"):
			animated_sprite.play("opened")
	else:
		if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("closed"):
			animated_sprite.play("closed")
		elif animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")


func _has_open_animation() -> bool:
	if not animated_sprite or animated_sprite.sprite_frames == null:
		return false

	return animated_sprite.sprite_frames.has_animation("open")


func _start_door_open_sequence() -> void:
	if not is_open:
		return

	is_opening = _has_open_animation()
	can_enter_open_door = not is_opening
	_play_door_animation()
	_update_hint_text()


func _on_door_animation_finished() -> void:
	if not is_opening or not is_open:
		return
	if not animated_sprite:
		return
	if animated_sprite.animation != "open":
		return

	is_opening = false
	can_enter_open_door = true
	_update_hint_text()


func _update_visual() -> void:
	_play_door_animation()

	if color_indicator:
		color_indicator.visible = false

	if is_open:
		_hide_lock_visuals()
	else:
		_show_closed_lock_visuals()


func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		_try_use_door()


func _on_body_entered(body: Node2D) -> void:
	if _is_player(body):
		player_in_range = true
		if hint_label:
			hint_label.visible = true
			_update_hint_text()


func _on_body_exited(body: Node2D) -> void:
	if _is_player(body):
		player_in_range = false
		if hint_label:
			hint_label.visible = false


func _is_player(body: Node2D) -> bool:
	return body.is_in_group("player") or body.has_method("take_damage")


func _try_use_door() -> void:
	if is_unlocking or is_opening:
		return

	if is_open:
		if not can_enter_open_door:
			return
		_use_door()
		return

	if requires_key:
		var key_color: int = int(required_key)
		if Global.has_key(key_color):
			if consumes_key:
				Global.remove_key(key_color)
			_open_door()
		else:
			_show_locked_feedback()
	else:
		_open_door()


func _open_door() -> void:
	is_open = true
	is_unlocking = requires_key and required_key != KeyColor.NONE
	is_opening = false
	can_enter_open_door = false

	if persistence:
		persistence.save_from_owner()

	if Global:
		Global.mark_door_opened(name)

	if is_unlocking:
		_play_unlock_animation()
	else:
		_start_door_open_sequence()
	_update_hint_text()
	door_opened.emit()


func _use_door() -> void:
	if target_scene.is_empty():
		print("target_scene is empty")
		return

	var level: Node = get_tree().current_scene
	if level and level.has_method("save_before_transition"):
		level.save_before_transition()
	else:
		_save_player_stats_direct()
		if RunState:
			RunState.capture_scene_state(get_tree().current_scene)

	Global.spawn_point = spawn_point_id
	door_used.emit()
	get_tree().change_scene_to_file(target_scene)


func _save_player_stats_direct() -> void:
	if not Global.current_player:
		return

	var player: Node = Global.current_player
	Global.saved_player_health = player.current_health
	if "current_mana" in player:
		Global.saved_player_mana = player.current_mana


func _show_locked_feedback() -> void:
	if animated_sprite:
		var original: Color = animated_sprite.modulate
		animated_sprite.modulate = Color(1.5, 0.5, 0.5)

		var tween: Tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", original, 0.3)

	if hint_label:
		var key_name: String = COLOR_NAMES.get(required_key, "ключ")
		hint_label.text = "Нужен %s ключ" % key_name
		hint_label.add_theme_color_override("font_color", Color.RED)

		await get_tree().create_timer(1.5).timeout

		if hint_label:
			hint_label.remove_theme_color_override("font_color")
			_update_hint_text()
