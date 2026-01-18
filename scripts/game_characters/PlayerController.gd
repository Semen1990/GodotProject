extends Node

# ===========================================
# PLAYER CONTROLLER - УЛУЧШЕННАЯ ВЕРСИЯ
# ===========================================
# Обрабатывает ввод игрока и передает команды персонажу

@export var character: CharacterBody2D

func _ready():
	# Автоматическое определение персонажа
	if character == null:
		character = get_parent()
	
	if character:
		print("🎮 PlayerController инициализирован для: ", character.character_name)
	else:
		print("❌ PlayerController: персонаж не найден!")

func _input(event):
	# Проверка что персонаж существует и жив
	if character == null:
		return
	
	if character.is_dead:
		return
	
	# === АТАКА (ЛКМ или настроенная кнопка) ===
	if event.is_action_pressed("attack"):
		if character.has_method("attack"):
			character.attack()
	
	# === СПЕЦИАЛЬНАЯ СПОСОБНОСТЬ (E) ===
	# Каждый класс имеет свою способность:
	# - Воин: Блок щитом
	# - Паладин: Исцеление
	# - Разбойник: Подкат (если двигается)
	# - Берсерк: (можно добавить)
	if event.is_action_pressed("special_ability"):
		if character.has_method("use_special_ability"):
			character.use_special_ability()
	
	# === БЛОК ЩИТОМ (F или ПКМ) - только для воина ===
	# Удерживание кнопки
	if event.is_action_pressed("shield_defence"):
		if character.has_method("block"):
			character.block()
	
	# Отпускание кнопки блока
	if event.is_action_released("shield_defence"):
		if character.has_method("stop_blocking"):
			character.stop_blocking()
	
	# === ЛЕЧЕНИЕ (H или отдельная кнопка) - для паладина ===
	if event.is_action_pressed("heal"):
		if character.has_method("heal"):
			character.heal()
	
	# === ПОДКАТ (SHIFT или отдельная кнопка) - для разбойника ===
	if event.is_action_pressed("slide"):
		if character.has_method("slide"):
			character.slide()
	
	# === ПРИСЕДАНИЕ (S или CTRL) ===
	# Обрабатывается в base_game_character.gd через Input.is_action_pressed

func _process(_delta):
	# Дополнительная обработка если нужна
	pass
