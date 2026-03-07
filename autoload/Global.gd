extends Node

# ===========================================
# GLOBAL.GD - Р’Р•Р РЎРРЇ v6.0
# ===========================================
# РР—РњР•РќР•РќРРЇ:
# 1. РџСЂР°РІРёР»СЊРЅС‹Р№ РїРѕСЂСЏРґРѕРє С†РІРµС‚РѕРІ РєР»СЋС‡РµР№
# 2. РђСЂС‚РµС„Р°РєС‚С‹ РќР• Р°РєС‚РёРІРёСЂСѓСЋС‚СЃСЏ Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё
# 3. Р”РѕР±Р°РІР»РµРЅ get_keys_array() РґР»СЏ UI
# 4. РЎРёСЃС‚РµРјР° СЃРѕС…СЂР°РЅРµРЅРёСЏ РѕС‚РєСЂС‹С‚С‹С… СЃСѓРЅРґСѓРєРѕРІ
# 5. РЎРёСЃС‚РµРјР° РІРѕСЃСЃС‚Р°РЅРѕРІР»РµРЅРёСЏ РІС‹РїР°РІС€РёС… РїСЂРµРґРјРµС‚РѕРІ

var selected_character = null
var character_data = {}

var character_player_scenes = {
	"warrior": "res://scenes/game_characters/warrior_player.tscn",
	"berserk": "res://scenes/game_characters/berserk_player.tscn",
	"paladin": "res://scenes/game_characters/paladin_player.tscn",
	"rogue": "res://scenes/game_characters/rogue_player.tscn"
}

var player_data = {
	"character_type": "",
	"level": 1,
	"experience": 0
}

var game_ui: CanvasLayer = null
var current_player = null

var game_settings = {
	"music_volume": 80,
	"sfx_volume": 90,
	"fullscreen": true
}

var fallback_character_data = {
	"warrior": {
		"name": "Р’РѕРёРЅ",
		"max_health": 150,
		"current_health": 150,
		"max_mana": 10,
		"current_mana": 10,
		"armor": 8,
		"abilities": ["Р‘Р»РѕРє", "Р’С‹СЃРѕРєРѕРµ Р·РґРѕСЂРѕРІСЊРµ"],
		"selection_animation": "demonstration"
	},
	"berserk": {
		"name": "Р‘РµСЂСЃРµСЂРє",
		"max_health": 120,
		"current_health": 120,
		"max_mana": 20,
		"current_mana": 20,
		"armor": 5,
		"abilities": ["РЇСЂРѕСЃС‚СЊ", "Р”РІРѕР№РЅР°СЏ Р°С‚Р°РєР°"],
		"selection_animation": "demonstration"
	},
	"rogue": {
		"name": "Р Р°Р·Р±РѕР№РЅРёРє",
		"max_health": 90,
		"current_health": 90,
		"max_mana": 30,
		"current_mana": 30,
		"armor": 2,
		"abilities": ["РџРѕРґРєР°С‚", "РљСЂРёС‚РёС‡РµСЃРєРёР№ СѓРґР°СЂ"],
		"selection_animation": "demonstration"
	},
	"paladin": {
		"name": "РџР°Р»Р°РґРёРЅ",
		"max_health": 130,
		"current_health": 130,
		"max_mana": 50,
		"current_mana": 50,
		"armor": 6,
		"abilities": ["РСЃС†РµР»РµРЅРёРµ", "Р‘РѕР¶РµСЃС‚РІРµРЅРЅР°СЏ Р·Р°С‰РёС‚Р°"],
		"selection_animation": "spellcast"
	}
}

# ===========================================
# РЎРРЎРўР•РњРђ РђР РўР•Р¤РђРљРўРћР’ (РўРћР›Р¬РљРћ Р”Р›РЇ РћРўРЎР›Р•Р–РР’РђРќРРЇ)
# ===========================================
# Р’РђР–РќРћ: РђСЂС‚РµС„Р°РєС‚С‹ С‚РµРїРµСЂСЊ СЂР°Р±РѕС‚Р°СЋС‚ РўРћР›Р¬РљРћ С‡РµСЂРµР· РёРЅРІРµРЅС‚Р°СЂСЊ!
# collected_artifacts - С‚РѕР»СЊРєРѕ РґР»СЏ СЃС‚Р°С‚РёСЃС‚РёРєРё

var collected_artifacts: Array = []

# ===========================================
# РЎРРЎРўР•РњРђ РљР›Р®Р§Р•Р™
# ===========================================
# РџРѕСЂСЏРґРѕРє С†РІРµС‚РѕРІ (СЃРѕРѕС‚РІРµС‚СЃС‚РІСѓРµС‚ KeyPickup.KeyColor):
# 0 = GOLD (Р—РѕР»РѕС‚РѕР№)
# 1 = SILVER (РЎРµСЂРµР±СЂСЏРЅС‹Р№)
# 2 = RED (РљСЂР°СЃРЅС‹Р№)
# 3 = BLUE (РЎРёРЅРёР№)
# 4 = GREEN (Р—РµР»С‘РЅС‹Р№)
# 5 = PURPLE (Р¤РёРѕР»РµС‚РѕРІС‹Р№)

var keys: Dictionary = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0}

