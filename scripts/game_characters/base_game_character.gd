# base_game_character.gd
extends CharacterBody2D

# ===========================================
# Р‘РђР—РћР’Р«Р™ РљР›РђРЎРЎ РџР•Р РЎРћРќРђР–Рђ (РЈР›РЈР§РЁР•РќРќРђРЇ Р’Р•Р РЎРРЇ)
# ===========================================
# Р­С‚РѕС‚ РєР»Р°СЃСЃ СЃРѕРґРµСЂР¶РёС‚ Р’РЎР® РѕР±С‰СѓСЋ Р»РѕРіРёРєСѓ РґР»СЏ РІСЃРµС… РїРµСЂСЃРѕРЅР°Р¶РµР№.
# Р”РѕС‡РµСЂРЅРёРµ РєР»Р°СЃСЃС‹ (warrior, paladin, rogue, berserk) РЅР°СЃР»РµРґСѓСЋС‚ РѕС‚ РЅРµРіРѕ
# Рё С‚РѕР»СЊРєРѕ РџР•Р Р•РћРџР Р•Р”Р•Р›РЇР®Рў СЃРїРµС†РёС„РёС‡РЅСѓСЋ Р»РѕРіРёРєСѓ.

# --- РЎРР“РќРђР›Р« ---
# РСЃРїРѕР»СЊР·СѓСЋС‚СЃСЏ РґР»СЏ СЃРІСЏР·Рё СЃ UI Рё РґСЂСѓРіРёРјРё СЃРёСЃС‚РµРјР°РјРё
signal health_changed(new_health: int)
signal mana_changed(new_mana: int)
signal armor_changed(new_armor: int)
signal died()
signal revived()

# --- Р‘РђР—РћР’Р«Р• РҐРђР РђРљРўР•Р РРЎРўРРљР ---
# РџРµСЂРµРѕРїСЂРµРґРµР»СЏСЋС‚СЃСЏ РІ РґРѕС‡РµСЂРЅРёС… РєР»Р°СЃСЃР°С… РІ _ready()
var character_name: String = "BaseCharacter"
var max_health: int = 100
var current_health: int = 100
var max_mana: int = 100
var current_mana: int = 100
var armor: int = 0
var current_damage: int = 2  # РўРµРєСѓС‰РёР№ СѓСЂРѕРЅ (Р±Р°Р·Р° + Р±РѕРЅСѓСЃС‹ РѕС‚ СЌРєРёРїРёСЂРѕРІРєРё)
var base_speed: int = 200
var current_speed: int = 200

# --- РЎРћРЎРўРћРЇРќРРЇ РџР•Р РЎРћРќРђР–Рђ ---
# РСЃРїРѕР»СЊР·СѓСЋС‚СЃСЏ РґР»СЏ РєРѕРЅС‚СЂРѕР»СЏ РґРµР№СЃС‚РІРёР№ Рё Р°РЅРёРјР°С†РёР№
var is_dead: bool = false
var is_attacking: bool = false
var is_moving: bool = false
var is_blocking: bool = false
var is_sliding: bool = false
var is_casting: bool = false
var is_crouching: bool = false
var is_hurt: bool = false
var is_invincible: bool = false  # РќРµСѓСЏР·РІРёРјРѕСЃС‚СЊ РїРѕСЃР»Рµ РІРѕР·СЂРѕР¶РґРµРЅРёСЏ
var is_inventory_open: bool = false  # Р‘Р»РѕРєРёСЂРѕРІРєР° РїСЂРё РѕС‚РєСЂС‹С‚РѕРј РёРЅРІРµРЅС‚Р°СЂРµ

# --- РЎРРЎРўР•РњРђ РђРўРђРљР ---
var attack_combo: int = 0
var last_attack_time: float = 0.0
var attack_combo_timeout: float = 1.0

# --- Р¤РР—РРљРђ ---
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")
var max_speed: float = 300.0
var acceleration: float = 1500.0
var friction: float = 1200.0
var jump_velocity: float = -400.0

# --- РЎРРЎРўР•РњРђ Р”Р’РћР™РќРћР“Рћ РџР Р«Р–РљРђ ---
# РђРєС‚РёРІРёСЂСѓРµС‚СЃСЏ Р°СЂС‚РµС„Р°РєС‚Р°РјРё (РЅР°РїСЂРёРјРµСЂ, "РљСЂС‹Р»СЊСЏ Р“РµСЂРјРµСЃР°")
var enable_double_jump: bool = false
var has_double_jumped: bool = false
var can_double_jump: bool = false
var coyote_time: float = 0.1  # Р’СЂРµРјСЏ РїРѕСЃР»Рµ РїР°РґРµРЅРёСЏ СЃ РїР»Р°С‚С„РѕСЂРјС‹, РєРѕРіРґР° РµС‰Рµ РјРѕР¶РЅРѕ РїСЂС‹РіРЅСѓС‚СЊ
var coyote_timer: float = 0.0

