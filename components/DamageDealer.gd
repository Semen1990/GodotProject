extends Node
class_name DamageDealer

# ===========================================
# DAMAGE DEALER - РљРћРњРџРћРќР•РќРў РќРђРќР•РЎР•РќРРЇ РЈР РћРќРђ
# ===========================================
# РџСѓС‚СЊ: res://scripts/components/DamageDealer.gd
#
# РћС‚РІРµС‡Р°РµС‚ Р·Р° СЂР°СЃС‡С‘С‚ Рё РЅР°РЅРµСЃРµРЅРёРµ СѓСЂРѕРЅР°.

signal damage_dealt(target: Node, amount: int, was_crit: bool)

# РЎСЃС‹Р»РєР° РЅР° РІР»Р°РґРµР»СЊС†Р°
var owner_node: Node = null

# Р‘Р°Р·РѕРІС‹Рµ С…Р°СЂР°РєС‚РµСЂРёСЃС‚РёРєРё
@export var base_damage: int = 10
@export var damage_type: String = "physical"  # physical, fire, poison, frost, magic

# РњРѕРґРёС„РёРєР°С‚РѕСЂС‹
var bonus_damage: int = 0
var damage_multiplier: float = 1.0

# РЎСЃС‹Р»РєРё РЅР° РєРѕРјРїРѕРЅРµРЅС‚С‹
var crit_component: Node = null  # CriticalHit
var status_effects: Node = null   # StatusEffects (РґР»СЏ Р±Р°С„С„РѕРІ)


func _ready():
	owner_node = get_parent()
	
	# РС‰РµРј РєРѕРјРїРѕРЅРµРЅС‚С‹
	crit_component = owner_node.get_node_or_null("CriticalHit")
	status_effects = owner_node.get_node_or_null("StatusEffects")


# ===========================================
# Р РђРЎР§РЃРў РЈР РћРќРђ
# ===========================================

func get_total_damage() -> int:
	"""Р’РѕР·РІСЂР°С‰Р°РµС‚ С‚РµРєСѓС‰РёР№ СѓСЂРѕРЅ СЃ СѓС‡С‘С‚РѕРј РІСЃРµС… РјРѕРґРёС„РёРєР°С‚РѕСЂРѕРІ"""
	var damage = base_damage + bonus_damage
	
	# РњРѕРґРёС„РёРєР°С‚РѕСЂ РѕС‚ Р±Р°С„С„РѕРІ
	if status_effects and "damage_modifier" in status_effects:
		damage = int(damage * status_effects.damage_modifier)
	
	# РћР±С‰РёР№ РјРЅРѕР¶РёС‚РµР»СЊ
	damage = int(damage * damage_multiplier)
	
	return max(1, damage)


func calculate_hit(target: Node = null) -> Dictionary:
	"""
	Р Р°СЃСЃС‡РёС‚С‹РІР°РµС‚ СѓРґР°СЂ. Р’РѕР·РІСЂР°С‰Р°РµС‚ СЃР»РѕРІР°СЂСЊ:
	{
		"damage": int,
		"is_crit": bool,
		"is_dodged": bool,
		"type": String
	}
	"""
	var result = {
		"damage": get_total_damage(),
		"is_crit": false,
		"is_dodged": false,
		"type": damage_type
	}
	
	# РџСЂРѕРІРµСЂРєР° СѓРєР»РѕРЅРµРЅРёСЏ С†РµР»Рё
	if target:
		var dodge = target.get_node_or_null("Dodge")
		if dodge and dodge.try_dodge():
			result["is_dodged"] = true
			result["damage"] = 0
			return result
	
	# РџСЂРѕРІРµСЂРєР° РєСЂРёС‚Р°
	if crit_component and crit_component.try_crit():
		result["is_crit"] = true
		result["damage"] = crit_component.apply_crit_damage(result["damage"])
	
	return result


# ===========================================
# РќРђРќР•РЎР•РќРР• РЈР РћРќРђ
# ===========================================