const KEY_COLOR_NAMES = {
	0: "Р·РѕР»РѕС‚РѕР№",
	1: "СЃРµСЂРµР±СЂСЏРЅС‹Р№",
	2: "РєСЂР°СЃРЅС‹Р№",
	3: "СЃРёРЅРёР№",
	4: "Р·РµР»С‘РЅС‹Р№",
	5: "С„РёРѕР»РµС‚РѕРІС‹Р№"
}

var spawn_point: String = ""
var opened_doors: Array = []

# ===========================================
# РЎРРЎРўР•РњРђ РЎРћРҐР РђРќР•РќРРЇ РЎРћРЎРўРћРЇРќРРЇ
# ===========================================

var collected_pickups: Array = []
var killed_enemies: Array = []

var saved_player_health: int = -1
var saved_player_mana: int = -1

# === РќРћР’РћР•: РЎРѕС…СЂР°РЅРµРЅРёРµ СЃСѓРЅРґСѓРєРѕРІ Рё РІС‹РїР°РІС€РёС… РїСЂРµРґРјРµС‚РѕРІ ===
var opened_chests: Dictionary = {}  # {"level1": ["Chest", "ChestEquipment"], ...}
var dropped_pickups: Dictionary = {}  # {"level1": [{type, id, position}, ...], ...}
var current_level: String = ""  # РўРµРєСѓС‰РёР№ СѓСЂРѕРІРµРЅСЊ РґР»СЏ РѕС‚СЃР»РµР¶РёРІР°РЅРёСЏ

# ===========================================
# Р‘РђР—Рђ Р”РђРќРќР«РҐ РђР РўР•Р¤РђРљРўРћР’ (РґР»СЏ СЃРїСЂР°РІРєРё)
# ===========================================

