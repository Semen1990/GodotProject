# base_game_character.gd
extends CharacterBody2D

# ===========================================
# Р вЂР С’Р вЂ”Р С›Р вЂ™Р В«Р в„ў Р С™Р вЂєР С’Р РЋР РЋ Р СџР вЂўР В Р РЋР С›Р СњР С’Р вЂ“Р С’ (Р Р€Р вЂєР Р€Р В§Р РЃР вЂўР СњР СњР С’Р Р‡ Р вЂ™Р вЂўР В Р РЋР ВР Р‡)
# ===========================================
# Р В­РЎвЂљР С•РЎвЂљ Р С”Р В»Р В°РЎРѓРЎРѓ РЎРѓР С•Р Т‘Р ВµРЎР‚Р В¶Р С‘РЎвЂљ Р вЂ™Р РЋР В® Р С•Р В±РЎвЂ°РЎС“РЎР‹ Р В»Р С•Р С–Р С‘Р С”РЎС“ Р Т‘Р В»РЎРЏ Р Р†РЎРѓР ВµРЎвЂ¦ Р С—Р ВµРЎР‚РЎРѓР С•Р Р…Р В°Р В¶Р ВµР в„–.
# Р вЂќР С•РЎвЂЎР ВµРЎР‚Р Р…Р С‘Р Вµ Р С”Р В»Р В°РЎРѓРЎРѓРЎвЂ№ (warrior, paladin, rogue, berserk) Р Р…Р В°РЎРѓР В»Р ВµР Т‘РЎС“РЎР‹РЎвЂљ Р С•РЎвЂљ Р Р…Р ВµР С–Р С•
# Р С‘ РЎвЂљР С•Р В»РЎРЉР С”Р С• Р СџР вЂўР В Р вЂўР С›Р СџР В Р вЂўР вЂќР вЂўР вЂєР Р‡Р В®Р Сћ РЎРѓР С—Р ВµРЎвЂ Р С‘РЎвЂћР С‘РЎвЂЎР Р…РЎС“РЎР‹ Р В»Р С•Р С–Р С‘Р С”РЎС“.

# --- Р РЋР ВР вЂњР СњР С’Р вЂєР В« ---
# Р ВРЎРѓР С—Р С•Р В»РЎРЉР В·РЎС“РЎР‹РЎвЂљРЎРѓРЎРЏ Р Т‘Р В»РЎРЏ РЎРѓР Р†РЎРЏР В·Р С‘ РЎРѓ UI Р С‘ Р Т‘РЎР‚РЎС“Р С–Р С‘Р СР С‘ РЎРѓР С‘РЎРѓРЎвЂљР ВµР СР В°Р СР С‘
signal health_changed(new_health: int)
signal mana_changed(new_mana: int)
signal armor_changed(new_armor: int)
signal madness_changed(new_stacks: int, max_stacks: int)
signal died()
signal revived()

# --- Р вЂР С’Р вЂ”Р С›Р вЂ™Р В«Р вЂў Р ТђР С’Р В Р С’Р С™Р СћР вЂўР В Р ВР РЋР СћР ВР С™Р В ---
# Р СџР ВµРЎР‚Р ВµР С•Р С—РЎР‚Р ВµР Т‘Р ВµР В»РЎРЏРЎР‹РЎвЂљРЎРѓРЎРЏ Р Р† Р Т‘Р С•РЎвЂЎР ВµРЎР‚Р Р…Р С‘РЎвЂ¦ Р С”Р В»Р В°РЎРѓРЎРѓР В°РЎвЂ¦ Р Р† _ready()
var character_name: String = "BaseCharacter"
var max_health: int = 100
var current_health: int = 100
var max_mana: int = 100
var current_mana: int = 100
var armor: int = 0
var current_damage: int = 2  # Р СћР ВµР С”РЎС“РЎвЂ°Р С‘Р в„– РЎС“РЎР‚Р С•Р Р… (Р В±Р В°Р В·Р В° + Р В±Р С•Р Р…РЎС“РЎРѓРЎвЂ№ Р С•РЎвЂљ РЎРЊР С”Р С‘Р С—Р С‘РЎР‚Р С•Р Р†Р С”Р С‘)
var base_speed: int = 200
var current_speed: int = 200
var madness_stacks: int = 0
var max_madness_stacks: int = 9

# --- Р РЋР С›Р РЋР СћР С›Р Р‡Р СњР ВР Р‡ Р СџР вЂўР В Р РЋР С›Р СњР С’Р вЂ“Р С’ ---
# Р ВРЎРѓР С—Р С•Р В»РЎРЉР В·РЎС“РЎР‹РЎвЂљРЎРѓРЎРЏ Р Т‘Р В»РЎРЏ Р С”Р С•Р Р…РЎвЂљРЎР‚Р С•Р В»РЎРЏ Р Т‘Р ВµР в„–РЎРѓРЎвЂљР Р†Р С‘Р в„– Р С‘ Р В°Р Р…Р С‘Р СР В°РЎвЂ Р С‘Р в„–
var is_dead: bool = false
var is_attacking: bool = false
var is_moving: bool = false
var is_blocking: bool = false
var is_sliding: bool = false
var is_casting: bool = false
var is_crouching: bool = false
var is_hurt: bool = false
var is_invincible: bool = false  # Р СњР ВµРЎС“РЎРЏР В·Р Р†Р С‘Р СР С•РЎРѓРЎвЂљРЎРЉ Р С—Р С•РЎРѓР В»Р Вµ Р Р†Р С•Р В·РЎР‚Р С•Р В¶Р Т‘Р ВµР Р…Р С‘РЎРЏ
var is_inventory_open: bool = false  # Р вЂР В»Р С•Р С”Р С‘РЎР‚Р С•Р Р†Р С”Р В° Р С—РЎР‚Р С‘ Р С•РЎвЂљР С”РЎР‚РЎвЂ№РЎвЂљР С•Р С Р С‘Р Р…Р Р†Р ВµР Р…РЎвЂљР В°РЎР‚Р Вµ

# --- Р РЋР ВР РЋР СћР вЂўР СљР С’ Р С’Р СћР С’Р С™Р В ---
var attack_combo: int = 0
var last_attack_time: float = 0.0
var attack_combo_timeout: float = 1.0

# --- Р В¤Р ВР вЂ”Р ВР С™Р С’ ---
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")
var max_speed: float = 300.0
var acceleration: float = 1500.0
var friction: float = 1200.0
var jump_velocity: float = -400.0

