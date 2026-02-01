extends Node
class_name Dodge

# ===========================================
# DODGE - КОМПОНЕНТ УКЛОНЕНИЯ
# ===========================================
# Путь: res://scripts/components/Dodge.gd

signal dodge_triggered
signal dodge_failed

@export var base_dodge_chance: float = 0.0  # Базовый шанс уклонения (%)
@export var dodge_cooldown: float = 0.5     # Минимальное время между уклонениями

var bonus_dodge_chance: float = 0.0
var cooldown_timer: float = 0.0
var can_dodge: bool = true


func _process(delta):
	if cooldown_timer > 0:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			can_dodge = true


func get_dodge_chance() -> float:
	return base_dodge_chance + bonus_dodge_chance


func try_dodge() -> bool:
	"""Проверяет, произошло ли уклонение"""
	if not can_dodge:
		return false
	
	var roll = randf() * 100.0
	var dodged = roll <= get_dodge_chance()
	
	if dodged:
		can_dodge = false
		cooldown_timer = dodge_cooldown
		dodge_triggered.emit()
		return true
	else:
		dodge_failed.emit()
		return false


func add_dodge_chance(amount: float):
	bonus_dodge_chance += amount


func reset():
	bonus_dodge_chance = 0.0
	can_dodge = true
	cooldown_timer = 0.0
