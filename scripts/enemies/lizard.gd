extends CharacterBody2D

# ===========================================
# LIZARD - ВРАГ С СИСТЕМОЙ СОХРАНЕНИЯ СОСТОЯНИЯ
# ===========================================

signal died()
signal health_changed(new_health)

# Тип врага для статистики
@export_enum("simple", "elite", "boss") var enemy_type: String = "simple"

@export var max_health: int = 6
@export var current_health: int = 6
@export var damage: int = 5
@export var move_speed: float = 100.0
@export var chase_speed: float = 120.0
@export var attack_range: float = 120.0
@export var detection_range: float = 150.0
@export var patrol_distance: float = 100.0

enum State { IDLE, PATROL, CHASE, ATTACK, HURT, DEAD }
var current_state: State = State.IDLE

var start_position: Vector2
var patrol_direction: int = 1
var target: Node2D = null
var can_attack: bool = true
var damage_dealt_this_attack: bool = false

var idle_timer: float = 0.0
var attack_cooldown: float = 0.0
const ATTACK_COOLDOWN_TIME: float = 1.0
const IDLE_TIME: float = 1.5

# Минимальная дистанция до игрока (чтобы не зажимать)
const MIN_DISTANCE_TO_PLAYER: float = 40.0

var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea

# Флаг смерти врага (для сохранения состояния)
var is_alive: bool = true
var is_active: bool = true

func _ready():
	print("🦎 Lizard создан! HP:", max_health, " DMG:", damage)
	start_position = global_position
	
	if detection_area:
		detection_area.body_entered.connect(_on_detection_entered)
		detection_area.body_exited.connect(_on_detection_exited)
		print("✅ DetectionArea подключена")
	
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)
		animated_sprite.frame_changed.connect(_on_frame_changed)
	
	_change_state(State.IDLE)
	
	# Проверяем, не был ли враг уже убит (например, при возрождении игрока)
	if not is_alive:
		_set_dead_state()
		return

func _physics_process(delta):
	# Если враг мертв или неактивен - не обрабатываем физику
	if not is_alive or not is_active:
		velocity = Vector2.ZERO
		return
	
	# Гравитация
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Кулдаун атаки
	if attack_cooldown > 0:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			can_attack = true
	
	# Состояния
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.PATROL:
			_process_patrol()
		State.CHASE:
			_process_chase()
		State.ATTACK:
			velocity.x = 0
		State.HURT:
			velocity.x = 0
		State.DEAD:
			velocity = Vector2.ZERO
			return
	
	move_and_slide()

# ===========================================
# СОХРАНЕНИЕ И ЗАГРУЗКА СОСТОЯНИЯ
# ===========================================

func save_state() -> Dictionary:
	"""Сохраняет текущее состояние врага"""
	return {
		"is_alive": is_alive,
		"current_health": current_health,
		"global_position": global_position,
		"current_state": current_state,
		"patrol_direction": patrol_direction,
		"target": null,  # Не сохраняем цель, так как она может измениться
		"start_position": start_position
	}

func load_state(state: Dictionary):
	"""Загружает сохраненное состояние врага"""
	is_alive = state.get("is_alive", true)
	current_health = state.get("current_health", max_health)
	
	# Если враг мертв - устанавливаем мертвое состояние
	if not is_alive:
		_set_dead_state()
		return
	
	# Если враг жив - восстанавливаем состояние
	is_active = true
	
	# Восстанавливаем здоровье
	health_changed.emit(current_health)
	
	# Восстанавливаем позицию
	var saved_position = state.get("global_position")
	if saved_position:
		global_position = saved_position
	
	# Восстанавливаем стартовую позицию
	var saved_start_position = state.get("start_position")
	if saved_start_position:
		start_position = saved_start_position
	
	# Восстанавливаем направление патрулирования
	patrol_direction = state.get("patrol_direction", 1)
	
	# Восстанавливаем состояние
	var saved_state = state.get("current_state", State.IDLE)
	_change_state(saved_state)
	
	print("🦎 Состояние ящерицы загружено: HP=", current_health, "/", max_health, " состояние=", State.keys()[current_state])