# --- Р РЋР ВР РЋР СћР вЂўР СљР С’ Р вЂќР вЂ™Р С›Р в„ўР СњР С›Р вЂњР С› Р СџР В Р В«Р вЂ“Р С™Р С’ ---
# Р С’Р С”РЎвЂљР С‘Р Р†Р С‘РЎР‚РЎС“Р ВµРЎвЂљРЎРѓРЎРЏ Р В°РЎР‚РЎвЂљР ВµРЎвЂћР В°Р С”РЎвЂљР В°Р СР С‘ (Р Р…Р В°Р С—РЎР‚Р С‘Р СР ВµРЎР‚, "Р С™РЎР‚РЎвЂ№Р В»РЎРЉРЎРЏ Р вЂњР ВµРЎР‚Р СР ВµРЎРѓР В°")
var enable_double_jump: bool = false
var has_double_jumped: bool = false
var can_double_jump: bool = false
var coyote_time: float = 0.1  # Р вЂ™РЎР‚Р ВµР СРЎРЏ Р С—Р С•РЎРѓР В»Р Вµ Р С—Р В°Р Т‘Р ВµР Р…Р С‘РЎРЏ РЎРѓ Р С—Р В»Р В°РЎвЂљРЎвЂћР С•РЎР‚Р СРЎвЂ№, Р С”Р С•Р С–Р Т‘Р В° Р ВµРЎвЂ°Р Вµ Р СР С•Р В¶Р Р…Р С• Р С—РЎР‚РЎвЂ№Р С–Р Р…РЎС“РЎвЂљРЎРЉ
var coyote_timer: float = 0.0

# --- Р В Р С’Р вЂ”Р СљР вЂўР В Р В« Р С™Р С›Р вЂєР вЂєР ВР вЂ”Р ВР В Р вЂќР вЂєР Р‡ Р СџР В Р ВР РЋР вЂўР вЂќР С’Р СњР ВР Р‡ ---
var standing_collision_height: float = 0.0
var crouching_collision_height: float = 0.0
var original_collision_position: Vector2 = Vector2.ZERO

# --- Р РЋР СћР С’Р СћР ВР РЋР СћР ВР С™Р С’ ---
var last_damage_source: String = "Р СњР ВµР С‘Р В·Р Р†Р ВµРЎРѓРЎвЂљР Р…Р С•"

# --- Р РЋР РЋР В«Р вЂєР С™Р В Р СњР С’ Р СњР С›Р вЂќР В« ---
var animated_sprite: AnimatedSprite2D
var collision_shape: CollisionShape2D
var player_controller: Node

# --- Р вЂ™Р ВР вЂ”Р Р€Р С’Р вЂє ---
var original_scale: Vector2 = Vector2.ONE

# --- Р СљР С’Р СџР СџР ВР СњР вЂњ Р С’Р вЂєР В¬Р СћР вЂўР В Р СњР С’Р СћР ВР вЂ™Р СњР В«Р Тђ Р СњР С’Р вЂ”Р вЂ™Р С’Р СњР ВР в„ў Р С’Р СњР ВР СљР С’Р В¦Р ВР в„ў ---
# Р В Р В°Р В·Р Р…РЎвЂ№Р Вµ РЎРѓР С—РЎР‚Р В°Р в„–РЎвЂљРЎв‚¬Р С‘РЎвЂљРЎвЂ№ Р СР С•Р С–РЎС“РЎвЂљ Р С‘Р СР ВµРЎвЂљРЎРЉ РЎР‚Р В°Р В·Р Р…РЎвЂ№Р Вµ Р Р…Р В°Р В·Р Р†Р В°Р Р…Р С‘РЎРЏ Р В°Р Р…Р С‘Р СР В°РЎвЂ Р С‘Р в„–
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
	
	# --- Р вЂР ВµР В·Р С•Р С—Р В°РЎРѓР Р…Р С•Р Вµ Р С—Р С•Р В»РЎС“РЎвЂЎР ВµР Р…Р С‘Р Вµ Р Р…Р С•Р Т‘Р С•Р Р† ---
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	collision_shape = get_node_or_null("CollisionShape2D") 
	player_controller = get_node_or_null("PlayerController")
	
	# Р РЋР С•РЎвЂ¦РЎР‚Р В°Р Р…РЎРЏР ВµР С Р С•РЎР‚Р С‘Р С–Р С‘Р Р…Р В°Р В»РЎРЉР Р…РЎвЂ№Р в„– Р СР В°РЎРѓРЎв‚¬РЎвЂљР В°Р В± РЎРѓР С—РЎР‚Р В°Р в„–РЎвЂљР В°
	if animated_sprite:
		original_scale = animated_sprite.scale
	
	# --- Р СњР В°РЎРѓРЎвЂљРЎР‚Р С•Р в„–Р С”Р В° Р С”Р С•Р В»Р В»Р С‘Р В·Р С‘Р С‘ Р Т‘Р В»РЎРЏ Р С—РЎР‚Р С‘РЎРѓР ВµР Т‘Р В°Р Р…Р С‘РЎРЏ ---
	if collision_shape and collision_shape.shape:
		original_collision_position = collision_shape.position
		if collision_shape.shape is CapsuleShape2D:
			standing_collision_height = collision_shape.shape.height
			crouching_collision_height = standing_collision_height * 0.5
		elif collision_shape.shape is RectangleShape2D:
			standing_collision_height = collision_shape.shape.size.y
			crouching_collision_height = standing_collision_height * 0.5
	
	# --- Р СњР В°РЎРѓРЎвЂљРЎР‚Р С•Р в„–Р С”Р В° Р С”Р С•Р Р…РЎвЂљРЎР‚Р С•Р В»Р В»Р ВµРЎР‚Р В° ---
	if player_controller:
		player_controller.character = self
	# --- Р СџРЎР‚Р С‘Р СР ВµР Р…Р ВµР Р…Р С‘Р Вµ Р В°РЎР‚РЎвЂљР ВµРЎвЂћР В°Р С”РЎвЂљР С•Р Р† ---
	call_deferred("apply_artifacts")
	
	# --- Р вЂ”Р В°Р С—РЎС“РЎРѓР С” Р В°Р Р…Р С‘Р СР В°РЎвЂ Р С‘Р С‘ Р С—Р С•Р С”Р С•РЎРЏ ---
	if animated_sprite:
		play_animation("idle")
	madness_changed.emit(madness_stacks, max_madness_stacks)


func apply_artifacts():
	"""Р СџРЎР‚Р С‘Р СР ВµР Р…РЎРЏР ВµР С Р Р†РЎРѓР Вµ РЎРѓР С•Р В±РЎР‚Р В°Р Р…Р Р…РЎвЂ№Р Вµ Р В°РЎР‚РЎвЂљР ВµРЎвЂћР В°Р С”РЎвЂљРЎвЂ№ Р С” Р С—Р ВµРЎР‚РЎРѓР С•Р Р…Р В°Р В¶РЎС“"""
	if Global:
		Global.apply_all_artifacts_to_player()
		
		# Р СџРЎР‚Р С•Р Р†Р ВµРЎР‚РЎРЏР ВµР С Р Р…Р В°Р В»Р С‘РЎвЂЎР С‘Р Вµ РЎРѓР С—Р С•РЎРѓР С•Р В±Р Р…Р С•РЎРѓРЎвЂљР С‘ Р Т‘Р Р†Р С•Р в„–Р Р…Р С•Р С–Р С• Р С—РЎР‚РЎвЂ№Р В¶Р С”Р В°
		if Global.has_ability("double_jump"):
			enable_double_jump = true
		else:
			enable_double_jump = false


