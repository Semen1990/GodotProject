extends "res://scripts/game_characters/base_game_character.gd"

var slide_cooldown: float = 0.0
var slide_timer: float = 0.0
var slide_direction: float = 0.0

const SLIDE_DURATION: float = 0.5  # Длительность подката
const SLIDE_SPEED_MULTIPLIER: float = 2.0  # Множитель скорости
const SLIDE_COOLDOWN: float = 2.0  # Кулдаун

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
	
	# ИСПРАВЛЕНО: управление подкатом
	if is_sliding:
		slide_timer -= delta
		
		# Двигаем персонажа в направлении подката
		velocity.x = slide_direction * base_speed * SLIDE_SPEED_MULTIPLIER
		
		# Завершаем подкат
		if slide_timer <= 0:
			_end_slide()
	
	super(delta)

func slide():
	print("🔍 Попытка подката...")
	
	# ИСПРАВЛЕНО: проверяем что персонаж движется
	if abs(velocity.x) < 10.0:
		print("⚠️ Нужно двигаться для подката!")
		return
	
	if not is_on_floor():
		print("⚠️ Нужно быть на земле!")
		return
	
	if is_dead or is_attacking or is_blocking or is_sliding or is_casting:
		print("⚠️ Персонаж занят!")
		return
	
	if slide_cooldown > 0:
		print("⚠️ Подкат на кулдауне! Осталось: ", slide_cooldown)
		return
	
	# Начинаем подкат
	_start_slide()

func _start_slide():
	is_sliding = true
	slide_timer = SLIDE_DURATION
	slide_cooldown = SLIDE_COOLDOWN
	
	# ИСПРАВЛЕНО: запоминаем направление движения
	slide_direction = sign(velocity.x)
	if slide_direction == 0:
		slide_direction = 1 if not animated_sprite.flip_h else -1
	
	print("🔽 Разбойник начинает подкат!")
	print("  Направление: ", "→" if slide_direction > 0 else "←")
	
	# ИСПРАВЛЕНО: уменьшаем коллайдер
	if collision_shape and collision_shape.shape:
		var shape = collision_shape.shape
		if shape is RectangleShape2D:
			# Сохраняем оригинальную высоту если еще не сохранили
			if not has_meta("original_collision_height"):
				set_meta("original_collision_height", shape.size.y)
			
			# Уменьшаем высоту на 50%
			shape.size.y = get_meta("original_collision_height") * 0.5
			collision_shape.position.y = get_meta("original_collision_height") * 0.25
			print("  Коллайдер уменьшен!")
	
	play_animation("sliding")

func _end_slide():
	is_sliding = false
	current_speed = base_speed
	
	print("✅ Подкат завершен!")
	
	# ИСПРАВЛЕНО: восстанавливаем коллайдер
	if collision_shape and collision_shape.shape:
		var shape = collision_shape.shape
		if shape is RectangleShape2D and has_meta("original_collision_height"):
			shape.size.y = get_meta("original_collision_height")
			collision_shape.position.y = 0
			print("  Коллайдер восстановлен!")
	
	handle_animations()
