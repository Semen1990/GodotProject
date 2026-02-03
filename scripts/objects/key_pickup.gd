extends Area2D
class_name KeyPickup

# ===========================================
# KEY PICKUP v5.0 - АВТООПРЕДЕЛЕНИЕ РАЗМЕРОВ
# ===========================================
# Спрайт-лист: res://assets/items/keys.png
# 6 ключей вертикально, автоматически определяет размеры

signal collected(key_color: int)

enum KeyColor { 
	GOLD = 0,    # Золотой
	SILVER = 1,  # Серебряный  
	RED = 2,     # Красный/Оранжевый
	BLUE = 3,    # Синий
	GREEN = 4,   # Зелёный
	PURPLE = 5   # Розовый/Фиолетовый
}

const COLOR_NAMES = {
	KeyColor.GOLD: "Золотой",
	KeyColor.SILVER: "Серебряный",
	KeyColor.RED: "Красный",
	KeyColor.BLUE: "Синий",
	KeyColor.GREEN: "Зелёный",
	KeyColor.PURPLE: "Фиолетовый",
}

@export var key_color: KeyColor = KeyColor.GOLD
@export var float_height: float = 4.0
@export var float_speed: float = 2.5
@export var auto_collect: bool = false  # ПО УМОЛЧАНИЮ ВЫКЛЮЧЕН!
@export var sprite_scale: float = 0.4   # Масштаб спрайта (ключи большие)

var sprite: Sprite2D = null
var hint_label: Label = null

var initial_y: float = 0.0
var time: float = 0.0
var player_in_range: bool = false
var is_collected: bool = false


func _ready():
	sprite = get_node_or_null("Sprite2D")
	hint_label = get_node_or_null("HintLabel")
	
	initial_y = position.y
	
	# Проверяем: уже подобран?
	if Global and Global.is_pickup_collected(name):
		print("🔑 Ключ '%s' уже подобран" % name)
		queue_free()
		return
	
	# Настраиваем collision - ВАЖНО: видим игрока на layer 2!
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(4, true)  # Layer 4 (items)
	set_collision_mask_value(2, true)   # Mask 2 (player)
	monitoring = true
	monitorable = true
	
	# Подключаем сигналы
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	
	# Настраиваем спрайт
	_setup_sprite()
	
	# Настраиваем подсказку
	_setup_hint()
	
	print("🔑 Ключ '%s': %s (sprite=%s)" % [name, COLOR_NAMES[key_color], "✅" if sprite and sprite.texture else "❌"])


func _setup_hint():
	"""Настраивает подсказку [F] Подобрать"""
	if not hint_label:
		hint_label = Label.new()
		hint_label.name = "HintLabel"
		add_child(hint_label)
	
	hint_label.text = "[F] Подобрать"
	hint_label.position = Vector2(-45, -50)
	hint_label.visible = false
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color.WHITE)


func _setup_sprite():
	"""Настраивает спрайт ключа из спрайт-листа"""
	if not sprite:
		# Создаём спрайт если его нет
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
		move_child(sprite, 0)  # Спрайт первым
	
	# Путь к спрайт-листу
	var keys_texture_path = "res://assets/items/keys.png"
	
	if not ResourceLoader.exists(keys_texture_path):
		print("⚠️ Спрайт-лист не найден: %s" % keys_texture_path)
		_create_fallback_sprite()
		return
	
	var full_texture = load(keys_texture_path) as Texture2D
	
	if not full_texture:
		print("⚠️ Не удалось загрузить текстуру")
		_create_fallback_sprite()
		return
	
	# Получаем размеры текстуры
	var tex_size = full_texture.get_size()
	print("🔑 Текстура keys.png: %dx%d" % [int(tex_size.x), int(tex_size.y)])
	
	# Вычисляем размер одного ключа (6 ключей вертикально)
	var key_height = tex_size.y / 6.0
	var key_width = tex_size.x
	
	# Создаём AtlasTexture для вырезания нужного ключа
	var atlas = AtlasTexture.new()
	atlas.atlas = full_texture
	
	# Вычисляем регион для выбранного цвета
	var color_index = int(key_color)
	var region_y = key_height * color_index
	atlas.region = Rect2(0, region_y, key_width, key_height)
	
	# Применяем текстуру
	sprite.texture = atlas
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	
	print("🔑 Текстура загружена: %s (y=%d, h=%d, scale=%.1f)" % [
		COLOR_NAMES[key_color], 
		int(region_y), 
		int(key_height),
		sprite_scale
	])


func _create_fallback_sprite():
	"""Создаёт запасной спрайт если текстура не найдена"""
	var colors = {
		KeyColor.GOLD: Color(1.0, 0.85, 0.0),
		KeyColor.SILVER: Color(0.75, 0.75, 0.8),
		KeyColor.RED: Color(1.0, 0.4, 0.2),
		KeyColor.BLUE: Color(0.3, 0.6, 1.0),
		KeyColor.GREEN: Color(0.3, 0.9, 0.3),
		KeyColor.PURPLE: Color(0.9, 0.3, 0.6),
	}
	
	# Создаём изображение ключа (простая форма)
	var size = 32
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var color = colors.get(key_color, Color.YELLOW)
	
	# Рисуем простой ключ
	for x in range(size):
		for y in range(size):
			# Ручка ключа (круг)
			var cx = size * 0.7
			var cy = size * 0.3
			var dist = sqrt(pow(x - cx, 2) + pow(y - cy, 2))
			if dist < size * 0.25 and dist > size * 0.15:
				image.set_pixel(x, y, color)
			# Стержень ключа
			elif x > size * 0.2 and x < size * 0.5 and y > size * 0.25 and y < size * 0.35:
				image.set_pixel(x, y, color)
			# Зубцы
			elif x < size * 0.3 and y > size * 0.35 and y < size * 0.5:
				image.set_pixel(x, y, color)
	
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	sprite.scale = Vector2(1.5, 1.5)
	print("🔑 Fallback спрайт: %s" % COLOR_NAMES[key_color])


func _process(delta):
	if is_collected:
		return
	
	# Парение
	time += delta * float_speed
	position.y = initial_y + sin(time) * float_height
	
	# Подбор по F
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
	var color_int = int(key_color)
	
	# Регистрируем
	if Global:
		Global.register_collected_pickup(name)
		Global.add_key(color_int)
	
	print("🔑 Подобран: %s ключ" % COLOR_NAMES[key_color])
	collected.emit(color_int)
	
	_play_collect_effect()


func _play_collect_effect():
	if hint_label:
		hint_label.visible = false
	
	set_deferred("monitoring", false)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	if sprite:
		tween.tween_property(sprite, "scale", sprite.scale * 1.5, 0.2)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
		tween.tween_property(sprite, "position:y", sprite.position.y - 20, 0.2)
	else:
		tween.tween_property(self, "modulate:a", 0.0, 0.2)
	
	tween.chain().tween_callback(queue_free)