func _physics_process(delta: float):
	if is_dead:
		return
	
	# --- Р В­РЎвЂћРЎвЂћР ВµР С”РЎвЂљ Р Р…Р ВµРЎС“РЎРЏР В·Р Р†Р С‘Р СР С•РЎРѓРЎвЂљР С‘ (Р СР С‘Р С–Р В°Р Р…Р С‘Р Вµ) ---
	if is_invincible and animated_sprite:
		animated_sprite.modulate.a = 0.7 + sin(Time.get_ticks_msec() * 0.01) * 0.3
	
	# --- Р вЂњРЎР‚Р В°Р Р†Р С‘РЎвЂљР В°РЎвЂ Р С‘РЎРЏ Р С‘ coyote time ---
	if not is_on_floor():
		velocity.y += gravity * delta
		if coyote_timer > 0:
			coyote_timer -= delta
	else:
		# Р РЋР В±РЎР‚Р С•РЎРѓ Р Т‘Р Р†Р С•Р в„–Р Р…Р С•Р С–Р С• Р С—РЎР‚РЎвЂ№Р В¶Р С”Р В° Р С—РЎР‚Р С‘ Р С”Р В°РЎРѓР В°Р Р…Р С‘Р С‘ Р В·Р ВµР СР В»Р С‘
		has_double_jumped = false
		can_double_jump = false
		coyote_timer = coyote_time
	
	# --- Р С›Р В±РЎР‚Р В°Р В±Р С•РЎвЂљР С”Р В° Р Т‘Р Р†Р С‘Р В¶Р ВµР Р…Р С‘РЎРЏ Р С‘ Р В°Р Р…Р С‘Р СР В°РЎвЂ Р С‘Р в„– ---
	handle_movement(delta)
	handle_animations()
	fix_sprite_scale()
	
	move_and_slide()


func fix_sprite_scale():
	"""Р В¤Р С‘Р С”РЎРѓР С‘РЎР‚РЎС“Р ВµРЎвЂљ Р СР В°РЎРѓРЎв‚¬РЎвЂљР В°Р В± РЎРѓР С—РЎР‚Р В°Р в„–РЎвЂљР В° (Р С—РЎР‚Р ВµР Т‘Р С•РЎвЂљР Р†РЎР‚Р В°РЎвЂ°Р В°Р ВµРЎвЂљ Р В±Р В°Р С–Р С‘ РЎРѓ flip_h)"""
	if animated_sprite:
		var current_sign = sign(animated_sprite.scale.x)
		if current_sign == 0:
			current_sign = 1
		animated_sprite.scale = Vector2(
			abs(original_scale.x) * current_sign,
			original_scale.y
		)


# ===========================================
# Р РЋР ВР РЋР СћР вЂўР СљР С’ Р вЂќР вЂ™Р ВР вЂ“Р вЂўР СњР ВР Р‡
# ===========================================

func handle_movement(delta: float):
	# --- Р вЂР В»Р С•Р С”Р С‘РЎР‚Р С•Р Р†Р С”Р В° Р С—РЎР‚Р С‘ Р С•РЎвЂљР С”РЎР‚РЎвЂ№РЎвЂљР С•Р С Р С‘Р Р…Р Р†Р ВµР Р…РЎвЂљР В°РЎР‚Р Вµ ---
	# Р ВР С–РЎР‚Р С•Р С” Р Р…Р Вµ Р СР С•Р В¶Р ВµРЎвЂљ Р Т‘Р Р†Р С‘Р С–Р В°РЎвЂљРЎРЉРЎРѓРЎРЏ Р С‘ Р С‘РЎРѓР С—Р С•Р В»РЎРЉР В·Р С•Р Р†Р В°РЎвЂљРЎРЉ РЎРѓР С—Р С•РЎРѓР С•Р В±Р Р…Р С•РЎРѓРЎвЂљР С‘,
	# Р Р…Р С• Р Р†РЎР‚Р В°Р С–Р С‘ Р С—РЎР‚Р С•Р Т‘Р С•Р В»Р В¶Р В°РЎР‹РЎвЂљ Р Т‘Р ВµР в„–РЎРѓРЎвЂљР Р†Р С•Р Р†Р В°РЎвЂљРЎРЉ Р С‘ Р СР С•Р С–РЎС“РЎвЂљ Р Р…Р В°Р Р…Р С•РЎРѓР С‘РЎвЂљРЎРЉ РЎС“РЎР‚Р С•Р Р…
	if is_inventory_open:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		return
	
	# --- Р СџР С•Р В»РЎС“РЎвЂЎР ВµР Р…Р С‘Р Вµ Р Р†Р Р†Р С•Р Т‘Р В° ---
	var direction = Input.get_axis("move_left", "move_right")
	var is_jumping = Input.is_action_just_pressed("jump")
	var is_crouch_pressed = Input.is_action_pressed("crouch")
	var is_special = Input.is_action_just_pressed("special_ability")
	
	# --- Р вЂР В»Р С•Р С”Р С‘РЎР‚Р С•Р Р†Р С”Р В° Р Т‘Р Р†Р С‘Р В¶Р ВµР Р…Р С‘РЎРЏ Р Р†Р С• Р Р†РЎР‚Р ВµР СРЎРЏ РЎРѓР С—Р ВµРЎвЂ Р С‘Р В°Р В»РЎРЉР Р…РЎвЂ№РЎвЂ¦ Р Т‘Р ВµР в„–РЎРѓРЎвЂљР Р†Р С‘Р в„– ---
	if is_attacking or is_casting or is_sliding:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		return
	
	# --- Р СџР В Р ВР РЋР вЂўР вЂќР С’Р СњР ВР вЂў ---
	if is_crouch_pressed and is_on_floor() and not is_blocking:
		if not is_crouching:
			start_crouch()
	elif is_crouching:
		stop_crouch()
	
	# --- Р РЋР СџР вЂўР В¦Р ВР С’Р вЂєР В¬Р СњР С’Р Р‡ Р РЋР СџР С›Р РЋР С›Р вЂР СњР С›Р РЋР СћР В¬ (E) ---
	if is_special and not is_crouching:
		use_special_ability()
	
	# --- Р вЂќР вЂ™Р ВР вЂ“Р вЂўР СњР ВР вЂў ---
	if not is_blocking and not is_crouching:
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * current_speed, acceleration * delta)
			# Р СџР С•Р Р†Р С•РЎР‚Р С•РЎвЂљ РЎРѓР С—РЎР‚Р В°Р в„–РЎвЂљР В°
			if animated_sprite:
				animated_sprite.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
	elif is_crouching:
		# Р СџРЎР‚Р С‘ Р С—РЎР‚Р С‘РЎРѓР ВµР Т‘Р В°Р Р…Р С‘Р С‘ - Р В·Р В°Р СР ВµР Т‘Р В»Р ВµР Р…Р С‘Р Вµ Р Т‘Р С• Р С•РЎРѓРЎвЂљР В°Р Р…Р С•Р Р†Р С”Р С‘
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	else:
		# Р СџРЎР‚Р С‘ Р В±Р В»Р С•Р С”Р Вµ - Р В±РЎвЂ№РЎРѓРЎвЂљРЎР‚Р В°РЎРЏ Р С•РЎРѓРЎвЂљР В°Р Р…Р С•Р Р†Р С”Р В°
		velocity.x = move_toward(velocity.x, 0, friction * delta * 2)
	
	# --- Р СџР В Р В«Р вЂ“Р С™Р В ---
	if is_jumping and not is_blocking and not is_crouching:
		if is_on_floor() or coyote_timer > 0:
			# Р С›Р В±РЎвЂ№РЎвЂЎР Р…РЎвЂ№Р в„– Р С—РЎР‚РЎвЂ№Р В¶Р С•Р С”
			velocity.y = jump_velocity
			can_double_jump = enable_double_jump
			has_double_jumped = false
			coyote_timer = 0
		elif enable_double_jump and can_double_jump and not has_double_jumped:
			# Р вЂќР Р†Р С•Р в„–Р Р…Р С•Р в„– Р С—РЎР‚РЎвЂ№Р В¶Р С•Р С” (РЎРѓР В»Р В°Р В±Р ВµР Вµ Р С•Р В±РЎвЂ№РЎвЂЎР Р…Р С•Р С–Р С•)
			velocity.y = jump_velocity * 0.8
			has_double_jumped = true
			can_double_jump = false
			_show_double_jump_effect()


