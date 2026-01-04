extends "res://scripts/base_character.gd"

func _ready():
	# ИСПРАВЛЕНО: загружаем данные для разбойника, а не воина
	if Global and Global.character_data:
		var data = Global.character_data.get("rogue")  # БЫЛО: "warrior"
		if data is Dictionary:
			setup_character(data)
		else:
			print("ERROR: Rogue data is not a Dictionary")
			setup_fallback_data()
	else:
		print("ERROR: Global or character_data not available")
		setup_fallback_data()
	
	print("✅ Rogue initialized: ", character_name)

func setup_fallback_data():
	character_name = "Разбойник"
	max_health = 90
	current_health = 90
	max_mana = 30
	current_mana = 30
	armor = 2
	abilities = ["Подкат", "Критический удар"]
	selection_animation = "demonstration"
