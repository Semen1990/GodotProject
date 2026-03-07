extends Node2D

# ===========================================
# LEVEL 1 - Р’Р•Р РЎРРЇ v8.0 - Р’РЎР• РРЎРџР РђР’Р›Р•РќРРЇ
# ===========================================
#
# РР—РњР•РќР•РќРРЇ:
# 1. РђСЂС‚РµС„Р°РєС‚С‹ РќР• Р°РєС‚РёРІРёСЂСѓСЋС‚СЃСЏ Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё
# 2. РЎСѓРЅРґСѓРєРё СЃРїР°РІРЅСЏС‚ РїСЂРµРґРјРµС‚С‹ РЅР° Р·РµРјР»СЋ
# 3. РџРµСЂРѕ Р¤РµРЅРёРєСЃР° СЂР°Р±РѕС‚Р°РµС‚ РўРћР›Р¬РљРћ РёР· СЃР»РѕС‚Р° Р°СЂС‚РµС„Р°РєС‚Р°
# 4. HP СЃРѕС…СЂР°РЅСЏРµС‚СЃСЏ РјРµР¶РґСѓ СѓСЂРѕРІРЅСЏРјРё

@onready var player_spawn = $PlayerSpawn
@onready var game_ui = $GameUI

var current_player = null
var last_armor_value: int = 0

var inventory_ui: InventoryUI = null
var hotbar_ui: HotbarUI = null

# === Р‘РђР—РћР’Р«Р• РЎРўРђРўР« ===
var base_player_armor: int = 0
var base_player_max_health: int = 0
var base_player_max_mana: int = 0
var base_player_speed: int = 0
var base_player_damage: int = 0

# === Р‘РћРќРЈРЎР« ===
var equipment_bonus_armor: int = 0
var equipment_bonus_hp: int = 0
var equipment_bonus_mana: int = 0
var equipment_bonus_speed: int = 0
var equipment_bonus_damage: int = 0

var potion_bonus_armor: int = 0
var potion_bonus_damage: int = 0


func _ready():
	print("\nрџЋ® ========== LEVEL 1 v8.1 ==========")

	# РЈСЃС‚Р°РЅР°РІР»РёРІР°РµРј С‚РµРєСѓС‰РёР№ СѓСЂРѕРІРµРЅСЊ РІ Global
	if Global:
		Global.set_current_level(scene_file_path if not scene_file_path.is_empty() else "level1")
	print("   run_started: %s" % Global.run_started)
	print("   spawn_point: '%s'" % Global.spawn_point)

	var is_new_game = not Global.run_started

	if is_new_game:
		print("рџ†• РќРћР’РђРЇ РР“Р Рђ")
		if Inventory:
			Inventory.clear_all()
		Global.start_run()
	else:
		print("рџ”„ Р’РћР—Р’Р РђРў")
		call_deferred("_remove_collected_objects")

	_initialize_inventory()
	_create_inventory_ui()

	await get_tree().process_frame

	spawn_selected_character(is_new_game)
	_setup_chests()

	if Global and game_ui:
		Global.register_game_ui(game_ui)

	print("рџЋ® ========== LEVEL 1 READY ==========")
	print("")


func _remove_collected_objects():
	await get_tree().process_frame

	print("рџ“‚ РЈРґР°Р»СЏРµРј СЃРѕР±СЂР°РЅРЅС‹Рµ РѕР±СЉРµРєС‚С‹...")

	for child in get_children():
		var child_name = child.name

		if Global.is_pickup_collected(child_name):
			print("   рџ—‘пёЏ %s" % child_name)
			child.queue_free()
			continue

		if Global.is_enemy_killed(child_name):
			print("   рџ’Ђ %s" % child_name)
			child.queue_free()
			continue

		if Global.is_door_opened(child_name):
			if "is_open" in child:
				child.is_open = true
			if child.has_method("_update_visual"):
				child._update_visual()