# ===========================================
# Р СџР В Р ВР РЋР вЂўР вЂќР С’Р СњР ВР вЂў
# ===========================================

func start_crouch():
	"""Р СњР В°РЎвЂЎР В°РЎвЂљРЎРЉ Р С—РЎР‚Р С‘РЎРѓР ВµР Т‘Р В°Р Р…Р С‘Р Вµ"""
	if not is_on_floor() or is_crouching:
		return
	
	is_crouching = true


func stop_crouch():
	"""Р вЂ”Р В°Р С”Р С•Р Р…РЎвЂЎР С‘РЎвЂљРЎРЉ Р С—РЎР‚Р С‘РЎРѓР ВµР Т‘Р В°Р Р…Р С‘Р Вµ"""
	if not is_crouching:
		return
	
	is_crouching = false
	
	# Р вЂ™Р С•РЎРѓРЎРѓРЎвЂљР В°Р Р…Р В°Р Р†Р В»Р С‘Р Р†Р В°Р ВµР С Р С”Р С•Р В»Р В»Р С‘Р В·Р С‘РЎР‹
	if collision_shape and collision_shape.shape:
		if collision_shape.shape is CapsuleShape2D:
			collision_shape.shape.height = standing_collision_height
			collision_shape.position.y = original_collision_position.y
		elif collision_shape.shape is RectangleShape2D:
			collision_shape.shape.size.y = standing_collision_height
			collision_shape.position.y = original_collision_position.y


# ===========================================
# Р РЋР СџР вЂўР В¦Р ВР С’Р вЂєР В¬Р СњР С’Р Р‡ Р РЋР СџР С›Р РЋР С›Р вЂР СњР С›Р РЋР СћР В¬
# ===========================================

func use_special_ability():
	"""
	Р вЂ™Р С‘РЎР‚РЎвЂљРЎС“Р В°Р В»РЎРЉР Р…Р В°РЎРЏ РЎвЂћРЎС“Р Р…Р С”РЎвЂ Р С‘РЎРЏ - Р С›Р вЂР Р‡Р вЂ”Р С’Р СћР вЂўР вЂєР В¬Р СњР С› Р С—Р ВµРЎР‚Р ВµР С•Р С—РЎР‚Р ВµР Т‘Р ВµР В»РЎРЏР ВµРЎвЂљРЎРѓРЎРЏ Р Р† Р Т‘Р С•РЎвЂЎР ВµРЎР‚Р Р…Р С‘РЎвЂ¦ Р С”Р В»Р В°РЎРѓРЎРѓР В°РЎвЂ¦!
	
	- Р вЂ™Р С•Р С‘Р Р…: block() - Р В±Р В»Р С•Р С” РЎвЂ°Р С‘РЎвЂљР С•Р С
	- Р СџР В°Р В»Р В°Р Т‘Р С‘Р Р…: heal() - Р С‘РЎРѓРЎвЂ Р ВµР В»Р ВµР Р…Р С‘Р Вµ
	- Р В Р В°Р В·Р В±Р С•Р в„–Р Р…Р С‘Р С”: slide() - Р С—Р С•Р Т‘Р С”Р В°РЎвЂљ
	- Р вЂР ВµРЎР‚РЎРѓР ВµРЎР‚Р С”: rage() - РЎРЏРЎР‚Р С•РЎРѓРЎвЂљРЎРЉ (Р ВµРЎРѓР В»Р С‘ РЎР‚Р ВµР В°Р В»Р С‘Р В·Р С•Р Р†Р В°Р Р…Р С•)
	"""


# ===========================================
# Р вЂ™Р ВР вЂ”Р Р€Р С’Р вЂєР В¬Р СњР В«Р вЂў Р В­Р В¤Р В¤Р вЂўР С™Р СћР В«
# ===========================================

func _show_double_jump_effect():
	"""Р вЂ™Р С‘Р В·РЎС“Р В°Р В»РЎРЉР Р…РЎвЂ№Р в„– РЎРЊРЎвЂћРЎвЂћР ВµР С”РЎвЂљ Р С—РЎР‚Р С‘ Р Т‘Р Р†Р С•Р в„–Р Р…Р С•Р С Р С—РЎР‚РЎвЂ№Р В¶Р С”Р Вµ"""
	if not animated_sprite:
		return
	
	var original_modulate = animated_sprite.modulate
	animated_sprite.modulate = Color(1.5, 1.5, 2.0, 1.0)
	
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", original_modulate, 0.3)


func _show_damage_effect():
	"""Р С™РЎР‚Р В°РЎРѓР Р…Р В°РЎРЏ Р Р†РЎРѓР С—РЎвЂ№РЎв‚¬Р С”Р В° Р С—РЎР‚Р С‘ Р С—Р С•Р В»РЎС“РЎвЂЎР ВµР Р…Р С‘Р С‘ РЎС“РЎР‚Р С•Р Р…Р В°"""
	if not animated_sprite:
		return
	
	var original_modulate = animated_sprite.modulate
	animated_sprite.modulate = Color(2.0, 0.5, 0.5, 1.0)
	
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", original_modulate, 0.2)


# ===========================================
# Р РЋР ВР РЋР СћР вЂўР СљР С’ Р С’Р СњР ВР СљР С’Р В¦Р ВР в„ў (Р Р€Р вЂєР Р€Р В§Р РЃР вЂўР СњР СњР С’Р Р‡)
# ===========================================

