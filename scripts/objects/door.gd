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
const COLOR_NAMES := {
	KeyColor.GOLD: "золотой",
	KeyColor.SILVER: "серебряный",
	KeyColor.RED: "красный",
	KeyColor.BLUE: "синий",
	KeyColor.GREEN: "зелёный",
	KeyColor.PURPLE: "фиолетовый",
	KeyColor.NONE: "нет",
}

@export var target_scene: String = ""
@export var spawn_point_id: String = "SpawnPoint"
@export var required_key: KeyColor = KeyColor.GOLD
@export var requires_key: bool = true
@export var consumes_key: bool = true
@export var is_initially_open: bool = false

var animated_sprite: AnimatedSprite2D = null
var color_indicator: CanvasItem = null
var hint_label: Label = null
var persistence: PersistenceComponent = null

var is_open: bool = false
var player_in_range: bool = false


func _ready() -> void:
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	color_indicator = get_node_or_null("ColorIndicator")
	hint_label = get_node_or_null("HintLabel")
	is_open = is_initially_open

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


func _setup_hint() -> void:
	if hint_label:
		hint_label.visible = false
		_update_hint_text()


func _update_hint_text() -> void:
	if not hint_label:
		return

	if is_open:
		hint_label.text = "[F] Войти"
	elif requires_key:
		var key_name: String = COLOR_NAMES.get(required_key, "ключ")
		hint_label.text = "[F] Открыть (%s ключ)" % key_name
	else:
		hint_label.text = "[F] Открыть"


func _update_visual() -> void:
	if animated_sprite:
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

	if color_indicator:
		var colors: Dictionary = {
			KeyColor.GOLD: Color(1.0, 0.85, 0.0),
			KeyColor.SILVER: Color(0.75, 0.75, 0.85),
			KeyColor.RED: Color(1.0, 0.25, 0.25),
			KeyColor.BLUE: Color(0.3, 0.5, 1.0),
			KeyColor.GREEN: Color(0.3, 0.85, 0.3),
			KeyColor.PURPLE: Color(0.75, 0.3, 0.9),
		}
		var target_color: Color = colors.get(required_key, Color.WHITE)

		if color_indicator is ColorRect:
			(color_indicator as ColorRect).color = target_color
		else:
			color_indicator.modulate = target_color


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
	if is_open:
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

	if persistence:
		persistence.save_from_owner()

	if Global:
		Global.mark_door_opened(name)

	_update_visual()
	_update_hint_text()
	door_opened.emit()


func _use_door() -> void:
	if target_scene.is_empty():
		print("target_scene is empty")
		return

	var level: Node = get_parent()
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
