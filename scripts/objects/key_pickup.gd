extends Area2D
class_name KeyPickup

# ===========================================
# КЛЮЧ - ПОДБИРАЕМЫЙ ПРЕДМЕТ v2
# ===========================================
# Путь: res://scripts/objects/key_pickup.gd

enum KeyColor {
	GOLD,      # 0
	SILVER,    # 1
	ORANGE,    # 2
	BLUE,      # 3
	GREEN,     # 4
	RED        # 5
}

const KEY_NAMES = {
	KeyColor.GOLD: "Золотой ключ",
	KeyColor.SILVER: "Серебряный ключ",
	KeyColor.ORANGE: "Оранжевый ключ",
	KeyColor.BLUE: "Синий ключ",
	KeyColor.GREEN: "Зелёный ключ",
	KeyColor.RED: "Красный ключ",
}

const KEY_COLORS_RGB = {
	KeyColor.GOLD: Color(0.9, 0.75, 0.4),
	KeyColor.SILVER: Color(0.75, 0.75, 0.8),
	KeyColor.ORANGE: Color(1.0, 0.5, 0.1),
	KeyColor.BLUE: Color(0.3, 0.6, 0.9),
	KeyColor.GREEN: Color(0.5, 0.9, 0.2),
	KeyColor.RED: Color(0.9, 0.3, 0.2),
}

# === НАСТРОЙКИ ===
@export var key_color: KeyColor = KeyColor.GOLD
@export var sprite_scale: float = 1.0
@export var float_height: float = 4.0
@export var float_speed: float = 2.5

# === УЗЛЫ ===
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var label: Label = $Label

var hint_label: Label = null
var initial_y: float
var time: float = 0.0
var is_collected: bool = false
var player_in_range: bool = false


func _ready():
	print("🔑 Ключ создан: %s" % KEY_NAMES[key_color])
	
	initial_y = position.y
	
	_setup_sprite()
	_ensure_hint_label()
	_setup_label()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _setup_sprite():
	if not sprite:
		return
	
	var paths = [
		"res://assets/items/keys.png",
		"res://assets/sprites/keys.png",
		"res://assets/keys.png",
	]
	
	var texture: Texture2D = null
	for path in paths:
		if ResourceLoader.exists(path):
			texture = load(path)
			break
	
	if not texture:
		_create_fallback_sprite()
		return
	
	var key_height = texture.get_height() / 6
	var key_width = texture.get_width()
	
	var atlas = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(0, key_color * key_height, key_width, key_height)
	
	sprite.texture = atlas
	sprite.scale = Vector2(sprite_scale, sprite_scale)


func _create_fallback_sprite():
	if not sprite:
		return
	
	var color = KEY_COLORS_RGB[key_color]
	var image = Image.create(32, 16, false, Image.FORMAT_RGBA8)
	image.fill(color)
	
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.scale = Vector2(sprite_scale, sprite_scale)


func _setup_label():
	if label:
		label.text = KEY_NAMES[key_color]
		label.modulate = KEY_COLORS_RGB[key_color]


func _ensure_hint_label():
	hint_label = get_node_or_null("HintLabel")
	
	if not hint_label:
		hint_label = Label.new()
		hint_label.name = "HintLabel"
		hint_label.text = "Нажми F"
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_label.position = Vector2(-35, -40)
		hint_label.add_theme_font_size_override("font_size", 12)
		hint_label.add_theme_color_override("font_color", Color(1, 1, 0.7))
		add_child(hint_label)
	
	hint_label.visible = false


func _process(delta):
	if not is_collected:
		time += delta * float_speed
		position.y = initial_y + sin(time) * float_height
	
	if player_in_range and not is_collected:
		if Input.is_action_just_pressed("interact"):
			_collect_key()


func _on_body_entered(body: Node2D):
	if is_collected:
		return
	if not _is_player(body):
		return
	
	player_in_range = true
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


func _collect_key():
	if is_collected:
		return
	
	if Global:
		Global.add_key(key_color)
		print("🔑 Подобран: %s" % KEY_NAMES[key_color])
	
	_play_collect_effect()


func _play_collect_effect():
	is_collected = true
	
	if hint_label:
		hint_label.visible = false
	
	if collision:
		collision.set_deferred("disabled", true)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	if sprite:
		tween.tween_property(sprite, "scale", sprite.scale * 1.3, 0.25)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
	
	if label:
		tween.tween_property(label, "modulate:a", 0.0, 0.25)
	
	tween.chain().tween_callback(queue_free)
