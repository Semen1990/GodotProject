extends Area2D
class_name KeyPickup

# ===========================================
# KEY PICKUP - КЛЮЧ (ПРЕФАБ)
# ===========================================
# Путь: res://scripts/objects/KeyPickup.gd

enum KeyColor { GOLD = 0, SILVER = 1, ORANGE = 2, BLUE = 3, GREEN = 4, RED = 5 }

const COLOR_NAMES = {
	KeyColor.GOLD: "Золотой",
	KeyColor.SILVER: "Серебряный",
	KeyColor.ORANGE: "Оранжевый",
	KeyColor.BLUE: "Синий",
	KeyColor.GREEN: "Зелёный",
	KeyColor.RED: "Красный",
}

const COLOR_RGB = {
	KeyColor.GOLD: Color(0.95, 0.85, 0.3),
	KeyColor.SILVER: Color(0.75, 0.75, 0.85),
	KeyColor.ORANGE: Color(1.0, 0.5, 0.1),
	KeyColor.BLUE: Color(0.3, 0.5, 0.95),
	KeyColor.GREEN: Color(0.3, 0.85, 0.3),
	KeyColor.RED: Color(0.95, 0.25, 0.25),
}

@export var key_color: KeyColor = KeyColor.GOLD
@export var float_height: float = 4.0
@export var float_speed: float = 2.5
@export var auto_collect: bool = false  # true = подбирается при касании

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var initial_y: float
var time: float = 0.0
var is_collected: bool = false
var player_in_range: bool = false
var hint_label: Label = null


func _ready():
	initial_y = position.y
	
	# Проверяем: был ли уже подобран?
	if GameState and GameState.is_pickup_collected(name):
		queue_free()
		return
	
	_setup_visual()
	_setup_hint()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	print("🔑 Ключ '%s': %s" % [name, COLOR_NAMES[key_color]])


func _setup_visual():
	if sprite:
		# Простой цветной квадрат (замени на спрайт)
		var img = Image.create(16, 24, false, Image.FORMAT_RGBA8)
		img.fill(COLOR_RGB[key_color])
		sprite.texture = ImageTexture.create_from_image(img)


func _setup_hint():
	hint_label = get_node_or_null("HintLabel")
	if not hint_label and not auto_collect:
		hint_label = Label.new()
		hint_label.name = "HintLabel"
		hint_label.text = "[F] Подобрать"
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_label.position = Vector2(-50, -45)
		hint_label.add_theme_font_size_override("font_size", 12)
		hint_label.add_theme_color_override("font_color", Color.YELLOW)
		add_child(hint_label)
	if hint_label:
		hint_label.visible = false


func _process(delta):
	if is_collected:
		return
	
	# Парение
	time += delta * float_speed
	position.y = initial_y + sin(time) * float_height
	
	# Подбор по кнопке
	if player_in_range and not auto_collect:
		if Input.is_action_just_pressed("interact"):
			_collect()


func _on_body_entered(body: Node2D):
	if is_collected:
		return
	
	if _is_player(body):
		player_in_range = true
		if auto_collect:
			_collect()
		elif hint_label:
			hint_label.visible = true


func _on_body_exited(body: Node2D):
	if _is_player(body):
		player_in_range = false
		if hint_label:
			hint_label.visible = false


func _is_player(body: Node2D) -> bool:
	return body.is_in_group("player") or body.has_method("take_damage")


func _collect():
	if is_collected:
		return
	
	is_collected = true
	
	# Регистрируем в GameState
	if GameState:
		GameState.register_pickup(name)
		GameState.add_key(int(key_color))
	
	print("🔑 Подобран: %s ключ" % COLOR_NAMES[key_color])
	
	_play_collect_effect()


func _play_collect_effect():
	if hint_label:
		hint_label.visible = false
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	var tween = create_tween()
	tween.set_parallel(true)
	if sprite:
		tween.tween_property(sprite, "scale", sprite.scale * 1.5, 0.2)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
		tween.tween_property(sprite, "position:y", sprite.position.y - 20, 0.2)
	tween.chain().tween_callback(queue_free)
