extends CharacterBody2D

# ===========================================
# LIZARD - ВРАГ (ФИНАЛЬНАЯ РАБОЧАЯ ВЕРСИЯ)
# ===========================================

signal died()
signal health_changed(new_health)

@export var max_health: int = 6
@export var current_health: int = 6
@export var damage: int = 2
@export var move_speed: float = 80.0
@export var chase_speed: float = 100.0
@export var attack_distance: float = 65.0
@export var damage_range: float = 80.0
@export var detection_range: float = 200.0
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

var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	print("🦎 Lizard создан! HP:", max_health, " DMG:", damage)
	start_position = global_position
	
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)
		animated_sprite.frame_changed.connect(_on_frame_changed)
	
	_change_state(State.IDLE)

func _physics_process(delta):
	# Гравитация
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Кулдаун атаки
	if attack_cooldown > 0:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			can_attack = true
	
	# Поиск игрока каждый кадр
	_search_for_player()
	
	# Обработка состояний
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.PATROL:
			_process_patrol()
		State.CHASE:
			_process_chase()
		State.ATTACK:
			velocity.x = move_toward(velocity.x, 0, 500 * delta)
		State.HURT:
			velocity.x = move_toward(velocity.x, 0, 500 * delta)
		State.DEAD:
			velocity = Vector2.ZERO
			return
	
	move_and_slide()

func _search_for_player():
	"""Ищет игрока в радиусе"""
	if current_state == State.DEAD or current_state == State.HURT or current_state == State.ATTACK:
		return
	
	# Проверяем текущую цель
	if target and is_instance_valid(target):
		# Проверяем жив ли игрок (is_dead - это ПЕРЕМЕННАЯ, не метод!)
		if target.get("is_dead") == true:
			target = null
			_change_state(State.PATROL)
			return
		
		# Проверяем дистанцию
		var dist = global_position.distance_to(target.global_position)
		if dist > detection_range * 1.5:
			print("🦎 Потерял игрока - слишком далеко")
			target = null
			_change_state(State.PATROL)
		return
	
	# Ищем игрока в группе "player" (с маленькой буквы!)
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		# Проверяем жив ли
		if player.get("is_dead") == true:
			continue
		
		var dist = global_position.distance_to(player.global_position)
		if dist <= detection_range:
			print("🦎 Заметил игрока! Дистанция:", int(dist))
			target = player
			_change_state(State.CHASE)
			return

func _change_state(new_state: State):
	if current_state == State.DEAD:
		return
	
	if current_state == new_state:
		return
	
	print("🦎 ", State.keys()[current_state], " → ", State.keys()[new_state])
	current_state = new_state
	
	match new_state:
		State.IDLE:
			_play_anim("idle")
			velocity.x = 0
			idle_timer = randf_range(1.5, 2.5)
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
		State.DEAD:
			_play_anim("death")
			velocity = Vector2.ZERO

func _process_idle(delta):
	idle_timer -= delta
	if idle_timer <= 0:
		_change_state(State.PATROL)

func _process_patrol():
	# Проверка стены
	if is_on_wall():
		patrol_direction *= -1
		_change_state(State.IDLE)
		return
	
	# Движение
	velocity.x = patrol_direction * move_speed
	
	# Поворот спрайта
	if animated_sprite:
		animated_sprite.flip_h = (patrol_direction < 0)
	
	# Проверка дистанции патруля
	if abs(global_position.x - start_position.x) > patrol_distance:
		patrol_direction *= -1
		_change_state(State.IDLE)

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
	if dist <= attack_distance and can_attack:
		_change_state(State.ATTACK)
		return
	
	# Ожидание кулдауна
	if dist <= attack_distance:
		velocity.x = 0
		return
	
	# Движение к цели
	velocity.x = sign(dir_x) * chase_speed

func _face_target():
	if target and animated_sprite:
		var dir = target.global_position.x - global_position.x
		animated_sprite.flip_h = (dir < 0)

func _play_anim(name: String):
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation(name):
			if animated_sprite.animation != name:
				animated_sprite.play(name)

func _on_frame_changed():
	# Урон на 4-м кадре (индекс 3) - для 5-кадровой анимации
	if current_state != State.ATTACK or damage_dealt_this_attack:
		return
	
	if animated_sprite.frame == 3:
		_deal_damage()
		damage_dealt_this_attack = true

func _on_animation_finished():
	match current_state:
		State.ATTACK:
			if not damage_dealt_this_attack:
				_deal_damage()
			can_attack = false
			attack_cooldown = 0.8
			_change_state(State.CHASE if _is_target_valid() else State.PATROL)
		State.HURT:
			_change_state(State.CHASE if _is_target_valid() else State.PATROL)
		State.DEAD:
			var tw = create_tween()
			tw.tween_property(animated_sprite, "modulate:a", 0.0, 1.0)
			tw.tween_callback(queue_free)

func _is_target_valid() -> bool:
	return target and is_instance_valid(target) and target.get("is_dead") != true

func _deal_damage():
	if not _is_target_valid():
		return
	
	var dist = global_position.distance_to(target.global_position)
	print("🦎 Атака! Дист:", int(dist), "/", int(damage_range))
	
	if dist <= damage_range and target.has_method("take_damage"):
		print("🦎 >>> УРОН:", damage, " <<<")
		target.take_damage(damage, "physical")

func take_damage(amount: int, _type: String = "physical"):
	if current_state == State.DEAD:
		return
	
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)
	print("🦎 HP:", current_health, "/", max_health)
	
	if current_health <= 0:
		_die()
	else:
		_change_state(State.HURT)
		if animated_sprite:
			animated_sprite.modulate = Color(2, 0.5, 0.5)
			var tw = create_tween()
			tw.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)

func _die():
	print("💀 Lizard погиб!")
	_change_state(State.DEAD)
	died.emit()