# --- Р РђР—РњР•Р Р« РљРћР›Р›РР—РР Р”Р›РЇ РџР РРЎР•Р”РђРќРРЇ ---
var standing_collision_height: float = 0.0
var crouching_collision_height: float = 0.0
var original_collision_position: Vector2 = Vector2.ZERO

# --- РЎРўРђРўРРЎРўРРљРђ ---
var last_damage_source: String = "РќРµРёР·РІРµСЃС‚РЅРѕ"

# --- РЎРЎР«Р›РљР РќРђ РќРћР”Р« ---
var animated_sprite: AnimatedSprite2D
var collision_shape: CollisionShape2D
var player_controller: Node

# --- Р’РР—РЈРђР› ---
var original_scale: Vector2 = Vector2.ONE

# --- РњРђРџРџРРќР“ РђР›Р¬РўР•Р РќРђРўРР’РќР«РҐ РќРђР—Р’РђРќРР™ РђРќРРњРђР¦РР™ ---
# Р Р°Р·РЅС‹Рµ СЃРїСЂР°Р№С‚С€РёС‚С‹ РјРѕРіСѓС‚ РёРјРµС‚СЊ СЂР°Р·РЅС‹Рµ РЅР°Р·РІР°РЅРёСЏ Р°РЅРёРјР°С†РёР№
const ANIMATION_NAME_MAPPING: Dictionary = {
	"hurt": ["hurt", "taking damage", "hit", "damage"],
	"shield_defence": ["shield_defence", "shield defence", "block", "defend"],
	"crouch": ["crouch", "duck", "crouching"],
	"sliding": ["sliding", "slide", "roll"],
	"spellcast": ["spellcast", "cast", "magic", "spell"]
}


func _ready():
	if not is_in_group("player"):
		add_to_group("player")
	print("вњ… ", character_name, " РёРЅРёС†РёР°Р»РёР·РёСЂРѕРІР°РЅ")
	
	# --- Р‘РµР·РѕРїР°СЃРЅРѕРµ РїРѕР»СѓС‡РµРЅРёРµ РЅРѕРґРѕРІ ---
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	collision_shape = get_node_or_null("CollisionShape2D") 
	player_controller = get_node_or_null("PlayerController")
	
	# РЎРѕС…СЂР°РЅСЏРµРј РѕСЂРёРіРёРЅР°Р»СЊРЅС‹Р№ РјР°СЃС€С‚Р°Р± СЃРїСЂР°Р№С‚Р°
	if animated_sprite:
		original_scale = animated_sprite.scale
	
	# --- РќР°СЃС‚СЂРѕР№РєР° РєРѕР»Р»РёР·РёРё РґР»СЏ РїСЂРёСЃРµРґР°РЅРёСЏ ---
	if collision_shape and collision_shape.shape:
		original_collision_position = collision_shape.position
		if collision_shape.shape is CapsuleShape2D:
			standing_collision_height = collision_shape.shape.height
			crouching_collision_height = standing_collision_height * 0.5
		elif collision_shape.shape is RectangleShape2D:
			standing_collision_height = collision_shape.shape.size.y
			crouching_collision_height = standing_collision_height * 0.5
	
	# --- РќР°СЃС‚СЂРѕР№РєР° РєРѕРЅС‚СЂРѕР»Р»РµСЂР° ---
	if player_controller:
		player_controller.character = self
	else:
		print("вљ пёЏ PlayerController РЅРµ РЅР°Р№РґРµРЅ РґР»СЏ: ", character_name)
	
	# --- РџСЂРёРјРµРЅРµРЅРёРµ Р°СЂС‚РµС„Р°РєС‚РѕРІ ---
	call_deferred("apply_artifacts")
	
	# --- Р—Р°РїСѓСЃРє Р°РЅРёРјР°С†РёРё РїРѕРєРѕСЏ ---
	if animated_sprite:
		play_animation("idle")


func apply_artifacts():
	"""РџСЂРёРјРµРЅСЏРµРј РІСЃРµ СЃРѕР±СЂР°РЅРЅС‹Рµ Р°СЂС‚РµС„Р°РєС‚С‹ Рє РїРµСЂСЃРѕРЅР°Р¶Сѓ"""
	if Global:
		Global.apply_all_artifacts_to_player()
		
		# РџСЂРѕРІРµСЂСЏРµРј РЅР°Р»РёС‡РёРµ СЃРїРѕСЃРѕР±РЅРѕСЃС‚Рё РґРІРѕР№РЅРѕРіРѕ РїСЂС‹Р¶РєР°
		if Global.has_ability("double_jump"):
			enable_double_jump = true
			print("рџ¦ Р”РІРѕР№РЅРѕР№ РїСЂС‹Р¶РѕРє РґРѕСЃС‚СѓРїРµРЅ РґР»СЏ ", character_name)
		else:
			enable_double_jump = false


