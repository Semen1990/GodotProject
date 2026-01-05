extends "res://scripts/game_characters/base_game_character.gd"

# Система комбо
var combo_stage: int = 0  # 0 = нет комбо, 1 = первая атака, 2 = вторая, 3 = третья
var combo_timer: float = 0.0
const COMBO_WINDOW: float = 1  # Окно для продолжения комбо
const COMBO_RESET_TIME: float = 1.5  # Время до сброса комбо

# Урон
const BASE_DAMAGE: int = 10
var last_target = null

func _ready():
	character_name = "Берсерк"
	max_health = 120
	current_health = 120
	max_mana = 20
	current_mana = 20
	armor = 5
	jump_velocity = -400
	base_speed = 220
	current_speed = 220
	max_speed = 220.0
	
	print("🔪 Берсерк наполнен яростью!")
	super()

func _physics_process(delta):
	# Обновляем таймер комбо
	if combo_timer > 0:
		combo_timer -= delta
		
		# Сбрасываем комбо если время вышло
		if combo_timer <= 0:
			_reset_combo()
	
	super(delta)

func attack():
	if is_dead or is_blocking or is_casting or is_sliding:
		print("⚠️ Берсерк занят!")
		return
	
	# ИСПРАВЛЕНО: проверяем можно ли продолжить комбо
	if is_attacking and combo_timer <= 0:
		print("⚠️ Слишком поздно для комбо!")
		return
	
	# Определяем какую атаку делать
	var next_combo = combo_stage + 1
	
	if next_combo > 3:
		print("⚠️ Комбо уже завершено!")
		return
	
	print("⚔️ Берсерк: атака ", next_combo)
	
	combo_stage = next_combo
	is_attacking = true
	
	# Выбираем анимацию
	var anim_name = "attack"
	if combo_stage == 2:
		anim_name = "attack2"
	elif combo_stage == 3:
		anim_name = "attack3"
	
	# ИСПРАВЛЕНО: рассчитываем урон
	var damage = _calculate_damage()
	print("💥 Урон атаки ", combo_stage, ": ", damage)
	
	play_animation(anim_name)
	
	# Ждем окончания анимации
	if animated_sprite:
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout
	
	is_attacking = false
	
	# ИСПРАВЛЕНО: устанавливаем окно для следующей атаки
	if combo_stage < 3:
		combo_timer = COMBO_WINDOW
		print("⏰ Окно для атаки ", combo_stage + 1, ": ", COMBO_WINDOW, " сек")
	else:
		# Третья атака - сбрасываем комбо
		combo_timer = COMBO_RESET_TIME
		print("✅ Комбо завершено! Сброс через ", COMBO_RESET_TIME, " сек")
	
	handle_animations()

func _calculate_damage() -> int:
	"""Рассчитывает урон в зависимости от стадии комбо"""
	var damage = BASE_DAMAGE
	
	match combo_stage:
		1:
			# Первая атака: базовый урон
			damage = BASE_DAMAGE
			print("  Обычная атака")
		
		2:
			# Вторая атака: 50% шанс x2
			damage = BASE_DAMAGE
			if randf() < 0.5:
				damage = BASE_DAMAGE * 2
				print("  ⚡ КРИТИЧЕСКИЙ УДАР x2!")
			else:
				print("  Обычная атака")
		
		3:
			# Третья атака: всегда критический + бонус
			damage = (BASE_DAMAGE * 2) + 2
			print("  💥 ФИНИШЕР! x2 + 2 урона!")
	
	return damage

func _reset_combo():
	"""Сбрасывает комбо"""
	if combo_stage > 0:
		print("🔄 Комбо сброшено (было на стадии ", combo_stage, ")")
	combo_stage = 0
	combo_timer = 0.0

func deal_damage_to_target(target):
	"""Наносит урон цели с учетом комбо"""
	if not target or not target.has_method("take_damage"):
		return
	
	var damage = _calculate_damage()
	target.take_damage(damage)
	print("🎯 Нанесено урона: ", damage)

func take_damage(amount: int):
	# Ярость при низком здоровье (из оригинала)
	if current_health < max_health * 0.3:
		var reduced_amount = int(amount * 0.7)
		print("🛡️ Ярость защищает! Урон: ", amount, " → ", reduced_amount)
		super.take_damage(reduced_amount)
	else:
		super.take_damage(amount)
	
	# ОПЦИОНАЛЬНО: сбрасываем комбо при получении урона
	# _reset_combo()
