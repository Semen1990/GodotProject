extends Area2D
class_name Door

# ===========================================
# ДВЕРЬ - ПЕРЕХОД МЕЖДУ УРОВНЯМИ v3
# ===========================================
# Путь: res://scripts/objects/door.gd

enum DoorColor {
	GOLD,      # 0
	SILVER,    # 1
	ORANGE,    # 2
	BLUE,      # 3
	GREEN,     # 4
	RED        # 5
}

const DOOR_COLORS_RGB = {
	DoorColor.GOLD: Color(0.9, 0.75, 0.4),
	DoorColor.SILVER: Color(0.75, 0.75, 0.8),
	DoorColor.ORANGE: Color(1.0, 0.5, 0.1),
	DoorColor.BLUE: Color(0.3, 0.6, 0.9),
	DoorColor.GREEN: Color(0.5, 0.9, 0.2),
	DoorColor.RED: Color(0.9, 0.3, 0.2),
}

const COLOR_NAMES = {
	DoorColor.GOLD: "золотой",
	DoorColor.SILVER: "серебряный",
	DoorColor.ORANGE: "оранжевый",
	DoorColor.BLUE: "синий",
	DoorColor.GREEN: "зелёный",
	DoorColor.RED: "красный",
}

# === НАСТРОЙКИ ===
@export var door_color: DoorColor = DoorColor.GOLD
@export var target_scene: String = ""
@export var spawn_point_name: String = ""
@export var is_initially_open: bool = false
@export var use_key: bool = true

# === УЗЛЫ ===
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var hint_label: Label = null
var color_indicator: ColorRect = null

var is_open: bool = false
var player_in_range: bool = false


func _ready():
	print("🚪 Дверь создана: %s (target: %s)" % [COLOR_NAMES[door_color], target_scene])
	
	is_open = is_initially_open
	
	_ensure_hint_label()
	_ensure_color_indicator()
	_update_door_state()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _ensure_hint_label():
	hint_label = get_node_or_null("HintLabel")
	
	if not hint_label:
		hint_label = Label.new()
		hint_label.name = "HintLabel"
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_label.position = Vector2(-80, -100)
		hint_label.add_theme_font_size_override("font_size", 14)
		hint_label.add_theme_color_override("font_color", Color(1, 1, 0.9))
		add_child(hint_label)
	
	hint_label.visible = false


func _ensure_color_indicator():
	color_indicator = get_node_or_null("ColorIndicator")
	
	if not color_indicator:
		color_indicator = ColorRect.new()
		color_indicator.name = "ColorIndicator"
		color_indicator.size = Vector2(40, 8)
		color_indicator.position = Vector2(-20, -85)
		add_child(color_indicator)
	
	color_indicator.color = DOOR_COLORS_RGB[door_color]


func _update_door_state():
	if animated_sprite and animated_sprite.sprite_frames:
		var anim = "open" if is_open else "idle"
		if animated_sprite.sprite_frames.has_animation(anim):
			animated_sprite.play(anim)
	
	if color_indicator:
		color_indicator.color = DOOR_COLORS_RGB[door_color]
		color_indicator.color.a = 0.5 if is_open else 1.0


func _process(_delta):
	if player_in_range:
		if Input.is_action_just_pressed("interact"):
			_interact()
	
	# Пульсация когда можно открыть
	if color_indicator and player_in_range and not is_open and _has_required_key():
		var pulse = (sin(Time.get_ticks_msec() * 0.005) + 1) / 2
		color_indicator.color.a = 0.5 + pulse * 0.5


func _on_body_entered(body: Node2D):
	if not _is_player(body):
		return
	
	player_in_range = true
	_update_hint()
	
	if hint_label:
		hint_label.visible = true


func _on_body_exited(body: Node2D):
	if not _is_player(body):
		return
	
	player_in_range = false
	
	if hint_label:
		hint_label.visible = false


func _is_player(body: Node2D) -> bool:
	return body.is_in_group("player") or body.has_method("take_damage")


func _update_hint():
	if not hint_label:
		return
	
	if is_open:
		hint_label.text = "Нажми F чтобы войти"
		hint_label.add_theme_color_override("font_color", Color(0.7, 1, 0.7))
	elif not use_key:
		hint_label.text = "Нажми F чтобы открыть"
		hint_label.add_theme_color_override("font_color", Color(1, 1, 0.7))
	elif _has_required_key():
		hint_label.text = "Нажми F чтобы открыть"
		hint_label.add_theme_color_override("font_color", Color(0.7, 1, 0.7))
	else:
		hint_label.text = "Нужен %s ключ" % COLOR_NAMES[door_color]
		hint_label.add_theme_color_override("font_color", Color(1, 0.7, 0.7))


func _has_required_key() -> bool:
	if not use_key:
		return true
	if not Global:
		return false
	return Global.has_key(door_color)


func _interact():
	if is_open:
		_enter_door()
	else:
		_try_open()


func _try_open():
	if not use_key or _has_required_key():
		_open_door()
	else:
		print("🚪 Заперто! Нужен %s ключ" % COLOR_NAMES[door_color])
		# Эффект тряски
		if animated_sprite:
			var tween = create_tween()
			var pos = animated_sprite.position.x
			tween.tween_property(animated_sprite, "position:x", pos + 3, 0.05)
			tween.tween_property(animated_sprite, "position:x", pos - 6, 0.1)
			tween.tween_property(animated_sprite, "position:x", pos, 0.05)


func _open_door():
	print("🚪 Дверь открыта!")
	is_open = true
	_update_door_state()
	_update_hint()


func _enter_door():
	if target_scene.is_empty():
		print("⚠️ Целевая сцена не указана в Inspector!")
		print("   Установи Target Scene в настройках двери")
		return
	
	print("🚪 Переход: %s" % target_scene)
	print("   spawn_point: %s" % spawn_point_name)
	
	# Сохраняем spawn_point ПЕРЕД переходом
	if Global and not spawn_point_name.is_empty():
		Global.spawn_point = spawn_point_name
		print("   ✅ Global.spawn_point = '%s'" % Global.spawn_point)
	
	# Проверяем существование сцены
	if not ResourceLoader.exists(target_scene):
		print("❌ Сцена не найдена: %s" % target_scene)
		print("   Проверь путь в Target Scene!")
		return
	
	# Переход БЕЗ затемнения (чтобы избежать ошибки)
	get_tree().change_scene_to_file(target_scene)
