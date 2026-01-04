# base_character.gd
extends CharacterBody2D

# Экспортируемые переменные для настройки каждого персонажа
@export var max_speed: float = 300.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0
@export var jump_velocity: float = -400.0
@export var double_jump_velocity: float = -300.0

# Получаем ноды
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Переменные для управления состоянием
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")
var has_double_jumped: bool = false
var is_blocking: bool = false
var direction: float = 0.0
var original_scale: Vector2

func _ready():
	animation_tree.active = true
	original_scale = sprite.scale
	# Сохраняем оригинальный размер коллайдера если нужно
	if collision_shape:
		collision_shape.set_deferred("disabled", false)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		has_double_jumped = false

	handle_movement(delta)
	handle_animations()
	
	move_and_slide()

func handle_movement(delta):
	# Получаем ввод
	direction = Input.get_axis("ui_left", "ui_right")
	var is_jumping = Input.is_action_just_pressed("ui_accept")
	var is_running = Input.is_action_pressed("sprint")
	
	# Блокируем движение во время блока
	if !is_blocking:
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
			# Поворачиваем спрайт
			sprite.scale.x = original_scale.x * sign(direction)
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
	
	# Обработка прыжков
	if is_jumping:
		if is_on_floor():
			velocity.y = jump_velocity
		elif not has_double_jumped:
			velocity.y = double_jump_velocity
			has_double_jumped = true

func handle_animations():
	if animation_tree:
		animation_tree.set("parameters/conditions/is_idle", is_on_floor() and abs(velocity.x) < 1.0 and !is_blocking)
		animation_tree.set("parameters/conditions/is_running", is_on_floor() and abs(velocity.x) > 1.0 and !is_blocking)
		animation_tree.set("parameters/conditions/is_jumping", !is_on_floor() and !is_blocking)
		animation_tree.set("parameters/conditions/is_falling", velocity.y > 0 and !is_on_floor() and !is_blocking)
		animation_tree.set("parameters/conditions/is_blocking", is_blocking)
		animation_tree.set("parameters/conditions/block_release", !is_blocking)

func handle_block():
	is_blocking = Input.is_action_pressed("block")
	return is_blocking

# Функция для сброса состояния (может пригодиться)
func reset_state():
	is_blocking = false
	sprite.scale = original_scale