func save_before_transition():
	"""Р’С‹Р·С‹РІР°РµС‚СЃСЏ РґРІРµСЂСЊСЋ РїРµСЂРµРґ РїРµСЂРµС…РѕРґРѕРј"""
	if not current_player:
		return

	Global.saved_player_health = current_player.current_health
	if "current_mana" in current_player:
		Global.saved_player_mana = current_player.current_mana
	else:
		Global.saved_player_mana = -1

	print("рџ’ѕ в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ")
	print("рџ’ѕ РЎРћРҐР РђРќР•РќРћ: HP=%d Mana=%d" % [Global.saved_player_health, Global.saved_player_mana])
	print("рџ’ѕ в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ")

	if RunState:
		RunState.capture_scene_state(self)

func _restore_player_stats():
	if not current_player:
		return

	print("рџ’ѕ Р’РѕСЃСЃС‚Р°РЅР°РІР»РёРІР°РµРј СЃС‚Р°С‚С‹...")
	print("рџ’ѕ Saved HP: %d" % Global.saved_player_health)

	if Global.saved_player_health > 0:
		current_player.current_health = mini(Global.saved_player_health, current_player.max_health)
		print("рџ’ѕ HP: %d" % current_player.current_health)

		if current_player.has_signal("health_changed"):
			current_player.health_changed.emit(current_player.current_health)

	if Global.saved_player_mana >= 0 and "current_mana" in current_player:
		current_player.current_mana = mini(Global.saved_player_mana, current_player.max_mana)
		print("рџ’ѕ Mana: %d" % current_player.current_mana)

		if current_player.has_signal("mana_changed"):
			current_player.mana_changed.emit(current_player.current_mana)

	setup_player_ui()
	Global.clear_saved_stats()


# ===========================================
# РРќР’Р•РќРўРђР Р¬
# ===========================================

func _initialize_inventory():
	print("=== рџЋ’ РРќРР¦РРђР›РР—РђР¦РРЇ РРќР’Р•РќРўРђР РЇ ===")

	if not Inventory:
		push_error("вќЊ Inventory РЅРµ РЅР°Р№РґРµРЅ!")
		return

	var db_path = "res://data/items/demo_database.tres"

	if not ResourceLoader.exists(db_path):
		push_warning("вљ пёЏ Р‘Р°Р·Р° РґР°РЅРЅС‹С… РЅРµ РЅР°Р№РґРµРЅР°")
		return

	var item_db = load(db_path) as GameItemDatabase

	if item_db:
		Inventory.set_database(item_db)
		print("вњ… Р‘Р°Р·Р° РґР°РЅРЅС‹С…: %d РїСЂРµРґРјРµС‚РѕРІ" % item_db.items.size())

		var char_class = _get_character_class()
		Inventory.set_character_class(char_class)

		if not Inventory.stats_updated.is_connected(_on_equipment_stats_changed):
			Inventory.stats_updated.connect(_on_equipment_stats_changed)
		if not Inventory.equipment_changed.is_connected(_on_equipment_changed):
			Inventory.equipment_changed.connect(_on_equipment_changed)

	print("=== вњ… РРќР’Р•РќРўРђР Р¬ Р“РћРўРћР’ ===")


func _get_character_class() -> InventoryEnums.CharacterClass:
	match Global.selected_character:
		"warrior":
			return InventoryEnums.CharacterClass.WARRIOR
		"paladin":
			return InventoryEnums.CharacterClass.PALADIN
		"rogue":
			return InventoryEnums.CharacterClass.ROGUE
		"berserk":
			return InventoryEnums.CharacterClass.BERSERK
		_:
			return InventoryEnums.CharacterClass.WARRIOR


func _create_inventory_ui():
	inventory_ui = InventoryUI.new()
	inventory_ui.name = "InventoryUI"
	add_child(inventory_ui)
	inventory_ui.visible = false

	inventory_ui.item_used.connect(_on_inventory_item_used)
	print("вњ… InventoryUI СЃРѕР·РґР°РЅ")

	hotbar_ui = HotbarUI.new()
	hotbar_ui.name = "HotbarUI"
	add_child(hotbar_ui)

	if hotbar_ui.has_signal("hotbar_slot_used"):
		hotbar_ui.hotbar_slot_used.connect(_on_hotbar_slot_used)
	print("вњ… HotbarUI СЃРѕР·РґР°РЅ")