func handle_animations():
	"""Р Р€Р С—РЎР‚Р В°Р Р†Р В»РЎРЏР ВµРЎвЂљ Р В°Р Р…Р С‘Р СР В°РЎвЂ Р С‘РЎРЏР СР С‘ Р Р† Р В·Р В°Р Р†Р С‘РЎРѓР С‘Р СР С•РЎРѓРЎвЂљР С‘ Р С•РЎвЂљ РЎРѓР С•РЎРѓРЎвЂљР С•РЎРЏР Р…Р С‘РЎРЏ"""
	if not animated_sprite:
		return
	
	# Р СџРЎР‚Р С‘Р С•РЎР‚Р С‘РЎвЂљР ВµРЎвЂљ Р В°Р Р…Р С‘Р СР В°РЎвЂ Р С‘Р в„– (Р С•РЎвЂљ Р Р†РЎвЂ№РЎРѓРЎв‚¬Р ВµР С–Р С• Р С” Р Р…Р С‘Р В·РЎв‚¬Р ВµР СРЎС“)
	
	# 1. Р РЋР СР ВµРЎР‚РЎвЂљРЎРЉ
	if is_dead:
		play_animation("death")
		return
	
	# 2. Р С’РЎвЂљР В°Р С”Р В° - Р Р…Р Вµ Р С—РЎР‚Р ВµРЎР‚РЎвЂ№Р Р†Р В°Р ВµР С
	if is_attacking:
		return
	
	# 3. Р СџР С•Р В»РЎС“РЎвЂЎР ВµР Р…Р С‘Р Вµ РЎС“РЎР‚Р С•Р Р…Р В°
	if is_hurt:
		play_animation("hurt")
		return
	
	# 4. Р вЂР В»Р С•Р С”
	if is_blocking:
		play_animation("shield_defence")
		return
	
	# 5. Р СџРЎР‚Р С‘РЎРѓР ВµР Т‘Р В°Р Р…Р С‘Р Вµ
	if is_crouching and is_on_floor():
		play_animation("crouch")
		return
	
	# 6. Р вЂ™ Р Р†Р С•Р В·Р Т‘РЎС“РЎвЂ¦Р Вµ
	if not is_on_floor():
		if velocity.y < 0:
			play_animation("jump")
		else:
			play_animation("fall")
		return
	
	# 7. Р вЂќР Р†Р С‘Р В¶Р ВµР Р…Р С‘Р Вµ / Р СџР С•Р С”Р С•Р в„–
	if abs(velocity.x) > 10:
		play_animation("run")
	else:
		play_animation("idle")


func play_animation(anim_name: String):
	"""
	Р СџРЎР‚Р С•Р С‘Р С–РЎР‚РЎвЂ№Р Р†Р В°Р ВµРЎвЂљ Р В°Р Р…Р С‘Р СР В°РЎвЂ Р С‘РЎР‹ РЎРѓ Р С—Р С•Р Т‘Р Т‘Р ВµРЎР‚Р В¶Р С”Р С•Р в„– Р В°Р В»РЎРЉРЎвЂљР ВµРЎР‚Р Р…Р В°РЎвЂљР С‘Р Р†Р Р…РЎвЂ№РЎвЂ¦ Р Р…Р В°Р В·Р Р†Р В°Р Р…Р С‘Р в„–.
	
	Р СњР В°Р С—РЎР‚Р С‘Р СР ВµРЎР‚, Р ВµРЎРѓР В»Р С‘ Р В·Р В°Р С—РЎР‚Р С•РЎв‚¬Р ВµР Р…Р В° "hurt", Р Р…Р С• Р Р† РЎРѓР С—РЎР‚Р В°Р в„–РЎвЂљРЎв‚¬Р С‘РЎвЂљР Вµ Р ВµРЎРѓРЎвЂљРЎРЉ РЎвЂљР С•Р В»РЎРЉР С”Р С•
	"taking damage", РЎвЂћРЎС“Р Р…Р С”РЎвЂ Р С‘РЎРЏ Р В°Р Р†РЎвЂљР С•Р СР В°РЎвЂљР С‘РЎвЂЎР ВµРЎРѓР С”Р С‘ Р Р…Р В°Р в„–Р Т‘РЎвЂРЎвЂљ Р С—РЎР‚Р В°Р Р†Р С‘Р В»РЎРЉР Р…Р С•Р Вµ Р Р…Р В°Р В·Р Р†Р В°Р Р…Р С‘Р Вµ.
	"""
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	
	var actual_anim_name = _find_animation_name(anim_name)
	
	if actual_anim_name != "" and animated_sprite.animation != actual_anim_name:
		animated_sprite.play(actual_anim_name)


func _find_animation_name(requested_name: String) -> String:
	"""
	Р ВРЎвЂ°Р ВµРЎвЂљ Р В°Р Р…Р С‘Р СР В°РЎвЂ Р С‘РЎР‹ Р С—Р С• Р В·Р В°Р С—РЎР‚Р С•РЎв‚¬Р ВµР Р…Р Р…Р С•Р СРЎС“ Р С‘Р СР ВµР Р…Р С‘ Р С‘Р В»Р С‘ Р ВµР С–Р С• Р В°Р В»РЎРЉРЎвЂљР ВµРЎР‚Р Р…Р В°РЎвЂљР С‘Р Р†Р В°Р С.
	Р вЂ™Р С•Р В·Р Р†РЎР‚Р В°РЎвЂ°Р В°Р ВµРЎвЂљ РЎР‚Р ВµР В°Р В»РЎРЉР Р…Р С•Р Вµ Р С‘Р СРЎРЏ Р В°Р Р…Р С‘Р СР В°РЎвЂ Р С‘Р С‘ Р С‘Р В»Р С‘ Р С—РЎС“РЎРѓРЎвЂљРЎС“РЎР‹ РЎРѓРЎвЂљРЎР‚Р С•Р С”РЎС“ Р ВµРЎРѓР В»Р С‘ Р Р…Р Вµ Р Р…Р В°Р в„–Р Т‘Р ВµР Р…Р В°.
	"""
	if not animated_sprite or not animated_sprite.sprite_frames:
		return ""
	
	var frames = animated_sprite.sprite_frames
	
	# 1. Р СџРЎР‚Р С•Р Р†Р ВµРЎР‚РЎРЏР ВµР С РЎвЂљР С•РЎвЂЎР Р…Р С•Р Вµ РЎРѓР С•Р Р†Р С—Р В°Р Т‘Р ВµР Р…Р С‘Р Вµ
	if frames.has_animation(requested_name):
		return requested_name
	
	# 2. Р СџРЎР‚Р С•Р Р†Р ВµРЎР‚РЎРЏР ВµР С Р В°Р В»РЎРЉРЎвЂљР ВµРЎР‚Р Р…Р В°РЎвЂљР С‘Р Р†Р Р…РЎвЂ№Р Вµ Р Р…Р В°Р В·Р Р†Р В°Р Р…Р С‘РЎРЏ Р С‘Р В· Р СР В°Р С—Р С—Р С‘Р Р…Р С–Р В°
	if ANIMATION_NAME_MAPPING.has(requested_name):
		for alt_name in ANIMATION_NAME_MAPPING[requested_name]:
			if frames.has_animation(alt_name):
				return alt_name
	
	# 3. Р СџРЎР‚Р С•Р Р†Р ВµРЎР‚РЎРЏР ВµР С Р С•Р В±РЎР‚Р В°РЎвЂљР Р…РЎвЂ№Р в„– Р СР В°Р С—Р С—Р С‘Р Р…Р С– (Р ВµРЎРѓР В»Р С‘ Р В·Р В°Р С—РЎР‚Р С•РЎРѓР С‘Р В»Р С‘ Р В°Р В»РЎРЉРЎвЂљР ВµРЎР‚Р Р…Р В°РЎвЂљР С‘Р Р†Р Р…Р С•Р Вµ Р С‘Р СРЎРЏ)
	for base_name in ANIMATION_NAME_MAPPING:
		if requested_name in ANIMATION_NAME_MAPPING[base_name]:
			if frames.has_animation(base_name):
				return base_name
			for alt_name in ANIMATION_NAME_MAPPING[base_name]:
				if frames.has_animation(alt_name):
					return alt_name
	
	# Р С’Р Р…Р С‘Р СР В°РЎвЂ Р С‘РЎРЏ Р Р…Р Вµ Р Р…Р В°Р в„–Р Т‘Р ВµР Р…Р В°
	return ""


