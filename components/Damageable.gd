extends Node
class_name Damageable

# ===========================================
# DAMAGEABLE - КОМПОНЕНТ ПОЛУЧЕНИЯ УРОНА
# ===========================================
# Путь: res://scripts/components/Damageable.gd
#
# Добавляется как дочерний узел к любому объекту,
# который может получать урон.

signal damage_taken(amount: int, type: String, source: String)
signal healed(amount: int)
signal died(killer: String)
signal health_changed(current: int, maximum: int)

# Ссылка на владельца
var owner_node: Node = null

# Характеристики
@export var max_health: int = 100
@export var current_health: int = 100
@export var armor: int = 0
@export var is_invulnerable: bool = false

# Сопротивления (0.0 - 1.0, где 1.0 = иммунитет)
@export var resistance_physical: float = 0.0
@export var resistance_fire: float = 0.0
@export var resistance_poison: float = 0.0
@export var resistance_frost: float = 0.0
@export var resistance_magic: float = 0.0

# Неуязвимость после урона
@export var invulnerability_time: float = 0.2
var invulnerability_timer: float = 0.0

# Флаги
var is_dead: bool = false


func _ready():
	owner_node = get_parent()
	current_health = max_health


func _process(delta):
	if invulnerability_timer > 0:
		invulnerability_timer -= delta


# ===========================================
# ПОЛУЧЕНИЕ УРОНА
# ===========================================

func take_damage(amount: int, damage_type: String = "physical", source: String = "Unknown") -> int:
	"""
	Получает урон. Возвращает фактически нанесённый урон.
	
	damage_type: physical, fire, poison, frost, magic, true (чистый)
	"""
	if is_dead or is_invulnerable:
		return 0
	
	if invulnerability_timer > 0:
		return 0
	
	# Рассчитываем фактический урон
	var final_damage = _calculate_damage(amount, damage_type)
	
	if final_damage <= 0:
		return 0
	
	# Применяем урон
	current_health = max(0, current_health - final_damage)
	
	# Запускаем неуязвимость
	if invulnerability_time > 0:
		invulnerability_timer = invulnerability_time
	
	# Сигналы
	damage_taken.emit(final_damage, damage_type, source)
	health_changed.emit(current_health, max_health)
	
	# Статистика
	if GameState:
		GameState.add_damage_taken(final_damage)
	
	print("💔 %s получил %d урона (%s) от %s [HP: %d/%d]" % [
		owner_node.name if owner_node else "???",
		final_damage,
		damage_type,
		source,
		current_health,
		max_health
	])
	
	# Проверка смерти
	if current_health <= 0:
		_die(source)
	
	return final_damage


func _calculate_damage(base_damage: int, damage_type: String) -> int:
	"""Рассчитывает урон с учётом брони и сопротивлений"""
	var damage = float(base_damage)
	
	# Применяем сопротивление по типу
	var resistance = 0.0
	match damage_type:
		"physical":
			resistance = resistance_physical
			# Броня снижает физ. урон
			damage = max(1, damage - armor * 0.5)
		"fire":
			resistance = resistance_fire
		"poison":
			resistance = resistance_poison
		"frost":
			resistance = resistance_frost
		"magic":
			resistance = resistance_magic
		"true", "effect":
			# Чистый урон игнорирует всё
			resistance = 0.0
	
	# Применяем сопротивление
	damage *= (1.0 - resistance)
	
	return max(0, int(damage))


# ===========================================
# СМЕРТЬ
# ===========================================

func _die(killer: String):
	if is_dead:
		return
	
	is_dead = true
	print("💀 %s погиб от %s" % [owner_node.name if owner_node else "???", killer])
	
	died.emit(killer)
	
	# Уведомляем владельца
	if owner_node and owner_node.has_method("_on_death"):
		owner_node._on_death(killer)
	
	# Если это игрок - уведомляем GameState
	if owner_node and owner_node.is_in_group("player"):
		if GameState:
			GameState.stats["death_reason"] = killer


# ===========================================
# ЛЕЧЕНИЕ
# ===========================================

func heal(amount: int) -> int:
	"""Лечит. Возвращает фактически восстановленное HP."""
	if is_dead:
		return 0
	
	var old_health = current_health
	current_health = min(max_health, current_health + amount)
	var healed_amount = current_health - old_health
	
	if healed_amount > 0:
		healed.emit(healed_amount)
		health_changed.emit(current_health, max_health)
		print("💚 %s +%d HP [%d/%d]" % [
			owner_node.name if owner_node else "???",
			healed_amount,
			current_health,
			max_health
		])
	
	return healed_amount


func heal_percent(percent: float) -> int:
	"""Лечит на процент от макс. HP"""
	var amount = int(max_health * percent / 100.0)
	return heal(amount)


func heal_to_full():
	"""Полное восстановление"""
	heal(max_health)


# ===========================================
# ВОСКРЕШЕНИЕ
# ===========================================

func revive(health_percent: float = 50.0):
	"""Воскрешает с указанным % HP"""
	if not is_dead:
		return
	
	is_dead = false
	current_health = int(max_health * health_percent / 100.0)
	health_changed.emit(current_health, max_health)
	
	print("✨ %s воскрес! [%d/%d HP]" % [
		owner_node.name if owner_node else "???",
		current_health,
		max_health
	])


# ===========================================
# МОДИФИКАТОРЫ
# ===========================================

func add_max_health(amount: int, heal_added: bool = true):
	"""Увеличивает максимальное HP"""
	max_health += amount
	if heal_added:
		current_health += amount
	health_changed.emit(current_health, max_health)


func add_armor(amount: int):
	"""Добавляет броню"""
	armor += amount


func set_invulnerable(value: bool):
	"""Устанавливает неуязвимость"""
	is_invulnerable = value


# ===========================================
# ПРОВЕРКИ
# ===========================================

func get_health_percent() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health) * 100.0


func is_full_health() -> bool:
	return current_health >= max_health


func is_low_health(threshold: float = 30.0) -> bool:
	return get_health_percent() <= threshold
