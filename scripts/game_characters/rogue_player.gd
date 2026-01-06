extends "res://scripts/game_characters/base_game_character.gd"

var slide_cooldown: float = 0.0
var slide_timer: float = 0.0
var slide_direction: float = 0.0

# НАСТРОЙКИ ПОДКАТА
const SLIDE_DURATION: float = 0.6  # УВЕЛИЧЕНО: длительность подката
const SLIDE_SPEED_MULTIPLIER: float = 2.5  # УВЕЛИЧЕНО: множитель скорости
const SLIDE_COOLDOWN: float = 2.0  # Кулдаун
const SLIDE_ANIMATION_SPEED: float = 1.0  # Скорость анимации (1.0 = нормальная, 0.5 = медленнее)

func _ready():
	character_name = "Разбойник"
	max_health = 90
	current_health = 90
	max_mana = 30
	current_mana = 30
	armor = 2
	jump_velocity = -450
	base_speed = 280
	current_speed = 280
	max_speed = 280.0
	
	print("🗡️ Разбойник скрывается в тени!")
	super()

func _physics_process(delta):
	if slide_cooldown > 0:
		slide_cooldown -= delta
	
	# Управление подкатом
	if is_sliding:
		slide_timer -= delta
		
		# Двигаем персонажа в направлении подката
		velocity.x = slide_direction * base_speed * SLIDE_SPEED_MULTIPLIER
		
		# Завершаем подкат
		if slide_timer <= 0:
			_end_slide()
	
	super(delta)

func slide():
	print("\n=== 🔽 ПОПЫТКА ПОДКАТА ===")
	print("Скорость X: ", velocity.x)
	print("На земле: ", is_on_floor())
	
	# Проверяем что персонаж движется
	if abs(velocity.x) < 10.0:
		print("❌ Нужно двигаться для подката!")
		return
	
	if not is_on_floor():
		print("❌ Нужно быть на земле!")
		return
	
	if is_dead or is_attacking or is_blocking or is_sliding or is_casting:
		print("❌ Персонаж занят!")
		return
	
	if slide_cooldown > 0:
		print("❌ Подкат на кулдауне! Осталось: %.1f сек" % slide_cooldown)
		return
	
	# Начинаем подкат
	_start_slide()

func _start_slide():
	is_sliding = true
	slide_timer = SLIDE_DURATION
	slide_cooldown = SLIDE_COOLDOWN
	
	# Запоминаем направление движения
	slide_direction = sign(velocity.x)
	if slide_direction == 0:
		slide_direction = 1 if not animated_sprite.flip_h else -1
	
	print("\n🔽 === ПОДКАТ НАЧАТ ===")
	print("Направление: ", "→" if slide_direction > 0 else "←")
	print("Скорость: ", base_speed * SLIDE_SPEED_MULTIPLIER)
	print("Длительность: ", SLIDE_DURATION, " сек")
	
	# Уменьшаем коллайдер
	_shrink_collision()
	
	# Проигрываем анимацию с настроенной скоростью
	play_animation("sliding")
	
	# ВАЖНО: Устанавливаем скорость анимации
	if animated_sprite:
		animated_sprite.speed_scale = SLIDE_ANIMATION_SPEED
		print("Скорость анимации: ", SLIDE_ANIMATION_SPEED)

func _end_slide():
	is_sliding = false
	current_speed = base_speed
	
	print("\n✅ === ПОДКАТ ЗАВЕРШЕН ===")
	
	# Восстанавливаем коллайдер
	_restore_collision()
	
	# Восстанавливаем нормальную скорость анимации
	if animated_sprite:
		animated_sprite.speed_scale = 1.0
	
	handle_animations()

func _shrink_collision():
	"""Уменьшает коллайдер для подката"""
	if collision_shape and collision_shape.shape:
		var shape = collision_shape.shape
		if shape is RectangleShape2D:
			# Сохраняем оригинальную высоту
			if not has_meta("original_collision_height"):
				set_meta("original_collision_height", shape.size.y)
				set_meta("original_collision_offset", collision_shape.position.y)
			
			# Уменьшаем высоту на 60%
			var original_height = get_meta("original_collision_height")
			shape.size.y = original_height * 0.4
			
			# Опускаем коллайдер вниз
			collision_shape.position.y = original_height * 0.3
			
			print("📦 Коллайдер уменьшен: ", original_height, " → ", shape.size.y)
		elif shape is CapsuleShape2D:
			# Для капсульного коллайдера
			if not has_meta("original_collision_height"):
				set_meta("original_collision_height", shape.height)
				set_meta("original_collision_offset", collision_shape.position.y)
			
			var original_height = get_meta("original_collision_height")
			shape.height = original_height * 0.4
			collision_shape.position.y = original_height * 0.3
			
			print("📦 Капсула уменьшена: ", original_height, " → ", shape.height)

func _restore_collision():
	"""Восстанавливает оригинальный размер коллайдера"""
	if collision_shape and collision_shape.shape:
		var shape = collision_shape.shape
		
		if shape is RectangleShape2D and has_meta("original_collision_height"):
			shape.size.y = get_meta("original_collision_height")
			collision_shape.position.y = get_meta("original_collision_offset")
			print("📦 Коллайдер восстановлен")
		
		elif shape is CapsuleShape2D and has_meta("original_collision_height"):
			shape.height = get_meta("original_collision_height")
			collision_shape.position.y = get_meta("original_collision_offset")
			print("📦 Капсула восстановлена")
