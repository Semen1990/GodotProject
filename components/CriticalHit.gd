extends Node
class_name CriticalHit

# ===========================================
# CRITICAL HIT - КОМПОНЕНТ КРИТИЧЕСКИХ УДАРОВ
# ===========================================
# Путь: res://scripts/components/CriticalHit.gd

signal crit_triggered(damage_multiplier: float)

@export var base_crit_chance: float = 5.0      # Базовый шанс крита (%)
@export var base_crit_multiplier: float = 2.0  # Множитель урона при крите

var bonus_crit_chance: float = 0.0
var bonus_crit_multiplier: float = 0.0


func get_crit_chance() -> float:
	return base_crit_chance + bonus_crit_chance


func get_crit_multiplier() -> float:
	return base_crit_multiplier + bonus_crit_multiplier


func try_crit() -> bool:
	"""Проверяет, произошёл ли крит"""
	var roll = randf() * 100.0
	return roll <= get_crit_chance()


func apply_crit_damage(base_damage: int) -> int:
	"""Применяет множитель крита к урону"""
	var crit_damage = int(base_damage * get_crit_multiplier())
	crit_triggered.emit(get_crit_multiplier())
	return crit_damage


func add_crit_chance(amount: float):
	bonus_crit_chance += amount


func add_crit_multiplier(amount: float):
	bonus_crit_multiplier += amount


func reset():
	bonus_crit_chance = 0.0
	bonus_crit_multiplier = 0.0