func get_available_animations() -> Array:
	"""Р вЂ™Р С•Р В·Р Р†РЎР‚Р В°РЎвЂ°Р В°Р ВµРЎвЂљ РЎРѓР С—Р С‘РЎРѓР С•Р С” Р Т‘Р С•РЎРѓРЎвЂљРЎС“Р С—Р Р…РЎвЂ№РЎвЂ¦ Р В°Р Р…Р С‘Р СР В°РЎвЂ Р С‘Р в„–"""
	if animated_sprite and animated_sprite.sprite_frames:
		return animated_sprite.sprite_frames.get_animation_names()
	return []


# ===========================================
# Р вЂР С›Р вЂўР вЂ™Р С’Р Р‡ Р РЋР ВР РЋР СћР вЂўР СљР С’
# ===========================================

func attack():
	"""Р вЂР В°Р В·Р С•Р Р†Р В°РЎРЏ Р В°РЎвЂљР В°Р С”Р В° - Р СР С•Р В¶Р ВµРЎвЂљ Р В±РЎвЂ№РЎвЂљРЎРЉ Р С—Р ВµРЎР‚Р ВµР С•Р С—РЎР‚Р ВµР Т‘Р ВµР В»Р ВµР Р…Р В° Р Р† Р Т‘Р С•РЎвЂЎР ВµРЎР‚Р Р…Р С‘РЎвЂ¦ Р С”Р В»Р В°РЎРѓРЎРѓР В°РЎвЂ¦"""
	if is_dead or is_attacking or is_blocking or is_casting or is_sliding or is_crouching or is_inventory_open:
		return
	
	is_attacking = true
	attack_combo += 1
	
	play_animation("attack")
	
	# Р вЂ“Р Т‘РЎвЂР С Р В·Р В°Р Р†Р ВµРЎР‚РЎв‚¬Р ВµР Р…Р С‘РЎРЏ Р В°Р Р…Р С‘Р СР В°РЎвЂ Р С‘Р С‘
	if animated_sprite:
		await animated_sprite.animation_finished
	
	is_attacking = false
	handle_animations()


func take_damage(amount: int, damage_type: String = "physical", source: String = "Р СњР ВµР С‘Р В·Р Р†Р ВµРЎРѓРЎвЂљР Р…Р С•"):
	"""
	Р СџР С•Р В»РЎС“РЎвЂЎР ВµР Р…Р С‘Р Вµ РЎС“РЎР‚Р С•Р Р…Р В°.
	
	Р СџР В°РЎР‚Р В°Р СР ВµРЎвЂљРЎР‚РЎвЂ№:
		amount - Р С”Р С•Р В»Р С‘РЎвЂЎР ВµРЎРѓРЎвЂљР Р†Р С• РЎС“РЎР‚Р С•Р Р…Р В°
		damage_type - РЎвЂљР С‘Р С— РЎС“РЎР‚Р С•Р Р…Р В° ("physical", "magical", "true")
		source - Р С‘РЎРѓРЎвЂљР С•РЎвЂЎР Р…Р С‘Р С” РЎС“РЎР‚Р С•Р Р…Р В° (Р Т‘Р В»РЎРЏ РЎРѓРЎвЂљР В°РЎвЂљР С‘РЎРѓРЎвЂљР С‘Р С”Р С‘)
	
	Р вЂ™Р С’Р вЂ“Р СњР С›: Р СџРЎР‚Р С‘ Р С—Р ВµРЎР‚Р ВµР С•Р С—РЎР‚Р ВµР Т‘Р ВµР В»Р ВµР Р…Р С‘Р С‘ Р Р† Р Т‘Р С•РЎвЂЎР ВµРЎР‚Р Р…Р С‘РЎвЂ¦ Р С”Р В»Р В°РЎРѓРЎРѓР В°РЎвЂ¦ РЎРѓР С•РЎвЂ¦РЎР‚Р В°Р Р…РЎРЏР в„–РЎвЂљР Вµ РЎРѓР С‘Р С–Р Р…Р В°РЎвЂљРЎС“РЎР‚РЎС“!
	"""
	if is_dead or is_invincible:
		return
	
	# Р вЂ”Р В°Р С—Р С•Р СР С‘Р Р…Р В°Р ВµР С Р С‘РЎРѓРЎвЂљР С•РЎвЂЎР Р…Р С‘Р С” РЎС“РЎР‚Р С•Р Р…Р В°
	last_damage_source = source
	
	# Р В Р В°РЎРѓРЎвЂЎРЎвЂРЎвЂљ РЎС“РЎР‚Р С•Р Р…Р В° РЎРѓ РЎС“РЎвЂЎРЎвЂРЎвЂљР С•Р С Р В±РЎР‚Р С•Р Р…Р С‘
	var reduced_amount = max(1, amount - armor)
	current_health -= reduced_amount
	current_health = max(0, current_health)
	
	# Р С›РЎвЂљР С—РЎР‚Р В°Р Р†Р В»РЎРЏР ВµР С РЎРѓР С‘Р С–Р Р…Р В°Р В»
	health_changed.emit(current_health)
	
	
	# Р С›Р В±Р Р…Р С•Р Р†Р В»РЎРЏР ВµР С РЎРѓРЎвЂљР В°РЎвЂљР С‘РЎРѓРЎвЂљР С‘Р С”РЎС“
	if Global and Global.has_method("add_damage_taken"):
		Global.add_damage_taken(reduced_amount)
	
	# Р вЂ™Р С‘Р В·РЎС“Р В°Р В»РЎРЉР Р…РЎвЂ№Р в„– РЎРЊРЎвЂћРЎвЂћР ВµР С”РЎвЂљ
	_show_damage_effect()
	
	# Р СџРЎР‚Р С•Р Р†Р ВµРЎР‚Р С”Р В° РЎРѓР СР ВµРЎР‚РЎвЂљР С‘
	if current_health <= 0:
		die()


# ===========================================
# Р РЋР ВР РЋР СћР вЂўР СљР С’ Р РЋР СљР вЂўР В Р СћР В Р В Р вЂ™Р С›Р вЂ”Р В Р С›Р вЂ“Р вЂќР вЂўР СњР ВР Р‡
# ===========================================

