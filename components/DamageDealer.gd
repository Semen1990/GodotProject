extends Node
class_name DamageDealer

# ===========================================
# DAMAGE DEALER - КОМПОНЕНТ НАНЕСЕНИЯ УРОНА
# ===========================================
# Путь: res://scripts/components/DamageDealer.gd
#
# Отвечает за расчёт и нанесение урона.

signal damage_dealt(target: Node, amount: int, was_crit: bool)

# Ссылка на владельца
var owner_node: Node = null

# Базовые характеристики
@export var base_damage: int = 10
@export var damage_type: String = "physical"  # physical, fire, poison, frost, magic

# Модификаторы
var bonus_damage: int = 0
var damage_multiplier: float = 1.0

# Ссылки на компоненты
var crit_component: Node = null  # CriticalHit
var status_effects: Node = null   # StatusEffects (для баффов)


func _ready():
	owner_node = get_parent()
	
	# Ищем компоненты
	crit_component = owner_node.get_node_or_null("CriticalHit")
	status_effects = owner_node.get_node_or_null("StatusEffects")


# ===========================================
# РАСЧЁТ УРОНА
# ===========================================

func get_total_damage() -> int:
	"""Возвращает текущий урон с учётом всех модификаторов"""
	var damage = base_damage + bonus_damage
	
	# Модификатор от баффов
	if status_effects and "damage_modifier" in status_effects:
		damage = int(damage * status_effects.damage_modifier)
	
	# Общий множитель
	damage = int(damage * damage_multiplier)
	
	return max(1, damage)


func calculate_hit(target: Node = null) -> Dictionary:
	"""
	Рассчитывает удар. Возвращает словарь:
	{
		"damage": int,
		"is_crit": bool,
		"is_dodged": bool,
		"type": String
	}
	"""
	var result = {
		"damage": get_total_damage(),
		"is_crit": false,
		"is_dodged": false,
		"type": damage_type
	}
	
	# Проверка уклонения цели
	if target:
		var dodge = target.get_node_or_null("Dodge")
		if dodge and dodge.try_dodge():
			result["is_dodged"] = true
			result["damage"] = 0
			return result
	
	# Проверка крита
	if crit_component and crit_component.try_crit():
		result["is_crit"] = true
		result["damage"] = crit_component.apply_crit_damage(result["damage"])
	
	return result


# ===========================================
# НАНЕСЕНИЕ УРОНА
# ===========================================

func deal_damage_to(target: Node, override_damage: int = -1) -> int:
	"""
	Наносит урон цели. Возвращает фактический урон.
	"""
	if not target:
		return 0
	
	# Рассчитываем удар
	var hit = calculate_hit(target)
	
	if hit["is_dodged"]:
		print("💨 %s уклонился!" % target.name)
		return 0
	
	# Переопределённый урон (для способностей)
	var damage = override_damage if override_damage >= 0 else hit["damage"]
	
	# Ищем Damageable у цели
	var damageable = target.get_node_or_null("Damageable")
	var actual_damage = 0
	
	if damageable:
		actual_damage = damageable.take_damage(damage, hit["type"], owner_node.name if owner_node else "Unknown")
	elif target.has_method("take_damage"):
		target.take_damage(damage, hit["type"], owner_node.name if owner_node else "Unknown")
		actual_damage = damage
	
	# Сигнал и статистика
	if actual_damage > 0:
		damage_dealt.emit(target, actual_damage, hit["is_crit"])
		
		if GameState:
			GameState.add_damage_dealt(actual_damage)
		
		# Визуальная индикация крита
		if hit["is_crit"]:
			_show_crit_effect(target)
	
	return actual_damage


func deal_area_damage(targets: Array, damage_percent: float = 100.0) -> int:
	"""Наносит урон нескольким целям"""
	var total_damage = 0
	var damage = int(get_total_damage() * damage_percent / 100.0)
	
	for target in targets:
		total_damage += deal_damage_to(target, damage)
	
	return total_damage


# ===========================================
# МОДИФИКАТОРЫ
# ===========================================

func add_bonus_damage(amount: int):
	bonus_damage += amount


func set_damage_multiplier(mult: float):
	damage_multiplier = mult


func reset_modifiers():
	bonus_damage = 0
	damage_multiplier = 1.0


# ===========================================
# ЭФФЕКТЫ ПРИ УДАРЕ
# ===========================================

func apply_on_hit_effect(target: Node, effect_type: String, value: float = 0.0):
	"""Применяет эффект при ударе"""
	var target_status = target.get_node_or_null("StatusEffects")
	if not target_status:
		return
	
	match effect_type:
		"burn":
			target_status.apply_burn(value if value > 0 else 3.0)
		"poison":
			target_status.apply_poison(value if value > 0 else 5.0)
		"bleed":
			target_status.apply_bleed(value if value > 0 else 2.0)
		"frost":
			target_status.apply_frost(value if value > 0 else 30.0)
		"stun":
			target_status.apply_stun(value if value > 0 else 2.0)


# ===========================================
# ВИЗУАЛЬНЫЕ ЭФФЕКТЫ
# ===========================================

func _show_crit_effect(target: Node):
	"""Показывает эффект критического удара"""
	# Можно добавить партиклы, всплывающий текст и т.д.
	print("💥 КРИТ!")
