extends "res://scripts/game_characters/base_game_character.gd"

# ===========================================
# Р’РћРРќ - РўРђРќРљ/Р—РђР©РРўРќРРљ (РРЎРџР РђР’Р›Р•РќРћ v3.0)
# ===========================================
#
# РРЎРџР РђР’Р›Р•РќРћ:
# - Р‘СЂРѕРЅСЏ РїСЂР°РІРёР»СЊРЅРѕ СЃСѓРјРјРёСЂСѓРµС‚СЃСЏ: Р‘РђР—Рђ + Р­РљРРџРР РћР’РљРђ + Р—Р•Р›Р¬Р• + Р‘Р›РћРљ
# - РџСЂРё СЃРЅСЏС‚РёРё Р±Р»РѕРєР° Р±СЂРѕРЅСЏ РЅРµ СЃР±СЂР°СЃС‹РІР°РµС‚СЃСЏ Рє Р±Р°Р·Рµ

# Р‘Р»РѕРє
var block_cooldown: float = 0.0
var is_block_active: bool = false  # РћС‚СЃР»РµР¶РёРІР°РµРј Р°РєС‚РёРІРµРЅ Р»Рё Р±Р»РѕРє

# Р‘РђР—РћР’РђРЇ Р±СЂРѕРЅСЏ РїРµСЂСЃРѕРЅР°Р¶Р° (Р±РµР· РјРѕРґРёС„РёРєР°С‚РѕСЂРѕРІ)
var warrior_base_armor: int = 2

# Р”Р»СЏ СЃРѕРІРјРµСЃС‚РёРјРѕСЃС‚Рё СЃ РґСЂСѓРіРёРјРё СЃРёСЃС‚РµРјР°РјРё
var base_armor: int = 2

# Р‘РѕРЅСѓСЃ РѕС‚ Р±Р»РѕРєР°
var block_armor_bonus: int = 0

# РљРѕРЅСЃС‚Р°РЅС‚С‹
const BLOCK_COOLDOWN_TIME: float = 3.0
const BLOCK_ARMOR_BONUS_VALUE: int = 2
const BASE_DAMAGE: int = 2
const ATTACK_RANGE: float = 55.0

# === Р’РќР•РЁРќРР• Р‘РћРќРЈРЎР« (РѕС‚ СЌРєРёРїРёСЂРѕРІРєРё Рё Р·РµР»РёР№) ===
# Р­С‚Рё РїРµСЂРµРјРµРЅРЅС‹Рµ РѕР±РЅРѕРІР»СЏСЋС‚СЃСЏ РёР· level1.gd
var equipment_armor_bonus: int = 0
var potion_armor_bonus: int = 0

func _ready():
	
	# РҐР°СЂР°РєС‚РµСЂРёСЃС‚РёРєРё
	character_name = "Р’РѕРёРЅ"
	max_health = 12
	current_health = 12
	max_mana = 0
	current_mana = 0
	
	# Р‘РђР—РћР’РђРЇ Р±СЂРѕРЅСЏ
	warrior_base_armor = 2
	armor = warrior_base_armor
	base_armor = warrior_base_armor  # Р”Р»СЏ СЃРѕРІРјРµСЃС‚РёРјРѕСЃС‚Рё
	
	# Р‘Р°Р·РѕРІС‹Р№ СѓСЂРѕРЅ
	current_damage = BASE_DAMAGE
	
	# РЎРєРѕСЂРѕСЃС‚СЊ Рё РїСЂС‹Р¶РѕРє
	base_speed = 180
	current_speed = 180
	max_speed = 180.0
	jump_velocity = -350
	
	
	super()

func _physics_process(delta):
	# РћР±РЅРѕРІР»СЏРµРј РєСѓР»РґР°СѓРЅ Р±Р»РѕРєР°
	if block_cooldown > 0:
		block_cooldown -= delta
		_update_block_cooldown_ui()
	
	super(delta)

func _input(event):
	# РћС‚РїСѓСЃРєР°РЅРёРµ РєРЅРѕРїРєРё E - РѕРїСѓСЃРєР°РµРј С‰РёС‚
	if event.is_action_released("special_ability") and is_blocking:
		stop_blocking()

# ===========================================
# Р РђРЎР§РЃРў РРўРћР“РћР’РћР™ Р‘Р РћРќР
# ===========================================