func _set_dead_state():
	"""Устанавливает мертвое состояние врага (после загрузки)"""
	is_alive = false
	is_active = false
	current_state = State.DEAD
	
	# Отключаем видимость
	visible = false
	
	# Отключаем коллизии
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if detection_area:
		detection_area.set_deferred("monitoring", false)
		detection_area.set_deferred("monitorable", false)
	
	print("🦎 Ящерица загружена как мертвая")

# ===========================================
# СОСТОЯНИЯ
# ===========================================

func _change_state(new_state: State):
	if current_state == State.DEAD and not is_alive:
		return
	if current_state == new_state:
		return
	
	print("🦎 ", State.keys()[current_state], " → ", State.keys()[new_state])
	current_state = new_state
	
	match new_state:
		State.IDLE:
			_play_anim("idle")
			velocity.x = 0
			idle_timer = IDLE_TIME
		State.PATROL:
			_play_anim("walk")
		State.CHASE:
			_play_anim("walk")
		State.ATTACK:
			velocity.x = 0
			damage_dealt_this_attack = false
			_face_target()
			_play_anim("attack")
		State.HURT:
			_play_anim("hurt")
			velocity.x = 0
		State.DEAD:
			# Отключаем коллизию сразу при смерти
			_disable_collision()
			_play_anim("death")
			velocity = Vector2.ZERO

func _disable_collision():
	"""Отключает коллизию врага чтобы игрок мог пройти сквозь"""
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if detection_area:
		detection_area.monitoring = false
		detection_area.monitorable = false

func _process_idle(delta):
	velocity.x = 0
	idle_timer -= delta
	if idle_timer <= 0:
		_change_state(State.PATROL)

func _process_patrol():
	# Проверяем стену
	if is_on_wall():
		patrol_direction *= -1
		idle_timer = 0.5
		_change_state(State.IDLE)
		return
	
	# Проверяем дистанцию от старта
	var dist_from_start = global_position.x - start_position.x
	
	if patrol_direction > 0 and dist_from_start >= patrol_distance:
		patrol_direction = -1
		idle_timer = 0.5
		_change_state(State.IDLE)
		return
	elif patrol_direction < 0 and dist_from_start <= -patrol_distance:
		patrol_direction = 1
		idle_timer = 0.5
		_change_state(State.IDLE)
		return
	
	# Двигаемся
	velocity.x = patrol_direction * move_speed
	
	if animated_sprite:
		animated_sprite.flip_h = (patrol_direction < 0)

func _process_chase():
	# Проверка цели
	if not target or not is_instance_valid(target):
		_change_state(State.PATROL)
		return
	
	if target.get("is_dead") == true:
		target = null
		_change_state(State.PATROL)
		return
	
	var dist = global_position.distance_to(target.global_position)
	var dir_x = target.global_position.x - global_position.x
	
	# Поворот к цели
	if animated_sprite:
		animated_sprite.flip_h = (dir_x < 0)
	
	# Атака если близко
	if dist <= attack_range and can_attack:
		print("🦎 АТАКУЮ! дист=", int(dist))
		_change_state(State.ATTACK)
		return
	
	# Ожидание кулдауна - стоим на месте
	if dist <= attack_range and not can_attack:
		velocity.x = 0
		return
	
	# Не подходим слишком близко к игроку (чтобы не зажимать)
	if dist <= MIN_DISTANCE_TO_PLAYER:
		velocity.x = -sign(dir_x) * move_speed * 0.5
		return
	
	# Преследование
	velocity.x = sign(dir_x) * chase_speed

func _face_target():
	if target and animated_sprite:
		var dir = target.global_position.x - global_position.x
		animated_sprite.flip_h = (dir < 0)

# ===========================================
# ОБНАРУЖЕНИЕ
# ===========================================

func _on_detection_entered(body):
	# Если враг мертв - не реагируем на игрока
	if not is_alive:
		return
	
	if body.is_in_group("player"):
		if body.get("is_dead") == true:
			return
		print("🦎 Заметил игрока!")
		target = body
		_change_state(State.CHASE)

func _on_detection_exited(body):
	# Если враг мертв - не реагируем
	if not is_alive:
		return
	
	if body == target:
		print("🦎 Потерял игрока")
		target = null
		if current_state == State.CHASE:
			_change_state(State.PATROL)

# ===========================================
# АНИМАЦИИ
# ===========================================

func _play_anim(anim_name: String):
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation(anim_name):
			if animated_sprite.animation != anim_name:
				animated_sprite.play(anim_name)

