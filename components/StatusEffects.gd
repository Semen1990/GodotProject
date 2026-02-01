extends Node
class_name StatusEffectsComponent

# ===========================================
# STATUS EFFECTS COMPONENT
# ===========================================
# Путь: res://scripts/components/StatusEffects.gd
#
# Добавляется как дочерний узел персонажа.
# Управляет всеми статус-эффектами на персонаже.

signal effect_applied(effect_type: int, stacks: int)
signal effect_removed(effect_type: int)
signal effect_tick(effect_type: int, value: float)

# Ссылка на владельца (персонаж)
var owner_character: Node = null

# Активные эффекты: {EffectType: BaseStatusEffect}
var active_effects: Dictionary = {}

# Модификаторы от эффектов
var speed_modifier: float = 1.0      # Множитель скорости (холод)
var damage_modifier: float = 1.0     # Множитель урона
var armor_modifier: int = 0          # Бонус брони
var is_stunned: bool = false         # Оглушён

# Визуальные эффекты
var effect_particles: Dictionary = {}


func _ready():
	owner_character = get_parent()
	if not owner_character:
		push_warning("StatusEffects: нет родительского узла!")


func _process(delta):
	_process_effects(delta)
	_update_modifiers()


func _process_effects(delta):
	"""Обрабатывает все активные эффекты"""
	var to_remove: Array = []
	
	for effect_type in active_effects:
		var effect: BaseStatusEffect = active_effects[effect_type]
		if not effect.process(delta):
			to_remove.append(effect_type)
	
	for effect_type in to_remove:
		_remove_effect(effect_type)


func _update_modifiers():
	"""Обновляет модификаторы от эффектов"""
	speed_modifier = 1.0
	damage_modifier = 1.0
	armor_modifier = 0
	is_stunned = false
	
	for effect_type in active_effects:
		var effect: BaseStatusEffect = active_effects[effect_type]
		
		match effect.effect_type:
			BaseStatusEffect.EffectType.FROST:
				speed_modifier *= (1.0 - effect.get_total_value() / 100.0)
			BaseStatusEffect.EffectType.BUFF_DAMAGE:
				damage_modifier += effect.get_total_value() / 100.0
			BaseStatusEffect.EffectType.BUFF_ARMOR:
				armor_modifier += int(effect.get_total_value())
			BaseStatusEffect.EffectType.STUN:
				is_stunned = true


# ===========================================
# ПРИМЕНЕНИЕ ЭФФЕКТОВ
# ===========================================

func apply_effect(effect: BaseStatusEffect) -> bool:
	"""Применяет эффект к персонажу"""
	if not effect or not owner_character:
		return false
	
	var effect_type = effect.effect_type
	
	# Если эффект уже есть - стакаем или обновляем
	if active_effects.has(effect_type):
		var existing: BaseStatusEffect = active_effects[effect_type]
		existing.stack()
		effect_applied.emit(effect_type, existing.current_stacks)
		return true
	
	# Применяем новый эффект
	if effect.apply(owner_character):
		active_effects[effect_type] = effect
		_create_effect_visual(effect_type)
		effect_applied.emit(effect_type, 1)
		print("✨ Эффект применён: %s" % effect.effect_name)
		return true
	
	return false


func _remove_effect(effect_type: int):
	"""Удаляет эффект"""
	if not active_effects.has(effect_type):
		return
	
	var effect: BaseStatusEffect = active_effects[effect_type]
	print("✨ Эффект снят: %s" % effect.effect_name)
	
	active_effects.erase(effect_type)
	_remove_effect_visual(effect_type)
	effect_removed.emit(effect_type)


func remove_effect(effect_type: int):
	"""Принудительно снимает эффект"""
	if active_effects.has(effect_type):
		active_effects[effect_type].remove()
		_remove_effect(effect_type)


func clear_all_effects():
	"""Снимает все эффекты"""
	for effect_type in active_effects.keys():
		remove_effect(effect_type)


func clear_debuffs():
	"""Снимает только негативные эффекты"""
	var debuff_types = [
		BaseStatusEffect.EffectType.BURN,
		BaseStatusEffect.EffectType.POISON,
		BaseStatusEffect.EffectType.BLEED,
		BaseStatusEffect.EffectType.FROST,
		BaseStatusEffect.EffectType.MADNESS,
		BaseStatusEffect.EffectType.STUN,
	]
	
	for effect_type in debuff_types:
		remove_effect(effect_type)


# ===========================================
# БЫСТРЫЕ МЕТОДЫ ПРИМЕНЕНИЯ
# ===========================================

func apply_burn(damage_per_tick: float, duration: float = 5.0):
	"""Применяет горение"""
	var effect = BurnEffect.new()
	effect.value = damage_per_tick
	effect.duration = duration
	apply_effect(effect)


func apply_poison(damage_per_tick: float, duration: float = 8.0):
	"""Применяет яд"""
	var effect = PoisonEffect.new()
	effect.value = damage_per_tick
	effect.duration = duration
	apply_effect(effect)


func apply_bleed(damage_per_tick: float, duration: float = 6.0):
	"""Применяет кровотечение"""
	var effect = BleedEffect.new()
	effect.value = damage_per_tick
	effect.duration = duration
	apply_effect(effect)


func apply_frost(slow_percent: float, duration: float = 4.0):
	"""Применяет замедление"""
	var effect = FrostEffect.new()
	effect.value = slow_percent
	effect.duration = duration
	apply_effect(effect)


func apply_stun(duration: float = 2.0):
	"""Применяет оглушение"""
	var effect = StunEffect.new()
	effect.duration = duration
	apply_effect(effect)


# ===========================================
# ПРОВЕРКИ
# ===========================================

func has_effect(effect_type: int) -> bool:
	return active_effects.has(effect_type)


func get_effect(effect_type: int) -> BaseStatusEffect:
	return active_effects.get(effect_type, null)


func get_effect_stacks(effect_type: int) -> int:
	if active_effects.has(effect_type):
		return active_effects[effect_type].current_stacks
	return 0


func is_affected_by_dot() -> bool:
	"""Проверяет, есть ли DOT эффекты"""
	var dot_types = [
		BaseStatusEffect.EffectType.BURN,
		BaseStatusEffect.EffectType.POISON,
		BaseStatusEffect.EffectType.BLEED,
	]
	for t in dot_types:
		if has_effect(t):
			return true
	return false


# ===========================================
# ВИЗУАЛЬНЫЕ ЭФФЕКТЫ
# ===========================================

func _create_effect_visual(effect_type: int):
	"""Создаёт визуальный эффект (частицы)"""
	# Переопределяется в наследниках или через сигналы
	pass


func _remove_effect_visual(effect_type: int):
	"""Убирает визуальный эффект"""
	if effect_particles.has(effect_type):
		effect_particles[effect_type].queue_free()
		effect_particles.erase(effect_type)


# ===========================================
# УРОН ОТ ЭФФЕКТОВ
# ===========================================

func deal_effect_damage(amount: float, effect_name: String):
	"""Наносит урон от эффекта"""
	if not owner_character:
		return
	
	if owner_character.has_method("take_damage"):
		owner_character.take_damage(int(amount), "effect", effect_name)
	elif "current_health" in owner_character:
		owner_character.current_health -= int(amount)
	
	effect_tick.emit(0, amount)