var artifacts_database = {
	"hermes_wings": {
		"name": "РљСЂС‹Р»СЊСЏ Р“РµСЂРјРµСЃР°",
		"description": "Р›РµРіРµРЅРґР°СЂРЅС‹Рµ РєСЂС‹Р»Р°С‚С‹Рµ СЃР°РЅРґР°Р»РёРё",
		"icon": "res://assets/items/artifacts/hermes_wings.png",
		"ability": "double_jump",
		"rarity": "rare",
		"effect_text": "РџРѕР·РІРѕР»СЏРµС‚ СЃРѕРІРµСЂС€РёС‚СЊ РІС‚РѕСЂРѕР№ РїСЂС‹Р¶РѕРє РІ РІРѕР·РґСѓС…Рµ",
		"item_id": 201  # ID РІ РёРЅРІРµРЅС‚Р°СЂРµ
	},
	"phoenix_feather": {
		"name": "РџРµСЂРѕ Р¤РµРЅРёРєСЃР°",
		"description": "РњР°РіРёС‡РµСЃРєРѕРµ РїРµСЂРѕ РІРѕР·СЂРѕР¶РґРµРЅРёСЏ",
		"icon": "res://assets/items/artifacts/phoenix_feather.png",
		"ability": "revival",
		"rarity": "legendary",
		"effect_text": "Р’РѕР·СЂРѕР¶РґР°РµС‚ РїРѕСЃР»Рµ СЃРјРµСЂС‚Рё СЃ 50% HP",
		"item_id": 202  # ID РІ РёРЅРІРµРЅС‚Р°СЂРµ
	},
	"griffin_feather": {
		"name": "РџРµСЂРѕ Р“СЂРёС„РѕРЅР°",
		"description": "РњР°РіРёС‡РµСЃРєРѕРµ РїРµСЂРѕ РјРёС„РёС‡РµСЃРєРѕРіРѕ СЃСѓС‰РµСЃС‚РІР°",
		"icon": "res://assets/artifacts/griffin_feather.png",
		"ability": "double_jump",
		"rarity": "epic",
		"effect_text": "Р”Р°СЂСѓРµС‚ РІРѕР·РјРѕР¶РЅРѕСЃС‚СЊ РґРІРѕР№РЅРѕРіРѕ РїСЂС‹Р¶РєР°"
	},
	"wind_ring": {
		"name": "РљРѕР»СЊС†Рѕ Р’РµС‚СЂР°",
		"description": "Р”СЂРµРІРЅРµРµ РєРѕР»СЊС†Рѕ СЃ СЃРёР»РѕР№ РІРѕР·РґСѓС€РЅРѕР№ СЃС‚РёС…РёРё",
		"icon": "res://assets/artifacts/wind_ring.png",
		"ability": "double_jump",
		"rarity": "rare",
		"effect_text": "РЈСЃРёР»РёРІР°РµС‚ РїСЂС‹Р¶РєРё"
	},
	"eagle_amulet": {
		"name": "РђРјСѓР»РµС‚ РћСЂР»Р°",
		"description": "РђРјСѓР»РµС‚ СЃ РґСѓС…РѕРј РІРµР»РёРєРѕРіРѕ РѕСЂР»Р°",
		"icon": "res://assets/artifacts/eagle_amulet.png",
		"ability": "double_jump",
		"rarity": "epic",
		"effect_text": "Р”СѓС… РѕСЂР»Р° РїРѕРјРѕРіР°РµС‚ РІР·Р»РµС‚РµС‚СЊ РІС‹С€Рµ"
	},
	"dash_boots": {
		"name": "РЎР°РїРѕРіРё Р С‹РІРєР°",
		"description": "РњР°РіРёС‡РµСЃРєРёРµ СЃР°РїРѕРіРё СѓРІРµР»РёС‡РёРІР°СЋС‰РёРµ СЃРєРѕСЂРѕСЃС‚СЊ",
		"icon": "res://assets/artifacts/dash_boots.png",
		"ability": "dash",
		"rarity": "rare",
		"effect_text": "РЈРІРµР»РёС‡РёРІР°РµС‚ СЃРєРѕСЂРѕСЃС‚СЊ РїРµСЂРµРґРІРёР¶РµРЅРёСЏ РЅР° 30%"
	},
	"health_crystal": {
		"name": "РљСЂРёСЃС‚Р°Р»Р» Р—РґРѕСЂРѕРІСЊСЏ",
		"description": "РЎРІРµС‚СЏС‰РёР№СЃСЏ РєСЂРёСЃС‚Р°Р»Р» СѓСЃРёР»РёРІР°СЋС‰РёР№ Р¶РёР·РЅРµРЅРЅСѓСЋ СЃРёР»Сѓ",
		"icon": "res://assets/artifacts/health_crystal.png",
		"ability": "max_health",
		"rarity": "common",
		"effect_text": "РЈРІРµР»РёС‡РёРІР°РµС‚ РјР°РєСЃРёРјР°Р»СЊРЅРѕРµ Р·РґРѕСЂРѕРІСЊРµ РЅР° 20"
	},
	"mana_crystal": {
		"name": "РљСЂРёСЃС‚Р°Р»Р» РњР°РЅС‹",
		"description": "РљСЂРёСЃС‚Р°Р»Р» РјР°РіРёС‡РµСЃРєРѕР№ СЌРЅРµСЂРіРёРё",
		"icon": "res://assets/artifacts/mana_crystal.png",
		"ability": "max_mana",
		"rarity": "rare",
		"effect_text": "РЈРІРµР»РёС‡РёРІР°РµС‚ РјР°РєСЃРёРјР°Р»СЊРЅСѓСЋ РјР°РЅСѓ РЅР° 20"
	},
	"vampire_ring": {
		"name": "РљРѕР»СЊС†Рѕ Р’Р°РјРїРёСЂР°",
		"description": "РўС‘РјРЅРѕРµ РєРѕР»СЊС†Рѕ СЃ РєСЂРѕРІР°РІС‹Рј РєР°РјРЅРµРј",
		"icon": "res://assets/artifacts/vampire_ring.png",
		"ability": "lifesteal",
		"rarity": "epic",
		"effect_text": "Р’РѕСЃСЃС‚Р°РЅР°РІР»РёРІР°РµС‚ HP РїСЂРё СѓР±РёР№СЃС‚РІРµ РІСЂР°РіРѕРІ"
	},
	"berserker_gloves": {
		"name": "РџРµСЂС‡Р°С‚РєРё Р‘РµСЂСЃРµСЂРєР°",
		"description": "РћРєСЂРѕРІР°РІР»РµРЅРЅС‹Рµ РїРµСЂС‡Р°С‚РєРё РІРѕРёРЅР°",
		"icon": "res://assets/artifacts/berserker_gloves.png",
		"ability": "damage_boost",
		"rarity": "epic",
		"effect_text": "+50% СѓСЂРѕРЅР° РїСЂРё HP РЅРёР¶Рµ 30%"
	},
	"mirror_shield": {
		"name": "Р—РµСЂРєР°Р»СЊРЅС‹Р№ Р©РёС‚",
		"description": "Р©РёС‚ РѕС‚СЂР°Р¶Р°СЋС‰РёР№ Р°С‚Р°РєРё",
		"icon": "res://assets/artifacts/mirror_shield.png",
		"ability": "reflect",
		"rarity": "legendary",
		"effect_text": "20% С€Р°РЅСЃ РѕС‚СЂР°Р·РёС‚СЊ СѓСЂРѕРЅ"
	},
	"speed_boots": {
		"name": "РЎР°РїРѕРіРё РЎРєРѕСЂРѕСЃС‚Рё",
		"description": "Р›С‘РіРєРёРµ СЃР°РїРѕРіРё РґР»СЏ Р±С‹СЃС‚СЂРѕРіРѕ Р±РµРіР°",
		"icon": "res://assets/artifacts/speed_boots.png",
		"ability": "speed",
		"rarity": "common",
		"effect_text": "РЈРІРµР»РёС‡РёРІР°РµС‚ СЃРєРѕСЂРѕСЃС‚СЊ РЅР° 15%"
	}
}

signal artifact_collected(artifact_id: String)

var run_statistics: Dictionary = {
	"death_reason": "",
	"keys_collected": 0,
	"items_collected": 0,
	"artifacts_collected": 0,
	"coins_collected": 0,
	"enemies_simple": 0,
	"enemies_elite": 0,
	"enemies_boss": 0,
	"damage_dealt": 0,
	"damage_taken": 0,
	"rooms_visited": 1,
	"time_played": 0.0,
	"start_time": 0.0
}

# РђСЂС‚РµС„Р°РєС‚ РІРѕР·СЂРѕР¶РґРµРЅРёСЏ - СѓСЃС‚Р°РЅР°РІР»РёРІР°РµС‚СЃСЏ РўРћР›Р¬РљРћ РёР· level1.gd
# РєРѕРіРґР° Р°СЂС‚РµС„Р°РєС‚ Р­РљРРџРР РћР’РђРќ РІ СЃР»РѕС‚!
var revival_artifact_id: String = ""

