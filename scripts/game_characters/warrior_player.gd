extends "res://scripts/game_characters/base_game_character.gd"

# ===========================================
# ВОИН - ТАНК/ЗАЩИТНИК (ИСПРАВЛЕНО v3.0)
# ===========================================
#
# ИСПРАВЛЕНО:
# - Броня правильно суммируется: БАЗА + ЭКИПИРОВКА + ЗЕЛЬЕ + БЛОК
# - При снятии блока броня не сбрасывается к базе

# Блок
var block_cooldown: float = 0.0
var is_block_active: bool = false  # Отслеживаем активен ли блок

# БАЗОВАЯ броня персонажа (без модификаторов)
var warrior_base_armor: int = 2

# Для совместимости с другими системами
var base_armor: int = 2

# Бонус от блока
var block_armor_bonus: int = 0

# Константы
const BLOCK_COOLDOWN_TIME: float = 3.0
const BLOCK_ARMOR_BONUS_VALUE: int = 2
const BASE_DAMAGE: int = 2
const ATTACK_RANGE: float = 55.0

# === ВНЕШНИЕ БОНУСЫ (от экипировки и зелий) ===
# Эти переменные обновляются из level1.gd
var equipment_armor_bonus: int = 0
var potion_armor_bonus: int = 0

func _ready():
	print("\n=== 🛡️ ИНИЦИАЛИЗАЦИЯ ВОИНА ===")
	
	# Характеристики
	character_name = "Воин"
	max_health = 12
	current_health = 12
	max_mana = 0
	current_mana = 0
	
	# БАЗОВАЯ броня
	warrior_base_armor = 2
	armor = warrior_base_armor
	base_armor = warrior_base_armor  # Для совместимости
	
	# Базовый урон
	current_damage = BASE_DAMAGE
	
	# Скорость и прыжок
	base_speed = 180
	current_speed = 180
	max_speed = 180.0
	jump_velocity = -350
	
	print("📊 Характеристики:")
	print("  HP: ", current_health, "/", max_health)
	print("  MP: ", current_mana, "/", max_mana, " (скрыто)")
	print("  ARM: ", armor, " (база)")
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
# РАСЧЁТ ИТОГОВОЙ БРОНИ
# ===========================================

func recalculate_armor():
	"""Пересчитывает итоговую броню с учётом ВСЕХ модификаторов"""
	var old_armor = armor
	
	# Итого = База + Экипировка + Зелья + Блок
	armor = warrior_base_armor + equipment_armor_bonus + potion_armor_bonus + block_armor_bonus
	
	# Обновляем base_armor (для совместимости с родительским классом)
	# base_armor = база + экипировка (без зелий и блока)
	base_armor = warrior_base_armor + equipment_armor_bonus
	
	if armor != old_armor:
		print("🛡️ Броня пересчитана: %d (база %d + экип %d + зелье %d + блок %d)" % [
			armor, warrior_base_armor, equipment_armor_bonus, potion_armor_bonus, block_armor_bonus
		])


func set_equipment_armor(bonus: int):
	"""Устанавливает бонус брони от экипировки"""
	equipment_armor_bonus = bonus
	recalculate_armor()


func set_potion_armor(bonus: int):
	"""Устанавливает бонус брони от зелий"""
	potion_armor_bonus = bonus
	recalculate_armor()


func add_potion_armor(bonus: int):
	"""Добавляет бонус брони от зелья"""
	potion_armor_bonus += bonus
	recalculate_armor()


func reset_potion_bonuses():
	"""Сбрасывает бонусы от зелий (при смене комнаты/смерти)"""
	potion_armor_bonus = 0
	recalculate_armor()

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
	"""Поднимает щит - ДОБАВЛЯЕТ бонус к текущей броне"""
	if is_dead or is_attacking or is_casting or is_sliding:
		return
	
	print("\n🛡️ ЩИТ ПОДНЯТ!")
	
	is_blocking = true
	is_block_active = true
	
	# Добавляем бонус от блока
	block_armor_bonus = BLOCK_ARMOR_BONUS_VALUE
	recalculate_armor()
	
	velocity.x = 0
	play_animation("shield_defence")
	
	print("  Итого броня: %d" % armor)

func stop_blocking():
	"""Опускает щит - УБИРАЕТ только бонус от блока"""
	if not is_blocking:
		return
	
	print("🛡️ ЩИТ ОПУЩЕН!")
	
	is_blocking = false
	is_block_active = false
	
	# Убираем ТОЛЬКО бонус от блока
	block_armor_bonus = 0
	recalculate_armor()
	
	block_cooldown = BLOCK_COOLDOWN_TIME
	
	print("  Итого броня: %d" % armor)

# ===========================================
# АТАКА - УРОН НА 4-М КАДРЕ
# ===========================================

var _attack_damage_dealt: bool = false

func attack():
	"""Атака воина - урон на 4-м кадре"""
	if is_dead or is_blocking or is_casting or is_sliding or is_crouching or is_attacking:
		return
	
	print("\n⚔️ ВОИН АТАКУЕТ!")
	is_attacking = true
	_attack_damage_dealt = false
	
	play_animation("attack")
	
	if animated_sprite and not animated_sprite.frame_changed.is_connected(_on_attack_frame):
		animated_sprite.frame_changed.connect(_on_attack_frame)
	
	if animated_sprite:
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout
	
	if animated_sprite and animated_sprite.frame_changed.is_connected(_on_attack_frame):
		animated_sprite.frame_changed.disconnect(_on_attack_frame)
	
	is_attacking = false
	handle_animations()

func _on_attack_frame():
	"""Урон на 4-м кадре (индекс 3)"""
	if not is_attacking or _attack_damage_dealt:
		return
	
	if animated_sprite.frame == 3:
		_deal_damage_to_enemies()
		_attack_damage_dealt = true
		print("🎯 Урон на кадре 4!")

func _deal_damage_to_enemies():
	"""Наносит урон врагам"""
	if not animated_sprite:
		return
	
	var dir = -1 if animated_sprite.flip_h else 1
	var center = global_position + Vector2(40 * dir, 0)
	
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 55
	query.shape = shape
	query.transform = Transform2D(0, center)
	
	for result in space.intersect_shape(query):
		var body = result["collider"]
		if body != self and body.has_method("take_damage"):
			body.take_damage(current_damage, "physical")
			print("🎯 Попадание! Урон:", current_damage)
			
			if Global and Global.has_method("add_damage_dealt"):
				Global.add_damage_dealt(current_damage)

# ===========================================
# ПОЛУЧЕНИЕ УРОНА
# ===========================================

func take_damage(amount: int, damage_type: String = "physical", source: String = "Неизвестно"):
	"""Получение урона с учётом брони"""
	if is_dead:
		return
	
	last_damage_source = source
	
	print("\n💥 ВОИН ПОЛУЧАЕТ УРОН!")
	print("  Входящий: ", amount, " (", damage_type, ")")
	print("  Текущая броня: ", armor)
	
	var final_damage: int
	if damage_type == "magical":
		final_damage = amount - int(armor * 0.5)
	else:
		final_damage = amount - armor
	
	final_damage = max(1, final_damage)
	
	print("  Итоговый урон: ", final_damage)
	print("  HP до: ", current_health)
	
	current_health -= final_damage
	current_health = max(0, current_health)
	
	print("  HP после: ", current_health)
	
	if Global and Global.has_method("add_damage_taken"):
		Global.add_damage_taken(final_damage)
	
	health_changed.emit(current_health)
	_show_damage_effect()
	
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
	if Global and Global.game_ui and Global.game_ui.has_method("update_ability_cooldown"):
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
