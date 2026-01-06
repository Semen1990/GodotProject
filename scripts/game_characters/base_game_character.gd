# base_game_character.gd
extends CharacterBody2D

# Сигналы
signal health_changed(new_health)
signal mana_changed(new_mana)
signal armor_changed(new_armor)
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
var is_crouching: bool = false  # НОВОЕ: Приседание

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

# СИСТЕМА СПОСОБНОСТЕЙ (управляется артефактами)
var enable_double_jump: bool = false
var has_double_jumped: bool = false
var can_double_jump: bool = false
var coyote_time: float = 0.1
var coyote_timer: float = 0.0

# Размеры коллизии для приседания
var standing_collision_height: float = 0.0
var crouching_collision_height: float = 0.0
var original_collision_position: Vector2 = Vector2.ZERO

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
	
	# Сохраняем размер коллизии для приседания
	if collision_shape and collision_shape.shape:
		original_collision_position = collision_shape.position
		if collision_shape.shape is CapsuleShape2D:
			standing_collision_height = collision_shape.shape.height
			crouching_collision_height = standing_collision_height * 0.5
		elif collision_shape.shape is RectangleShape2D:
			standing_collision_height = collision_shape.shape.size.y
			crouching_collision_height = standing_collision_height * 0.5
	
	# Настраиваем контроллер игрока
	if player_controller:
		player_controller.character = self
	else:
		print("⚠️ PlayerController не найден для: ", character_name)
	
	# Применяем артефакты из Global
	call_deferred("apply_artifacts")
	
	# Запускаем анимацию покоя
	if animated_sprite:
		if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
		else:
			print("⚠️ Нет анимации idle или SpriteFrames для: ", character_name)

func apply_artifacts():
	"""Применяем все собранные артефакты к персонажу"""
	if Global:
		Global.apply_all_artifacts_to_player()
		
		# Проверяем наличие двойного прыжка
		if Global.has_ability("double_jump"):
			enable_double_jump = true
			print("🦘 Двойной прыжок доступен для ", character_name)
		else:
			enable_double_jump = false
			print("🚫 Двойной прыжок недоступен для ", character_name)

func _physics_process(delta):
	if is_dead:
		return
	
	# Применяем гравитацию
	if not is_on_floor():
		velocity.y += gravity * delta
		if coyote_timer > 0:
			coyote_timer -= delta
	else:
		has_double_jumped = false
		can_double_jump = false
		coyote_timer = coyote_time

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
	var is_crouch_pressed = Input.is_action_pressed("crouch")
	var is_special = Input.is_action_just_pressed("special_ability")
	
	# Блокируем движение во время специальных действий
	if is_attacking or is_casting or is_sliding:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		return
	
	# ПРИСЕДАНИЕ
	if is_crouch_pressed and is_on_floor() and not is_blocking:
		if not is_crouching:
			start_crouch()
	elif is_crouching:
		stop_crouch()
	
	# СПЕЦИАЛЬНАЯ СПОСОБНОСТЬ (E)
	if is_special and not is_crouching:
		use_special_ability()
	
	# Движение
	if not is_blocking and not is_crouching:
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * current_speed, acceleration * delta)
			if animated_sprite:
				animated_sprite.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
	elif is_crouching:
		# Замедленное движение при приседании
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * current_speed * 0.3, acceleration * delta)
			if animated_sprite:
				animated_sprite.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta * 2)
	
	# ПРЫЖКИ - нельзя прыгать при приседании
	if is_jumping and not is_blocking and not is_crouching:
		if is_on_floor() or coyote_timer > 0:
			velocity.y = jump_velocity
			can_double_jump = enable_double_jump
			has_double_jumped = false
			coyote_timer = 0
			print("🦘 ", character_name, " прыгает!")
		elif enable_double_jump and can_double_jump and not has_double_jumped:
			velocity.y = jump_velocity * 0.8
			has_double_jumped = true
			can_double_jump = false
			print("🦘✨ ", character_name, " использует двойной прыжок!")
			_show_double_jump_effect()

# ===========================================
# ПРИСЕДАНИЕ
# ===========================================