var last_room_path: String = ""
var last_safe_position: Vector2 = Vector2.ZERO
var run_started: bool = false


func _ready():
	print("рџЊЌ Global.gd v5.0 loaded!")
	load_character_data()
	load_settings()


func load_character_data():
	var data_script = load("res://scripts/character_data.gd")
	if data_script:
		character_data = data_script.get_characters()
		print("вњ… Character data loaded! Count: ", character_data.size())
		validate_character_data()
	else:
		print("вќЊ ERROR: Failed to load character_data.gd, using fallback")
		character_data = fallback_character_data


func validate_character_data():
	var required_characters = ["warrior", "berserk", "rogue", "paladin"]
	var missing_characters = []
	for char_key in required_characters:
		if not character_data.has(char_key):
			missing_characters.append(char_key)

	if missing_characters.size() > 0:
		print("вљ пёЏ Missing character data: ", missing_characters)
		for char_key in missing_characters:
			if fallback_character_data.has(char_key):
				character_data[char_key] = fallback_character_data[char_key]


func load_settings():
	print("вљ™пёЏ Default settings loaded")


func get_character_scene_path(character_key: String) -> String:
	if not character_player_scenes.has(character_key):
		return ""

	var path = character_player_scenes[character_key]

	if ResourceLoader.exists(path):
		return path
	else:
		return ""


func character_scene_exists(character_key: String) -> bool:
	return get_character_scene_path(character_key) != ""


func load_character_scene(character_key: String):
	var path = get_character_scene_path(character_key)
	if path == "":
		return null
	return load(path)


func register_game_ui(ui_node: CanvasLayer):
	game_ui = ui_node
	_update_keys_ui()


func unregister_game_ui():
	game_ui = null


func register_player(player_node):
	if player_node == null:
		return

	current_player = player_node
	if player_node is Node:
		print("вњ… РРіСЂРѕРє Р·Р°СЂРµРіРёСЃС‚СЂРёСЂРѕРІР°РЅ: ", player_node.name)
		# РќР• РїСЂРёРјРµРЅСЏРµРј Р°СЂС‚РµС„Р°РєС‚С‹ Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё!
		# РђСЂС‚РµС„Р°РєС‚С‹ СЂР°Р±РѕС‚Р°СЋС‚ С‚РѕР»СЊРєРѕ С‡РµСЂРµР· РёРЅРІРµРЅС‚Р°СЂСЊ
		if saved_player_health > 0:
			call_deferred("restore_player_stats")


func unregister_player():
	current_player = null


func get_selected_character_data():
	if selected_character == null:
		return null
	if character_data == null:
		return null
	if character_data.has(selected_character):
		return character_data[selected_character]
	return null


func get_selected_character_name():
	var data = get_selected_character_data()
	if data == null:
		return "Unknown"
	if data is Dictionary and data.has("name"):
		return data["name"]
	return "Unknown"


func change_level(level_path: String):
	if level_path == null or level_path == "":
		return

	unregister_player()
	unregister_game_ui()

	if ResourceLoader.exists(level_path):
		get_tree().change_scene_to_file(level_path)


func return_to_main_menu():
	full_reset()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func quit_game():
	get_tree().quit()


func debug_print_state():
	print("=== GLOBAL STATE DEBUG ===")
	print("Selected character: ", selected_character)
	print("Current player: ", current_player)
	print("Keys: ", keys)
	print("Collected pickups: ", collected_pickups)
	print("Killed enemies: ", killed_enemies)
	print("Spawn point: ", spawn_point)
	print("Run started: ", run_started)
	print("Revival artifact: ", revival_artifact_id)
	print("==========================")


# ===========================================
# РђР РўР•Р¤РђРљРўР« (РўРћР›Р¬РљРћ Р”Р›РЇ РЎРўРђРўРРЎРўРРљР!)
# ===========================================
# Р’РђР–РќРћ: РўРµРїРµСЂСЊ Р°СЂС‚РµС„Р°РєС‚С‹ СЂР°Р±РѕС‚Р°СЋС‚ РўРћР›Р¬РљРћ С‡РµСЂРµР· СЃРёСЃС‚РµРјСѓ РёРЅРІРµРЅС‚Р°СЂСЏ!
# Р­С‚Рё РјРµС‚РѕРґС‹ РѕСЃС‚Р°РІР»РµРЅС‹ РґР»СЏ РѕР±СЂР°С‚РЅРѕР№ СЃРѕРІРјРµСЃС‚РёРјРѕСЃС‚Рё

func has_artifact(artifact_id: String) -> bool:
	"""РџСЂРѕРІРµСЂСЏРµС‚ Р±С‹Р» Р»Рё Р°СЂС‚РµС„Р°РєС‚ СЃРѕР±СЂР°РЅ (РґР»СЏ СЃС‚Р°С‚РёСЃС‚РёРєРё)"""
	return collected_artifacts.has(artifact_id)