func recalculate_armor():
	"""РџРµСЂРµСЃС‡РёС‚С‹РІР°РµС‚ РёС‚РѕРіРѕРІСѓСЋ Р±СЂРѕРЅСЋ СЃ СѓС‡С‘С‚РѕРј Р’РЎР•РҐ РјРѕРґРёС„РёРєР°С‚РѕСЂРѕРІ"""
	var old_armor = armor
	
	# РС‚РѕРіРѕ = Р‘Р°Р·Р° + Р­РєРёРїРёСЂРѕРІРєР° + Р—РµР»СЊСЏ + Р‘Р»РѕРє
	armor = warrior_base_armor + equipment_armor_bonus + potion_armor_bonus + block_armor_bonus
	
	# РћР±РЅРѕРІР»СЏРµРј base_armor (РґР»СЏ СЃРѕРІРјРµСЃС‚РёРјРѕСЃС‚Рё СЃ СЂРѕРґРёС‚РµР»СЊСЃРєРёРј РєР»Р°СЃСЃРѕРј)
	# base_armor = Р±Р°Р·Р° + СЌРєРёРїРёСЂРѕРІРєР° (Р±РµР· Р·РµР»РёР№ Рё Р±Р»РѕРєР°)
	base_armor = warrior_base_armor + equipment_armor_bonus
	

func set_equipment_armor(bonus: int):
	"""РЈСЃС‚Р°РЅР°РІР»РёРІР°РµС‚ Р±РѕРЅСѓСЃ Р±СЂРѕРЅРё РѕС‚ СЌРєРёРїРёСЂРѕРІРєРё"""
	equipment_armor_bonus = bonus
	recalculate_armor()


func set_potion_armor(bonus: int):
	"""РЈСЃС‚Р°РЅР°РІР»РёРІР°РµС‚ Р±РѕРЅСѓСЃ Р±СЂРѕРЅРё РѕС‚ Р·РµР»РёР№"""
	potion_armor_bonus = bonus
	recalculate_armor()


func add_potion_armor(bonus: int):
	"""Р”РѕР±Р°РІР»СЏРµС‚ Р±РѕРЅСѓСЃ Р±СЂРѕРЅРё РѕС‚ Р·РµР»СЊСЏ"""
	potion_armor_bonus += bonus
	recalculate_armor()


func reset_potion_bonuses():
	"""РЎР±СЂР°СЃС‹РІР°РµС‚ Р±РѕРЅСѓСЃС‹ РѕС‚ Р·РµР»РёР№ (РїСЂРё СЃРјРµРЅРµ РєРѕРјРЅР°С‚С‹/СЃРјРµСЂС‚Рё)"""
	potion_armor_bonus = 0
	recalculate_armor()

# ===========================================
# РЎРџР•Р¦РРђР›Р¬РќРђРЇ РЎРџРћРЎРћР‘РќРћРЎРўР¬ (E) - Р‘Р›РћРљ Р©РРўРћРњ
# ===========================================

func use_special_ability():
	"""Р’РѕРёРЅ: Р‘Р»РѕРє С‰РёС‚РѕРј"""
	if is_blocking:
		return
	
	if block_cooldown > 0:
		return
	
	block()

func block():
	"""РџРѕРґРЅРёРјР°РµС‚ С‰РёС‚ - Р”РћР‘РђР’Р›РЇР•Рў Р±РѕРЅСѓСЃ Рє С‚РµРєСѓС‰РµР№ Р±СЂРѕРЅРµ"""
	if is_dead or is_attacking or is_casting or is_sliding:
		return
	
	
	is_blocking = true
	is_block_active = true
	
	# Р”РѕР±Р°РІР»СЏРµРј Р±РѕРЅСѓСЃ РѕС‚ Р±Р»РѕРєР°
	block_armor_bonus = BLOCK_ARMOR_BONUS_VALUE
	recalculate_armor()
	
	velocity.x = 0
	play_animation("shield_defence")
	

func stop_blocking():
	"""РћРїСѓСЃРєР°РµС‚ С‰РёС‚ - РЈР‘РР РђР•Рў С‚РѕР»СЊРєРѕ Р±РѕРЅСѓСЃ РѕС‚ Р±Р»РѕРєР°"""
	if not is_blocking:
		return
	
	
	is_blocking = false
	is_block_active = false
	
	# РЈР±РёСЂР°РµРј РўРћР›Р¬РљРћ Р±РѕРЅСѓСЃ РѕС‚ Р±Р»РѕРєР°
	block_armor_bonus = 0
	recalculate_armor()
	
	block_cooldown = BLOCK_COOLDOWN_TIME
	