func start_crouch():
	"""Начать приседание"""
	is_crouching = true
	print("🔽 ", character_name, " присел")
	
	# Уменьшаем коллизию
	if collision_shape and collision_shape.shape:
		if collision_shape.shape is CapsuleShape2D:
			collision_shape.shape.height = crouching_collision_height
			collision_shape.position.y = original_collision_position.y + (standing_collision_height - crouching_collision_height) / 4
		elif collision_shape.shape is RectangleShape2D:
			collision_shape.shape.size.y = crouching_collision_height
			collision_shape.position.y = original_collision_position.y + (standing_collision_height - crouching_collision_height) / 4

func stop_crouch():
	"""Закончить приседание"""
	is_crouching = false
	print("🔼 ", character_name, " встал")
	
	# Восстанавливаем коллизию
	if collision_shape and collision_shape.shape:
		if collision_shape.shape is CapsuleShape2D:
			collision_shape.shape.height = standing_collision_height
			collision_shape.position.y = original_collision_position.y
		elif collision_shape.shape is RectangleShape2D:
			collision_shape.shape.size.y = standing_collision_height
			collision_shape.position.y = original_collision_position.y

# ===========================================
# СПЕЦИАЛЬНАЯ СПОСОБНОСТЬ
# ===========================================

func use_special_ability():
	"""Виртуальная функция - переопределяется в классах персонажей"""
	print("⚡ ", character_name, " использует способность (базовая - не переопределена)")

# ===========================================
# ВИЗУАЛЬНЫЕ ЭФФЕКТЫ
# ===========================================

func _show_double_jump_effect():
	"""Визуальный эффект при двойном прыжке"""
	if animated_sprite:
		var original_modulate = animated_sprite.modulate
		animated_sprite.modulate = Color(1.5, 1.5, 2.0, 1.0)
		
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", original_modulate, 0.3)

# ===========================================
# АНИМАЦИИ
# ===========================================

func handle_animations():
	if is_dead:
		play_animation("death")
		return
	
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
	
	if is_crouching:
		play_animation("crouch")
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
		var actual_anim_name = anim_name
		
		# Проверяем альтернативные названия анимаций
		if anim_name == "shield_defence" and animated_sprite.sprite_frames.has_animation("shield defence"):
			actual_anim_name = "shield defence"
		elif anim_name == "shield defence" and animated_sprite.sprite_frames.has_animation("shield_defence"):
			actual_anim_name = "shield_defence"
		
		if animated_sprite.sprite_frames.has_animation(actual_anim_name):
			if animated_sprite.animation != actual_anim_name:
				animated_sprite.play(actual_anim_name)
		else:
			# Не спамим ошибками для стандартных анимаций
			if anim_name not in ["fall", "jump", "crouch"]:
				pass  # Тихо игнорируем отсутствующие анимации

func get_available_animations() -> Array:
	if animated_sprite and animated_sprite.sprite_frames:
		return animated_sprite.sprite_frames.get_animation_names()
	return []

# ===========================================
# БОЕВАЯ СИСТЕМА
# ===========================================

func attack():
	if is_dead or is_attacking or is_blocking or is_casting or is_sliding or is_crouching:
		return
	
	is_attacking = true
	attack_combo += 1
	
	play_animation("attack")
	
	if animated_sprite:
		await animated_sprite.animation_finished
	is_attacking = false
	
	handle_animations()

func take_damage(amount: int, damage_type: String = "physical"):
	if is_dead:
		return
	
	var reduced_amount = max(1, amount - armor)
	current_health -= reduced_amount
	current_health = max(0, current_health)
	health_changed.emit(current_health)
	
	print("💥 ", character_name, " получает урон: ", reduced_amount, " (", damage_type, ")")
	
	# Визуальный эффект
	_show_damage_effect()
	
	if current_health <= 0:
		die()

func _show_damage_effect():
	"""Эффект получения урона"""
	if not animated_sprite:
		return
	
	var original_modulate = animated_sprite.modulate
	animated_sprite.modulate = Color(2.0, 0.5, 0.5, 1.0)
	
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", original_modulate, 0.2)

func die():
	is_dead = true
	play_animation("death")
	died.emit()
	print("💀 ", character_name, " погиб")

# ===========================================
# БАЗОВЫЕ СПОСОБНОСТИ (переопределяются)
# ===========================================

func heal():
	print("❤️ ", character_name, " базовое лечение")

func slide():
	print("🔽 ", character_name, " базовый подкат")

func block():
	pass

func stop_blocking():
	pass