# ===========================================
# РРЎРџРћР›Р¬Р—РћР’РђРќРР• Р—Р•Р›РР™
# ===========================================

func _on_inventory_item_used(item: InventoryItem):
	if not current_player or not item or not item.data:
		return

	var item_id = item.get_item_id()

	if Inventory.is_potion_used(item_id):
		print("вљ пёЏ Р—РµР»СЊРµ '%s' СѓР¶Рµ РёСЃРїРѕР»СЊР·РѕРІР°РЅРѕ!" % item.get_display_name())
		return

	print("рџ§Є РСЃРїРѕР»СЊР·СѓРµРј: %s" % item.get_display_name())
	Inventory.mark_potion_used(item_id)

	for effect in item.data.effects:
		_apply_potion_effect(effect)


func _on_hotbar_slot_used(index: int):
	if not current_player or not Inventory:
		return

	var item = Inventory.get_hotbar_item(index)
	if not item or not item.data:
		return

	var item_id = item.get_item_id()

	if Inventory.is_potion_used(item_id):
		print("вљ пёЏ Р—РµР»СЊРµ СѓР¶Рµ РёСЃРїРѕР»СЊР·РѕРІР°РЅРѕ!")
		return

	print("рџ§Є Р‘С‹СЃС‚СЂС‹Р№ СЃР»РѕС‚ %d: %s" % [index + 1, item.get_display_name()])
	Inventory.mark_potion_used(item_id)

	for effect in item.data.effects:
		_apply_potion_effect(effect)


func _apply_potion_effect(effect: Dictionary):
	if not current_player:
		return

	var effect_type = effect.get("type", InventoryEnums.EffectType.NONE)
	var value = effect.get("value", 0.0)

	match effect_type:
		InventoryEnums.EffectType.INSTANT_HEAL_HP:
			var heal = int(value)
			var old_hp = current_player.current_health
			current_player.current_health = mini(old_hp + heal, current_player.max_health)
			print("рџ’љ +%d HP" % (current_player.current_health - old_hp))

			if current_player.has_signal("health_changed"):
				current_player.health_changed.emit(current_player.current_health)
			_show_heal_effect()

		InventoryEnums.EffectType.INSTANT_HEAL_MANA:
			var mana = int(value)
			var old_mana = current_player.current_mana
			current_player.current_mana = mini(old_mana + mana, current_player.max_mana)
			print("рџ’™ +%d РјР°РЅС‹" % (current_player.current_mana - old_mana))

			if current_player.has_signal("mana_changed"):
				current_player.mana_changed.emit(current_player.current_mana)

		InventoryEnums.EffectType.BUFF_ARMOR:
			var armor = int(value)
			potion_bonus_armor += armor
			current_player.armor += armor
			_update_armor_ui()
			print("рџ›ЎпёЏ +%d Р±СЂРѕРЅРё" % armor)

		InventoryEnums.EffectType.BUFF_DAMAGE:
			var damage = int(value)
			potion_bonus_damage += damage
			print("вљ”пёЏ +%d СѓСЂРѕРЅР°" % damage)
			_recalculate_player_damage()


func _show_heal_effect():
	if not current_player:
		return

	var sprite = current_player.get_node_or_null("AnimatedSprite2D")
	if not sprite:
		return

	var original = sprite.modulate
	sprite.modulate = Color(0.5, 2.0, 0.5, 1.0)

	var tween = create_tween()
	tween.tween_property(sprite, "modulate", original, 0.3)


# ===========================================
# Р­РљРРџРР РћР’РљРђ
# ===========================================

