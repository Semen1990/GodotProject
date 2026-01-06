extends "res://scripts/game_characters/base_game_character.gd"

var heal_cooldown: float = 0.0
var is_healing: bool = false  # ДОБАВЛЕНО: флаг процесса исцеления

# НАСТРОЙКИ
const HEAL_COST: int = 10
const HEAL_AMOUNT: int = 25
const HEAL_COOLDOWN_TIME: float = 5.0
const HEAL_CAST_TIME: float = 1.0  # Время каста заклинания

func _ready():
	character_name = "Паладин"
	max_health = 130
	current_health = 100
	max_mana = 50
	current_mana = 50
	armor = 6
	jump_velocity = -380
	base_speed = 200
	current_speed = 200
	max_speed = 200.0
	
	print("✨ Паладин освещает путь!")
	super()

func _physics_process(delta):
	if heal_cooldown > 0:
		heal_cooldown -= delta
	
	super(delta)

func heal():
	print("\n=== ✨ ПОПЫТКА ИСЦЕЛЕНИЯ ===")
	print("Здоровье: ", current_health, "/", max_health)
	print("Мана: ", current_mana, "/", max_mana)
	print("Кулдаун: ", heal_cooldown)
	print("Уже лечится: ", is_healing)
	print("Атакует: ", is_attacking)
	print("Блокирует: ", is_blocking)
	print("Скользит: ", is_sliding)
	print("Кастует: ", is_casting)
	
	# Проверка 1: Здоровье полное?
	if current_health >= max_health:
		print("❌ Здоровье уже полное!")
		return
	
	# Проверка 2: Достаточно маны?
	if current_mana < HEAL_COST:
		print("❌ Недостаточно маны! Нужно: ", HEAL_COST, ", есть: ", current_mana)
		return
	
	# Проверка 3: Кулдаун?
	if heal_cooldown > 0:
		print("❌ На кулдауне! Осталось: %.1f сек" % heal_cooldown)
		return
	
	# Проверка 4: Занят?
	if is_healing:
		print("❌ Уже лечится!")
		return
	
	if is_attacking or is_blocking or is_sliding or is_casting:
		print("❌ Персонаж занят другим действием!")
		return
	
	# ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ - начинаем исцеление
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
	print("💙 Осталось маны: ", current_mana)
	
	# Останавливаем персонажа
	velocity.x = 0
	
	# Проигрываем анимацию
	play_animation("spellcast")
	print("🎭 Анимация: spellcast")
	
	# ВАЖНО: Ждем завершения анимации ИЛИ таймер
	_wait_for_heal_completion()

func _wait_for_heal_completion():
	"""Ожидает завершения каста"""
	# Используем таймер вместо await для надежности
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
	print("⏰ Кулдаун: ", HEAL_COOLDOWN_TIME, " сек")
	
	# Сбрасываем флаги
	is_healing = false
	is_casting = false
	
	# Возвращаемся к обычной анимации
	handle_animations()
	
	print("=== ✅ ПРОЦЕСС ЗАВЕРШЕН ===\n")

func take_damage(amount: int):
	"""Переопределяем получение урона - прерываем исцеление"""
	super.take_damage(amount)
	
	# Прерываем исцеление если идет
	if is_healing:
		print("💔 Исцеление прервано уроном!")
		_interrupt_healing()

func _interrupt_healing():
	"""Прерывает процесс исцеления"""
	is_healing = false
	is_casting = false
	
	# Можно вернуть часть маны
	# current_mana = min(current_mana + HEAL_COST / 2, max_mana)
	# mana_changed.emit(current_mana)
	
	handle_animations()