func _physics_process(delta: float):
	if is_dead:
		return
	
	# --- Р­С„С„РµРєС‚ РЅРµСѓСЏР·РІРёРјРѕСЃС‚Рё (РјРёРіР°РЅРёРµ) ---
	if is_invincible and animated_sprite:
		animated_sprite.modulate.a = 0.7 + sin(Time.get_ticks_msec() * 0.01) * 0.3
	
	# --- Р“СЂР°РІРёС‚Р°С†РёСЏ Рё coyote time ---
	if not is_on_floor():
		velocity.y += gravity * delta
		if coyote_timer > 0:
			coyote_timer -= delta
	else:
		# РЎР±СЂРѕСЃ РґРІРѕР№РЅРѕРіРѕ РїСЂС‹Р¶РєР° РїСЂРё РєР°СЃР°РЅРёРё Р·РµРјР»Рё
		has_double_jumped = false
		can_double_jump = false
		coyote_timer = coyote_time
	
	# --- РћР±СЂР°Р±РѕС‚РєР° РґРІРёР¶РµРЅРёСЏ Рё Р°РЅРёРјР°С†РёР№ ---
	handle_movement(delta)
	handle_animations()
	fix_sprite_scale()
	
	move_and_slide()


func fix_sprite_scale():
	"""Р¤РёРєСЃРёСЂСѓРµС‚ РјР°СЃС€С‚Р°Р± СЃРїСЂР°Р№С‚Р° (РїСЂРµРґРѕС‚РІСЂР°С‰Р°РµС‚ Р±Р°РіРё СЃ flip_h)"""
	if animated_sprite:
		var current_sign = sign(animated_sprite.scale.x)
		if current_sign == 0:
			current_sign = 1
		animated_sprite.scale = Vector2(
			abs(original_scale.x) * current_sign,
			original_scale.y
		)


# ===========================================
# РЎРРЎРўР•РњРђ Р”Р’РР–Р•РќРРЇ
# ===========================================

func handle_movement(delta: float):
	# --- Р‘Р»РѕРєРёСЂРѕРІРєР° РїСЂРё РѕС‚РєСЂС‹С‚РѕРј РёРЅРІРµРЅС‚Р°СЂРµ ---
	# РРіСЂРѕРє РЅРµ РјРѕР¶РµС‚ РґРІРёРіР°С‚СЊСЃСЏ Рё РёСЃРїРѕР»СЊР·РѕРІР°С‚СЊ СЃРїРѕСЃРѕР±РЅРѕСЃС‚Рё,
	# РЅРѕ РІСЂР°РіРё РїСЂРѕРґРѕР»Р¶Р°СЋС‚ РґРµР№СЃС‚РІРѕРІР°С‚СЊ Рё РјРѕРіСѓС‚ РЅР°РЅРѕСЃРёС‚СЊ СѓСЂРѕРЅ
	if is_inventory_open:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		return
	
	# --- РџРѕР»СѓС‡РµРЅРёРµ РІРІРѕРґР° ---
	var direction = Input.get_axis("move_left", "move_right")
	var is_jumping = Input.is_action_just_pressed("jump")
	var is_crouch_pressed = Input.is_action_pressed("crouch")
	var is_special = Input.is_action_just_pressed("special_ability")
	
	# --- Р‘Р»РѕРєРёСЂРѕРІРєР° РґРІРёР¶РµРЅРёСЏ РІРѕ РІСЂРµРјСЏ СЃРїРµС†РёР°Р»СЊРЅС‹С… РґРµР№СЃС‚РІРёР№ ---
	if is_attacking or is_casting or is_sliding:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		return
	
	# --- РџР РРЎР•Р”РђРќРР• ---
	if is_crouch_pressed and is_on_floor() and not is_blocking:
		if not is_crouching:
			start_crouch()
	elif is_crouching:
		stop_crouch()
	
	# --- РЎРџР•Р¦РРђР›Р¬РќРђРЇ РЎРџРћРЎРћР‘РќРћРЎРўР¬ (E) ---
	if is_special and not is_crouching:
		use_special_ability()
	
	# --- Р”Р’РР–Р•РќРР• ---
	if not is_blocking and not is_crouching:
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * current_speed, acceleration * delta)
			# РџРѕРІРѕСЂРѕС‚ СЃРїСЂР°Р№С‚Р°
			if animated_sprite:
				animated_sprite.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
	elif is_crouching:
		# РџСЂРё РїСЂРёСЃРµРґР°РЅРёРё - Р·Р°РјРµРґР»РµРЅРёРµ РґРѕ РѕСЃС‚Р°РЅРѕРІРєРё
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	else:
		# РџСЂРё Р±Р»РѕРєРµ - Р±С‹СЃС‚СЂР°СЏ РѕСЃС‚Р°РЅРѕРІРєР°
		velocity.x = move_toward(velocity.x, 0, friction * delta * 2)
	
	# --- РџР Р«Р–РљР ---
	if is_jumping and not is_blocking and not is_crouching:
		if is_on_floor() or coyote_timer > 0:
			# РћР±С‹С‡РЅС‹Р№ РїСЂС‹Р¶РѕРє
			velocity.y = jump_velocity
			can_double_jump = enable_double_jump
			has_double_jumped = false
			coyote_timer = 0
			print("рџ¦ ", character_name, " РїСЂС‹РіР°РµС‚!")
		elif enable_double_jump and can_double_jump and not has_double_jumped:
			# Р”РІРѕР№РЅРѕР№ РїСЂС‹Р¶РѕРє (СЃР»Р°Р±РµРµ РѕР±С‹С‡РЅРѕРіРѕ)
			velocity.y = jump_velocity * 0.8
			has_double_jumped = true
			can_double_jump = false
			print("рџ¦вњЁ ", character_name, " РёСЃРїРѕР»СЊР·СѓРµС‚ РґРІРѕР№РЅРѕР№ РїСЂС‹Р¶РѕРє!")
			_show_double_jump_effect()