func die():
	"""Р РЋР СР ВµРЎР‚РЎвЂљРЎРЉ Р С—Р ВµРЎР‚РЎРѓР С•Р Р…Р В°Р В¶Р В°"""
	if is_dead:
		return
	
	is_dead = true
	
	# Р С›РЎРѓРЎвЂљР В°Р Р…Р В°Р Р†Р В»Р С‘Р Р†Р В°Р ВµР С Р Т‘Р Р†Р С‘Р В¶Р ВµР Р…Р С‘Р Вµ
	velocity = Vector2.ZERO
	
	# Р С›РЎвЂљР С”Р В»РЎР‹РЎвЂЎР В°Р ВµР С Р С”Р С•Р В»Р В»Р С‘Р В·Р С‘Р С‘
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	# Р С›РЎвЂљР С—РЎР‚Р В°Р Р†Р В»РЎРЏР ВµР С РЎРѓР С‘Р С–Р Р…Р В°Р В»
	died.emit()
	
	# Р С›Р В±Р Р…Р С•Р Р†Р В»РЎРЏР ВµР С РЎРѓРЎвЂљР В°РЎвЂљР С‘РЎРѓРЎвЂљР С‘Р С”РЎС“
	if Global and Global.has_method("set_death_reason"):
		Global.set_death_reason(last_damage_source)
	
	# Р СџРЎР‚Р С•Р С‘Р С–РЎР‚РЎвЂ№Р Р†Р В°Р ВµР С Р В°Р Р…Р С‘Р СР В°РЎвЂ Р С‘РЎР‹ РЎРѓР СР ВµРЎР‚РЎвЂљР С‘
	play_animation("death")
	
	# Р вЂ“Р Т‘РЎвЂР С Р В·Р В°Р Р†Р ВµРЎР‚РЎв‚¬Р ВµР Р…Р С‘РЎРЏ Р В°Р Р…Р С‘Р СР В°РЎвЂ Р С‘Р С‘
	if animated_sprite:
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(1.0).timeout
	
	# Р РЋР С”РЎР‚РЎвЂ№Р Р†Р В°Р ВµР С Р С‘Р С–РЎР‚Р С•Р С”Р В°
	visible = false
	
	# Р С›РЎвЂљР С”Р В»РЎР‹РЎвЂЎР В°Р ВµР С Р С”Р С•Р В»Р В»Р С‘Р В·Р С‘РЎР‹
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	# Р СџР С•Р С”Р В°Р В·РЎвЂ№Р Р†Р В°Р ВµР С Р СР ВµР Р…РЎР‹ РЎРѓР СР ВµРЎР‚РЎвЂљР С‘
	_show_death_menu()


func _show_death_menu():
	"""Р СџР С•Р С”Р В°Р В·РЎвЂ№Р Р†Р В°Р ВµРЎвЂљ Р СР ВµР Р…РЎР‹ РЎРѓР СР ВµРЎР‚РЎвЂљР С‘"""
	
	# Р СџР С•Р В»РЎС“РЎвЂЎР В°Р ВµР С РЎРѓРЎвЂљР В°РЎвЂљР С‘РЎРѓРЎвЂљР С‘Р С”РЎС“
	var stats = {}
	if Global and Global.has_method("get_run_statistics"):
		stats = Global.get_run_statistics()
	
	# Р СџРЎР‚Р С•Р Р†Р ВµРЎР‚РЎРЏР ВµР С Р В°РЎР‚РЎвЂљР ВµРЎвЂћР В°Р С”РЎвЂљ Р Р†Р С•Р В·РЎР‚Р С•Р В¶Р Т‘Р ВµР Р…Р С‘РЎРЏ
	var revival_artifact = ""
	if Global and Global.has_method("get_revival_artifact"):
		revival_artifact = Global.get_revival_artifact()
	
	# Р ВРЎвЂ°Р ВµР С Р С‘Р В»Р С‘ РЎРѓР С•Р В·Р Т‘Р В°РЎвЂР С Р СР ВµР Р…РЎР‹ РЎРѓР СР ВµРЎР‚РЎвЂљР С‘
	var death_menu = get_tree().get_first_node_in_group("death_menu")
	
	if not death_menu:
		var death_menu_scene = load("res://scenes/ui/death_menu.tscn")
		if death_menu_scene:
			death_menu = death_menu_scene.instantiate()
			death_menu.add_to_group("death_menu")
			get_tree().current_scene.add_child(death_menu)
	
	if death_menu:
		# Р СџР С•Р Т‘Р С”Р В»РЎР‹РЎвЂЎР В°Р ВµР С РЎРѓР С‘Р С–Р Р…Р В°Р В» Р Р†Р С•Р В·РЎР‚Р С•Р В¶Р Т‘Р ВµР Р…Р С‘РЎРЏ
		if death_menu.has_signal("revive_requested"):
			if not death_menu.revive_requested.is_connected(_on_revive_requested):
				death_menu.revive_requested.connect(_on_revive_requested)
		
		# Р СџР С•Р С”Р В°Р В·РЎвЂ№Р Р†Р В°Р ВµР С Р СР ВµР Р…РЎР‹
		if death_menu.has_method("show_death_menu"):
			death_menu.show_death_menu(stats, revival_artifact)


func _on_revive_requested(_data: Dictionary):
	"""Р С›Р В±РЎР‚Р В°Р В±Р С•РЎвЂљР С”Р В° Р Р†Р С•Р В·РЎР‚Р С•Р В¶Р Т‘Р ВµР Р…Р С‘РЎРЏ Р С‘Р В· Р СР ВµР Р…РЎР‹ РЎРѓР СР ВµРЎР‚РЎвЂљР С‘"""
	
	if Global and Global.has_method("use_revival_artifact"):
		Global.use_revival_artifact()
	
	revive()


func revive():
	"""Р вЂ™Р С•Р В·РЎР‚Р С•Р В¶Р Т‘Р В°Р ВµРЎвЂљ Р С—Р ВµРЎР‚РЎРѓР С•Р Р…Р В°Р В¶Р В°"""
	
	is_dead = false
	visible = true
	
	# Р вЂ™Р С•РЎРѓРЎРѓРЎвЂљР В°Р Р…Р В°Р Р†Р В»Р С‘Р Р†Р В°Р ВµР С Р В·Р Т‘Р С•РЎР‚Р С•Р Р†РЎРЉР Вµ (50%)
	current_health = max_health / 2
	health_changed.emit(current_health)
	
	# Р вЂ™Р С”Р В»РЎР‹РЎвЂЎР В°Р ВµР С Р С”Р С•Р В»Р В»Р С‘Р В·Р С‘РЎР‹
	if collision_shape:
		collision_shape.disabled = false
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	
	# Р СџР ВµРЎР‚Р ВµР СР ВµРЎвЂ°Р В°Р ВµР С Р Р…Р В° РЎвЂљР С•РЎвЂЎР С”РЎС“ РЎРѓР С—Р В°Р Р†Р Р…Р В°
	var current_scene: Node = get_tree().current_scene
	var player_spawn: Node2D = current_scene.get_node_or_null("World/Markers/PlayerSpawn") as Node2D
	if player_spawn == null:
		player_spawn = current_scene.get_node_or_null("PlayerSpawn") as Node2D
	if player_spawn:
		global_position = player_spawn.global_position
	
	# Р вЂ™Р С•РЎРѓРЎРѓРЎвЂљР В°Р Р…Р В°Р Р†Р В»Р С‘Р Р†Р В°Р ВµР С Р Р†Р С‘Р В·РЎС“Р В°Р В»
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE
		play_animation("idle")
	
	# Р вЂ™РЎР‚Р ВµР СР ВµР Р…Р Р…Р В°РЎРЏ Р Р…Р ВµРЎС“РЎРЏР В·Р Р†Р С‘Р СР С•РЎРѓРЎвЂљРЎРЉ
	clear_madness_stacks()
	give_temporary_invincibility(3.0)
	
	revived.emit()



