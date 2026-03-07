extends Node
class_name Damageable

# ===========================================
# DAMAGEABLE - РљРћРњРџРћРќР•РќРў РџРћР›РЈР§Р•РќРРЇ РЈР РћРќРђ
# ===========================================
# РџСѓС‚СЊ: res://scripts/components/Damageable.gd
#
# Р”РѕР±Р°РІР»СЏРµС‚СЃСЏ РєР°Рє РґРѕС‡РµСЂРЅРёР№ СѓР·РµР» Рє Р»СЋР±РѕРјСѓ РѕР±СЉРµРєС‚Сѓ,
# РєРѕС‚РѕСЂС‹Р№ РјРѕР¶РµС‚ РїРѕР»СѓС‡Р°С‚СЊ СѓСЂРѕРЅ.

signal damage_taken(amount: int, type: String, source: String)
signal healed(amount: int)
signal died(killer: String)
signal health_changed(current: int, maximum: int)

# РЎСЃС‹Р»РєР° РЅР° РІР»Р°РґРµР»СЊС†Р°
var owner_node: Node = null

# РҐР°СЂР°РєС‚РµСЂРёСЃС‚РёРєРё
@export var max_health: int = 100
@export var current_health: int = 100
@export var armor: int = 0
@export var is_invulnerable: bool = false

# РЎРѕРїСЂРѕС‚РёРІР»РµРЅРёСЏ (0.0 - 1.0, РіРґРµ 1.0 = РёРјРјСѓРЅРёС‚РµС‚)
@export var resistance_physical: float = 0.0
@export var resistance_fire: float = 0.0
@export var resistance_poison: float = 0.0
@export var resistance_frost: float = 0.0
@export var resistance_magic: float = 0.0

# РќРµСѓСЏР·РІРёРјРѕСЃС‚СЊ РїРѕСЃР»Рµ СѓСЂРѕРЅР°
@export var invulnerability_time: float = 0.2
var invulnerability_timer: float = 0.0

# Р¤Р»Р°РіРё
var is_dead: bool = false


func _ready():
	owner_node = get_parent()
	current_health = max_health


func _process(delta):
	if invulnerability_timer > 0:
		invulnerability_timer -= delta


# ===========================================
# РџРћР›РЈР§Р•РќРР• РЈР РћРќРђ
# ===========================================

func take_damage(amount: int, damage_type: String = "physical", source: String = "Unknown") -> int:
	"""
	РџРѕР»СѓС‡Р°РµС‚ СѓСЂРѕРЅ. Р’РѕР·РІСЂР°С‰Р°РµС‚ С„Р°РєС‚РёС‡РµСЃРєРё РЅР°РЅРµСЃС‘РЅРЅС‹Р№ СѓСЂРѕРЅ.
	
	damage_type: physical, fire, poison, frost, magic, true (С‡РёСЃС‚С‹Р№)
	"""
	if is_dead or is_invulnerable:
		return 0
	
	if invulnerability_timer > 0:
		return 0
	
	# Р Р°СЃСЃС‡РёС‚С‹РІР°РµРј С„Р°РєС‚РёС‡РµСЃРєРёР№ СѓСЂРѕРЅ
	var final_damage = _calculate_damage(amount, damage_type)
	
	if final_damage <= 0:
		return 0
	
	# РџСЂРёРјРµРЅСЏРµРј СѓСЂРѕРЅ
	current_health = max(0, current_health - final_damage)
	
	# Р—Р°РїСѓСЃРєР°РµРј РЅРµСѓСЏР·РІРёРјРѕСЃС‚СЊ
	if invulnerability_time > 0:
		invulnerability_timer = invulnerability_time
	
	# РЎРёРіРЅР°Р»С‹
	damage_taken.emit(final_damage, damage_type, source)
	health_changed.emit(current_health, max_health)
	
	# РЎС‚Р°С‚РёСЃС‚РёРєР°
	if Global and Global.has_method("add_damage_taken"):
		Global.add_damage_taken(final_damage)
	
	print("рџ’” %s РїРѕР»СѓС‡РёР» %d СѓСЂРѕРЅР° (%s) РѕС‚ %s [HP: %d/%d]" % [
		owner_node.name if owner_node else "???",
		final_damage,
		damage_type,
		source,
		current_health,
		max_health
	])
	
	# РџСЂРѕРІРµСЂРєР° СЃРјРµСЂС‚Рё
	if current_health <= 0:
		_die(source)
	
	return final_damage


