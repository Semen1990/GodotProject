# artifact_pickup.gd
extends Area2D

@export var artifact_id: String = "hermes_wings"  # ID артефакта из базы данных
@export var float_amplitude: float = 10.0  # Амплитуда парения
@export var float_speed: float = 2.0  # Скорость парения
@export var rotate_speed: float = 1.0  # Скорость вращения

var initial_position: Vector2
var time: float = 0.0

@onready var sprite = $Sprite2D
@onready var particles = $GPUParticles2D  # Опционально
@onready var label = $Label  # Название артефакта

func _ready():
	print("✨ Артефакт создан: ", artifact_id)
	initial_position = position
	
	# Настраиваем отображение
	setup_artifact_display()
	
	# Подключаем сигналы
	body_entered.connect(_on_body_entered)
	
	# Запускаем анимацию
	start_float_animation()

func setup_artifact_display():
	"""Настраивает визуал артефакта"""
	if not Global.artifacts_database.has(artifact_id):
		print("❌ Артефакт не найден: ", artifact_id)
		return
	
	var artifact_data = Global.artifacts_database[artifact_id]
	
	# Устанавливаем название
	if label:
		label.text = artifact_data["name"]
		label.modulate = get_rarity_color(artifact_data["rarity"])
	
	# Цвет спрайта по редкости
	if sprite:
		sprite.modulate = get_rarity_color(artifact_data["rarity"])

func get_rarity_color(rarity: String) -> Color:
	"""Возвращает цвет по редкости"""
	match rarity:
		"common":
			return Color.GRAY
		"rare":
			return Color.DODGER_BLUE
		"epic":
			return Color.PURPLE
		"legendary":
			return Color.GOLD
		_:
			return Color.WHITE

func start_float_animation():
	"""Запускает анимацию парения"""
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", initial_position.y - float_amplitude, float_speed / 2)
	tween.tween_property(self, "position:y", initial_position.y + float_amplitude, float_speed / 2)

func _process(delta):
	# Вращение
	if sprite:
		sprite.rotation += rotate_speed * delta
	
	time += delta

func _on_body_entered(body):
	"""Когда игрок подбирает артефакт"""
	print("🎯 Тело вошло: ", body.name)
	
	# Проверяем что это игрок
	if body.has_method("apply_artifacts"):
		collect_artifact(body)

func collect_artifact(player):
	"""Собираем артефакт"""
	print("✨ Игрок подобрал артефакт: ", artifact_id)
	
	# Добавляем артефакт в Global
	if Global.collect_artifact(artifact_id):
		# Показываем уведомление
		show_collection_notification()
		
		# Удаляем артефакт со сцены
		queue_free()
	else:
		print("⚠️ Артефакт уже был собран")

func show_collection_notification():
	"""Показывает уведомление о получении"""
	if not Global.artifacts_database.has(artifact_id):
		return
	
	var artifact_data = Global.artifacts_database[artifact_id]
	
	# Создаём всплывающий текст
	var notification = Label.new()
	notification.text = "Получен: " + artifact_data["name"] + "\n" + artifact_data["effect_text"]
	notification.modulate = get_rarity_color(artifact_data["rarity"])
	notification.add_theme_font_size_override("font_size", 20)
	notification.position = global_position - Vector2(100, 50)
	
	get_tree().current_scene.add_child(notification)
	
	# Анимация исчезновения
	var tween = create_tween()
	tween.tween_property(notification, "position:y", notification.position.y - 100, 2.0)
	tween.parallel().tween_property(notification, "modulate:a", 0.0, 2.0)
	tween.tween_callback(notification.queue_free)
