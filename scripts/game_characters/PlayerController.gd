extends Node

# ===========================================
# PLAYER CONTROLLER - ИСПРАВЛЕННАЯ ВЕРСИЯ
# ===========================================
# Обрабатывает ввод игрока
#
# УПРАВЛЕНИЕ:
# - ЛКМ/attack: Атака
# - E (special_ability): Спецспособность класса (блок у воина, лечение у паладина...)
# - F (interact): Взаимодействие (сундуки, предметы) - обрабатывается в других скриптах

@export var character: CharacterBody2D


func _ready():
	if character == null:
		character = get_parent()
	
	if character:
		print("🎮 PlayerController инициализирован для: ", character.character_name)
	else:
		print("❌ PlayerController: персонаж не найден!")


func _input(event):
	if character == null:
		return
	
	if character.is_dead:
		return
	
	# Блокировка при открытом инвентаре
	if character.is_inventory_open:
		return
	
	# === АТАКА (ЛКМ) ===
	if event.is_action_pressed("attack"):
		if character.has_method("attack"):
			character.attack()
	
	# === СПЕЦИАЛЬНАЯ СПОСОБНОСТЬ (E) ===
	if event.is_action_pressed("special_ability"):
		if character.has_method("use_special_ability"):
			character.use_special_ability()
	
	# === ЛЕЧЕНИЕ (H) - для паладина ===
	if InputMap.has_action("heal") and event.is_action_pressed("heal"):
		if character.has_method("heal"):
			character.heal()
	
	# === ПОДКАТ (SHIFT) - для разбойника ===
	if InputMap.has_action("slide") and event.is_action_pressed("slide"):
		if character.has_method("slide"):
			character.slide()


func _process(_delta):
	pass