func _calculate_damage(base_damage: int, damage_type: String) -> int:
	"""Р Р°СЃСЃС‡РёС‚С‹РІР°РµС‚ СѓСЂРѕРЅ СЃ СѓС‡С‘С‚РѕРј Р±СЂРѕРЅРё Рё СЃРѕРїСЂРѕС‚РёРІР»РµРЅРёР№"""
	var damage = float(base_damage)
	
	# РџСЂРёРјРµРЅСЏРµРј СЃРѕРїСЂРѕС‚РёРІР»РµРЅРёРµ РїРѕ С‚РёРїСѓ
	var resistance = 0.0
	match damage_type:
		"physical":
			resistance = resistance_physical
			# Р‘СЂРѕРЅСЏ СЃРЅРёР¶Р°РµС‚ С„РёР·. СѓСЂРѕРЅ
			damage = max(1, damage - armor * 0.5)
		"fire":
			resistance = resistance_fire
		"poison":
			resistance = resistance_poison
		"frost":
			resistance = resistance_frost
		"magic":
			resistance = resistance_magic
		"true", "effect":
			# Р§РёСЃС‚С‹Р№ СѓСЂРѕРЅ РёРіРЅРѕСЂРёСЂСѓРµС‚ РІСЃС‘
			resistance = 0.0
	
	# РџСЂРёРјРµРЅСЏРµРј СЃРѕРїСЂРѕС‚РёРІР»РµРЅРёРµ
	damage *= (1.0 - resistance)
	
	return max(0, int(damage))


# ===========================================
# РЎРњР•Р РўР¬
# ===========================================

func _die(killer: String):
	if is_dead:
		return
	
	is_dead = true
	print("рџ’Ђ %s РїРѕРіРёР± РѕС‚ %s" % [owner_node.name if owner_node else "???", killer])
	
	died.emit(killer)
	
	# РЈРІРµРґРѕРјР»СЏРµРј РІР»Р°РґРµР»СЊС†Р°
	if owner_node and owner_node.has_method("_on_death"):
		owner_node._on_death(killer)
	
	# Если это игрок - сохраняем причину смерти в текущую статистику забега
	if owner_node and owner_node.is_in_group("player"):
		if Global and Global.has_method("set_death_reason"):
			Global.set_death_reason(killer)


# ===========================================
# Р›Р•Р§Р•РќРР•
# ===========================================

func heal(amount: int) -> int:
	"""Р›РµС‡РёС‚. Р’РѕР·РІСЂР°С‰Р°РµС‚ С„Р°РєС‚РёС‡РµСЃРєРё РІРѕСЃСЃС‚Р°РЅРѕРІР»РµРЅРЅРѕРµ HP."""
	if is_dead:
		return 0
	
	var old_health = current_health
	current_health = min(max_health, current_health + amount)
	var healed_amount = current_health - old_health
	
	if healed_amount > 0:
		healed.emit(healed_amount)
		health_changed.emit(current_health, max_health)
		print("рџ’љ %s +%d HP [%d/%d]" % [
			owner_node.name if owner_node else "???",
			healed_amount,
			current_health,
			max_health
		])
	
	return healed_amount


func heal_percent(percent: float) -> int:
	"""Р›РµС‡РёС‚ РЅР° РїСЂРѕС†РµРЅС‚ РѕС‚ РјР°РєСЃ. HP"""
	var amount = int(max_health * percent / 100.0)
	return heal(amount)


func heal_to_full():
	"""РџРѕР»РЅРѕРµ РІРѕСЃСЃС‚Р°РЅРѕРІР»РµРЅРёРµ"""
	heal(max_health)


# ===========================================
# Р’РћРЎРљР Р•РЁР•РќРР•
# ===========================================

func revive(health_percent: float = 50.0):
	"""Р’РѕСЃРєСЂРµС€Р°РµС‚ СЃ СѓРєР°Р·Р°РЅРЅС‹Рј % HP"""
	if not is_dead:
		return
	
	is_dead = false
	current_health = int(max_health * health_percent / 100.0)
	health_changed.emit(current_health, max_health)
	
	print("вњЁ %s РІРѕСЃРєСЂРµСЃ! [%d/%d HP]" % [
		owner_node.name if owner_node else "???",
		current_health,
		max_health
	])


# ===========================================
# РњРћР”РР¤РРљРђРўРћР Р«
# ===========================================

func add_max_health(amount: int, heal_added: bool = true):
	"""РЈРІРµР»РёС‡РёРІР°РµС‚ РјР°РєСЃРёРјР°Р»СЊРЅРѕРµ HP"""
	max_health += amount
	if heal_added:
		current_health += amount
	health_changed.emit(current_health, max_health)


func add_armor(amount: int):
	"""Р”РѕР±Р°РІР»СЏРµС‚ Р±СЂРѕРЅСЋ"""
	armor += amount


func set_invulnerable(value: bool):
	"""РЈСЃС‚Р°РЅР°РІР»РёРІР°РµС‚ РЅРµСѓСЏР·РІРёРјРѕСЃС‚СЊ"""
	is_invulnerable = value


# ===========================================
# РџР РћР’Р•Р РљР
# ===========================================

func get_health_percent() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health) * 100.0


func is_full_health() -> bool:
	return current_health >= max_health


func is_low_health(threshold: float = 30.0) -> bool:
	return get_health_percent() <= threshold