func _on_equipment_stats_changed(stats: Dictionary):
	if not current_player:
		return

	equipment_bonus_hp = stats.get("max_hp", 0)
	equipment_bonus_mana = stats.get("max_mana", 0)
	equipment_bonus_armor = stats.get("armor", 0)
	equipment_bonus_speed = stats.get("speed_percent", 0)
	equipment_bonus_damage = stats.get("damage", 0)

	# HP
	var new_max_hp = base_player_max_health + equipment_bonus_hp
	if current_player.max_health != new_max_hp:
		var hp_diff = new_max_hp - current_player.max_health
		current_player.max_health = new_max_hp
		if hp_diff > 0:
			current_player.current_health += hp_diff
		current_player.current_health = mini(current_player.current_health, current_player.max_health)

		if game_ui:
			game_ui.update_max_health(current_player.max_health)
			game_ui.update_health(current_player.current_health)

	# Mana
	var new_max_mana = base_player_max_mana + equipment_bonus_mana
	if "max_mana" in current_player and current_player.max_mana != new_max_mana:
		var mana_diff = new_max_mana - current_player.max_mana
		current_player.max_mana = new_max_mana
		if mana_diff > 0:
			current_player.current_mana += mana_diff
		current_player.current_mana = mini(current_player.current_mana, current_player.max_mana)

		if game_ui:
			game_ui.update_max_mana(current_player.max_mana)
			game_ui.update_mana(current_player.current_mana)

	# Armor
	current_player.armor = base_player_armor + equipment_bonus_armor + potion_bonus_armor
	_update_armor_ui()

	# Damage
	_recalculate_player_damage()

	# РђСЂС‚РµС„Р°РєС‚ РІРѕР·СЂРѕР¶РґРµРЅРёСЏ - РўРћР›Р¬РљРћ РР— РЎР›РћРўРђ!
	_update_revival_artifact_status()


func _on_equipment_changed(slot = null, old_item = null, new_item = null):
	# РџСЂРѕРІРµСЂСЏРµРј Р°СЂС‚РµС„Р°РєС‚С‹ РїСЂРё Р»СЋР±РѕРј РёР·РјРµРЅРµРЅРёРё СЌРєРёРїРёСЂРѕРІРєРё
	_update_revival_artifact_status()
	_update_double_jump_artifact()


func _update_armor_ui():
	if game_ui and current_player:
		game_ui.update_armor(current_player.armor)


func _recalculate_player_damage():
	if not current_player:
		return

	var total = base_player_damage + equipment_bonus_damage + potion_bonus_damage
	if "current_damage" in current_player:
		current_player.current_damage = total


func _update_revival_artifact_status():
	"""РџРµСЂРѕ Р¤РµРЅРёРєСЃР° СЂР°Р±РѕС‚Р°РµС‚ РўРћР›Р¬РљРћ РµСЃР»Рё СЌРєРёРїРёСЂРѕРІР°РЅРѕ РІ СЃР»РѕС‚ Р°СЂС‚РµС„Р°РєС‚Р°!"""
	if not Inventory:
		return

	var has_phoenix = false

	# РџСЂРѕРІРµСЂСЏРµРј РўРћР›Р¬РљРћ СЃР»РѕС‚С‹ Р°СЂС‚РµС„Р°РєС‚РѕРІ
	for slot in [
		InventoryEnums.EquipSlot.ARTIFACT_1,
		InventoryEnums.EquipSlot.ARTIFACT_2,
		InventoryEnums.EquipSlot.ARTIFACT_3,
		InventoryEnums.EquipSlot.ARTIFACT_4,
	]:
		var item = Inventory.get_equipped_item(slot)
		if item and item.get_item_id() == 202:  # Phoenix Feather
			has_phoenix = true
			break

	if has_phoenix:
		Global.set_revival_artifact("phoenix_feather")
		print("вњЁ РђСЂС‚РµС„Р°РєС‚ РІРѕР·СЂРѕР¶РґРµРЅРёСЏ РђРљРўРР’Р•Рќ (РІ СЃР»РѕС‚Рµ)")
	else:
		if Global.revival_artifact_id == "phoenix_feather":
			Global.revival_artifact_id = ""
			print("вќЊ РђСЂС‚РµС„Р°РєС‚ РІРѕР·СЂРѕР¶РґРµРЅРёСЏ РќР• Р°РєС‚РёРІРµРЅ")