func _on_frame_changed():
	"""Урон на 4-м кадре (индекс 3) из 5 кадров анимации атаки"""
	if current_state != State.ATTACK or damage_dealt_this_attack:
		return
	
	# Кадр 4 (индекс 3) - момент удара копьём
	if animated_sprite.frame == 3:
		_deal_damage()
		damage_dealt_this_attack = true

func _on_animation_finished():
	match current_state:
		State.ATTACK:
			# Если урон не был нанесён (пропустили кадр) - наносим сейчас
			if not damage_dealt_this_attack:
				_deal_damage()
				damage_dealt_this_attack = true
			
			can_attack = false
			attack_cooldown = ATTACK_COOLDOWN_TIME
			
			# Возвращаемся к преследованию или патрулю
			if target and is_instance_valid(target) and target.get("is_dead") != true:
				_change_state(State.CHASE)
			else:
				target = null
				_change_state(State.PATROL)
		
		State.HURT:
			if target and is_instance_valid(target):
				_change_state(State.CHASE)
			else:
				_change_state(State.PATROL)
		
		State.DEAD:
			# После анимации смерти скрываем врага, НЕ удаляем
			_on_death_completed()

func _on_death_completed():
	"""Выполняется после завершения анимации смерти"""
	is_alive = false
	is_active = false
	
	# Плавное исчезновение
	var tw = create_tween()
	tw.tween_property(animated_sprite, "modulate:a", 0.0, 1.0)
	tw.tween_callback(_hide_enemy)
	
	print("🦎 Ящерица мертва, скрываем...")

func _hide_enemy():
	"""Скрывает врага после смерти"""
	visible = false
	
	# Полностью отключаем коллизии и мониторинг
	if collision_shape:
		collision_shape.disabled = true
	if detection_area:
		detection_area.monitoring = false
		detection_area.monitorable = false
	
	# Останавливаем обработку
	set_physics_process(false)
	
	print("🦎 Ящерица скрыта (не удалена)")

# ===========================================
# УРОН И СМЕРТЬ
# ===========================================

func _deal_damage():
	if not target or not is_instance_valid(target):
		return
	
	if target.get("is_dead") == true:
		return
	
	var dist = global_position.distance_to(target.global_position)
	print("🦎 Атака! Дист:", int(dist), "/", int(attack_range + 30))
	
	# Даём запас по дистанции для длинного копья
	if dist <= attack_range + 30:
		if target.has_method("take_damage"):
			print("🦎 >>> УРОН:", damage, " <<<")
			# Передаём источник урона для статистики
			target.take_damage(damage, "physical", "Ящерица с копьём")

func take_damage(amount: int, _type: String = "physical"):
	# Если враг уже мертв - не получаем урон
	if not is_alive or current_state == State.DEAD:
		return
	
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)
	print("🦎 HP:", current_health, "/", max_health)
	
	# Обновляем статистику урона
	if Global and Global.has_method("add_damage_dealt"):
		Global.add_damage_dealt(amount)
	
	# Красная вспышка ВСЕГДА (даже при смерти)
	_show_damage_flash()
	
	if current_health <= 0:
		_die()
	else:
		_change_state(State.HURT)

func _show_damage_flash():
	"""Красная вспышка при получении урона"""
	if not animated_sprite:
		return
	
	animated_sprite.modulate = Color(2, 0.5, 0.5)
	
	var tw = create_tween()
	tw.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)

func _die():
	print("💀 Lizard погиб!")
	
	# Обновляем статистику убийств
	if Global and Global.has_method("add_enemy_killed"):
		Global.add_enemy_killed(enemy_type)
	
	# Устанавливаем состояние смерти
	is_alive = false
	
	_change_state(State.DEAD)
	died.emit()

# ===========================================
# АКТИВАЦИЯ/ДЕАКТИВАЦИЯ (для оптимизации)
# ===========================================

func activate():
	"""Активирует врага (если он жив)"""
	if is_alive:
		is_active = true
		set_physics_process(true)
		visible = true

func deactivate():
	"""Деактивирует врага"""
	is_active = false
	set_physics_process(false)
	
	# Останавливаем анимацию
	if animated_sprite:
		animated_sprite.stop()
	
	print("🦎 Ящерица деактивирована")
