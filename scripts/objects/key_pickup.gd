extends Area2D
class_name KeyPickup

# ===========================================
# KEY PICKUP v4.0 - ВИДИМЫЙ КЛЮЧ, ПОДБОР ПО F
# ===========================================
# Использует спрайт-лист res://assets/items/keys.png
# Подбирается ТОЛЬКО по клавише F (не автоматически!)

signal collected(key_color: int)

enum KeyColor { 
	GOLD = 0,    # Золотой
	SILVER = 1,  # Серебряный  
	RED = 2,     # Красный
	BLUE = 3,    # Синий
	GREEN = 4,   # Зелёный
	PURPLE = 5   # Фиолетовый
}

const COLOR_NAMES = {
	KeyColor.GOLD: "Золотой",
	KeyColor.SILVER: "Серебряный",
	KeyColor.RED: "Красный",
	KeyColor.BLUE: "Синий",
	KeyColor.GREEN: "Зелёный",
	KeyColor.PURPLE: "Фиолетовый",
}

# Регионы в спрайт-листе keys.png (64x384)
# Ключи расположены ВЕРТИКАЛЬНО (в столбец), каждый ~64x64
# Порядок сверху вниз: Gold, Silver, Orange/Red, Blue, Green, Pink/Purple
const KEY_REGIONS = {
	KeyColor.GOLD: Rect2(0, 0, 64, 64),       # 1-й сверху - золотой
	KeyColor.SILVER: Rect2(0, 64, 64, 64),    # 2-й - серебряный
	KeyColor.RED: Rect2(0, 128, 64, 64),      # 3-й - оранжевый/красный
	KeyColor.BLUE: Rect2(0, 192, 64, 64),     # 4-й - синий
	KeyColor.GREEN: Rect2(0, 256, 64, 64),    # 5-й - зелёный
	KeyColor.PURPLE: Rect2(0, 320, 64, 64),   # 6-й - розовый/фиолетовый
}

@export var key_color: KeyColor = KeyColor.GOLD
@export var float_height: float = 4.0
@export var float_speed: float = 2.5
@export var auto_collect: bool = false  # ПО УМОЛЧАНИЮ ВЫКЛЮЧЕН!

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
	
	# Подключаем сигналы
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	
	# Настраиваем спрайт
	_setup_sprite()
	
	if hint_label:
		hint_label.visible = false
		hint_label.text = "[F] Подобрать"
	
	print("🔑 Ключ '%s': %s (sprite=%s)" % [name, COLOR_NAMES[key_color], "✅" if sprite and sprite.texture else "❌"])


func _setup_sprite():
	"""Настраивает спрайт ключа из спрайт-листа"""
	if not sprite:
		# Создаём спрайт если его нет
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	
	# Загружаем спрайт-лист
	var keys_texture_path = "res://assets/items/keys.png"
	if ResourceLoader.exists(keys_texture_path):
		var full_texture = load(keys_texture_path) as Texture2D
		
		if full_texture:
			# Создаём AtlasTexture для вырезания нужного ключа
			var atlas = AtlasTexture.new()
			atlas.atlas = full_texture
			atlas.region = KEY_REGIONS.get(key_color, Rect2(0, 0, 40, 40))
			sprite.texture = atlas
			print("🔑 Текстура загружена: %s" % COLOR_NAMES[key_color])
	else:
		print("⚠️ Спрайт-лист ключей не найден: %s" % keys_texture_path)
		# Fallback - цветной квадрат
		_create_fallback_sprite()


func _create_fallback_sprite():
	"""Создаёт запасной спрайт если текстура не найдена"""
	var colors = {
		KeyColor.GOLD: Color(1.0, 0.85, 0.0),
		KeyColor.SILVER: Color(0.75, 0.75, 0.8),
		KeyColor.RED: Color(1.0, 0.2, 0.2),
		KeyColor.BLUE: Color(0.2, 0.5, 1.0),
		KeyColor.GREEN: Color(0.2, 0.8, 0.2),
		KeyColor.PURPLE: Color(0.7, 0.2, 0.9),
	}
	
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var color = colors.get(key_color, Color.YELLOW)
	image.fill(color)
	
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture


func _process(delta):
	if is_collected:
		return
	
	# Парение
	time += delta * float_speed
	position.y = initial_y + sin(time) * float_height
	
	# Подбор
	if player_in_range:
		if auto_collect:
			_collect()
		elif Input.is_action_just_pressed("interact"):
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