# ===========================================
# РђРўРђРљРђ - РЈР РћРќ РќРђ 4-Рњ РљРђР”Р Р•
# ===========================================

var _attack_damage_dealt: bool = false

func attack():
	"""РђС‚Р°РєР° РІРѕРёРЅР° - СѓСЂРѕРЅ РЅР° 4-Рј РєР°РґСЂРµ"""
	if is_dead or is_blocking or is_casting or is_sliding or is_crouching or is_attacking:
		return
	
	is_attacking = true
	_attack_damage_dealt = false
	
	play_animation("attack")
	
	if animated_sprite and not animated_sprite.frame_changed.is_connected(_on_attack_frame):
		animated_sprite.frame_changed.connect(_on_attack_frame)
	
	if animated_sprite:
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout
	
	if animated_sprite and animated_sprite.frame_changed.is_connected(_on_attack_frame):
		animated_sprite.frame_changed.disconnect(_on_attack_frame)
	
	is_attacking = false
	handle_animations()

func _on_attack_frame():
	"""РЈСЂРѕРЅ РЅР° 4-Рј РєР°РґСЂРµ (РёРЅРґРµРєСЃ 3)"""
	if not is_attacking or _attack_damage_dealt:
		return
	
	if animated_sprite.frame == 3:
		_deal_damage_to_enemies()
		_attack_damage_dealt = true

func _deal_damage_to_enemies():
	"""РќР°РЅРѕСЃРёС‚ СѓСЂРѕРЅ РІСЂР°РіР°Рј"""
	if not animated_sprite:
		return
	
	var dir = -1 if animated_sprite.flip_h else 1
	var center = global_position + Vector2(40 * dir, 0)
	
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 55
	query.shape = shape
	query.transform = Transform2D(0, center)
	
	for result in space.intersect_shape(query):
		var body = result["collider"]
		if body != self and body.has_method("take_damage"):
			body.take_damage(current_damage, "physical")
			
			if Global and Global.has_method("add_damage_dealt"):
				Global.add_damage_dealt(current_damage)

# ===========================================
# РџРћР›РЈР§Р•РќРР• РЈР РћРќРђ
# ===========================================

func take_damage(amount: int, damage_type: String = "physical", source: String = "РќРµРёР·РІРµСЃС‚РЅРѕ"):
	"""РџРѕР»СѓС‡РµРЅРёРµ СѓСЂРѕРЅР° СЃ СѓС‡С‘С‚РѕРј Р±СЂРѕРЅРё"""
	if is_dead:
		return
	
	last_damage_source = source
	
	
	var final_damage: int
	if damage_type == "magical":
		final_damage = amount - int(armor * 0.5)
	else:
		final_damage = amount - armor
	
	final_damage = max(1, final_damage)
	
	
	current_health -= final_damage
	current_health = max(0, current_health)
	
	
	if Global and Global.has_method("add_damage_taken"):
		Global.add_damage_taken(final_damage)
	
	health_changed.emit(current_health)
	_show_damage_effect()
	
	if current_health <= 0:
		die()

func _show_damage_effect():
	"""РљСЂР°СЃРЅР°СЏ РІСЃРїС‹С€РєР° РїСЂРё РїРѕР»СѓС‡РµРЅРёРё СѓСЂРѕРЅР°"""
	if not animated_sprite:
		return
	
	var original = animated_sprite.modulate
	animated_sprite.modulate = Color(2.0, 0.5, 0.5, 1.0)
	
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", original, 0.2)

# ===========================================
# UI
# ===========================================

func _update_block_cooldown_ui():
	"""РћР±РЅРѕРІР»СЏРµС‚ UI РєСѓР»РґР°СѓРЅР°"""
	if Global and Global.game_ui and Global.game_ui.has_method("update_ability_cooldown"):
		var percent = 1.0 - (block_cooldown / BLOCK_COOLDOWN_TIME)
		Global.game_ui.update_ability_cooldown("block", percent)

# ===========================================
# РђР РўР•Р¤РђРљРўР«
# ===========================================

func apply_artifacts():
	"""РџСЂРёРјРµРЅСЏРµС‚ Р°СЂС‚РµС„Р°РєС‚С‹"""
	super.apply_artifacts()
