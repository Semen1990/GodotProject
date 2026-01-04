extends "res://scripts/game_characters/base_game_character.gd"

var block_cooldown: float = 0.0

func _ready():
	character_name = "Воин"
	max_health = 150
	current_health = 150
	max_mana = 10
	current_mana = 10
	armor = 8
	jump_velocity = -350
	base_speed = 180
	current_speed = 180
	max_speed = 180.0
	
	print("🛡️ Воин готов к битве!")
	super()

func _physics_process(delta):
	# Обновляем кулдаун блока
	if block_cooldown > 0:
		block_cooldown -= delta
	
	super(delta)

func block():
	if is_dead or is_attacking or is_blocking or block_cooldown > 0:
		return
	
	is_blocking = true
	armor += 10
	print("🛡️ Воин - Поднимает щит! Броня увеличена до ", armor)

func stop_blocking():
	if is_blocking:
		is_blocking = false
		block_cooldown = 0.3
		armor -= 10
		print("🛡️ Воин - Опускает щит! Броня уменьшена до ", armor)
