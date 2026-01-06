extends CharacterBody2D

# ===========================================
# LIZARD - ВРАГ С КОПЬЁМ (v5.0 ФИНАЛЬНАЯ)
# ===========================================

signal died()
signal health_changed(new_health)

# Характеристики
@export var max_health: int = 6
@export var current_health: int = 6
@export var damage: int = 2
@export var move_speed: float = 80.0
@export var chase_speed: float = 100.0

# Дальность для КОПЬЯ (БОЛЬШАЯ)
@export var attack_distance: float = 90.0     # Когда начинаем атаку
@export var damage_range: float = 150.0       # Дальность нанесения урона (ОЧЕНЬ большая!)
@export var detection_range: float = 200.0

# Состояния
enum State { IDLE, PATROL, CHASE, ATTACK, HURT, DEAD }
var current_state: State = State.IDLE

# Патруль
@export var patrol_distance: float = 100.0
var start_position: Vector2
var patrol_direction: int = 1
var patrol_target_x: float = 0.0

# Таргет
var target: Node2D = null
var can_attack: bool = true
var is_hurt: bool = false

# Флаг для однократного нанесения урона за атаку
var damage_dealt_this_attack: bool = false

# Таймеры
var idle_timer: float = 0.0
var attack_cooldown: float = 0.0
const ATTACK_COOLDOWN_TIME: float = 1.3
const IDLE_TIME: float = 1.5

# Физика
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

# Ноды
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea

func _ready():
	print("🦎 Lizard создан!")
	print("  HP: ", current_health, "/", max_health)
	print("  DMG: ", damage)
	print("  Damage Range: ", damage_range)
	
	start_position = global_position
	patrol_target_x = start_position.x + patrol_distance
	
	# Подключаем DetectionArea
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)
		print("✅ DetectionArea подключена")
	
	# Подключаем анимации
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)
		animated_sprite.frame_changed.connect(_on_frame_changed)
	
	change_state(State.IDLE)

func _physics_process(delta):
	# Гравитация
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Кулдаун атаки
	if attack_cooldown > 0:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			can_attack = true
	
	# Обработка состояний
	match current_state:
		State.IDLE:
			process_idle(delta)
		State.PATROL:
			process_patrol(delta)
		State.CHASE:
			process_chase(delta)
		State.ATTACK:
			velocity.x = 0
		State.HURT:
			velocity.x = 0
		State.DEAD:
			velocity = Vector2.ZERO
			return
	
	move_and_slide()

# ===========================================
# СОСТОЯНИЯ
# ===========================================

func change_state(new_state: State):
	if current_state == State.DEAD:
		return
	
	current_state = new_state
	
	match new_state:
		State.IDLE:
			play_animation("idle")
			velocity.x = 0
			idle_timer = IDLE_TIME
		State.PATROL:
			play_animation("walk")
		State.CHASE:
			play_animation("walk")
		State.ATTACK:
			# ВАЖНО: Поворачиваемся к цели ПЕРЕД атакой
			_face_target()
			play_animation("attack")
			velocity.x = 0
			damage_dealt_this_attack = false
		State.HURT:
			play_animation("hurt")
			velocity.x = 0
		State.DEAD:
			play_animation("death")
			velocity = Vector2.ZERO

func _face_target():
	"""Поворачивает врага лицом к цели"""
	if not target or not is_instance_valid(target):
		return
	
	if not animated_sprite:
		return
	
	var direction = sign(target.global_position.x - global_position.x)
	animated_sprite.flip_h = direction < 0
	print("🦎 Повернулся к цели, direction: ", direction)

func process_idle(delta):
	idle_timer -= delta
	if idle_timer <= 0:
		if patrol_direction > 0:
			patrol_target_x = start_position.x + patrol_distance
		else:
			patrol_target_x = start_position.x - patrol_distance
		change_state(State.PATROL)

func process_patrol(delta):
	if is_on_wall():
		_reverse_patrol()
		return
	
	velocity.x = patrol_direction * move_speed
	
	if animated_sprite:
		animated_sprite.flip_h = patrol_direction < 0
	
	var distance_to_target = abs(global_position.x - patrol_target_x)
	if distance_to_target < 10:
		_reverse_patrol()

func _reverse_patrol():
	patrol_direction *= -1
	if patrol_direction > 0:
		patrol_target_x = start_position.x + patrol_distance
	else:
		patrol_target_x = start_position.x - patrol_distance
	change_state(State.IDLE)

