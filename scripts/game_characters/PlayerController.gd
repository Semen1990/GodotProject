extends Node

@export var character: CharacterBody2D

func _ready():
	if character == null:
		character = get_parent()
	
	if character:
		print("🎮 PlayerController initialized for: ", character.character_name)
	else:
		print("❌ PlayerController: character is null!")

func _input(event):
	if character == null or character.is_dead:
		return
	
	# Обработка атаки
	if event.is_action_pressed("attack"):
		character.attack()
	
	# Блок - нажатие F
	if event.is_action_pressed("shield_defence"):
		if character.has_method("block"):
			character.block()
	
	# Блок - отпускание F
	if event.is_action_released("shield_defence"):
		if character.has_method("stop_blocking"):
			character.stop_blocking()
	
	# Лечение
	if event.is_action_pressed("heal"):
		if character.has_method("heal"):
			character.heal()
	
	# Подкат (для разбойника)
	if event.is_action_pressed("slide"):
		if character.has_method("slide"):
			character.slide()