func deal_damage_to(target: Node, override_damage: int = -1) -> int:
	"""
	РќР°РЅРѕСЃРёС‚ СѓСЂРѕРЅ С†РµР»Рё. Р’РѕР·РІСЂР°С‰Р°РµС‚ С„Р°РєС‚РёС‡РµСЃРєРёР№ СѓСЂРѕРЅ.
	"""
	if not target:
		return 0
	
	# Р Р°СЃСЃС‡РёС‚С‹РІР°РµРј СѓРґР°СЂ
	var hit = calculate_hit(target)
	
	if hit["is_dodged"]:
		print("рџ’Ё %s СѓРєР»РѕРЅРёР»СЃСЏ!" % target.name)
		return 0
	
	# РџРµСЂРµРѕРїСЂРµРґРµР»С‘РЅРЅС‹Р№ СѓСЂРѕРЅ (РґР»СЏ СЃРїРѕСЃРѕР±РЅРѕСЃС‚РµР№)
	var damage = override_damage if override_damage >= 0 else hit["damage"]
	
	# РС‰РµРј Damageable Сѓ С†РµР»Рё
	var damageable = target.get_node_or_null("Damageable")
	var actual_damage = 0
	
	if damageable:
		actual_damage = damageable.take_damage(damage, hit["type"], owner_node.name if owner_node else "Unknown")
	elif target.has_method("take_damage"):
		target.take_damage(damage, hit["type"], owner_node.name if owner_node else "Unknown")
		actual_damage = damage
	
	# РЎРёРіРЅР°Р» Рё СЃС‚Р°С‚РёСЃС‚РёРєР°
	if actual_damage > 0:
		damage_dealt.emit(target, actual_damage, hit["is_crit"])
		
		if Global and Global.has_method("add_damage_dealt"):
			Global.add_damage_dealt(actual_damage)
		
		# Р’РёР·СѓР°Р»СЊРЅР°СЏ РёРЅРґРёРєР°С†РёСЏ РєСЂРёС‚Р°
		if hit["is_crit"]:
			_show_crit_effect(target)
	
	return actual_damage


func deal_area_damage(targets: Array, damage_percent: float = 100.0) -> int:
	"""РќР°РЅРѕСЃРёС‚ СѓСЂРѕРЅ РЅРµСЃРєРѕР»СЊРєРёРј С†РµР»СЏРј"""
	var total_damage = 0
	var damage = int(get_total_damage() * damage_percent / 100.0)
	
	for target in targets:
		total_damage += deal_damage_to(target, damage)
	
	return total_damage


# ===========================================
# РњРћР”РР¤РРљРђРўРћР Р«
# ===========================================

func add_bonus_damage(amount: int):
	bonus_damage += amount


func set_damage_multiplier(mult: float):
	damage_multiplier = mult


func reset_modifiers():
	bonus_damage = 0
	damage_multiplier = 1.0


# ===========================================
# Р­Р¤Р¤Р•РљРўР« РџР Р РЈР”РђР Р•
# ===========================================

func apply_on_hit_effect(target: Node, effect_type: String, value: float = 0.0):
	"""РџСЂРёРјРµРЅСЏРµС‚ СЌС„С„РµРєС‚ РїСЂРё СѓРґР°СЂРµ"""
	var target_status = target.get_node_or_null("StatusEffects")
	if not target_status:
		return
	
	match effect_type:
		"burn":
			target_status.apply_burn(value if value > 0 else 3.0)
		"poison":
			target_status.apply_poison(value if value > 0 else 5.0)
		"bleed":
			target_status.apply_bleed(value if value > 0 else 2.0)
		"frost":
			target_status.apply_frost(value if value > 0 else 30.0)
		"stun":
			target_status.apply_stun(value if value > 0 else 2.0)


# ===========================================
# Р’РР—РЈРђР›Р¬РќР«Р• Р­Р¤Р¤Р•РљРўР«
# ===========================================

func _show_crit_effect(target: Node):
	"""РџРѕРєР°Р·С‹РІР°РµС‚ СЌС„С„РµРєС‚ РєСЂРёС‚РёС‡РµСЃРєРѕРіРѕ СѓРґР°СЂР°"""
	# РњРѕР¶РЅРѕ РґРѕР±Р°РІРёС‚СЊ РїР°СЂС‚РёРєР»С‹, РІСЃРїР»С‹РІР°СЋС‰РёР№ С‚РµРєСЃС‚ Рё С‚.Рґ.
	print("рџ’Ґ РљР РРў!")