# ===========================================
# РџР РРЎР•Р”РђРќРР•
# ===========================================

func start_crouch():
	"""РќР°С‡Р°С‚СЊ РїСЂРёСЃРµРґР°РЅРёРµ"""
	if not is_on_floor() or is_crouching:
		return
	
	is_crouching = true
	print("рџ¦† РџСЂРёСЃРµРґР°РЅРёРµ!")


func stop_crouch():
	"""Р—Р°РєРѕРЅС‡РёС‚СЊ РїСЂРёСЃРµРґР°РЅРёРµ"""
	if not is_crouching:
		return
	
	is_crouching = false
	print("рџ¦† Р’СЃС‚Р°Р»!")
	
	# Р’РѕСЃСЃС‚Р°РЅР°РІР»РёРІР°РµРј РєРѕР»Р»РёР·РёСЋ
	if collision_shape and collision_shape.shape:
		if collision_shape.shape is CapsuleShape2D:
			collision_shape.shape.height = standing_collision_height
			collision_shape.position.y = original_collision_position.y
		elif collision_shape.shape is RectangleShape2D:
			collision_shape.shape.size.y = standing_collision_height
			collision_shape.position.y = original_collision_position.y


# ===========================================
# РЎРџР•Р¦РРђР›Р¬РќРђРЇ РЎРџРћРЎРћР‘РќРћРЎРўР¬
# ===========================================

func use_special_ability():
	"""
	Р’РёСЂС‚СѓР°Р»СЊРЅР°СЏ С„СѓРЅРєС†РёСЏ - РћР‘РЇР—РђРўР•Р›Р¬РќРћ РїРµСЂРµРѕРїСЂРµРґРµР»СЏРµС‚СЃСЏ РІ РґРѕС‡РµСЂРЅРёС… РєР»Р°СЃСЃР°С…!
	
	- Р’РѕРёРЅ: block() - Р±Р»РѕРє С‰РёС‚РѕРј
	- РџР°Р»Р°РґРёРЅ: heal() - РёСЃС†РµР»РµРЅРёРµ
	- Р Р°Р·Р±РѕР№РЅРёРє: slide() - РїРѕРґРєР°С‚
	- Р‘РµСЂСЃРµСЂРє: rage() - СЏСЂРѕСЃС‚СЊ (РµСЃР»Рё СЂРµР°Р»РёР·РѕРІР°РЅРѕ)
	"""
	print("вљЎ ", character_name, " РёСЃРїРѕР»СЊР·СѓРµС‚ СЃРїРѕСЃРѕР±РЅРѕСЃС‚СЊ (Р±Р°Р·РѕРІР°СЏ - РЅРµ РїРµСЂРµРѕРїСЂРµРґРµР»РµРЅР°)")


# ===========================================
# Р’РР—РЈРђР›Р¬РќР«Р• Р­Р¤Р¤Р•РљРўР«
# ===========================================

func _show_double_jump_effect():
	"""Р’РёР·СѓР°Р»СЊРЅС‹Р№ СЌС„С„РµРєС‚ РїСЂРё РґРІРѕР№РЅРѕРј РїСЂС‹Р¶РєРµ"""
	if not animated_sprite:
		return
	
	var original_modulate = animated_sprite.modulate
	animated_sprite.modulate = Color(1.5, 1.5, 2.0, 1.0)
	
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", original_modulate, 0.3)


func _show_damage_effect():
	"""РљСЂР°СЃРЅР°СЏ РІСЃРїС‹С€РєР° РїСЂРё РїРѕР»СѓС‡РµРЅРёРё СѓСЂРѕРЅР°"""
	if not animated_sprite:
		return
	
	var original_modulate = animated_sprite.modulate
	animated_sprite.modulate = Color(2.0, 0.5, 0.5, 1.0)
	
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", original_modulate, 0.2)