func has_ability(ability_name: String) -> bool:
	"""РЈРЎРўРђР Р•Р›Рћ: РўРµРїРµСЂСЊ РїСЂРѕРІРµСЂСЏРµС‚СЃСЏ С‡РµСЂРµР· РёРЅРІРµРЅС‚Р°СЂСЊ!"""
	# РћСЃС‚Р°РІР»СЏРµРј РґР»СЏ РѕР±СЂР°С‚РЅРѕР№ СЃРѕРІРјРµСЃС‚РёРјРѕСЃС‚Рё, РЅРѕ РЅРµ РёСЃРїРѕР»СЊР·СѓРµРј
	return false


func collect_artifact(artifact_id: String) -> bool:
	"""Р РµРіРёСЃС‚СЂРёСЂСѓРµС‚ Р°СЂС‚РµС„Р°РєС‚ РєР°Рє СЃРѕР±СЂР°РЅРЅС‹Р№ (РґР»СЏ СЃС‚Р°С‚РёСЃС‚РёРєРё)
	   РќР• Р°РєС‚РёРІРёСЂСѓРµС‚ СЌС„С„РµРєС‚С‹! Р­С„С„РµРєС‚С‹ РїСЂРёРјРµРЅСЏСЋС‚СЃСЏ С‡РµСЂРµР· РёРЅРІРµРЅС‚Р°СЂСЊ."""
	if not artifacts_database.has(artifact_id):
		return false

	if collected_artifacts.has(artifact_id):
		return false

	collected_artifacts.append(artifact_id)
	add_artifact_collected()

	# РќР• РїСЂРёРјРµРЅСЏРµРј СЌС„С„РµРєС‚С‹ Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё!
	# РђСЂС‚РµС„Р°РєС‚ РЅСѓР¶РЅРѕ СЌРєРёРїРёСЂРѕРІР°С‚СЊ РІ СЃР»РѕС‚ РёРЅРІРµРЅС‚Р°СЂСЏ

	artifact_collected.emit(artifact_id)
	print("рџ“¦ РђСЂС‚РµС„Р°РєС‚ '%s' РґРѕР±Р°РІР»РµРЅ РІ СЃС‚Р°С‚РёСЃС‚РёРєСѓ (РЅСѓР¶РЅРѕ СЌРєРёРїРёСЂРѕРІР°С‚СЊ!)" % artifact_id)
	return true


func get_artifact_data(artifact_id: String) -> Dictionary:
	if artifacts_database.has(artifact_id):
		return artifacts_database[artifact_id]
	return {"name": artifact_id, "rarity": "common", "ability": "unknown"}


func get_artifact_rarity(artifact_id: String) -> String:
	if artifacts_database.has(artifact_id):
		return artifacts_database[artifact_id].get("rarity", "common")
	return "common"


func get_artifacts_by_rarity() -> Dictionary:
	var result = {"common": [], "rare": [], "epic": [], "legendary": []}

	for artifact_id in collected_artifacts:
		var rarity = get_artifact_rarity(artifact_id)
		if result.has(rarity):
			result[rarity].append(artifact_id)

	return result


func reset_artifacts():
	collected_artifacts.clear()
	revival_artifact_id = ""


func apply_all_artifacts_to_player():
	"""РЈРЎРўРђР Р•Р›Рћ: РћСЃС‚Р°РІР»РµРЅРѕ РґР»СЏ РѕР±СЂР°С‚РЅРѕР№ СЃРѕРІРјРµСЃС‚РёРјРѕСЃС‚Рё.
	   РђСЂС‚РµС„Р°РєС‚С‹ С‚РµРїРµСЂСЊ РїСЂРёРјРµРЅСЏСЋС‚СЃСЏ С‡РµСЂРµР· СЃРёСЃС‚РµРјСѓ РёРЅРІРµРЅС‚Р°СЂСЏ!"""
	pass


func apply_artifact_effect(_artifact_id: String):
	"""РЈРЎРўРђР Р•Р›Рћ: РћСЃС‚Р°РІР»РµРЅРѕ РґР»СЏ РѕР±СЂР°С‚РЅРѕР№ СЃРѕРІРјРµСЃС‚РёРјРѕСЃС‚Рё.
	   РђСЂС‚РµС„Р°РєС‚С‹ С‚РµРїРµСЂСЊ РїСЂРёРјРµРЅСЏСЋС‚СЃСЏ С‡РµСЂРµР· СЃРёСЃС‚РµРјСѓ РёРЅРІРµРЅС‚Р°СЂСЏ!"""
	pass


# ===========================================
# РЎРРЎРўР•РњРђ РљР›Р®Р§Р•Р™
# ===========================================

func has_key(color: int) -> bool:
	"""РџСЂРѕРІРµСЂСЏРµС‚ РЅР°Р»РёС‡РёРµ РєР»СЋС‡Р° СѓРєР°Р·Р°РЅРЅРѕРіРѕ С†РІРµС‚Р°"""
	return keys.get(color, 0) > 0


func add_key(color: int, amount: int = 1):
	"""Р”РѕР±Р°РІР»СЏРµС‚ РєР»СЋС‡(Рё) СѓРєР°Р·Р°РЅРЅРѕРіРѕ С†РІРµС‚Р°"""
	if not keys.has(color):
		keys[color] = 0
	keys[color] += amount
	run_statistics["keys_collected"] += amount

	var color_name = KEY_COLOR_NAMES.get(color, "РЅРµРёР·РІРµСЃС‚РЅС‹Р№")
	print("рџ”‘ +%d %s РєР»СЋС‡ (РІСЃРµРіРѕ: %d)" % [amount, color_name, keys[color]])
	_update_keys_ui()


