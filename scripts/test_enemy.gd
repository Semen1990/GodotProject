# test_enemy.gd
extends CharacterBody2D

# Характеристики
var max_health: int = 4
var current_health: int = 4
var damage: int = 2
var attack_range: float = 60.0
var attack_cooldown: float = 0.0
var attack_delay: float = 2.0  # Атакует каждые 2 секунды

# Состояния
var is_dead: bool = false
var player: Node = null

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var detection_area = $DetectionArea

func _ready():
	print("👹 Тестовый враг создан")
	print("  HP: ", current_health, "/", max_health)
	print("  DMG: ", damage)
	
	# Настраиваем Detection Area
	if detection_area:
		detection_area.body_entered.connect(_on_player_detected)
		detection_area.body_exited.connect(_on_player_lost)

func _physics_process(delta):
	if is_dead:
		return
	
	# Обновляем кулдаун атаки
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	# Если игрок рядом - атакуем
	if player and attack_cooldown <= 0:
		_try_attack()
	
	move_and_slide()

func _on_player_detected(body):
	"""Игрок вошёл в зону обнаружения"""
	if body.has_method("take_damage"):
		player = body
		print("👹 Враг обнаружил игрока!")

func _on_player_lost(body):
	"""Игрок вышел из зоны"""
	if body == player:
		player = null
		print("👹 Враг потерял игрока")

func _try_attack():
	"""Пытается атаковать игрока"""
	if not player:
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	if distance <= attack_range:
		_attack_player()

func _attack_player():
	"""Атакует игрока"""
	if not player or not player.has_method("take_damage"):
		return
	
	print("\n👹 ВРАГ АТАКУЕТ!")
	print("  Урон: ", damage)
	
	# Наносим урон (физический)
	player.take_damage(damage, "physical")
	
	# Устанавливаем кулдаун
	attack_cooldown = attack_delay
	
	# Визуальный эффект атаки
	_show_attack_effect()

func take_damage(amount: int, damage_type: String = "physical"):
	"""Враг получает урон"""
	if is_dead:
		return
	
	print("\n👹 ВРАГ ПОЛУЧАЕТ УРОН!")
	print("  Урон: ", amount)
	print("  HP до: ", current_health)
	
	current_health -= amount
	current_health = max(0, current_health)
	
	print("  HP после: ", current_health)
	
	# Визуальный эффект
	_show_damage_effect()
	
	# Проверка смерти
	if current_health <= 0:
		die()

func die():
	"""Смерть врага"""
	if is_dead:
		return
	
	is_dead = true
	
	print("💀 ВРАГ УБИТ!")
	
	# Отключаем коллизию
	if collision:
		collision.set_deferred("disabled", true)
	
	# Анимация смерти
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 1.0)
		tween.tween_callback(queue_free)
	else:
		# Если нет спрайта - удаляем сразу через 1 секунду
		await get_tree().create_timer(1.0).timeout
		queue_free()

func _show_damage_effect():
	"""Эффект получения урона"""
	if not sprite:
		return
	
	var original = sprite.modulate
	sprite.modulate = Color(2.0, 0.5, 0.5, 1.0)
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", original, 0.2)

func _show_attack_effect():
	"""Эффект атаки"""
	if not sprite:
		return
	
	# Небольшое дёргание вперёд
	var original_pos = sprite.position
	sprite.position.x += 10
	
	var tween = create_tween()
	tween.tween_property(sprite, "position", original_pos, 0.1)