# ===========================================
# РЎРРЎРўР•РњРђ РђРќРРњРђР¦РР™ (РЈР›РЈР§РЁР•РќРќРђРЇ)
# ===========================================

func handle_animations():
	"""РЈРїСЂР°РІР»СЏРµС‚ Р°РЅРёРјР°С†РёСЏРјРё РІ Р·Р°РІРёСЃРёРјРѕСЃС‚Рё РѕС‚ СЃРѕСЃС‚РѕСЏРЅРёСЏ"""
	if not animated_sprite:
		return
	
	# РџСЂРёРѕСЂРёС‚РµС‚ Р°РЅРёРјР°С†РёР№ (РѕС‚ РІС‹СЃС€РµРіРѕ Рє РЅРёР·С€РµРјСѓ)
	
	# 1. РЎРјРµСЂС‚СЊ
	if is_dead:
		play_animation("death")
		return
	
	# 2. РђС‚Р°РєР° - РЅРµ РїСЂРµСЂС‹РІР°РµРј
	if is_attacking:
		return
	
	# 3. РџРѕР»СѓС‡РµРЅРёРµ СѓСЂРѕРЅР°
	if is_hurt:
		play_animation("hurt")
		return
	
	# 4. Р‘Р»РѕРє
	if is_blocking:
		play_animation("shield_defence")
		return
	
	# 5. РџСЂРёСЃРµРґР°РЅРёРµ
	if is_crouching and is_on_floor():
		play_animation("crouch")
		return
	
	# 6. Р’ РІРѕР·РґСѓС…Рµ
	if not is_on_floor():
		if velocity.y < 0:
			play_animation("jump")
		else:
			play_animation("fall")
		return
	
	# 7. Р”РІРёР¶РµРЅРёРµ / РџРѕРєРѕР№
	if abs(velocity.x) > 10:
		play_animation("run")
	else:
		play_animation("idle")


func play_animation(anim_name: String):
	"""
	РџСЂРѕРёРіСЂС‹РІР°РµС‚ Р°РЅРёРјР°С†РёСЋ СЃ РїРѕРґРґРµСЂР¶РєРѕР№ Р°Р»СЊС‚РµСЂРЅР°С‚РёРІРЅС‹С… РЅР°Р·РІР°РЅРёР№.
	
	РќР°РїСЂРёРјРµСЂ, РµСЃР»Рё Р·Р°РїСЂРѕС€РµРЅР° "hurt", РЅРѕ РІ СЃРїСЂР°Р№С‚С€РёС‚Рµ РµСЃС‚СЊ С‚РѕР»СЊРєРѕ
	"taking damage", С„СѓРЅРєС†РёСЏ Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё РЅР°Р№РґС‘С‚ РїСЂР°РІРёР»СЊРЅРѕРµ РЅР°Р·РІР°РЅРёРµ.
	"""
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	
	var actual_anim_name = _find_animation_name(anim_name)
	
	if actual_anim_name != "" and animated_sprite.animation != actual_anim_name:
		animated_sprite.play(actual_anim_name)


func _find_animation_name(requested_name: String) -> String:
	"""
	РС‰РµС‚ Р°РЅРёРјР°С†РёСЋ РїРѕ Р·Р°РїСЂРѕС€РµРЅРЅРѕРјСѓ РёРјРµРЅРё РёР»Рё РµРіРѕ Р°Р»СЊС‚РµСЂРЅР°С‚РёРІР°Рј.
	Р’РѕР·РІСЂР°С‰Р°РµС‚ СЂРµР°Р»СЊРЅРѕРµ РёРјСЏ Р°РЅРёРјР°С†РёРё РёР»Рё РїСѓСЃС‚СѓСЋ СЃС‚СЂРѕРєСѓ РµСЃР»Рё РЅРµ РЅР°Р№РґРµРЅР°.
	"""
	if not animated_sprite or not animated_sprite.sprite_frames:
		return ""
	
	var frames = animated_sprite.sprite_frames
	
	# 1. РџСЂРѕРІРµСЂСЏРµРј С‚РѕС‡РЅРѕРµ СЃРѕРІРїР°РґРµРЅРёРµ
	if frames.has_animation(requested_name):
		return requested_name
	
	# 2. РџСЂРѕРІРµСЂСЏРµРј Р°Р»СЊС‚РµСЂРЅР°С‚РёРІРЅС‹Рµ РЅР°Р·РІР°РЅРёСЏ РёР· РјР°РїРїРёРЅРіР°
	if ANIMATION_NAME_MAPPING.has(requested_name):
		for alt_name in ANIMATION_NAME_MAPPING[requested_name]:
			if frames.has_animation(alt_name):
				return alt_name
	
	# 3. РџСЂРѕРІРµСЂСЏРµРј РѕР±СЂР°С‚РЅС‹Р№ РјР°РїРїРёРЅРі (РµСЃР»Рё Р·Р°РїСЂРѕСЃРёР»Рё Р°Р»СЊС‚РµСЂРЅР°С‚РёРІРЅРѕРµ РёРјСЏ)
	for base_name in ANIMATION_NAME_MAPPING:
		if requested_name in ANIMATION_NAME_MAPPING[base_name]:
			if frames.has_animation(base_name):
				return base_name
			for alt_name in ANIMATION_NAME_MAPPING[base_name]:
				if frames.has_animation(alt_name):
					return alt_name
	
	# РђРЅРёРјР°С†РёСЏ РЅРµ РЅР°Р№РґРµРЅР°
	return ""


