extends "res://scripts/game_characters/base_game_character.gd"

# ===========================================
# РАЗБОЙНИК - БЫСТРЫЙ БОЕЦ С ПОДКАТОМ (ИСПРАВЛЕННАЯ ВЕРСИЯ)
# ===========================================

# Система подката
var slide_cooldown: float = 0.0
var slide_timer: float = 0.0
var slide_direction: float = 0.0

# НАСТРОЙКИ ПОДКАТА (можно менять для баланса)
const SLIDE_DURATION: float = 0.6        # Длительность подката
const SLIDE_SPEED_MULTIPLIER: float = 2.5  # Множитель скорости при подкате
const SLIDE_COOLDOWN: float = 2.0         # Кулдаун между подкатами
const SLIDE_ANIMATION_SPEED: float = 1.0  # Скорость анимации (1.0 = нормальная)

func _ready():
	# === ХАРАКТЕРИСТИКИ РАЗБОЙНИКА ===
	character_name = "Разбойник"
	max_health = 6       # Низкое здоровье
	current_health = 6
	max_mana = 8
	current_mana = 8
	armor = 1             # Низкая броня
	
	# === ФИЗИКА (БЫСТРЫЙ ПЕРСОНАЖ) ===
	jump_velocity = -450  # Высокий прыжок
	base_speed = 280      # Высокая скорость
	current_speed = 280
	max_speed = 280.0
	
	print("🗡️ Разбойник скрывается в тени!")
	super()

func _physics_process(delta):
	# Обновляем кулдаун подката
	if slide_cooldown > 0:
		slide_cooldown -= delta
		_update_slide_cooldown_ui()
	
	# Управление активным подкатом
	if is_sliding:
		slide_timer -= delta
		
		# Двигаем персонажа в направлении подката
		velocity.x = slide_direction * base_speed * SLIDE_SPEED_MULTIPLIER
		
		# Завершаем подкат по таймеру
		if slide_timer <= 0:
			_end_slide()
	
	super(delta)

# ===========================================
# СПЕЦИАЛЬНАЯ СПОСОБНОСТЬ (E) - ПОДКАТ
# ===========================================

func use_special_ability():
	"""Разбойник: Подкат (вызывается при нажатии E)"""
	slide()

func slide():
	"""Выполняет подкат"""
	print("\n=== 🔽 ПОПЫТКА ПОДКАТА ===")
	print("Скорость X: ", velocity.x)
	print("На земле: ", is_on_floor())
	
	# === ПРОВЕРКИ ===
	
	# 1. Персонаж должен двигаться
	if abs(velocity.x) < 10.0:
		print("❌ Нужно двигаться для подката!")
		return
	
	# 2. Должен быть на земле
	if not is_on_floor():
		print("❌ Нужно быть на земле!")
		return
	
	# 3. Не должен быть занят
	if is_dead or is_attacking or is_blocking or is_sliding or is_casting:
		print("❌ Персонаж занят!")
		return
	
	# 4. Кулдаун
	if slide_cooldown > 0:
		print("❌ Подкат на кулдауне! Осталось: %.1f сек" % slide_cooldown)
		return
	
	# === ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ ===
	_start_slide()

func _start_slide():
	"""Начинает подкат"""
	is_sliding = true
	slide_timer = SLIDE_DURATION
	slide_cooldown = SLIDE_COOLDOWN
	
	# Запоминаем направление движения
	slide_direction = sign(velocity.x)
	if slide_direction == 0:
		# Если скорость 0, используем направление спрайта
		slide_direction = 1 if not animated_sprite.flip_h else -1
	
	print("\n🔽 === ПОДКАТ НАЧАТ ===")
	print("Направление: ", "→" if slide_direction > 0 else "←")
	print("Скорость: ", base_speed * SLIDE_SPEED_MULTIPLIER)
	print("Длительность: ", SLIDE_DURATION, " сек")
	
	# Уменьшаем коллайдер для прохождения под препятствиями
	_shrink_collision()
	
	# Проигрываем анимацию
	play_animation("sliding")
	
	# Устанавливаем скорость анимации
	if animated_sprite:
		animated_sprite.speed_scale = SLIDE_ANIMATION_SPEED

func _end_slide():
	"""Завершает подкат"""
	is_sliding = false
	current_speed = base_speed
	
	print("\n✅ === ПОДКАТ ЗАВЕРШЕН ===")
	
	# Восстанавливаем коллайдер
	_restore_collision()
	
	# Восстанавливаем нормальную скорость анимации
	if animated_sprite:
		animated_sprite.speed_scale = 1.0
	
	handle_animations()

# ===========================================
# УПРАВЛЕНИЕ КОЛЛАЙДЕРОМ ПРИ ПОДКАТЕ
# ===========================================

func _shrink_collision():
	"""Уменьшает коллайдер для подката (проход под препятствиями)"""
	if not collision_shape or not collision_shape.shape:
		return
	
	var shape = collision_shape.shape
	
	if shape is RectangleShape2D:
		# Сохраняем оригинальные значения
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
	if not collision_shape or not collision_shape.shape:
		return
	
	var shape = collision_shape.shape
	
	if shape is RectangleShape2D and has_meta("original_collision_height"):
		shape.size.y = get_meta("original_collision_height")
		collision_shape.position.y = get_meta("original_collision_offset")
		print("📦 Коллайдер восстановлен")
	
	elif shape is CapsuleShape2D and has_meta("original_collision_height"):
		shape.height = get_meta("original_collision_height")
		collision_shape.position.y = get_meta("original_collision_offset")
		print("📦 Капсула восстановлена")

# ===========================================
# UI КУЛДАУНА
# ===========================================

func _update_slide_cooldown_ui():
	"""Обновляет UI кулдауна подката"""
	if Global and Global.game_ui and Global.game_ui.has_method("update_ability_cooldown"):
		var percent = 1.0 - (slide_cooldown / SLIDE_COOLDOWN)
		Global.game_ui.update_ability_cooldown("slide", percent)
