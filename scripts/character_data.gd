static func get_characters() -> Dictionary:
	return {
		"warrior": {
			"name": "Воин",
			"max_health": 100,
			"current_health": 100,
			"max_mana": 0,
			"current_mana": 0,
			"armor": 2,
			"damage": 2,
			"abilities": ["Блок щитом (E)", "Высокая защита"],
			"description": "Танк с высоким здоровьем и бронёй.\nСпособность: Блок щитом увеличивает броню.",
			"selection_animation": "demonstration"
		},
		"berserk": {
			"name": "Берсерк",
			"max_health": 8,
			"current_health": 8,
			"max_mana": 4,
			"current_mana": 4,
			"armor": 0,
			"damage": 4,
			"abilities": ["Комбо-атаки", "Ярость"],
			"description": "Агрессивный боец с высоким уроном.\nКомбо из 3 атак наносит огромный урон.",
			"selection_animation": "demonstration"
		},
		"rogue": {
			"name": "Разбойник",
			"max_health": 6,
			"current_health": 6,
			"max_mana": 8,
			"current_mana": 8,
			"armor": 0,
			"damage": 3,
			"abilities": ["Подкат (E)", "Критический удар"],
			"description": "Быстрый и ловкий.\nПодкат уклоняется от атак.",
			"selection_animation": "demonstration"
		},
		"paladin": {
			"name": "Паладин",
			"max_health": 10,
			"current_health": 10,
			"max_mana": 12,
			"current_mana": 12,
			"armor": 1,
			"damage": 2,
			"abilities": ["Исцеление (E)", "Божественная защита"],
			"description": "Поддержка с лечением.\nМожет восстанавливать здоровье.",
			"selection_animation": "spellcast"
		}
	}
