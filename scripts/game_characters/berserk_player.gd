extends "res://scripts/game_characters/base_game_character.gd"

# Система комбо
var combo_stage: int = 0  # 0 = нет комбо, 1-3 = стадия комбо
var combo_window_active: bool = false  # Открыто ли окно для следующей атаки
var next_attack_queued: bool = false  # Нажата ли кнопка во время атаки
var combo_reset_timer: float = 0.0

# НАСТРОЙКИ КОМБО (можно менять)
const COMBO_WINDOW_DURATION: float = 1.2  # Окно после атаки для продолжения (секунды)
const COMBO_FULL_RESET_TIME: float = 2.0  # Время полного сброса комбо

# Урон
const BASE_DAMAGE: int = 10

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
	# Таймер сброса комбо
	if combo_reset_timer > 0:
		combo_reset_timer -= delta
		if combo_reset_timer <= 0:
			_reset_combo()
	
	super(delta)

func attack():
	print("\n=== 🗡️ ПОПЫТКА АТАКИ ===")
	print("Комбо стадия: ", combo_stage)
	print("Атакует сейчас: ", is_attacking)
	print("Окно активно: ", combo_window_active)
	
	# Базовые проверки
	if is_dead or is_blocking or is_casting or is_sliding:
		print("❌ Берсерк занят другим действием!")
		return
	
	# ЕСЛИ УЖЕ АТАКУЕТ - ставим атаку в очередь
	if is_attacking:
		next_attack_queued = true
		print("⏳ Атака поставлена в очередь")
		return
	
	# ЕСЛИ ОКНО КОМБО ЗАКРЫТО - сбрасываем
	if combo_stage > 0 and not combo_window_active:
		print("⏰ Окно комбо закрыто, сброс...")
		_reset_combo()
	
	# Выполняем атаку
	_execute_attack()

func _execute_attack():
	"""Выполняет атаку"""
	combo_stage += 1
	
	# Ограничиваем комбо тремя атаками
	if combo_stage > 3:
		combo_stage = 1
		print("🔄 Комбо завершено, начинаем заново")
	
	is_attacking = true
	combo_window_active = false  # Закрываем окно на время атаки
	next_attack_queued = false
	
	print("\n⚔️ === АТАКА ", combo_stage, " ===")
	
	# Выбираем анимацию
	var anim_name = "attack"
	if combo_stage == 2 and animated_sprite.sprite_frames.has_animation("attack2"):
		anim_name = "attack2"
	elif combo_stage == 3 and animated_sprite.sprite_frames.has_animation("attack3"):
		anim_name = "attack3"
	
	# Рассчитываем урон
	var damage = _calculate_damage()
	print("💥 Урон: ", damage)
	
	play_animation(anim_name)
	
	# Ждем окончания анимации
	if animated_sprite:
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout
	
	is_attacking = false
	
	# После атаки - открываем окно для следующей
	if combo_stage < 3:
		combo_window_active = true
		combo_reset_timer = COMBO_WINDOW_DURATION
		print("✅ Окно для атаки ", combo_stage + 1, " открыто на ", COMBO_WINDOW_DURATION, " сек")
	else:
		# После третьей атаки - финальный таймер сброса
		combo_window_active = false
		combo_reset_timer = COMBO_FULL_RESET_TIME
		print("💥 КОМБО ЗАВЕРШЕНО! Финишер нанесён!")
	
	# Если была нажата кнопка во время атаки - продолжаем комбо
	if next_attack_queued and combo_stage < 3:
		print("⚡ Выполняем атаку из очереди")
		await get_tree().create_timer(0.1).timeout  # Небольшая задержка
		_execute_attack()
	else:
		handle_animations()

func _calculate_damage() -> int:
	"""Рассчитывает урон в зависимости от стадии комбо"""
	var damage = BASE_DAMAGE
	
	match combo_stage:
		1:
			# Первая атака: базовый урон
			damage = BASE_DAMAGE
			print("  → Обычная атака")
		
		2:
			# Вторая атака: 50% шанс x2
			damage = BASE_DAMAGE
			if randf() < 0.5:
				damage = BASE_DAMAGE * 2
				print("  → ⚡ КРИТИЧЕСКИЙ УДАР x2!")
			else:
				print("  → Обычная атака")
		
		3:
			# Третья атака: всегда критический + бонус
			damage = (BASE_DAMAGE * 2) + 2
			print("  → 💥 ФИНИШЕР! Критический урон x2 + 2!")
	
	return damage

func _reset_combo():
	"""Сбрасывает комбо"""
	if combo_stage > 0:
		print("🔄 === КОМБО СБРОШЕНО === (было на стадии ", combo_stage, ")")
	combo_stage = 0
	combo_window_active = false
	combo_reset_timer = 0.0
	next_attack_queued = false

func take_damage(amount: int):
	# Ярость при низком здоровье
	if current_health < max_health * 0.3:
		var reduced_amount = int(amount * 0.7)
		print("🛡️ Ярость защищает! Урон: ", amount, " → ", reduced_amount)
		super.take_damage(reduced_amount)
	else:
		super.take_damage(amount)
	
	# Прерываем комбо при получении урона
	if combo_stage > 0:
		print("💔 Комбо прервано уроном!")
		_reset_combo()

# Для нанесения урона врагам (когда будут враги)
func deal_damage_to_target(target):
	"""Наносит урон цели с учетом комбо"""
	if not target or not target.has_method("take_damage"):
		return
	
	var damage = _calculate_damage()
	target.take_damage(damage)
	print("🎯 Цели нанесено урона: ", damage)
