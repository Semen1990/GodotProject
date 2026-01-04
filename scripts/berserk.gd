extends "res://scripts/base_character.gd"

func _ready():
	if Global and Global.character_data:
		var data = Global.character_data.get("berserk")
		if data is Dictionary:
			setup_character(data)
		else:
			print("ERROR: Berserk data is not a Dictionary")
			setup_fallback_data()
	else:
		print("ERROR: Global or character_data not available")
		setup_fallback_data()
	
	print("✅ Berserk initialized: ", character_name)

func setup_fallback_data():
	character_name = "Берсерк"
	max_health = 120
	current_health = 120
	max_mana = 20
	current_mana = 20
	armor = 5
	abilities = ["Ярость", "Двойная атака"]
	selection_animation = "demonstration"
