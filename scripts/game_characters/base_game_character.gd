# base_game_character.gd
extends CharacterBody2D

# Сигналы
signal health_changed(new_health)
signal mana_changed(new_mana)
signal died()

# Базовые статы персонажа
var character_name: String = "BaseCharacter"
var max_health: int = 100
var current_health: int = 100
var max_mana: int = 100
var current_mana: int = 100
var armor: int = 0
var base_speed: int = 200
var current_speed: int = 200

# Состояния персонажа
var is_dead: bool = false
var is_attacking: bool = false
var is_moving: bool = false
var is_blocking: bool = false
var is_sliding: bool = false
var is_casting: bool = false

# Атака
var attack_combo: int = 0
var last_attack_time: float = 0.0
var attack_combo_timeout: float = 1.0

# Физика
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

# Движение
var max_speed: float = 300.0
var acceleration: float = 1500.0
var friction: float = 1200.0
var jump_velocity: float = -400.0
var has_double_jumped: bool = false

# Ноды
var animated_sprite: AnimatedSprite2D
var collision_shape: CollisionShape2D
var player_controller: Node

# Масштаб спрайта
var original_scale: Vector2 = Vector2.ONE

func _ready():
	print("✅ ", character_name, " инициализирован")
	
	# Безопасное получение нодов
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	collision_shape = get_node_or_null("CollisionShape2D") 
	player_controller = get_node_or_null("PlayerController")
	
	# Сохраняем оригинальный масштаб
	if animated_sprite:
		original_scale = animated_sprite.scale
	
	# Настраиваем контроллер игрока
	if player_controller:
		player_controller.character = self
	else:
		print("⚠️ PlayerController не найден для: ", character_name)
	
	# Запускаем анимацию покоя
	if animated_sprite:
		if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
		else:
			print("⚠️ Нет анимации idle или SpriteFrames для: ", character_name)

func _physics_process(delta):
	if is_dead:
		return
	
	# Применяем гравитацию
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		has_double_jumped = false

	handle_movement(delta)
	handle_animations()
	fix_sprite_scale()
	
	move_and_slide()

func fix_sprite_scale():
	"""Фиксирует масштаб спрайта"""
	if animated_sprite:
		var current_sign = sign(animated_sprite.scale.x)
		if current_sign == 0:
			current_sign = 1
		animated_sprite.scale = Vector2(
			abs(original_scale.x) * current_sign,
			original_scale.y
		)

func handle_movement(delta):
	var direction = Input.get_axis("move_left", "move_right")
	var is_jumping = Input.is_action_just_pressed("jump")
	
	# Блокируем движение во время специальных действий
	if is_attacking or is_casting or is_sliding:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		return
	
	# Блокируем движение во время блока
	if not is_blocking:
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * current_speed, acceleration * delta)
			# Поворачиваем спрайт в направлении движения
			if animated_sprite:
				animated_sprite.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
	else:
		# Во время блока замедляемся
		velocity.x = move_toward(velocity.x, 0, friction * delta * 2)
	
	# ИСПРАВЛЕННАЯ логика прыжков
	if is_jumping and not is_blocking:
		if is_on_floor():
			velocity.y = jump_velocity
			has_double_jumped = false
		elif not has_double_jumped:
			velocity.y = jump_velocity * 0.8
			has_double_jumped = true

func handle_animations():
	if is_dead:
		play_animation("death")
		return
	
	# ИСПРАВЛЕНО: проверяем блок ПЕРЕД атакой
	if is_blocking:
		play_animation("shield_defence")
		return
	
	if is_attacking:
		return
	
	if is_casting:
		play_animation("spellcast")
		return
	
	if is_sliding:
		play_animation("sliding")
		return
	
	if is_on_floor():
		if abs(velocity.x) > 1.0:
			play_animation("run")
		else:
			play_animation("idle")
	else:
		if velocity.y < 0:
			play_animation("jump")
		else:
			play_animation("fall")

func play_animation(anim_name: String):
	if animated_sprite and animated_sprite.sprite_frames != null:
		# Проверяем разные варианты написания
		var actual_anim_name = anim_name
		if anim_name == "shield_defence" and animated_sprite.sprite_frames.has_animation("shield defence"):
			actual_anim_name = "shield defence"
		elif anim_name == "shield defence" and animated_sprite.sprite_frames.has_animation("shield_defence"):
			actual_anim_name = "shield_defence"
		
		if animated_sprite.sprite_frames.has_animation(actual_anim_name):
			if animated_sprite.animation != actual_anim_name:
				animated_sprite.play(actual_anim_name)
		else:
			if anim_name not in ["fall", "jump"]:  # Не спамим для частых анимаций
				print("❌ Анимация '", anim_name, "' не найдена для ", character_name)

func get_available_animations() -> Array:
	if animated_sprite and animated_sprite.sprite_frames:
		return animated_sprite.sprite_frames.get_animation_names()
	return []

func attack():
	if is_dead or is_attacking or is_blocking or is_casting or is_sliding:
		return
	
	is_attacking = true
	attack_combo += 1
	
	play_animation("attack")
	
	if animated_sprite:
		await animated_sprite.animation_finished
	is_attacking = false
	
	handle_animations()

func take_damage(amount: int):
	if is_dead:
		return
	
	var reduced_amount = max(1, amount - armor)
	current_health -= reduced_amount
	health_changed.emit(current_health)
	
	print("💥 ", character_name, " получает урон: ", reduced_amount)
	
	if current_health <= 0:
		die()

func die():
	is_dead = true
	play_animation("death")
	died.emit()
	print("💀 ", character_name, " погиб")

func heal():
	print("❤️ ", character_name, " базовое лечение")
	pass

func slide():
	print("🔽 ", character_name, " базовый подкат")
	pass

# Базовые методы для блока
func block():
	pass

func stop_blocking():
	pass
