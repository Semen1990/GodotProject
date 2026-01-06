# artifact_pickup.gd
extends Area2D

@export var artifact_id: String = "hermes_wings"
@export var float_amplitude: float = 8.0
@export var float_speed: float = 2.0

var initial_position: Vector2

# Ноды
var icon_sprite: Sprite2D
var name_label: Label

func _ready():
	print("✨ Артефакт создан: ", artifact_id)
	initial_position = position
	
	# Удаляем старые дочерние элементы
	for child in get_children():
		if child is Label or child is Sprite2D:
			child.queue_free()
	
	await get_tree().process_frame
	
	# Создаём визуал
	_create_icon()
	_create_name_label()
	_ensure_collision()
	
	# Подключаем сигналы
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	# Анимация парения
	_start_float_animation()

func _create_icon():
	"""Создаёт иконку артефакта"""
	icon_sprite = Sprite2D.new()
	icon_sprite.name = "ArtifactIcon"
	
	# Создаём текстуру - ромб
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var rarity_color = _get_rarity_color()
	
	for x in range(32):
		for y in range(32):
			var center_x = 16
			var center_y = 16
			var dist = abs(x - center_x) + abs(y - center_y)
			
			if dist <= 12:
				image.set_pixel(x, y, rarity_color)
			elif dist <= 14:
				image.set_pixel(x, y, rarity_color.darkened(0.3))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	var texture = ImageTexture.create_from_image(image)
	icon_sprite.texture = texture
	icon_sprite.scale = Vector2(1.5, 1.5)
	
	add_child(icon_sprite)
	
	# Эффект пульсации
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(icon_sprite, "scale", Vector2(1.7, 1.7), 0.5)
	tween.tween_property(icon_sprite, "scale", Vector2(1.5, 1.5), 0.5)

func _create_name_label():
	"""Создаёт название артефакта"""
	if not Global.artifacts_database.has(artifact_id):
		return
	
	var artifact_data = Global.artifacts_database[artifact_id]
	
	name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = artifact_data["name"]
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", _get_rarity_color())
	name_label.position = Vector2(-50, -45)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(100, 20)
	
	add_child(name_label)

func _get_rarity_color() -> Color:
	"""Возвращает цвет по редкости"""
	if not Global.artifacts_database.has(artifact_id):
		return Color.WHITE
	
	var rarity = Global.artifacts_database[artifact_id].get("rarity", "common")
	
	match rarity:
		"common":
			return Color(0.7, 0.7, 0.7, 1.0)
		"rare":
			return Color(0.3, 0.6, 1.0, 1.0)
		"epic":
			return Color(0.8, 0.3, 0.9, 1.0)
		"legendary":
			return Color(1.0, 0.85, 0.0, 1.0)
		_:
			return Color.WHITE

func _ensure_collision():
	"""Создаёт коллизию если её нет"""
	var has_collision = false
	for child in get_children():
		if child is CollisionShape2D:
			has_collision = true
			break
	
	if not has_collision:
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 25
		collision.shape = shape
		add_child(collision)

func _start_float_animation():
	"""Анимация парения"""
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", initial_position.y - float_amplitude, float_speed / 2).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", initial_position.y + float_amplitude, float_speed / 2).set_ease(Tween.EASE_IN_OUT)

func _on_body_entered(body):
	"""Когда игрок касается артефакта"""
	if not body.is_in_group("player") and not body.has_method("apply_artifacts"):
		return
	
	print("✨ Игрок подобрал артефакт: ", artifact_id)
	
	if Global.collect_artifact(artifact_id):
		# Удаляем артефакт БЕЗ эффектов (чтобы не оставался квадратик)
		queue_free()