func get_available_animations() -> Array:
	"""Р’РѕР·РІСЂР°С‰Р°РµС‚ СЃРїРёСЃРѕРє РґРѕСЃС‚СѓРїРЅС‹С… Р°РЅРёРјР°С†РёР№"""
	if animated_sprite and animated_sprite.sprite_frames:
		return animated_sprite.sprite_frames.get_animation_names()
	return []


# ===========================================
# Р‘РћР•Р’РђРЇ РЎРРЎРўР•РњРђ
# ===========================================

func attack():
	"""Р‘Р°Р·РѕРІР°СЏ Р°С‚Р°РєР° - РјРѕР¶РµС‚ Р±С‹С‚СЊ РїРµСЂРµРѕРїСЂРµРґРµР»РµРЅР° РІ РґРѕС‡РµСЂРЅРёС… РєР»Р°СЃСЃР°С…"""
	if is_dead or is_attacking or is_blocking or is_casting or is_sliding or is_crouching or is_inventory_open:
		return
	
	is_attacking = true
	attack_combo += 1
	
	play_animation("attack")
	
	# Р–РґС‘Рј Р·Р°РІРµСЂС€РµРЅРёСЏ Р°РЅРёРјР°С†РёРё
	if animated_sprite:
		await animated_sprite.animation_finished
	
	is_attacking = false
	handle_animations()


func take_damage(amount: int, damage_type: String = "physical", source: String = "РќРµРёР·РІРµСЃС‚РЅРѕ"):
	"""
	РџРѕР»СѓС‡РµРЅРёРµ СѓСЂРѕРЅР°.
	
	РџР°СЂР°РјРµС‚СЂС‹:
		amount - РєРѕР»РёС‡РµСЃС‚РІРѕ СѓСЂРѕРЅР°
		damage_type - С‚РёРї СѓСЂРѕРЅР° ("physical", "magical", "true")
		source - РёСЃС‚РѕС‡РЅРёРє СѓСЂРѕРЅР° (РґР»СЏ СЃС‚Р°С‚РёСЃС‚РёРєРё)
	
	Р’РђР–РќРћ: РџСЂРё РїРµСЂРµРѕРїСЂРµРґРµР»РµРЅРёРё РІ РґРѕС‡РµСЂРЅРёС… РєР»Р°СЃСЃР°С… СЃРѕС…СЂР°РЅСЏР№С‚Рµ СЃРёРіРЅР°С‚СѓСЂСѓ!
	"""
	if is_dead or is_invincible:
		return
	
	# Р—Р°РїРѕРјРёРЅР°РµРј РёСЃС‚РѕС‡РЅРёРє СѓСЂРѕРЅР°
	last_damage_source = source
	
	# Р Р°СЃС‡С‘С‚ СѓСЂРѕРЅР° СЃ СѓС‡С‘С‚РѕРј Р±СЂРѕРЅРё
	var reduced_amount = max(1, amount - armor)
	current_health -= reduced_amount
	current_health = max(0, current_health)
	
	# РћС‚РїСЂР°РІР»СЏРµРј СЃРёРіРЅР°Р»
	health_changed.emit(current_health)
	
	print("рџ’Ґ ", character_name, " РїРѕР»СѓС‡Р°РµС‚ СѓСЂРѕРЅ: ", reduced_amount, " (", damage_type, ") РѕС‚: ", source)
	print("   HP: ", current_health, "/", max_health)
	
	# РћР±РЅРѕРІР»СЏРµРј СЃС‚Р°С‚РёСЃС‚РёРєСѓ
	if Global and Global.has_method("add_damage_taken"):
		Global.add_damage_taken(reduced_amount)
	
	# Р’РёР·СѓР°Р»СЊРЅС‹Р№ СЌС„С„РµРєС‚
	_show_damage_effect()
	
	# РџСЂРѕРІРµСЂРєР° СЃРјРµСЂС‚Рё
	if current_health <= 0:
		die()


# ===========================================
# РЎРРЎРўР•РњРђ РЎРњР•Р РўР Р Р’РћР—Р РћР–Р”Р•РќРРЇ
# ===========================================

