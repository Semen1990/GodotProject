extends Area2D
class_name Door

# ===========================================
# DOOR - ДВЕРЬ (ПРЕФАБ)
# ===========================================
# Путь: res://scripts/objects/Door.gd
#
# Использует GameState для:
# - Проверки ключей
# - Регистрации открытия
# - Сохранения состояния при переходе

enum DoorColor { GOLD = 0, SILVER = 1, ORANGE = 2, BLUE = 3, GREEN = 4, RED = 5 }

const COLOR_NAMES = {
	DoorColor.GOLD: "золотой",
	DoorColor.SILVER: "серебряный",
	DoorColor.ORANGE: "оранжевый",
	DoorColor.BLUE: "синий",
	DoorColor.GREEN: "зелёный",
	DoorColor.RED: "красный",
}

const COLOR_RGB = {
	DoorColor.GOLD: Color(0.95, 0.8, 0.3),
	DoorColor.SILVER: Color(0.75, 0.75, 0.85),
	DoorColor.ORANGE: Color(1.0, 0.5, 0.1),
	DoorColor.BLUE: Color(0.3, 0.5, 0.95),
	DoorColor.GREEN: Color(0.3, 0.85, 0.3),
	DoorColor.RED: Color(0.95, 0.25, 0.25),
}

@export var door_color: DoorColor = DoorColor.GOLD
@export var target_scene: String = ""
@export var spawn_point_id: String = ""       # ID точки спавна на целевом уровне
@export var requires_key: bool = true
@export var consumes_key: bool = true
@export var is_initially_open: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var is_open: bool = false
var player_in_range: bool = false
var hint_label: Label = null


func _ready():
	is_open = is_initially_open
	
	# Проверяем сохранённое состояние
	if GameState and GameState.is_door_opened(name):
		is_open = true
	
	_setup_hint()
	_update_visual()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	print("🚪 Дверь '%s': цвет=%s, требует_ключ=%s, открыта=%s" % [
		name, COLOR_NAMES[door_color], requires_key, is_open
	])


func _setup_hint():
	hint_label = get_node_or_null("HintLabel")
	if not hint_label:
		hint_label = Label.new()
		hint_label.name = "HintLabel"
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_label.position = Vector2(-70, -90)
		hint_label.add_theme_font_size_override("font_size", 14)
		add_child(hint_label)
	hint_label.visible = false


func _update_visual():
	# Анимация
	if animated_sprite and animated_sprite.sprite_frames:
		var anim = "open" if is_open else "idle"
		if animated_sprite.sprite_frames.has_animation(anim):
			animated_sprite.play(anim)
	
	# Цветовой индикатор (если есть)
	var indicator = get_node_or_null("ColorIndicator")
	if indicator:
		indicator.color = COLOR_RGB[door_color]
		indicator.color.a = 0.5 if is_open else 1.0


func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		_interact()


func _on_body_entered(body: Node2D):
	if _is_player(body):
		player_in_range = true
		_update_hint()
		hint_label.visible = true


func _on_body_exited(body: Node2D):
	if _is_player(body):
		player_in_range = false
		hint_label.visible = false


func _is_player(body: Node2D) -> bool:
	return body.is_in_group("player") or body.has_method("take_damage")


func _update_hint():
	if not hint_label:
		return
	
	if is_open:
		hint_label.text = "[F] Войти"
		hint_label.add_theme_color_override("font_color", Color(0.7, 1, 0.7))
	elif not requires_key:
		hint_label.text = "[F] Открыть"
		hint_label.add_theme_color_override("font_color", Color.YELLOW)
	elif _has_key():
		hint_label.text = "[F] Открыть (%s)" % COLOR_NAMES[door_color]
		hint_label.add_theme_color_override("font_color", Color(0.7, 1, 0.7))
	else:
		hint_label.text = "Нужен %s ключ" % COLOR_NAMES[door_color]
		hint_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))


func _has_key() -> bool:
	if GameState:
		return GameState.has_key(int(door_color))
	return false


func _interact():
	if is_open:
		_enter_door()
	else:
		_try_open()


func _try_open():
	if not requires_key:
		_open()
		return
	
	if _has_key():
		if consumes_key and GameState:
			GameState.remove_key(int(door_color))
		_open()
	else:
		_shake()
		print("🚪 Нужен %s ключ!" % COLOR_NAMES[door_color])


func _open():
	is_open = true
	
	# Регистрируем в GameState
	if GameState:
		GameState.register_door_opened(name)
	
	_update_visual()
	_update_hint()
	print("🚪 Дверь '%s' открыта" % name)


func _shake():
	if animated_sprite:
		var tween = create_tween()
		var pos = animated_sprite.position.x
		tween.tween_property(animated_sprite, "position:x", pos + 4, 0.05)
		tween.tween_property(animated_sprite, "position:x", pos - 8, 0.1)
		tween.tween_property(animated_sprite, "position:x", pos + 4, 0.1)
		tween.tween_property(animated_sprite, "position:x", pos, 0.05)


func _enter_door():
	if target_scene.is_empty():
		push_warning("🚪 Целевая сцена не указана!")
		return
	
	if not ResourceLoader.exists(target_scene):
		push_error("🚪 Сцена не найдена: %s" % target_scene)
		return
	
	print("🚪 Переход: %s → %s (spawn: %s)" % [name, target_scene, spawn_point_id])
	
	# Сохраняем состояние
	var level = get_tree().current_scene
	if level and level.has_method("save_before_transition"):
		level.save_before_transition()
	
	# Подготавливаем переход
	if GameState:
		GameState.prepare_level_transition(target_scene, spawn_point_id)
	
	# Переходим
	get_tree().change_scene_to_file(target_scene)
