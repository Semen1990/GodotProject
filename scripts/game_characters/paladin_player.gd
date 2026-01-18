extends "res://scripts/game_characters/base_game_character.gd"

# ===========================================
# ПАЛАДИН - ЦЕЛИТЕЛЬ/ЗАЩИТНИК (ИСПРАВЛЕННАЯ ВЕРСИЯ)
# ===========================================

# Кулдаун и состояние лечения
var heal_cooldown: float = 0.0
var is_healing: bool = false

# НАСТРОЙКИ ПАЛАДИНА (легко изменить)
const HEAL_COST: int = 10        # Стоимость лечения в мане
const HEAL_AMOUNT: int = 2      # Количество восстанавливаемого HP
const HEAL_COOLDOWN_TIME: float = 5.0  # Кулдаун лечения
const HEAL_CAST_TIME: float = 1.0      # Время каста заклинания

func _ready():
	# === ХАРАКТЕРИСТИКИ ПАЛАДИНА ===
	character_name = "Паладин"
	max_health = 8
	current_health = 8  # Начинаем не с полным HP для демонстрации лечения
	max_mana = 10
	current_mana = 10
	armor = 1
	
	# === ФИЗИКА ===
	jump_velocity = -380
	base_speed = 200
	current_speed = 200
	max_speed = 200.0
	
	print("✨ Паладин освещает путь!")
	super()

func _physics_process(delta):
	# Обновляем кулдаун лечения
	if heal_cooldown > 0:
		heal_cooldown -= delta
	
	super(delta)

# ===========================================
# СПЕЦИАЛЬНАЯ СПОСОБНОСТЬ (E) - ИСЦЕЛЕНИЕ
# ===========================================

func use_special_ability():
	"""Паладин: Исцеление (вызывается при нажатии E)"""
	heal()

func heal():
	"""Начинает процесс исцеления"""
	print("\n=== ✨ ПОПЫТКА ИСЦЕЛЕНИЯ ===")
	print("Здоровье: ", current_health, "/", max_health)
	print("Мана: ", current_mana, "/", max_mana)
	print("Кулдаун: ", heal_cooldown)
	
	# === ПРОВЕРКИ ===
	
	# 1. Здоровье полное?
	if current_health >= max_health:
		print("❌ Здоровье уже полное!")
		return
	
	# 2. Достаточно маны?
	if current_mana < HEAL_COST:
		print("❌ Недостаточно маны! Нужно: ", HEAL_COST, ", есть: ", current_mana)
		return
	
	# 3. Кулдаун?
	if heal_cooldown > 0:
		print("❌ На кулдауне! Осталось: %.1f сек" % heal_cooldown)
		return
	
	# 4. Уже лечится?
	if is_healing:
		print("❌ Уже лечится!")
		return
	
	# 5. Занят другим действием?
	if is_attacking or is_blocking or is_sliding or is_casting:
		print("❌ Персонаж занят другим действием!")
		return
	
	# === ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ ===
	_start_healing()

func _start_healing():
	"""Начинает процесс исцеления"""
	print("\n✨ === ИСЦЕЛЕНИЕ НАЧАТО ===")
	
	is_healing = true
	is_casting = true
	
	# Тратим ману
	current_mana -= HEAL_COST
	mana_changed.emit(current_mana)
	print("💙 Потрачено маны: ", HEAL_COST)
	
	# Останавливаем персонажа
	velocity.x = 0
	
	# Проигрываем анимацию каста
	play_animation("spellcast")
	
	# Ждем завершения каста
	_wait_for_heal_completion()

func _wait_for_heal_completion():
	"""Ожидает завершения каста"""
	var timer = get_tree().create_timer(HEAL_CAST_TIME)
	await timer.timeout
	
	# Проверяем что каст не был прерван
	if not is_healing:
		print("⚠️ Исцеление было прервано!")
		return
	
	_complete_healing()

func _complete_healing():
	"""Завершает исцеление и восстанавливает здоровье"""
	print("\n❤️ === ИСЦЕЛЕНИЕ ЗАВЕРШЕНО ===")
	
	# Восстанавливаем здоровье
	var old_health = current_health
	current_health = min(current_health + HEAL_AMOUNT, max_health)
	var actual_heal = current_health - old_health
	
	health_changed.emit(current_health)
	
	print("💚 Восстановлено: ", actual_heal)
	print("💚 Текущее здоровье: ", current_health, "/", max_health)
	
	# Устанавливаем кулдаун
	heal_cooldown = HEAL_COOLDOWN_TIME
	
	# Сбрасываем флаги
	is_healing = false
	is_casting = false
	
	# Возвращаемся к обычной анимации
	handle_animations()

# ===========================================
# ПОЛУЧЕНИЕ УРОНА (ИСПРАВЛЕННАЯ СИГНАТУРА!)
# ===========================================

func take_damage(amount: int, damage_type: String = "physical", source: String = "Неизвестно"):
	"""
	Переопределяем получение урона - прерываем исцеление
	ВАЖНО: Сигнатура должна совпадать с родителем!
	"""
	# Вызываем родительскую функцию с ВСЕМИ параметрами
	super.take_damage(amount, damage_type, source)
	
	# Прерываем исцеление если идет
	if is_healing:
		print("💔 Исцеление прервано уроном от: ", source)
		_interrupt_healing()

func _interrupt_healing():
	"""Прерывает процесс исцеления"""
	is_healing = false
	is_casting = false
	
	# Опционально: вернуть часть маны
	# current_mana = min(current_mana + HEAL_COST / 2, max_mana)
	# mana_changed.emit(current_mana)
	
	handle_animations()