func die():
	"""РЎРјРµСЂС‚СЊ РїРµСЂСЃРѕРЅР°Р¶Р°"""
	if is_dead:
		return
	
	is_dead = true
	print("рџ’Ђ ", character_name, " РїРѕРіРёР± РѕС‚: ", last_damage_source)
	
	# РћСЃС‚Р°РЅР°РІР»РёРІР°РµРј РґРІРёР¶РµРЅРёРµ
	velocity = Vector2.ZERO
	
	# РћС‚РєР»СЋС‡Р°РµРј РєРѕР»Р»РёР·РёРё
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	# РћС‚РїСЂР°РІР»СЏРµРј СЃРёРіРЅР°Р»
	died.emit()
	
	# РћР±РЅРѕРІР»СЏРµРј СЃС‚Р°С‚РёСЃС‚РёРєСѓ
	if Global and Global.has_method("set_death_reason"):
		Global.set_death_reason(last_damage_source)
	
	# РџСЂРѕРёРіСЂС‹РІР°РµРј Р°РЅРёРјР°С†РёСЋ СЃРјРµСЂС‚Рё
	play_animation("death")
	
	# Р–РґС‘Рј Р·Р°РІРµСЂС€РµРЅРёСЏ Р°РЅРёРјР°С†РёРё
	if animated_sprite:
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(1.0).timeout
	
	# РЎРєСЂС‹РІР°РµРј РёРіСЂРѕРєР°
	visible = false
	
	# РћС‚РєР»СЋС‡Р°РµРј РєРѕР»Р»РёР·РёСЋ
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	# РџРѕРєР°Р·С‹РІР°РµРј РјРµРЅСЋ СЃРјРµСЂС‚Рё
	_show_death_menu()


func _show_death_menu():
	"""РџРѕРєР°Р·С‹РІР°РµС‚ РјРµРЅСЋ СЃРјРµСЂС‚Рё"""
	print("рџ“њ РџРѕРєР°Р·С‹РІР°РµРј РјРµРЅСЋ СЃРјРµСЂС‚Рё...")
	
	# РџРѕР»СѓС‡Р°РµРј СЃС‚Р°С‚РёСЃС‚РёРєСѓ
	var stats = {}
	if Global and Global.has_method("get_run_statistics"):
		stats = Global.get_run_statistics()
	
	# РџСЂРѕРІРµСЂСЏРµРј Р°СЂС‚РµС„Р°РєС‚ РІРѕР·СЂРѕР¶РґРµРЅРёСЏ
	var revival_artifact = ""
	if Global and Global.has_method("get_revival_artifact"):
		revival_artifact = Global.get_revival_artifact()
	
	# РС‰РµРј РёР»Рё СЃРѕР·РґР°С‘Рј РјРµРЅСЋ СЃРјРµСЂС‚Рё
	var death_menu = get_tree().get_first_node_in_group("death_menu")
	
	if not death_menu:
		var death_menu_scene = load("res://scenes/ui/death_menu.tscn")
		if death_menu_scene:
			death_menu = death_menu_scene.instantiate()
			death_menu.add_to_group("death_menu")
			get_tree().current_scene.add_child(death_menu)
	
	if death_menu:
		# РџРѕРґРєР»СЋС‡Р°РµРј СЃРёРіРЅР°Р» РІРѕР·СЂРѕР¶РґРµРЅРёСЏ
		if death_menu.has_signal("revive_requested"):
			if not death_menu.revive_requested.is_connected(_on_revive_requested):
				death_menu.revive_requested.connect(_on_revive_requested)
		
		# РџРѕРєР°Р·С‹РІР°РµРј РјРµРЅСЋ
		if death_menu.has_method("show_death_menu"):
			death_menu.show_death_menu(stats, revival_artifact)


func _on_revive_requested(_data: Dictionary):
	"""РћР±СЂР°Р±РѕС‚РєР° РІРѕР·СЂРѕР¶РґРµРЅРёСЏ РёР· РјРµРЅСЋ СЃРјРµСЂС‚Рё"""
	print("рџ”® Р’РѕР·СЂРѕР¶РґРµРЅРёРµ РёРіСЂРѕРєР°!")
	
	if Global and Global.has_method("use_revival_artifact"):
		Global.use_revival_artifact()
	
	revive()


func revive():
	"""Р’РѕР·СЂРѕР¶РґР°РµС‚ РїРµСЂСЃРѕРЅР°Р¶Р°"""
	print("вњЁ Р’РѕР·СЂРѕР¶РґРµРЅРёРµ ", character_name, "...")
	
	is_dead = false
	visible = true
	
	# Р’РѕСЃСЃС‚Р°РЅР°РІР»РёРІР°РµРј Р·РґРѕСЂРѕРІСЊРµ (50%)
	current_health = max_health / 2
	health_changed.emit(current_health)
	
	# Р’РєР»СЋС‡Р°РµРј РєРѕР»Р»РёР·РёСЋ
	if collision_shape:
		collision_shape.disabled = false
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	
	# РџРµСЂРµРјРµС‰Р°РµРј РЅР° С‚РѕС‡РєСѓ СЃРїР°РІРЅР°
	var current_scene: Node = get_tree().current_scene
	var player_spawn: Node2D = current_scene.get_node_or_null("World/Markers/PlayerSpawn") as Node2D
	if player_spawn == null:
		player_spawn = current_scene.get_node_or_null("PlayerSpawn") as Node2D
	if player_spawn:
		global_position = player_spawn.global_position
	
	# Р’РѕСЃСЃС‚Р°РЅР°РІР»РёРІР°РµРј РІРёР·СѓР°Р»
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE
		play_animation("idle")
	
	# Р’СЂРµРјРµРЅРЅР°СЏ РЅРµСѓСЏР·РІРёРјРѕСЃС‚СЊ
	give_temporary_invincibility(3.0)
	
	revived.emit()
	print("вњ… ", character_name, " РІРѕР·СЂРѕР¶РґС‘РЅ СЃ ", current_health, " HP")