func remove_key(color: int, amount: int = 1) -> bool:
	"""РЈРґР°Р»СЏРµС‚ РєР»СЋС‡. Р’РѕР·РІСЂР°С‰Р°РµС‚ true РµСЃР»Рё СѓСЃРїРµС€РЅРѕ"""
	if keys.get(color, 0) < amount:
		var color_name = KEY_COLOR_NAMES.get(color, "РЅРµРёР·РІРµСЃС‚РЅС‹Р№")
		print("рџ”‘ вќЊ РќРµРґРѕСЃС‚Р°С‚РѕС‡РЅРѕ %s РєР»СЋС‡РµР№" % color_name)
		return false

	keys[color] -= amount
	var color_name = KEY_COLOR_NAMES.get(color, "РЅРµРёР·РІРµСЃС‚РЅС‹Р№")
	print("рџ”‘ -%d %s РєР»СЋС‡ (РѕСЃС‚Р°Р»РѕСЃСЊ: %d)" % [amount, color_name, keys[color]])
	_update_keys_ui()
	return true


func get_key_count(color: int) -> int:
	"""Р’РѕР·РІСЂР°С‰Р°РµС‚ РєРѕР»РёС‡РµСЃС‚РІРѕ РєР»СЋС‡РµР№ СѓРєР°Р·Р°РЅРЅРѕРіРѕ С†РІРµС‚Р°"""
	return keys.get(color, 0)


func get_all_keys() -> Dictionary:
	"""Р’РѕР·РІСЂР°С‰Р°РµС‚ РІСЃРµ РєР»СЋС‡Рё"""
	return keys.duplicate()


func get_keys_array() -> Array:
	"""Р’РѕР·РІСЂР°С‰Р°РµС‚ РјР°СЃСЃРёРІ РєРѕР»РёС‡РµСЃС‚РІР° РєР»СЋС‡РµР№ РґР»СЏ UI
	   [gold, silver, red, blue, green, purple]"""
	return [
		keys.get(0, 0),  # Gold
		keys.get(1, 0),  # Silver
		keys.get(2, 0),  # Red
		keys.get(3, 0),  # Blue
		keys.get(4, 0),  # Green
		keys.get(5, 0),  # Purple
	]


func reset_keys():
	"""РЎР±СЂР°СЃС‹РІР°РµС‚ РІСЃРµ РєР»СЋС‡Рё"""
	keys = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
	spawn_point = ""
	opened_doors.clear()
	_update_keys_ui()


func _update_keys_ui():
	"""РћР±РЅРѕРІР»СЏРµС‚ UI РєР»СЋС‡РµР№"""
	if not game_ui:
		return

	if game_ui.has_method("update_keys"):
		game_ui.update_keys(get_keys_array())
	elif game_ui.has_method("update_single_key"):
		for i in range(6):
			game_ui.update_single_key(i, keys.get(i, 0))


func mark_door_opened(door_id: String):
	if not opened_doors.has(door_id):
		opened_doors.append(door_id)

	if RunState:
		RunState.save_object_state(current_level, door_id, {
			"opened": true,
			"object_type": "door",
		})

func is_door_opened(door_id: String) -> bool:
	if opened_doors.has(door_id):
		return true

	if RunState:
		var state: Dictionary = _get_current_level_object_state(door_id)
		if _state_matches_object_type(state, "door"):
			return bool(state.get("opened", false))

	return false

# ===========================================
# РЎРћРҐР РђРќР•РќРР• РЎРћРЎРўРћРЇРќРРЇ
# ===========================================

func register_collected_pickup(object_name: String):
	"""Регистрирует подобранный объект по имени узла"""
	if object_name not in collected_pickups:
		collected_pickups.append(object_name)
		print("📦 Собрано: %s" % object_name)

	if RunState:
		RunState.mark_object_consumed(current_level, object_name, {
			"collected": true,
			"object_type": "pickup",
		})

func _get_current_level_object_state(object_name: String) -> Dictionary:
	if not RunState:
		return {}

	return RunState.get_object_state(current_level, object_name)


func _state_matches_object_type(state: Dictionary, expected_type: String) -> bool:
	if state.is_empty():
		return false

	return String(state.get("object_type", "")) == expected_type


func register_killed_enemy(enemy_name: String):
	"""Регистрирует убитого врага по имени узла"""
	if enemy_name not in killed_enemies:
		killed_enemies.append(enemy_name)
		print("💀 Убит: %s" % enemy_name)

	if RunState:
		RunState.mark_object_consumed(current_level, enemy_name, {
			"dead": true,
			"object_type": "enemy",
		})

func is_pickup_collected(object_name: String) -> bool:
	if object_name in collected_pickups:
		return true

	if RunState:
		var state: Dictionary = _get_current_level_object_state(object_name)
		if _state_matches_object_type(state, "pickup"):
			return bool(state.get("collected", false)) or bool(state.get("consumed", false))

	return false

func is_enemy_killed(enemy_name: String) -> bool:
	if enemy_name in killed_enemies:
		return true

	if RunState:
		var state: Dictionary = _get_current_level_object_state(enemy_name)
		if _state_matches_object_type(state, "enemy"):
			return bool(state.get("dead", false)) or bool(state.get("consumed", false))

	return false

