extends "res://scripts/game_characters/base_game_character.gd"

func _ready():
	character_name = "Берсерк"
	max_health = 120
	current_health = 120
	max_mana = 20
	current_mana = 20
	armor = 5
	jump_velocity = -400
	base_speed = 220
	current_speed = 220
	max_speed = 220.0
	
	print("🔪 Берсерк наполнен яростью!")
	super()

func take_damage(amount: int):
	# Ярость при низком здоровье
	if current_health < max_health * 0.3:
		var reduced_amount = int(amount * 0.7)
		print("🛡️ Ярость защищает! Урон: ", amount, " → ", reduced_amount)
		super.take_damage(reduced_amount)
	else:
		super.take_damage(amount)
