extends "res://scripts/game_characters/base_game_character.gd"

# ===========================================
# ВОИН - ТАНК/ЗАЩИТНИК (v2.0 ИСПРАВЛЕННЫЙ)
# ===========================================

# Блок
var block_cooldown: float = 0.0
var base_armor: int = 2

# Константы
const BLOCK_COOLDOWN_TIME: float = 3.0
const BLOCK_ARMOR_BONUS: int = 2
const BASE_DAMAGE: int = 2
const ATTACK_RANGE: float = 55.0  # Дальность атаки воина

func _ready():
	print("\n=== 🛡️ ИНИЦИАЛИЗАЦИЯ ВОИНА ===")
	
	# Характеристики
	character_name = "Воин"
	max_health = 12
	current_health = 12
	max_mana = 0
	current_mana = 0
	armor = 2
	base_armor = 2
	
	# Скорость и прыжок
	base_speed = 180
	current_speed = 180
	max_speed = 180.0
	jump_velocity = -350
	
	print("📊 Характеристики:")
	print("  HP: ", current_health, "/", max_health)
	print("  MP: ", current_mana, "/", max_mana, " (скрыто)")
	print("  ARM: ", armor)
	print("  DMG: ", BASE_DAMAGE)
	
	print("🛡️ Воин готов к битве!")
	super()

func _physics_process(delta):
	# Обновляем кулдаун блока
	if block_cooldown > 0:
		block_cooldown -= delta
		_update_block_cooldown_ui()
	
	super(delta)

func _input(event):
	# Отпускание кнопки E - опускаем щит
	if event.is_action_released("special_ability") and is_blocking:
		stop_blocking()

# ===========================================
# СПЕЦИАЛЬНАЯ СПОСОБНОСТЬ (E) - БЛОК ЩИТОМ
# ===========================================

func use_special_ability():
	"""Воин: Блок щитом"""
	if is_blocking:
		return
	
	if block_cooldown > 0:
		print("❌ Блок на кулдауне! Осталось: %.1f сек" % block_cooldown)
		return
	
	block()

func block():
	"""Поднимает щит"""
	if is_dead or is_attacking or is_casting or is_sliding:
		return
	
	print("\n🛡️ ЩИТ ПОДНЯТ!")
	
	is_blocking = true
	armor = base_armor + BLOCK_ARMOR_BONUS
	velocity.x = 0
	
	print("  Броня: ", base_armor, " → ", armor)

func stop_blocking():
	"""Опускает щит"""
	if not is_blocking:
		return
	
	print("🛡️ ЩИТ ОПУЩЕН!")
	
	is_blocking = false
	armor = base_armor
	block_cooldown = BLOCK_COOLDOWN_TIME

# ===========================================
# АТАКА - УРОН В КОНЦЕ АНИМАЦИИ
# ===========================================

func attack():
	"""Атака воина - урон наносится В КОНЦЕ анимации"""
	# Проверки
	if is_dead or is_blocking or is_casting or is_sliding or is_crouching:
		return
	
	if is_attacking:
		return
	
	print("\n⚔️ ВОИН АТАКУЕТ!")
	
	is_attacking = true
	play_animation("attack")
	
	# СНАЧАЛА ждём окончания анимации
	if animated_sprite:
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout
	
	# ПОТОМ наносим урон (в конце анимации)
	_deal_damage_to_enemies()
	
	is_attacking = false
	handle_animations()

func _deal_damage_to_enemies():
	"""Наносит урон всем врагам в радиусе атаки"""
	if not animated_sprite:
		return
	
	# Направление атаки
	var attack_direction = -1 if animated_sprite.flip_h else 1
	var attack_center = global_position + Vector2(35 * attack_direction, 0)
	
	print("🎯 Проверяем попадание...")
	
	# Ищем врагов через физику
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = ATTACK_RANGE
	query.shape = shape
	query.transform = Transform2D(0, attack_center)
	query.collision_mask = 0xFFFFFFFF  # Все слои
	
	var results = space_state.intersect_shape(query)
	
	var hit_count = 0
	for result in results:
		var body = result["collider"]
		# Проверяем что это враг (не игрок)
		if body != self and body.has_method("take_damage"):
			body.take_damage(BASE_DAMAGE, "physical")
			hit_count += 1
			print("🎯 Попадание по: ", body.name, " | Урон: ", BASE_DAMAGE)
	
	if hit_count == 0:
		print("❌ Промах - нет врагов в радиусе")

# ===========================================
# ПОЛУЧЕНИЕ УРОНА
# ===========================================

func take_damage(amount: int, damage_type: String = "physical"):
	"""Получение урона с учётом брони"""
	if is_dead:
		return
	
	print("\n💥 ВОИН ПОЛУЧАЕТ УРОН!")
	print("  Входящий: ", amount, " (", damage_type, ")")
	print("  Броня: ", armor)
	
	# Рассчитываем урон
	var final_damage: int
	if damage_type == "magical":
		final_damage = amount - int(armor / 2)
	else:
		final_damage = amount - armor
	
	# Минимум 1 урон
	final_damage = max(1, final_damage)
	
	print("  Итоговый урон: ", final_damage)
	print("  HP до: ", current_health)
	
	current_health -= final_damage
	current_health = max(0, current_health)
	
	print("  HP после: ", current_health)
	
	# Обновляем UI
	health_changed.emit(current_health)
	
	# Визуальный эффект
	_show_damage_effect()
	
	# Проверка смерти
	if current_health <= 0:
		die()

func _show_damage_effect():
	"""Красная вспышка при получении урона"""
	if not animated_sprite:
		return
	
	var original = animated_sprite.modulate
	animated_sprite.modulate = Color(2.0, 0.5, 0.5, 1.0)
	
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", original, 0.2)

# ===========================================
# UI
# ===========================================

func _update_block_cooldown_ui():
	"""Обновляет UI кулдауна"""
	if Global.game_ui and Global.game_ui.has_method("update_ability_cooldown"):
		var percent = 1.0 - (block_cooldown / BLOCK_COOLDOWN_TIME)
		Global.game_ui.update_ability_cooldown("block", percent)

# ===========================================
# АРТЕФАКТЫ
# ===========================================

func apply_artifacts():
	"""Применяет артефакты"""
	super.apply_artifacts()
	
	if max_mana > 0:
		print("💙 Воин получил ману: ", max_mana)