func _update_double_jump_artifact():
	"""РљСЂС‹Р»СЊСЏ Р“РµСЂРјРµСЃР° СЂР°Р±РѕС‚Р°СЋС‚ РўРћР›Р¬РљРћ РµСЃР»Рё СЌРєРёРїРёСЂРѕРІР°РЅС‹"""
	if not Inventory or not current_player:
		return

	var has_wings = false

	for slot in [
		InventoryEnums.EquipSlot.ARTIFACT_1,
		InventoryEnums.EquipSlot.ARTIFACT_2,
		InventoryEnums.EquipSlot.ARTIFACT_3,
		InventoryEnums.EquipSlot.ARTIFACT_4,
	]:
		var item = Inventory.get_equipped_item(slot)
		if item and item.get_item_id() == 201:  # Hermes Wings
			has_wings = true
			break

	if "enable_double_jump" in current_player:
		current_player.enable_double_jump = has_wings
		if has_wings:
			print("вњЁ Р”РІРѕР№РЅРѕР№ РїСЂС‹Р¶РѕРє РђРљРўРР’Р•Рќ")
		else:
			print("вќЊ Р”РІРѕР№РЅРѕР№ РїСЂС‹Р¶РѕРє РќР• Р°РєС‚РёРІРµРЅ")


# ===========================================
# РЎРњР•Р РўР¬ / Р’РћР—Р РћР–Р”Р•РќРР•
# ===========================================

func _on_player_died():
	print("рџ’Ђ РРіСЂРѕРє РїРѕРіРёР±")

	potion_bonus_armor = 0
	potion_bonus_damage = 0

	if current_player and current_player.has_method("reset_potion_bonuses"):
		current_player.reset_potion_bonuses()

	_recalculate_player_damage()

	if Inventory:
		Inventory.reset_on_death()


func _on_player_revived():
	print("вњЁ РРіСЂРѕРє РІРѕР·СЂРѕРґРёР»СЃСЏ")
	_consume_revival_artifact()
	_recalculate_player_damage()


func _consume_revival_artifact():
	"""РЈРґР°Р»СЏРµС‚ РёСЃРїРѕР»СЊР·РѕРІР°РЅРЅРѕРµ РџРµСЂРѕ Р¤РµРЅРёРєСЃР° РёР· СЃР»РѕС‚Р°"""
	if not Inventory:
		return

	for slot in [
		InventoryEnums.EquipSlot.ARTIFACT_1,
		InventoryEnums.EquipSlot.ARTIFACT_2,
		InventoryEnums.EquipSlot.ARTIFACT_3,
		InventoryEnums.EquipSlot.ARTIFACT_4,
	]:
		var item = Inventory.get_equipped_item(slot)
		if item and item.get_item_id() == 202:
			Inventory.unequip_item(slot)
			Inventory.remove_item_by_id(202, 1)
			print("рџ”Ґ РџРµСЂРѕ Р¤РµРЅРёРєСЃР° РРЎРџРћР›Р¬Р—РћР’РђРќРћ Рё СѓРґР°Р»РµРЅРѕ!")
			_update_revival_artifact_status()
			break


# ===========================================
# РќРђРЎРўР РћР™РљРђ РЎРЈРќР”РЈРљРћР’ - РќРћР’РђРЇ РЎРРЎРўР•РњРђ!
# ===========================================

func _setup_chests():
	"""РќР°СЃС‚СЂР°РёРІР°РµС‚ СЃСѓРЅРґСѓРєРё - С‚РµРїРµСЂСЊ РѕРЅРё СЃРїР°РІРЅСЏС‚ РїСЂРµРґРјРµС‚С‹ РќРђ Р—Р•РњР›Р®"""
	print("")
	print("=== рџ“¦ РќРђРЎРўР РћР™РљРђ РЎРЈРќР”РЈРљРћР’ ===")

	var chest_count = 0

	for child in get_children():
		if child is Chest:
			chest_count += 1
			_configure_chest(child, chest_count)

			if Global.is_chest_opened(child.name):
				print("   рџ“¦ %s - СѓР¶Рµ РѕС‚РєСЂС‹С‚, РІРѕСЃСЃС‚Р°РЅР°РІР»РёРІР°РµРј РЅРµРїРѕРґРѕР±СЂР°РЅРЅС‹Р№ Р»СѓС‚" % child.name)
				if child.has_method("restore_opened_chest"):
					child.restore_opened_chest()

	if chest_count == 0:
		print("вљ пёЏ РЎСѓРЅРґСѓРєРё РЅРµ РЅР°Р№РґРµРЅС‹!")
	else:
		print("вњ… РќР°СЃС‚СЂРѕРµРЅРѕ: %d" % chest_count)
	print("")


