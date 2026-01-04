extends "res://scripts/base_character.gd"

func _ready():
	if Global and Global.character_data:
		var data = Global.character_data.get("warrior")
		if data is Dictionary:
			setup_character(data)
		else:
			print("ERROR: Warrior data is not a Dictionary")
			setup_fallback_data()
	else:
		print("ERROR: Global or character_data not available")
		setup_fallback_data()
	
	print("✅ Warrior initialized: ", character_name)

func setup_fallback_data():
	character_name = "Воин"
	max_health = 150
	current_health = 150
	max_mana = 10
	current_mana = 10
	armor = 8
	abilities = ["Блок", "Высокое здоровье"]
	selection_animation = "demonstration"