func process_chase(delta):
	if not target or not is_instance_valid(target):
		change_state(State.PATROL)
		return
	
	if target.get("is_dead") == true:
		target = null
		change_state(State.IDLE)
		return
	
	var distance = global_position.distance_to(target.global_position)
	var direction = sign(target.global_position.x - global_position.x)
	
	# Поворачиваем спрайт к цели
	if animated_sprite:
		animated_sprite.flip_h = direction < 0
	
	# Атакуем если в дистанции
	if distance <= attack_distance and can_attack:
		change_state(State.ATTACK)
		return
	
	# На кулдауне - стоим
	if distance <= attack_distance * 0.8:
		velocity.x = 0
		play_animation("idle")
		return
	
	# Преследуем
	velocity.x = direction * chase_speed

# ===========================================
# ОБНАРУЖЕНИЕ
# ===========================================

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		if body.get("is_dead") == true:
			return
		print("🦎 Lizard заметил игрока!")
		target = body
		change_state(State.CHASE)

func _on_detection_area_body_exited(body):
	if body == target:
		print("🦎 Lizard потерял игрока")
		target = null
		if current_state != State.DEAD and current_state != State.HURT and current_state != State.ATTACK:
			change_state(State.PATROL)

# ===========================================
# АНИМАЦИИ
# ===========================================

func play_animation(anim_name: String):
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation(anim_name):
			if animated_sprite.animation != anim_name:
				animated_sprite.play(anim_name)

func _on_frame_changed():
	"""Урон наносится на 4 кадре (кадр 3, т.к. счёт с 0)"""
	if current_state != State.ATTACK:
		return
	
	if damage_dealt_this_attack:
		return
	
	# Кадр 3 = четвёртый кадр (счёт с 0)
	if animated_sprite.frame == 3:
		print("🦎 Кадр 4 - наносим урон!")
		_deal_damage_to_target()
		damage_dealt_this_attack = true

func _on_animation_finished():
	match current_state:
		State.ATTACK:
			# Если урон не был нанесён (на всякий случай)
			if not damage_dealt_this_attack:
				_deal_damage_to_target()
				damage_dealt_this_attack = true
			
			can_attack = false
			attack_cooldown = ATTACK_COOLDOWN_TIME
			
			if target and is_instance_valid(target) and target.get("is_dead") != true:
				change_state(State.CHASE)
			else:
				target = null
				change_state(State.PATROL)
		
		State.HURT:
			is_hurt = false
			if target and is_instance_valid(target) and target.get("is_dead") != true:
				change_state(State.CHASE)
			else:
				change_state(State.PATROL)
		
		State.DEAD:
			var tween = create_tween()
			tween.tween_property(animated_sprite, "modulate:a", 0.0, 1.0)
			tween.tween_callback(queue_free)

# ===========================================
# УРОН
# ===========================================

func _deal_damage_to_target():
	"""Наносит урон с БОЛЬШОЙ дальностью для копья"""
	if not target or not is_instance_valid(target):
		print("🦎 Нет цели")
		return
	
	if target.get("is_dead") == true:
		print("🦎 Цель мертва")
		return
	
	var distance = global_position.distance_to(target.global_position)
	
	print("🦎 Проверка урона: дистанция = ", int(distance), " / макс = ", int(damage_range))
	
	if distance <= damage_range:
		if target.has_method("take_damage"):
			print("🦎 >>> УРОН НАНЕСЁН: ", damage, " <<<")
			target.take_damage(damage, "physical")
	else:
		print("🦎 Промах - слишком далеко")

func take_damage(amount: int, _damage_type: String = "physical"):
	if current_state == State.DEAD:
		return
	
	print("🦎 Получает урон: ", amount)
	
	current_health -= amount
	current_health = max(0, current_health)
	
	health_changed.emit(current_health)
	print("🦎 HP: ", current_health, "/", max_health)
	
	if current_health <= 0:
		die()
	else:
		is_hurt = true
		change_state(State.HURT)
		_show_damage_effect()

func _show_damage_effect():
	if not animated_sprite:
		return
	
	var original = animated_sprite.modulate
	animated_sprite.modulate = Color(2.0, 0.5, 0.5, 1.0)
	
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", original, 0.2)

func die():
	print("💀 Lizard погибает!")
	change_state(State.DEAD)
	
	if detection_area:
		detection_area.monitoring = false
	
	died.emit()