func _configure_chest(chest: Chest, index: int):
	"""РќР°СЃС‚СЂР°РёРІР°РµС‚ СЃСѓРЅРґСѓРє - РїСЂРµРґРјРµС‚С‹ Р±СѓРґСѓС‚ СЃРїР°РІРЅРёС‚СЊСЃСЏ РЅР° Р·РµРјР»Рµ!"""
	match index:
		1:
			# РЎСѓРЅРґСѓРє СЃ РђР РўР•Р¤РђРљРўРђРњР
			chest.setup_artifacts(["hermes_wings", "phoenix_feather"])
			print("   рџ“¦ РЎСѓРЅРґСѓРє #1: РђСЂС‚РµС„Р°РєС‚С‹ (РїР°РґР°СЋС‚ РЅР° Р·РµРјР»СЋ)")

		2:
			# РЎСѓРЅРґСѓРє СЃ РџР Р•Р”РњР•РўРђРњР
			chest.setup_items(
				[1, 2, 3, 4, 101, 102, 103, 104, 105],
				[2, 2, 1, 1, 1, 1, 1, 1, 1]
			)
			print("   рџ“¦ РЎСѓРЅРґСѓРє #2: Р­РєРёРїРёСЂРѕРІРєР° Рё Р·РµР»СЊСЏ (РїР°РґР°СЋС‚ РЅР° Р·РµРјР»СЋ)")

		_:
			chest.setup_items([1, 2], [2, 2])
			print("   рџ“¦ РЎСѓРЅРґСѓРє #%d: РЎР»СѓС‡Р°Р№РЅС‹Р№ Р»СѓС‚" % index)


# ===========================================
# РЎРџРђР’Рќ РџР•Р РЎРћРќРђР–Рђ
# ===========================================

func spawn_selected_character(is_new_game: bool = true):
	if not Global.selected_character:
		Global.selected_character = "warrior"

	print("рџ”„ Spawning: ", Global.selected_character)

	var scene_path = Global.character_player_scenes.get(Global.selected_character)

	if scene_path and ResourceLoader.exists(scene_path):
		var scene = load(scene_path)
		current_player = scene.instantiate()

		# РџРѕР·РёС†РёСЏ СЃРїР°РІРЅР°
		var spawn_pos = player_spawn.global_position if player_spawn else Vector2(100, 100)
		var spawn_source = "PlayerSpawn"

		if Global.spawn_point != "":
			print("рџ”Ќ РС‰РµРј SpawnPoint: '%s'" % Global.spawn_point)
			var spawn_node = get_node_or_null(Global.spawn_point)
			if spawn_node:
				spawn_pos = spawn_node.global_position
				spawn_source = Global.spawn_point
				print("вњ… SpawnPoint РЅР°Р№РґРµРЅ: %s" % spawn_pos)
			Global.spawn_point = ""

		print("рџ“Ќ РС‚РѕРіРѕРІС‹Р№ СЃРїР°РІРЅ: %s [%s]" % [spawn_pos, spawn_source])

		current_player.global_position = spawn_pos
		add_child(current_player)
		print("вњ… Player spawned")

		Global.register_player(current_player)

		_save_base_stats()
		_apply_current_equipment_state()
		setup_player_ui()
		setup_player_camera()

		if current_player.has_signal("died"):
			current_player.died.connect(_on_player_died)
		if current_player.has_signal("revived"):
			current_player.revived.connect(_on_player_revived)

		# РћРўРљР›Р®Р§РђР•Рњ СЃС‚Р°СЂСѓСЋ СЃРёСЃС‚РµРјСѓ Р°СЂС‚РµС„Р°РєС‚РѕРІ!
		if "enable_double_jump" in current_player:
			current_player.enable_double_jump = false

		# Р’РѕСЃСЃС‚Р°РЅР°РІР»РёРІР°РµРј HP РїСЂРё РІРѕР·РІСЂР°С‚Рµ
		if not is_new_game:
			call_deferred("_restore_player_stats")

		# РџСЂРѕРІРµСЂСЏРµРј СЌРєРёРїРёСЂРѕРІР°РЅРЅС‹Рµ Р°СЂС‚РµС„Р°РєС‚С‹
		call_deferred("_update_revival_artifact_status")
		call_deferred("_update_double_jump_artifact")
	else:
		print("вќЊ Character scene not found")
		create_fallback_player()


