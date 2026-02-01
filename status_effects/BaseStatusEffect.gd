extends Resource
class_name BaseStatusEffect

# ===========================================
# BASE STATUS EFFECT - БАЗОВЫЙ СТАТУС-ЭФФЕКТ
# ===========================================
# Путь: res://scripts/status_effects/BaseStatusEffect.gd
#
# Наследуйся для создания новых эффектов:
# - BurnEffect (огонь)
# - PoisonEffect (яд)
# - BleedEffect (кровотечение)
# - FrostEffect (холод)
# - MadnessEffect (безумие)

enum EffectType {
	NONE,
	BURN,       # Огонь - урон каждую секунду
	POISON,     # Яд - урон каждые 2 секунды
	BLEED,      # Кровотечение - урон при движении
	FROST,      # Холод - замедление
	MADNESS,    # Безумие - случайный урон себе
	STUN,       # Оглушение - нельзя двигаться
	BUFF_ARMOR, # Бафф брони
	BUFF_DAMAGE # Бафф урона
}

@export var effect_name: String = "Base Effect"
@export var effect_type: EffectType = EffectType.NONE
@export var duration: float = 5.0           # Длительность в секундах
@export var tick_interval: float = 1.0      # Интервал тиков (для DOT)
@export var value: float = 0.0              # Значение (урон/замедление/бафф)
@export var is_stackable: bool = false      # Можно ли накладывать несколько раз
@export var max_stacks: int = 1             # Максимум стаков

var current_stacks: int = 1
var time_remaining: float = 0.0
var tick_timer: float = 0.0
var target: Node = null


func apply(new_target: Node) -> bool:
	"""Применяет эффект к цели. Возвращает true если успешно."""
	if not new_target:
		return false
	
	target = new_target
	time_remaining = duration
	tick_timer = 0.0
	current_stacks = 1
	
	_on_apply()
	return true


func stack() -> bool:
	"""Добавляет стак эффекта. Возвращает true если успешно."""
	if not is_stackable:
		# Просто обновляем длительность
		time_remaining = duration
		return false
	
	if current_stacks >= max_stacks:
		time_remaining = duration
		return false
	
	current_stacks += 1
	time_remaining = duration
	_on_stack()
	return true


func process(delta: float) -> bool:
	"""Обрабатывает эффект. Возвращает false когда эффект закончился."""
	if not target or time_remaining <= 0:
		return false
	
	time_remaining -= delta
	
	# Тики для DOT эффектов
	if tick_interval > 0:
		tick_timer += delta
		if tick_timer >= tick_interval:
			tick_timer -= tick_interval
			_on_tick()
	
	if time_remaining <= 0:
		remove()
		return false
	
	return true


func remove():
	"""Снимает эффект"""
	_on_remove()
	target = null
	time_remaining = 0


# ===========================================
# ПЕРЕОПРЕДЕЛЯЕМЫЕ МЕТОДЫ
# ===========================================

func _on_apply():
	"""Вызывается при применении эффекта"""
	pass


func _on_tick():
	"""Вызывается каждый tick_interval"""
	pass


func _on_stack():
	"""Вызывается при добавлении стака"""
	pass


func _on_remove():
	"""Вызывается при снятии эффекта"""
	pass


func get_total_value() -> float:
	"""Возвращает значение с учётом стаков"""
	return value * current_stacks


func get_description() -> String:
	"""Возвращает описание эффекта"""
	return "%s (%.1f сек)" % [effect_name, time_remaining]