func give_temporary_invincibility(duration: float):
	"""Р”Р°С‘С‚ РІСЂРµРјРµРЅРЅСѓСЋ РЅРµСѓСЏР·РІРёРјРѕСЃС‚СЊ"""
	is_invincible = true
	print("рџ›ЎпёЏ РќРµСѓСЏР·РІРёРјРѕСЃС‚СЊ РЅР° ", duration, " СЃРµРєСѓРЅРґ")
	
	await get_tree().create_timer(duration).timeout
	
	is_invincible = false
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE
	print("рџ›ЎпёЏ РќРµСѓСЏР·РІРёРјРѕСЃС‚СЊ Р·Р°РєРѕРЅС‡РёР»Р°СЃСЊ")


# ===========================================
# Р‘РђР—РћР’Р«Р• РЎРџРћРЎРћР‘РќРћРЎРўР (РїРµСЂРµРѕРїСЂРµРґРµР»СЏСЋС‚СЃСЏ РІ РґРѕС‡РµСЂРЅРёС… РєР»Р°СЃСЃР°С…)
# ===========================================

func heal():
	"""Р‘Р°Р·РѕРІРѕРµ Р»РµС‡РµРЅРёРµ - РїРµСЂРµРѕРїСЂРµРґРµР»СЏРµС‚СЃСЏ РІ paladin_player.gd"""
	print("вќ¤пёЏ ", character_name, " Р±Р°Р·РѕРІРѕРµ Р»РµС‡РµРЅРёРµ (РЅРµ СЂРµР°Р»РёР·РѕРІР°РЅРѕ)")


func slide():
	"""Р‘Р°Р·РѕРІС‹Р№ РїРѕРґРєР°С‚ - РїРµСЂРµРѕРїСЂРµРґРµР»СЏРµС‚СЃСЏ РІ rogue_player.gd"""
	print("рџ”Ѕ ", character_name, " Р±Р°Р·РѕРІС‹Р№ РїРѕРґРєР°С‚ (РЅРµ СЂРµР°Р»РёР·РѕРІР°РЅ)")


func block():
	"""Р‘Р°Р·РѕРІС‹Р№ Р±Р»РѕРє - РїРµСЂРµРѕРїСЂРµРґРµР»СЏРµС‚СЃСЏ РІ warrior_player.gd"""
	pass


func stop_blocking():
	"""РџСЂРµРєСЂР°С‰РµРЅРёРµ Р±Р»РѕРєР° - РїРµСЂРµРѕРїСЂРµРґРµР»СЏРµС‚СЃСЏ РІ warrior_player.gd"""
	pass


# ===========================================
# РЈРџР РђР’Р›Р•РќРР• РРќР’Р•РќРўРђР РЃРњ (Р±Р»РѕРєРёСЂРѕРІРєР° РёРіСЂРѕРєР°)
# ===========================================

func set_inventory_open(open: bool):
	"""РЈСЃС‚Р°РЅР°РІР»РёРІР°РµС‚ СЃРѕСЃС‚РѕСЏРЅРёРµ РёРЅРІРµРЅС‚Р°СЂСЏ - Р±Р»РѕРєРёСЂСѓРµС‚/СЂР°Р·Р±Р»РѕРєРёСЂСѓРµС‚ РёРіСЂРѕРєР°"""
	is_inventory_open = open
	
	if open:
		# РџСЂРё РѕС‚РєСЂС‹С‚РёРё РёРЅРІРµРЅС‚Р°СЂСЏ РѕСЃС‚Р°РЅР°РІР»РёРІР°РµРј РґРІРёР¶РµРЅРёРµ
		velocity.x = 0
		# РџСЂРµСЂС‹РІР°РµРј Р°С‚Р°РєСѓ РµСЃР»Рё РѕРЅР° Р±С‹Р»Р°
		if is_attacking:
			is_attacking = false
		# РћС‚РјРµРЅСЏРµРј РїСЂРёСЃРµРґР°РЅРёРµ
		if is_crouching:
			stop_crouch()
		# РћС‚РјРµРЅСЏРµРј Р±Р»РѕРє
		if is_blocking:
			stop_blocking()