func _save_base_stats():
	if not current_player:
		return

	if "armor" in current_player:
		base_player_armor = current_player.armor
	if "max_health" in current_player:
		base_player_max_health = current_player.max_health
	if "max_mana" in current_player:
		base_player_max_mana = current_player.max_mana
	if "current_speed" in current_player:
		base_player_speed = current_player.current_speed

	if "BASE_DAMAGE" in current_player:
		base_player_damage = current_player.BASE_DAMAGE
	elif "current_damage" in current_player:
		base_player_damage = current_player.current_damage
	else:
		base_player_damage = 2

	print("рџ“Љ Р‘Р°Р·РѕРІС‹Рµ СЃС‚Р°С‚С‹ СЃРѕС…СЂР°РЅРµРЅС‹ (СѓСЂРѕРЅ: %d)" % base_player_damage)


# ===========================================
# UI
# ===========================================

func _apply_current_equipment_state():
	if not current_player or not Inventory:
		return

	var stats: Dictionary = Inventory.get_equipment_stats()
	_on_equipment_stats_changed(stats)
	_on_equipment_changed()


func setup_player_ui():
	if not current_player or not game_ui:
		return

	var stats = {
		"health": current_player.current_health,
		"max_health": current_player.max_health,
		"mana": current_player.current_mana if "current_mana" in current_player else 0,
		"max_mana": current_player.max_mana if "max_mana" in current_player else 0,
		"armor": current_player.armor if "armor" in current_player else 0
	}

	game_ui.setup_character_ui(stats)

	if current_player.has_signal("health_changed"):
		if not current_player.health_changed.is_connected(_on_player_health_changed):
			current_player.health_changed.connect(_on_player_health_changed)

	if current_player.has_signal("mana_changed"):
		if not current_player.mana_changed.is_connected(_on_player_mana_changed):
			current_player.mana_changed.connect(_on_player_mana_changed)

	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.timeout.connect(_check_armor_changed)
	add_child(timer)
	timer.start()


func _check_armor_changed():
	if not current_player:
		return

	if current_player.armor != last_armor_value:
		last_armor_value = current_player.armor
		_on_player_armor_changed(current_player.armor)


func _on_player_health_changed(new_health):
	if game_ui:
		game_ui.update_health(new_health)


func _on_player_mana_changed(new_mana):
	if game_ui:
		game_ui.update_mana(new_mana)


func _on_player_armor_changed(new_armor):
	if game_ui:
		game_ui.update_armor(new_armor)


# ===========================================
# РљРђРњР•Р Рђ
# ===========================================

func setup_player_camera():
	if not current_player:
		return

	var camera = current_player.get_node_or_null("Camera2D")
	if not camera:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		camera.zoom = Vector2(1.5, 1.5)
		current_player.add_child(camera)

	camera.limit_left = 0
	camera.limit_right = 2000
	camera.limit_top = 0
	camera.limit_bottom = 1200
	camera.make_current()


func create_fallback_player():
	var player = CharacterBody2D.new()
	player.name = "FallbackPlayer"

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(30, 50)
	collision.shape = shape
	player.add_child(collision)

	var sprite = Sprite2D.new()
	sprite.texture = preload("res://icon.svg")
	sprite.modulate = Color.RED
	player.add_child(sprite)

	if player_spawn:
		player.global_position = player_spawn.global_position
	else:
		player.global_position = Vector2(100, 100)

	add_child(player)
	current_player = player