func set_current_level(level_name: String):
	"""Устанавливает текущий уровень"""
	current_level = level_name
	if RunState:
		RunState.set_current_level(level_name)
	print("🗺️ Текущий уровень: %s" % level_name)

func register_opened_chest(chest_name: String):
	"""Регистрирует открытый сундук"""
	if current_level == "":
		current_level = "unknown"

	if current_level not in opened_chests:
		opened_chests[current_level] = []

	if chest_name not in opened_chests[current_level]:
		opened_chests[current_level].append(chest_name)
		print("📦 Сундук открыт: %s на %s" % [chest_name, current_level])

	if RunState:
		RunState.mark_object_consumed(current_level, chest_name, {
			"opened": true,
			"object_type": "chest",
		})

func is_chest_opened(chest_name: String) -> bool:
	"""Проверяет, был ли сундук уже открыт (ищем во всех уровнях)"""
	if RunState:
		if RunState.get_object_flag(current_level, chest_name, "opened"):
			return true
		if RunState.get_object_flag_any_level(chest_name, "opened"):
			return true

	for level in opened_chests.keys():
		if chest_name in opened_chests[level]:
			return true
	return false

func register_dropped_pickup(pickup_data: Dictionary):
	"""Р РµРіРёСЃС‚СЂРёСЂСѓРµС‚ РІС‹РїР°РІС€РёР№ РїСЂРµРґРјРµС‚ РґР»СЏ РІРѕСЃСЃС‚Р°РЅРѕРІР»РµРЅРёСЏ РїСЂРё РІРѕР·РІСЂР°С‚Рµ
	pickup_data = {type: "item"/"artifact", id: int/String, position: Vector2}
	"""
	if current_level == "":
		current_level = "unknown"

	if current_level not in dropped_pickups:
		dropped_pickups[current_level] = []

	dropped_pickups[current_level].append(pickup_data)


func get_dropped_pickups_for_level(level_name: String) -> Array:
	"""Р’РѕР·РІСЂР°С‰Р°РµС‚ СЃРїРёСЃРѕРє РІС‹РїР°РІС€РёС… РїСЂРµРґРјРµС‚РѕРІ РґР»СЏ СѓСЂРѕРІРЅСЏ"""
	if level_name in dropped_pickups:
		return dropped_pickups[level_name]
	return []


func remove_dropped_pickup(pickup_name: String):
	"""РЈРґР°Р»СЏРµС‚ РІС‹РїР°РІС€РёР№ РїСЂРµРґРјРµС‚ РёР· СЃРїРёСЃРєР° (РєРѕРіРґР° РїРѕРґРѕР±СЂР°РЅ)"""
	if current_level in dropped_pickups:
		for i in range(dropped_pickups[current_level].size() - 1, -1, -1):
			var pickup = dropped_pickups[current_level][i]
			if pickup.get("name", "") == pickup_name:
				dropped_pickups[current_level].remove_at(i)
				return


func clear_dropped_pickups_for_level(level_name: String):
	"""РћС‡РёС‰Р°РµС‚ РІС‹РїР°РІС€РёРµ РїСЂРµРґРјРµС‚С‹ РґР»СЏ СѓСЂРѕРІРЅСЏ"""
	if level_name in dropped_pickups:
		dropped_pickups[level_name].clear()


func save_player_stats():
	"""РЎРѕС…СЂР°РЅСЏРµС‚ HP/Mana РёРіСЂРѕРєР° РїРµСЂРµРґ РїРµСЂРµС…РѕРґРѕРј"""
	if current_player:
		saved_player_health = current_player.current_health
		if "current_mana" in current_player:
			saved_player_mana = current_player.current_mana
		else:
			saved_player_mana = -1
		print("рџ’ѕ РЎРѕС…СЂР°РЅРµРЅРѕ: HP=%d Mana=%d" % [saved_player_health, saved_player_mana])


func restore_player_stats():
	"""Р’РѕСЃСЃС‚Р°РЅР°РІР»РёРІР°РµС‚ HP/Mana РїРѕСЃР»Рµ РїРµСЂРµС…РѕРґР°"""
	if current_player and saved_player_health > 0:
		current_player.current_health = saved_player_health
		print("рџ’ѕ Р’РѕСЃСЃС‚Р°РЅРѕРІР»РµРЅРѕ: HP=%d" % saved_player_health)

		if "current_mana" in current_player and saved_player_mana >= 0:
			current_player.current_mana = saved_player_mana

		if current_player.has_signal("health_changed"):
			current_player.health_changed.emit(current_player.current_health)
		if current_player.has_signal("mana_changed") and "current_mana" in current_player:
			current_player.mana_changed.emit(current_player.current_mana)


func clear_saved_stats():
	saved_player_health = -1
	saved_player_mana = -1


# ===========================================
# Р—РђР‘Р•Р“
# ===========================================

func start_run():
	print("🎮 === НОВЫЙ ЗАБЕГ ===")
	reset_run_statistics()
	run_statistics["start_time"] = Time.get_unix_time_from_system()
	run_started = true

	collected_pickups.clear()
	killed_enemies.clear()
	opened_doors.clear()
	opened_chests.clear()  # Очищаем открытые сундуки
	dropped_pickups.clear()  # Очищаем выпавшие предметы
	reset_keys()
	reset_artifacts()
	clear_saved_stats()

	if RunState:
		RunState.start_new_run()
		if current_level != "":
			RunState.set_current_level(current_level)

