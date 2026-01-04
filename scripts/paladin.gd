extends "res://scripts/base_character.gd"

func _ready():
	if Global and Global.character_data:
		var data = Global.character_data.get("paladin")
		if data is Dictionary:
			setup_character(data)
		else:
			print("ERROR: Paladin data is not a Dictionary")
			setup_fallback_data()
	else:
		print("ERROR: Global or character_data not available")
		setup_fallback_data()
	
	print("✅ Paladin initialized: ", character_name)

func setup_fallback_data():
	character_name = "Паладин"
	max_health = 130
	current_health = 130
	max_mana = 50
	current_mana = 50
	armor = 6
	abilities = ["Исцеление", "Божественная защита"]
	selection_animation = "spellcast"
