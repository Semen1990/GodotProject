# artifact_pickup.gd
extends Area2D

# ===========================================
# ARTIFACT PICKUP - ИСПРАВЛЕННАЯ ВЕРСИЯ v3
# ===========================================

@export var artifact_id: String = "hermes_wings"
@export var float_amplitude: float = 8.0
@export var float_speed: float = 2.0

var initial_position: Vector2
var is_collected: bool = false

# Ноды
var icon_sprite: Sprite2D
var name_label: Label

# Кэш для базы данных артефактов
var artifacts_db_cache = null
var collected_artifacts_cache = []

func _ready():
	print("✨ Артефакт создан: ", artifact_id)
	initial_position = position
	
	# Кэшируем данные из Global
	_cache_global_data()
	
	# Проверяем - если артефакт уже собран, НЕ создаём визуал
	if _is_artifact_already_collected():
		print("⚠️ Артефакт ", artifact_id, " уже собран, скрываем...")
		_hide_and_disable()
		return
	
	# Удаляем старые дочерние элементы
	_cleanup_old_children()
	
	await get_tree().process_frame
	
	# Создаём визуал
	_create_icon()
	_create_name_label()
	_ensure_collision()
	
	# Подключаем сигналы
	_connect_signals()
	
	# Анимация парения
	_start_float_animation()

func _cache_global_data():
	"""Кэширует данные из Global для быстрого доступа"""
	if is_instance_valid(Global):
		artifacts_db_cache = Global.get("artifacts_database")
		collected_artifacts_cache = Global.get("collected_artifacts")
		
		# Убеждаемся что это массив
		if collected_artifacts_cache == null or not (collected_artifacts_cache is Array):
			collected_artifacts_cache = []

func _is_artifact_already_collected() -> bool:
	"""Проверяет, был ли уже собран этот артефакт"""
	if collected_artifacts_cache == null:
		return false
	
	return artifact_id in collected_artifacts_cache

func _cleanup_old_children():
	"""Очищает старые дочерние элементы"""
	for child in get_children():
		if child is Label or child is Sprite2D or child is CollisionShape2D:
			child.free()

func _connect_signals():
	"""Подключает сигналы"""
	if body_entered.is_connected(_on_body_entered):
		body_entered.disconnect(_on_body_entered)
	body_entered.connect(_on_body_entered)

func _hide_and_disable():
	"""Скрывает и отключает артефакт если он уже собран"""
	is_collected = true
	visible = false
	
	# Отключаем коллизию
	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
			break
	
	# Отключаем мониторинг Area2D
	monitoring = false
	monitorable = false

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
	var artifact_name = _get_artifact_name()
	var rarity_color = _get_rarity_color()
	
	name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = artifact_name
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", rarity_color)
	name_label.position = Vector2(-50, -45)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(100, 20)
	
	add_child(name_label)

func _get_artifact_name() -> String:
	"""Возвращает название артефакта"""
	if artifacts_db_cache != null and artifacts_db_cache.has(artifact_id):
		return artifacts_db_cache[artifact_id].get("name", artifact_id)
	return artifact_id

func _get_rarity_color() -> Color:
	"""Возвращает цвет по редкости"""
	var rarity = "common"
	
	if artifacts_db_cache != null and artifacts_db_cache.has(artifact_id):
		rarity = artifacts_db_cache[artifact_id].get("rarity", "common")
	
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
	
	# Правильный синтаксис для Godot 4.x
	tween.tween_property(self, "position", Vector2(position.x, initial_position.y - float_amplitude), float_speed / 2).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", Vector2(position.x, initial_position.y + float_amplitude), float_speed / 2).set_ease(Tween.EASE_IN_OUT)

func _on_body_entered(body):
	"""Когда игрок касается артефакта"""
	if is_collected:
		return
	
	if not body.is_in_group("player") and not body.has_method("apply_artifacts"):
		return
	
	print("✨ Игрок подобрал артефакт: ", artifact_id)
	
	# Проверяем ещё раз перед сбором
	if _is_artifact_already_collected():
		print("⚠️ Артефакт уже собран, скрываем")
		_hide_and_disable()
		return
	
	# Пытаемся собрать
	if is_instance_valid(Global) and Global.has_method("collect_artifact"):
		if Global.collect_artifact(artifact_id):
			print("✅ Артефакт ", artifact_id, " успешно собран!")
			is_collected = true
			
			# Обновляем кэш
			_cache_global_data()
			
			# Эффект исчезновения
			_play_pickup_effect()
			
			# Применяем к игроку если есть метод
			if body.has_method("apply_artifacts"):
				body.apply_artifacts()
		else:
			print("❌ Не удалось собрать артефакт: ", artifact_id)
	else:
		print("❌ Global невалиден или нет метода collect_artifact")

func _play_pickup_effect():
	"""Эффект при подборе"""
	if icon_sprite:
		var tween = create_tween()
		tween.tween_property(icon_sprite, "scale", Vector2(2.0, 2.0), 0.2)
		tween.tween_property(icon_sprite, "modulate:a", 0.0, 0.2)
		tween.tween_callback(func(): if is_instance_valid(self): queue_free())
