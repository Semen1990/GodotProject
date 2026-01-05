extends "res://scripts/game_characters/base_game_character.gd"

var heal_cooldown: float = 0.0
const HEAL_COST: int = 10
const HEAL_AMOUNT: int = 25
const HEAL_COOLDOWN_TIME: float = 5.0

func _ready():
	character_name = "Паладин"
	max_health = 130
	current_health = 130
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
	# ИСПРАВЛЕНО: добавлены все проверки
	print("🔍 Попытка исцеления...")
	print("  Мана: ", current_mana, "/", max_mana)
	print("  Кулдаун: ", heal_cooldown)
	print("  Атакует: ", is_attacking)
	print("  Блокирует: ", is_blocking)
	print("  Скользит: ", is_sliding)
	print("  Здоровье: ", current_health, "/", max_health)
	
	# Проверки
	if current_health >= max_health:
		print("⚠️ Здоровье уже полное!")
		return
	
	if current_mana < HEAL_COST:
		print("⚠️ Недостаточно маны! Нужно: ", HEAL_COST)
		return
	
	if heal_cooldown > 0:
		print("⚠️ Способность на кулдауне! Осталось: ", heal_cooldown)
		return
	
	if is_attacking or is_blocking or is_sliding or is_casting:
		print("⚠️ Персонаж занят другим действием!")
		return
	
	# Начинаем каст
	is_casting = true
	current_mana -= HEAL_COST
	mana_changed.emit(current_mana)
	
	print("✨ Паладин начинает исцеление!")
	print("  Потрачено маны: ", HEAL_COST)
	print("  Осталось маны: ", current_mana)
	
	play_animation("spellcast")
	
	# Ждем окончания анимации
	if animated_sprite:
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(1.0).timeout
	
	# Применяем исцеление
	var old_health = current_health
	current_health = min(current_health + HEAL_AMOUNT, max_health)
	var actual_heal = current_health - old_health
	
	heal_cooldown = HEAL_COOLDOWN_TIME
	health_changed.emit(current_health)
	is_casting = false
	
	print("❤️ Исцеление завершено!")
	print("  Восстановлено: ", actual_heal)
	print("  Здоровье: ", current_health, "/", max_health)
	print("  Кулдаун: ", HEAL_COOLDOWN_TIME, " сек")
	
	handle_animations()