func set_madness_stacks(value: int) -> void:
	var clamped_value: int = clampi(value, 0, max_madness_stacks)
	madness_stacks = clamped_value
	madness_changed.emit(madness_stacks, max_madness_stacks)


func add_madness_stacks(amount: int = 1, source: String = "Р‘РµР·СѓРјРёРµ") -> void:
	if is_dead or amount <= 0:
		return

	set_madness_stacks(madness_stacks + amount)
	if madness_stacks >= max_madness_stacks:
		last_damage_source = source
		die()


func clear_madness_stacks(amount: int = -1) -> void:
	if amount < 0:
		set_madness_stacks(0)
		return

	set_madness_stacks(madness_stacks - amount)


func apply_effect_template(effect_id: String, payload: Dictionary = {}) -> bool:
	var template: Dictionary = EffectTemplateLibrary.get_template(effect_id)
	if template.is_empty():
		return false

	var effect_type: String = String(payload.get("type", template.get("type", "")))
	match effect_type:
		"apply_madness":
			var chance_value: float = _normalize_effect_chance(payload.get("chance", template.get("chance", 1.0)))
			if chance_value <= 0.0:
				return false
			if chance_value < 1.0 and randf() > chance_value:
				return false

			var power: int = maxi(1, int(payload.get("power", template.get("power", 1))))
			var max_stacks_override: int = int(payload.get("max_stacks", template.get("max_stacks", max_madness_stacks)))
			if max_stacks_override > 0:
				max_madness_stacks = max_stacks_override

			var source: String = String(payload.get("source", "Р‘РµР·СѓРјРёРµ"))
			add_madness_stacks(power, source)
			return true
		"cure_madness":
			var cure_power: int = maxi(1, int(payload.get("power", template.get("power", 1))))
			clear_madness_stacks(cure_power)
			return true
		_:
			return false


func _normalize_effect_chance(raw_chance: Variant) -> float:
	var chance: float = float(raw_chance)
	if chance > 1.0:
		chance /= 100.0
	return clampf(chance, 0.0, 1.0)
func give_temporary_invincibility(duration: float):
	"""Р вЂќР В°РЎвЂРЎвЂљ Р Р†РЎР‚Р ВµР СР ВµР Р…Р Р…РЎС“РЎР‹ Р Р…Р ВµРЎС“РЎРЏР В·Р Р†Р С‘Р СР С•РЎРѓРЎвЂљРЎРЉ"""
	is_invincible = true
	
	await get_tree().create_timer(duration).timeout
	
	is_invincible = false
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE


# ===========================================
# Р вЂР С’Р вЂ”Р С›Р вЂ™Р В«Р вЂў Р РЋР СџР С›Р РЋР С›Р вЂР СњР С›Р РЋР СћР В (Р С—Р ВµРЎР‚Р ВµР С•Р С—РЎР‚Р ВµР Т‘Р ВµР В»РЎРЏРЎР‹РЎвЂљРЎРѓРЎРЏ Р Р† Р Т‘Р С•РЎвЂЎР ВµРЎР‚Р Р…Р С‘РЎвЂ¦ Р С”Р В»Р В°РЎРѓРЎРѓР В°РЎвЂ¦)
# ===========================================

func heal():
	pass

func slide():
	pass

func block():
	"""Р вЂР В°Р В·Р С•Р Р†РЎвЂ№Р в„– Р В±Р В»Р С•Р С” - Р С—Р ВµРЎР‚Р ВµР С•Р С—РЎР‚Р ВµР Т‘Р ВµР В»РЎРЏР ВµРЎвЂљРЎРѓРЎРЏ Р Р† warrior_player.gd"""
	pass


func stop_blocking():
	"""Р СџРЎР‚Р ВµР С”РЎР‚Р В°РЎвЂ°Р ВµР Р…Р С‘Р Вµ Р В±Р В»Р С•Р С”Р В° - Р С—Р ВµРЎР‚Р ВµР С•Р С—РЎР‚Р ВµР Т‘Р ВµР В»РЎРЏР ВµРЎвЂљРЎРѓРЎРЏ Р Р† warrior_player.gd"""
	pass


# ===========================================
# Р Р€Р СџР В Р С’Р вЂ™Р вЂєР вЂўР СњР ВР вЂў Р ВР СњР вЂ™Р вЂўР СњР СћР С’Р В Р РѓР Сљ (Р В±Р В»Р С•Р С”Р С‘РЎР‚Р С•Р Р†Р С”Р В° Р С‘Р С–РЎР‚Р С•Р С”Р В°)
# ===========================================

func set_inventory_open(open: bool):
	"""Р Р€РЎРѓРЎвЂљР В°Р Р…Р В°Р Р†Р В»Р С‘Р Р†Р В°Р ВµРЎвЂљ РЎРѓР С•РЎРѓРЎвЂљР С•РЎРЏР Р…Р С‘Р Вµ Р С‘Р Р…Р Р†Р ВµР Р…РЎвЂљР В°РЎР‚РЎРЏ - Р В±Р В»Р С•Р С”Р С‘РЎР‚РЎС“Р ВµРЎвЂљ/РЎР‚Р В°Р В·Р В±Р В»Р С•Р С”Р С‘РЎР‚РЎС“Р ВµРЎвЂљ Р С‘Р С–РЎР‚Р С•Р С”Р В°"""
	is_inventory_open = open
	
	if open:
		# Р СџРЎР‚Р С‘ Р С•РЎвЂљР С”РЎР‚РЎвЂ№РЎвЂљР С‘Р С‘ Р С‘Р Р…Р Р†Р ВµР Р…РЎвЂљР В°РЎР‚РЎРЏ Р С•РЎРѓРЎвЂљР В°Р Р…Р В°Р Р†Р В»Р С‘Р Р†Р В°Р ВµР С Р Т‘Р Р†Р С‘Р В¶Р ВµР Р…Р С‘Р Вµ
		velocity.x = 0
		# Р СџРЎР‚Р ВµРЎР‚РЎвЂ№Р Р†Р В°Р ВµР С Р В°РЎвЂљР В°Р С”РЎС“ Р ВµРЎРѓР В»Р С‘ Р С•Р Р…Р В° Р В±РЎвЂ№Р В»Р В°
		if is_attacking:
			is_attacking = false
		# Р С›РЎвЂљР СР ВµР Р…РЎРЏР ВµР С Р С—РЎР‚Р С‘РЎРѓР ВµР Т‘Р В°Р Р…Р С‘Р Вµ
		if is_crouching:
			stop_crouch()
		# Р С›РЎвЂљР СР ВµР Р…РЎРЏР ВµР С Р В±Р В»Р С•Р С”
		if is_blocking:
			stop_blocking()
