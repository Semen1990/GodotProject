extends Area2D

# ===========================================
# ARTIFACT PICKUP - СИСТЕМА 4: ДИНАМИЧЕСКАЯ ЗАГРУЗКА ЧЕРЕЗ GLOBAL.GD
# ===========================================

@export var artifact_id: String = "hermes_wings"
@export var float_height: float = 10.0
@export var float_speed: float = 2.0

var initial_y: float
var time: float = 0.0
var is_collected: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var label: Label = $Label

func _ready():
	print("🎁 Артефакт создан: ", artifact_id)
	
	# Проверяем, собран ли уже этот артефакт
	if Global and Global.has_method("has_artifact"):
		if Global.has_artifact(artifact_id):
			print("⚠️ Артефакт уже собран, удаляем...")
			queue_free()
			return
	
	# Инициализация позиции для парения
	initial_y = position.y
	
	# Загружаем и настраиваем артефакт
	_setup_artifact()
	
	# Подключаем сигнал
	body_entered.connect(_on_body_entered)

func _setup_artifact():
	"""Настраивает внешний вид артефакта на основе данных из Global.gd"""
	# Проверяем, существует ли Global и база данных
	if not Global:
		print("❌ Global не найден, использование запасного варианта")
		_set_fallback_visuals()
		return
	
	# Получаем данные об артефакте из Global
	var artifact_data = Global.get_artifact_data(artifact_id)
	
	if artifact_data:
		# 1. Настраиваем иконку (спрайт)
		_setup_sprite_from_global(artifact_data)
		
		# 2. Настраиваем название
		_setup_label_from_global(artifact_data)
		
		# 3. Настраиваем цвет названия по редкости
		if artifact_data.has("rarity"):
			_set_label_color_by_rarity(artifact_data["rarity"])
		else:
			label.modulate = Color.WHITE
	else:
		print("⚠️ Данные артефакта не найдены в Global, ID: ", artifact_id)
		_set_fallback_visuals()

func _setup_sprite_from_global(artifact_data: Dictionary):
	"""Устанавливает иконку из данных Global"""
	if artifact_data.has("icon"):
		var icon_path = artifact_data["icon"]
		if icon_path and icon_path != "":
			var texture = load(icon_path)
			if texture:
				sprite.texture = texture
				print("✅ Загружена иконка: ", icon_path)
				return
	
	# Если не удалось загрузить иконку
	print("⚠️ Не удалось загрузить иконку для ", artifact_id)
	_create_color_sprite_by_rarity(artifact_data.get("rarity", "common"))

func _setup_label_from_global(artifact_data: Dictionary):
	"""Устанавливает название из данных Global"""
	if artifact_data.has("name"):
		label.text = artifact_data["name"]
	elif artifact_data.has("display_name"):
		label.text = artifact_data["display_name"]
	else:
		# Преобразуем ID в читаемое имя
		var readable_name = artifact_id.capitalize().replace("_", " ")
		label.text = readable_name

func _create_color_sprite_by_rarity(rarity: String):
	"""Создает цветной спрайт в зависимости от редкости"""
	var color: Color
	
	match rarity:
		"common":
			color = Color(0.7, 0.7, 0.7)  # Серый
		"rare":
			color = Color(0.2, 0.5, 1.0)  # Синий
		"epic":
			color = Color(0.8, 0.2, 0.8)  # Фиолетовый
		"legendary":
			color = Color(1.0, 0.8, 0.0)  # Золотой
		_:
			color = Color(1.0, 0.5, 0.0)  # Оранжевый по умолчанию
	
	# Создаём цветной круг
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	print("🎨 Создана цветная иконка для редкости: ", rarity)

func _set_label_color_by_rarity(rarity: String):
	"""Устанавливает цвет текста по редкости"""
	match rarity:
		"common":
			label.modulate = Color(0.7, 0.7, 0.7)  # Серый
		"rare":
			label.modulate = Color(0.2, 0.5, 1.0)  # Синий
		"epic":
			label.modulate = Color(0.8, 0.2, 0.8)  # Фиолетовый
		"legendary":
			label.modulate = Color(1.0, 0.8, 0.0)  # Золотой
		_:
			label.modulate = Color.WHITE

func _set_fallback_visuals():
	"""Запасные визуальные эффекты если Global недоступен"""
	print("🛠️ Используем запасные визуальные эффекты")
	
	# Создаем цветную иконку на основе ID
	var hash_color = _string_to_color(artifact_id)
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(hash_color)
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	
	# Устанавливаем название
	label.text = artifact_id.capitalize().replace("_", " ")
	label.modulate = Color.WHITE

func _string_to_color(text: String) -> Color:
	"""Преобразует строку в цвет (для запасного варианта)"""
	var hash = text.hash()
	var r = float((hash >> 16) & 0xFF) / 255.0
	var g = float((hash >> 8) & 0xFF) / 255.0
	var b = float(hash & 0xFF) / 255.0
	return Color(r, g, b)

func _process(delta):
	# Анимация парения (только если не собран)
	if not is_collected:
		time += delta * float_speed
		position.y = initial_y + sin(time) * float_height

func _on_body_entered(body):
	"""Обработка столкновения с игроком"""
	if is_collected:
		return
	
	# Проверяем что это игрок
	if not (body.is_in_group("player") or body.has_method("take_damage")):
		return
	
	print("🎁 Игрок подбирает артефакт: ", artifact_id)
	
	# Проверяем, собран ли уже этот артефакт
	if Global and Global.has_method("has_artifact"):
		if Global.has_artifact(artifact_id):
			print("⚠️ Артефакт уже собран (навсегда)")
			queue_free()
			return
	
	# Собираем артефакт через Global
	if Global and Global.has_method("collect_artifact"):
		var success = Global.collect_artifact(artifact_id)
		if success:
			print("✅ Артефакт навсегда добавлен игроку!")
			_collect_artifact_effect()
		else:
			print("❌ Ошибка при сборе артефакта")
	else:
		print("❌ Global или метод collect_artifact не найден")
		# Запасной вариант - просто собираем
		_collect_artifact_effect()

func _collect_artifact_effect():
	"""Визуальный эффект при подборе"""
	is_collected = true
	
	# Отключаем коллизию
	if collision:
		collision.set_deferred("disabled", true)
	
	# Эффект увеличения и исчезновения
	var tween = create_tween()
	tween.tween_property(sprite, "scale", sprite.scale * 1.5, 0.3)
	tween.parallel().tween_property(sprite, "modulate:a", 0, 0.3)
	tween.parallel().tween_property(label, "modulate:a", 0, 0.3)
	tween.tween_callback(queue_free)
	
	# Визуальная обратная связь
	print("✨ Артефакт подобран: ", label.text)

# Функции для отладки
func print_artifact_info():
	"""Выводит информацию об артефакте в консоль"""
	print("=== ARTIFACT INFO ===")
	print("ID:", artifact_id)
	print("Position:", position)
	print("Global exists:", Global != null)
	
	if Global and Global.has_method("get_artifact_data"):
		var data = Global.get_artifact_data(artifact_id)
		if data:
			print("Name:", data.get("name", "N/A"))
			print("Rarity:", data.get("rarity", "N/A"))
			print("Ability:", data.get("ability", "N/A"))
	print("=====================")