func reset_run_statistics():
	run_statistics = {
		"death_reason": "",
		"keys_collected": 0,
		"items_collected": 0,
		"artifacts_collected": 0,
		"coins_collected": 0,
		"enemies_simple": 0,
		"enemies_elite": 0,
		"enemies_boss": 0,
		"damage_dealt": 0,
		"damage_taken": 0,
		"rooms_visited": 1,
		"time_played": 0.0,
		"start_time": 0.0
	}
	run_started = false


func full_reset():
	print("🔄 === ПОЛНЫЙ СБРОС ===")
	reset_run_statistics()
	reset_artifacts()
	reset_keys()

	collected_pickups.clear()
	killed_enemies.clear()
	opened_doors.clear()
	opened_chests.clear()    # Очищаем открытые сундуки
	dropped_pickups.clear()  # Очищаем выпавшие предметы
	current_level = ""
	clear_saved_stats()

	if RunState:
		RunState.clear_run()

	unregister_player()
	unregister_game_ui()

func reset_all_for_new_game():
	full_reset()


# ===========================================
# РЎРўРђРўРРЎРўРРљРђ
# ===========================================

func add_key_collected():
	run_statistics["keys_collected"] += 1


func add_item_collected():
	run_statistics["items_collected"] += 1


func add_artifact_collected():
	run_statistics["artifacts_collected"] += 1


func add_coins(amount: int):
	run_statistics["coins_collected"] += amount


func add_enemy_killed(enemy_type: String):
	match enemy_type:
		"simple":
			run_statistics["enemies_simple"] += 1
		"elite":
			run_statistics["enemies_elite"] += 1
		"boss":
			run_statistics["enemies_boss"] += 1


func add_damage_dealt(amount: int):
	run_statistics["damage_dealt"] += amount


func add_damage_taken(amount: int):
	run_statistics["damage_taken"] += amount


func add_room_visited():
	run_statistics["rooms_visited"] += 1
	if RunState and last_room_path != "":
		RunState.mark_room_visited(last_room_path)

func set_death_reason(reason: String):
	run_statistics["death_reason"] = reason


func update_play_time():
	if run_started and run_statistics["start_time"] > 0:
		run_statistics["time_played"] = Time.get_unix_time_from_system() - run_statistics["start_time"]


func get_run_statistics() -> Dictionary:
	update_play_time()
	run_statistics["artifacts_collected"] = collected_artifacts.size()
	return run_statistics.duplicate()


# ===========================================
# Р’РћР—Р РћР–Р”Р•РќРР•
# ===========================================
# Р’РђР–РќРћ: revival_artifact_id СѓСЃС‚Р°РЅР°РІР»РёРІР°РµС‚СЃСЏ РўРћР›Р¬РљРћ РёР· level1.gd
# РєРѕРіРґР° РџРµСЂРѕ Р¤РµРЅРёРєСЃР° Р­РљРРџРР РћР’РђРќРћ РІ СЃР»РѕС‚ Р°СЂС‚РµС„Р°РєС‚Р°!

func set_revival_artifact(artifact_id: String):
	"""РЈСЃС‚Р°РЅР°РІР»РёРІР°РµС‚ Р°СЂС‚РµС„Р°РєС‚ РІРѕР·СЂРѕР¶РґРµРЅРёСЏ (РІС‹Р·С‹РІР°РµС‚СЃСЏ РёР· level1.gd)"""
	revival_artifact_id = artifact_id
	if artifact_id != "":
		print("вњЁ РђСЂС‚РµС„Р°РєС‚ РІРѕР·СЂРѕР¶РґРµРЅРёСЏ Р°РєС‚РёРІРµРЅ: %s" % artifact_id)


func get_revival_artifact() -> String:
	return revival_artifact_id


func has_revival_artifact() -> bool:
	"""РџСЂРѕРІРµСЂСЏРµС‚ РµСЃС‚СЊ Р»Рё РђРљРўРР’РќР«Р™ Р°СЂС‚РµС„Р°РєС‚ РІРѕР·СЂРѕР¶РґРµРЅРёСЏ"""
	return revival_artifact_id != ""


func use_revival_artifact() -> String:
	"""РСЃРїРѕР»СЊР·СѓРµС‚ Р°СЂС‚РµС„Р°РєС‚ РІРѕР·СЂРѕР¶РґРµРЅРёСЏ.
	   Р’РђР–РќРћ: РЈРґР°Р»РµРЅРёРµ РёР· РёРЅРІРµРЅС‚Р°СЂСЏ РґРµР»Р°РµС‚СЃСЏ РІ level1.gd!"""
	var used_id = revival_artifact_id
	revival_artifact_id = ""
	print("рџ”® РђСЂС‚РµС„Р°РєС‚ РІРѕР·СЂРѕР¶РґРµРЅРёСЏ РёСЃРїРѕР»СЊР·РѕРІР°РЅ: %s" % used_id)
	return used_id


func save_safe_position(room_path: String, pos: Vector2):
	last_room_path = room_path
	last_safe_position = pos
	if RunState:
		RunState.save_safe_position(room_path, pos)
