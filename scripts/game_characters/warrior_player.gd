extends "res://scripts/game_characters/base_game_character.gd"

enum BlockPhase { NONE, STARTUP, ACTIVE, RECOVERY }
enum CrouchPhase { NONE, STARTUP, ACTIVE, RECOVERY }

enum HitReaction { LIGHT, HURT, HEAVY }

const BASE_DAMAGE: int = 2
const ATTACK_RANGE: float = 60.0
const COUNTER_ATTACK_RANGE: float = 68.0
const ATTACK_DAMAGE_FRAME: int = 3
const COUNTER_DAMAGE_FRAME: int = 4
const COUNTER_DAMAGE_MULTIPLIER: float = 1.8
const BACKSTAB_STAGGER_DURATION: float = 0.45
const BACKSTAB_KNOCKDOWN_DURATION: float = 0.95
const COUNTER_STAGGER_DURATION: float = 0.35
const COUNTER_WINDOW_TIME: float = 0.9

const SNEAK_SPEED_MULTIPLIER: float = 0.62

const CROUCH_STARTUP_TIME: float = 0.18
const CROUCH_ACTIVE_TIME: float = 0.22
const CROUCH_RECOVERY_TIME: float = 0.10
const CROUCH_COOLDOWN_TIME: float = 0.20

const BLOCK_STARTUP_TIME: float = 0.12
const BLOCK_ACTIVE_TIME: float = 0.32
const BLOCK_RECOVERY_TIME: float = 0.24
const BLOCK_COOLDOWN_TIME: float = 2.0
const BLOCK_EARLY_GRACE_TIME: float = 0.08
const BLOCK_SUCCESS_STUN_DURATION: float = 1.6
const BLOCK_SOUND_PATH: String = "res://sounds/players/block1-shield.mp3"
const BLOCK_ICON_PATH: String = "res://assets/Spell/shield_defence.png"
const SLIDE_ICON_PATH: String = "res://assets/Spell/Icon43.png"
const BLOCK_LIGHT_THRESHOLD: int = 4
const BLOCK_MEDIUM_THRESHOLD: int = 6

const SLIDE_TOTAL_DURATION: float = 0.68
const SLIDE_STARTUP_TIME: float = 0.10
const SLIDE_IFRAME_TIME: float = 0.28
const SLIDE_COOLDOWN_TIME: float = 1.5
const SLIDE_SPEED_MULTIPLIER: float = 3.0
const ENEMY_COLLISION_LAYER_BIT: int = 4
const SLIDE_CORE_POSE_START_TIME: float = 0.16
const SLIDE_CORE_POSE_TOGGLE_TIME: float = 0.09

const LIGHT_HIT_LOCK: float = 0.08
const HURT_LOCK: float = 0.20
const HEAVY_LOCK: float = 0.48
const MEDIUM_HURT_SPEED_SCALE: float = 1.75
const HEAVY_HURT_SPEED_SCALE: float = 1.0
const HEAVY_PUSHBACK: float = 210.0
const HEAVY_PUSHBACK_DECAY: float = 520.0

var warrior_base_armor: int = 2
var base_armor: int = 2
var equipment_armor_bonus: int = 0
var potion_armor_bonus: int = 0
var block_armor_bonus: int = 0

var block_cooldown: float = 0.0
var block_phase: int = BlockPhase.NONE
var block_phase_timer: float = 0.0
var is_block_active: bool = false

var counter_window_timer: float = 0.0
var is_counter_attack_ready: bool = false

var slide_cooldown: float = 0.0
var slide_timer: float = 0.0
var slide_direction: float = 1.0
var slide_iframe_active: bool = false
var default_collision_mask: int = 0
var default_collision_layer: int = 0
var slide_enemy_collision_disabled: bool = false
var last_incoming_attacker: Node2D = null
var block_audio_player: AudioStreamPlayer2D = null

var reaction_lock_timer: float = 0.0
var current_hit_reaction: int = HitReaction.LIGHT
var hurt_animation_speed_scale: float = 1.0
var is_sneaking: bool = false
var sneak_mode_enabled: bool = false
var crouch_phase: int = CrouchPhase.NONE
var crouch_phase_timer: float = 0.0
var crouch_cooldown: float = 0.0

var _attack_damage_dealt: bool = false
var _current_attack_animation: String = "attack"
var _current_attack_damage_multiplier: float = 1.0
var _current_attack_stagger_duration: float = 0.0
var _current_attack_started_from_sneak: bool = false


func _ready() -> void:
	character_name = "Воин"
	max_health = 100
	current_health = 100
	max_mana = 0
	current_mana = 0
	warrior_base_armor = 2
	armor = warrior_base_armor
	base_armor = warrior_base_armor
	current_damage = BASE_DAMAGE
	base_speed = 180
	current_speed = 180
	max_speed = 180.0
	jump_velocity = -350.0
	super()
	default_collision_mask = collision_mask
	default_collision_layer = collision_layer
	_setup_block_audio()
	_configure_skill_ui()
	_update_block_cooldown_ui()


func _physics_process(delta: float) -> void:
	if block_cooldown > 0.0:
		block_cooldown = maxf(0.0, block_cooldown - delta)

	if slide_cooldown > 0.0:
		slide_cooldown = maxf(0.0, slide_cooldown - delta)

	if crouch_cooldown > 0.0:
		crouch_cooldown = maxf(0.0, crouch_cooldown - delta)

	if counter_window_timer > 0.0:
		counter_window_timer = maxf(0.0, counter_window_timer - delta)
		if counter_window_timer <= 0.0:
			is_counter_attack_ready = false

	if reaction_lock_timer > 0.0:
		reaction_lock_timer = maxf(0.0, reaction_lock_timer - delta)
		if reaction_lock_timer <= 0.0:
			is_hurt = false
			hurt_animation_speed_scale = 1.0
			if animated_sprite:
				animated_sprite.speed_scale = 1.0

	_update_block_state(delta)
	_update_slide_state(delta)
	_update_crouch_state(delta)
	_update_block_cooldown_ui()

	super(delta)


func handle_movement(delta: float) -> void:
	if is_inventory_open:
		_cancel_sneak_mode()
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		return

	var direction: float = Input.get_axis("move_left", "move_right")
	var is_jumping: bool = Input.is_action_just_pressed("jump")
	var crouch_pressed: bool = Input.is_action_just_pressed("crouch")

	if Input.is_action_just_pressed("sneak_toggle"):
		_toggle_sneak_mode()

	if reaction_lock_timer > 0.0:
		_cancel_sneak_mode()
		if current_hit_reaction == HitReaction.HEAVY:
			velocity.x = move_toward(velocity.x, 0.0, HEAVY_PUSHBACK_DECAY * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta * 0.75)
		return

	if is_attacking or block_phase != BlockPhase.NONE or (is_casting and not is_using_consumable):
		_cancel_sneak_mode()
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		return

	if crouch_pressed:
		_start_crouch_action()

	if crouch_phase != CrouchPhase.NONE:
		_cancel_sneak_mode()
		velocity.x = move_toward(velocity.x, 0.0, friction * delta * 1.2)
		return

	if is_sliding:
		var slide_progress: float = 1.0 - (slide_timer / SLIDE_TOTAL_DURATION)
		var slide_speed: float = lerpf(current_speed * SLIDE_SPEED_MULTIPLIER, current_speed * 1.05, slide_progress)
		velocity.x = slide_direction * slide_speed
		return

	is_sneaking = sneak_mode_enabled and is_on_floor() and direction != 0.0 and not is_blocking and not is_attacking and not is_using_consumable

	if direction != 0.0:
		var target_speed: float = current_speed
		if is_sneaking:
			target_speed *= SNEAK_SPEED_MULTIPLIER
		if is_using_consumable:
			target_speed *= consumable_move_speed_multiplier
		velocity.x = move_toward(velocity.x, direction * target_speed, acceleration * delta)
		if animated_sprite:
			animated_sprite.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	if is_jumping and not is_blocking and not is_using_consumable:
		_cancel_sneak_mode()
		if is_on_floor() or coyote_timer > 0.0:
			velocity.y = jump_velocity
			can_double_jump = enable_double_jump
			has_double_jumped = false
			coyote_timer = 0.0
		elif enable_double_jump and can_double_jump and not has_double_jumped:
			velocity.y = jump_velocity * 0.8
			has_double_jumped = true
			can_double_jump = false
			_show_double_jump_effect()


func handle_animations() -> void:
	if not animated_sprite:
		return

	if is_dead:
		play_animation("death")
		return

	if is_attacking:
		return

	if is_hurt:
		if animated_sprite:
			animated_sprite.speed_scale = hurt_animation_speed_scale
		play_animation("hurt")
		return

	if animated_sprite:
		animated_sprite.speed_scale = 1.0

	if crouch_phase != CrouchPhase.NONE:
		play_animation("crouch")
		if crouch_phase == CrouchPhase.ACTIVE:
			_hold_crouch_pose_frame()
		return

	if is_sliding:
		_update_slide_visual()
		return

	if block_phase != BlockPhase.NONE:
		play_animation("shield_defence")
		if block_phase == BlockPhase.ACTIVE:
			_hold_block_pose_frame()
		return

	if is_sneaking and is_on_floor() and absf(velocity.x) > 5.0:
		play_animation("Sneaking around")
		return

	if not is_on_floor():
		if velocity.y < 0.0:
			play_animation("jump")
		else:
			play_animation("fall")
		return

	if absf(velocity.x) > 10.0:
		play_animation("run")
	else:
		play_animation("idle")


func use_special_ability() -> void:
	if is_dead or is_attacking or is_casting or is_sliding or is_hurt:
		return
	if block_phase != BlockPhase.NONE or block_cooldown > 0.0 or crouch_phase != CrouchPhase.NONE:
		return
	block()


func block() -> void:
	_cancel_sneak_mode()
	is_blocking = true
	is_block_active = false
	block_phase = BlockPhase.STARTUP
	block_phase_timer = BLOCK_STARTUP_TIME
	velocity.x = 0.0
	play_animation("shield_defence")
	if animated_sprite:
		animated_sprite.play()


func stop_blocking() -> void:
	_finish_block_sequence(true)


func attack() -> void:
	if is_dead or is_casting or is_sliding or is_inventory_open:
		return
	if block_phase != BlockPhase.NONE or is_hurt or is_attacking or crouch_phase != CrouchPhase.NONE:
		return

	var use_counter: bool = is_counter_attack_ready and counter_window_timer > 0.0
	_current_attack_started_from_sneak = is_sneaking
	_cancel_sneak_mode()
	is_attacking = true
	_attack_damage_dealt = false

	if use_counter:
		_current_attack_animation = "attack2"
		_current_attack_damage_multiplier = COUNTER_DAMAGE_MULTIPLIER
		_current_attack_stagger_duration = COUNTER_STAGGER_DURATION
		is_counter_attack_ready = false
		counter_window_timer = 0.0
	else:
		_current_attack_animation = "attack"
		_current_attack_damage_multiplier = 1.0
		_current_attack_stagger_duration = 0.0

	play_animation(_current_attack_animation)
	if animated_sprite and not animated_sprite.frame_changed.is_connected(_on_attack_frame):
		animated_sprite.frame_changed.connect(_on_attack_frame)

	if animated_sprite:
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(0.45).timeout

	if animated_sprite and animated_sprite.frame_changed.is_connected(_on_attack_frame):
		animated_sprite.frame_changed.disconnect(_on_attack_frame)

	is_attacking = false
	_current_attack_started_from_sneak = false
	handle_animations()


func slide() -> void:
	if is_dead or is_attacking or is_casting or is_hurt:
		return
	if is_sliding or block_phase != BlockPhase.NONE or slide_cooldown > 0.0 or crouch_phase != CrouchPhase.NONE:
		return
	if not is_on_floor():
		return

	_cancel_sneak_mode()
	is_sliding = true
	slide_timer = SLIDE_TOTAL_DURATION
	slide_iframe_active = false
	_set_enemy_slide_collision_enabled(false)

	var input_direction: float = Input.get_axis("move_left", "move_right")
	if input_direction == 0.0:
		slide_direction = -1.0 if animated_sprite and animated_sprite.flip_h else 1.0
	else:
		slide_direction = signf(input_direction)
		if animated_sprite:
			animated_sprite.flip_h = slide_direction < 0.0

	_update_slide_visual()


func take_damage(amount: int, damage_type: String = "physical", source: String = "Неизвестно", reaction_hint: String = "") -> void:
	if is_dead:
		return
	if slide_iframe_active:
		return

	last_damage_source = source

	var incoming_amount: int = max(0, amount)
	var was_successfully_blocked: bool = _can_successfully_block()
	if was_successfully_blocked:
		incoming_amount = _resolve_blocked_damage(incoming_amount)
		_register_successful_block()
		if incoming_amount <= 0:
			_show_block_flash()
			return

	var final_damage: int = incoming_amount
	if damage_type == "magical":
		final_damage -= int(armor * 0.5)
	elif damage_type != "true":
		final_damage -= armor
	final_damage = max(1, final_damage)

	current_health = max(0, current_health - final_damage)
	if Global and Global.has_method("add_damage_taken"):
		Global.add_damage_taken(final_damage)
	health_changed.emit(current_health)
	_show_damage_effect()
	var reaction_type: int = _classify_hit_reaction(final_damage, reaction_hint)
	_apply_hit_reaction(reaction_type)
	damage_received.emit(final_damage, _reaction_type_to_tag(reaction_type))

	if current_health <= 0:
		die()


func recalculate_armor() -> void:
	armor = warrior_base_armor + equipment_armor_bonus + potion_armor_bonus + block_armor_bonus
	base_armor = warrior_base_armor + equipment_armor_bonus


func set_equipment_armor(bonus: int) -> void:
	equipment_armor_bonus = bonus
	recalculate_armor()


func set_potion_armor(bonus: int) -> void:
	potion_armor_bonus = bonus
	recalculate_armor()


func add_potion_armor(bonus: int) -> void:
	potion_armor_bonus += bonus
	recalculate_armor()


func reset_potion_bonuses() -> void:
	potion_armor_bonus = 0
	recalculate_armor()


func is_hidden_from_enemy(enemy: Node2D) -> bool:
	if not is_sneaking or enemy == null:
		return false
	return _is_behind_target(enemy)


func _update_block_state(delta: float) -> void:
	if block_phase == BlockPhase.NONE:
		return

	block_phase_timer = maxf(0.0, block_phase_timer - delta)

	match block_phase:
		BlockPhase.STARTUP:
			if block_phase_timer <= 0.0:
				block_phase = BlockPhase.ACTIVE
				block_phase_timer = BLOCK_ACTIVE_TIME
				is_block_active = true
				_hold_block_pose_frame()
		BlockPhase.ACTIVE:
			_hold_block_pose_frame()
			if block_phase_timer <= 0.0:
				block_phase = BlockPhase.RECOVERY
				block_phase_timer = BLOCK_RECOVERY_TIME
				is_block_active = false
		BlockPhase.RECOVERY:
			if block_phase_timer <= 0.0:
				_finish_block_sequence(false)


func _update_slide_state(delta: float) -> void:
	if not is_sliding:
		slide_iframe_active = false
		_set_enemy_slide_collision_enabled(true)
		return

	slide_timer = maxf(0.0, slide_timer - delta)
	var elapsed: float = SLIDE_TOTAL_DURATION - slide_timer
	slide_iframe_active = elapsed >= SLIDE_STARTUP_TIME and elapsed < (SLIDE_STARTUP_TIME + SLIDE_IFRAME_TIME)

	if slide_timer <= 0.0:
		is_sliding = false
		slide_iframe_active = false
		slide_cooldown = SLIDE_COOLDOWN_TIME
		_set_enemy_slide_collision_enabled(true)


func _finish_block_sequence(force_cooldown: bool) -> void:
	if block_phase == BlockPhase.NONE and not force_cooldown:
		return

	is_blocking = false
	is_block_active = false
	block_phase = BlockPhase.NONE
	block_phase_timer = 0.0
	if force_cooldown or block_cooldown <= 0.0:
		block_cooldown = BLOCK_COOLDOWN_TIME
func _set_enemy_slide_collision_enabled(enabled: bool) -> void:
	if enabled:
		if slide_enemy_collision_disabled:
			collision_mask = default_collision_mask
			collision_layer = default_collision_layer
			slide_enemy_collision_disabled = false
		return

	default_collision_mask = collision_mask
	default_collision_layer = collision_layer
	collision_mask = collision_mask & ~ENEMY_COLLISION_LAYER_BIT
	collision_layer = 0
	slide_enemy_collision_disabled = true


func _can_successfully_block() -> bool:
	if not _is_attack_in_front():
		return false
	if block_phase == BlockPhase.ACTIVE and is_block_active:
		return true
	if block_phase == BlockPhase.STARTUP and block_phase_timer <= BLOCK_EARLY_GRACE_TIME:
		return true
	return false


func _is_attack_in_front() -> bool:
	if last_incoming_attacker == null or not is_instance_valid(last_incoming_attacker):
		return true

	var relative_x: float = last_incoming_attacker.global_position.x - global_position.x
	if absf(relative_x) <= 4.0:
		return true

	var facing_dir: float = _get_facing_direction()
	return signf(relative_x) == facing_dir


func _resolve_blocked_damage(amount: int) -> int:
	if amount <= BLOCK_LIGHT_THRESHOLD:
		return 0
	if amount <= BLOCK_MEDIUM_THRESHOLD:
		return 1
	return maxi(1, int(ceil(amount * 0.4)))


func _register_successful_block() -> void:
	is_counter_attack_ready = true
	counter_window_timer = COUNTER_WINDOW_TIME
	block_phase = BlockPhase.RECOVERY
	block_phase_timer = minf(block_phase_timer, 0.12)
	is_block_active = false
	_show_block_flash()
	_play_block_success_sound()
	if last_incoming_attacker and is_instance_valid(last_incoming_attacker) and last_incoming_attacker.has_method("show_player_guard_feedback"):
		last_incoming_attacker.show_player_guard_feedback(BLOCK_SUCCESS_STUN_DURATION)
	last_incoming_attacker = null


func _classify_hit_reaction(final_damage: int, reaction_hint: String = "") -> int:
	match reaction_hint:
		"light":
			return HitReaction.LIGHT
		"hurt", "medium":
			return HitReaction.HURT
		"heavy":
			return HitReaction.HEAVY
		_:
			pass

	if final_damage <= 1:
		return HitReaction.LIGHT
	if final_damage >= 4:
		return HitReaction.HEAVY
	return HitReaction.HURT


func _apply_hit_reaction(reaction_type: int) -> void:
	current_hit_reaction = reaction_type
	match reaction_type:
		HitReaction.LIGHT:
			hurt_animation_speed_scale = 1.0
			reaction_lock_timer = maxf(reaction_lock_timer, LIGHT_HIT_LOCK)
		HitReaction.HURT:
			hurt_animation_speed_scale = MEDIUM_HURT_SPEED_SCALE
			reaction_lock_timer = maxf(reaction_lock_timer, HURT_LOCK)
			if not is_hurt:
				is_hurt = true
				play_animation("hurt")
		HitReaction.HEAVY:
			hurt_animation_speed_scale = HEAVY_HURT_SPEED_SCALE
			reaction_lock_timer = maxf(reaction_lock_timer, HEAVY_LOCK)
			if not is_hurt:
				is_hurt = true
				play_animation("hurt")
			velocity.x = _get_heavy_pushback_velocity()


func _reaction_type_to_tag(reaction_type: int) -> String:
	match reaction_type:
		HitReaction.LIGHT:
			return "light"
		HitReaction.HEAVY:
			return "heavy"
		_:
			return "hurt"


func _on_attack_frame() -> void:
	if not is_attacking or _attack_damage_dealt:
		return
	if not animated_sprite:
		return

	var target_frame: int = ATTACK_DAMAGE_FRAME
	if _current_attack_animation == "attack2":
		target_frame = COUNTER_DAMAGE_FRAME

	var frame_count: int = animated_sprite.sprite_frames.get_frame_count(animated_sprite.animation)
	target_frame = mini(target_frame, max(0, frame_count - 1))
	if animated_sprite.frame >= target_frame:
		_deal_damage_to_enemies()
		_attack_damage_dealt = true


func _deal_damage_to_enemies() -> void:
	if not animated_sprite:
		return

	var attack_dir: float = _get_facing_direction()
	var attack_range: float = ATTACK_RANGE if _current_attack_animation == "attack" else COUNTER_ATTACK_RANGE
	var center: Vector2 = global_position + Vector2(attack_range * 0.72 * attack_dir, 0.0)

	var space := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = attack_range
	query.shape = shape
	query.transform = Transform2D(0.0, center)

	for result in space.intersect_shape(query):
		var body: Node = result.get("collider")
		if body == null or body == self or not body.has_method("take_damage"):
			continue

		var damage_amount: int = maxi(1, int(round(current_damage * _current_attack_damage_multiplier)))
		if body.has_method("register_incoming_attacker"):
			body.register_incoming_attacker(self)
		body.take_damage(damage_amount, "physical")

		if Global and Global.has_method("add_damage_dealt"):
			Global.add_damage_dealt(damage_amount)

		var is_backstab: bool = _current_attack_animation == "attack" and _current_attack_started_from_sneak and _is_behind_target(body)
		if is_backstab and body.has_method("apply_backstab_knockdown"):
			body.apply_backstab_knockdown(BACKSTAB_KNOCKDOWN_DURATION, global_position.x)
		elif is_backstab and body.has_method("apply_short_stagger"):
			body.apply_short_stagger(BACKSTAB_STAGGER_DURATION, global_position.x)
		if is_backstab and body.has_method("force_alert"):
			body.force_alert(self)
		elif _current_attack_stagger_duration > 0.0 and body.has_method("apply_short_stagger"):
			body.apply_short_stagger(_current_attack_stagger_duration, global_position.x)


func _is_behind_target(target: Node) -> bool:
	if target == null or not (target is Node2D):
		return false

	var facing_dir: float = 0.0
	if target.has_method("get_facing_direction"):
		facing_dir = float(target.get_facing_direction())
	else:
		var target_sprite: AnimatedSprite2D = target.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if target_sprite == null:
			return false
		facing_dir = -1.0 if target_sprite.flip_h else 1.0

	var relative_dir: float = signf(global_position.x - (target as Node2D).global_position.x)
	if relative_dir == 0.0:
		relative_dir = -facing_dir
	return relative_dir == -facing_dir


func _get_facing_direction() -> float:
	if animated_sprite and animated_sprite.flip_h:
		return -1.0
	return 1.0


func _hold_block_pose_frame() -> void:
	if not animated_sprite or animated_sprite.sprite_frames == null:
		return
	var anim_name: String = animated_sprite.animation
	if anim_name == "":
		anim_name = "shield_defence"
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		return
	var frame_count: int = animated_sprite.sprite_frames.get_frame_count(anim_name)
	var hold_frame: int = mini(2, max(0, frame_count - 1))
	animated_sprite.stop()
	animated_sprite.frame = hold_frame


func _show_block_flash() -> void:
	if not animated_sprite:
		return
	var tween := create_tween()
	animated_sprite.modulate = Color(1.8, 1.8, 2.2, 1.0)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.12)


func _get_heavy_pushback_velocity() -> float:
	if last_incoming_attacker and is_instance_valid(last_incoming_attacker):
		var attacker_side: float = signf(last_incoming_attacker.global_position.x - global_position.x)
		if attacker_side != 0.0:
			return -attacker_side * HEAVY_PUSHBACK
	return -_get_facing_direction() * HEAVY_PUSHBACK


func register_incoming_attacker(attacker: Node2D) -> void:
	last_incoming_attacker = attacker


func apply_guard_break_stun(duration: float = 0.38) -> void:
	if is_dead:
		return
	if animated_sprite and animated_sprite.frame_changed.is_connected(_on_attack_frame):
		animated_sprite.frame_changed.disconnect(_on_attack_frame)
	_attack_damage_dealt = true
	is_attacking = false
	_cancel_sneak_mode()
	is_hurt = true
	reaction_lock_timer = maxf(reaction_lock_timer, duration)
	play_animation("hurt")


func set_consumable_use_state(active: bool, move_multiplier: float = 1.0) -> void:
	super.set_consumable_use_state(active, move_multiplier)
	if active:
		_cancel_sneak_mode()


func _setup_block_audio() -> void:
	if not ResourceLoader.exists(BLOCK_SOUND_PATH):
		return
	block_audio_player = AudioStreamPlayer2D.new()
	block_audio_player.name = "BlockAudio"
	block_audio_player.stream = load(BLOCK_SOUND_PATH)
	block_audio_player.max_distance = 1200.0
	add_child(block_audio_player)


func _play_block_success_sound() -> void:
	if block_audio_player and block_audio_player.stream:
		block_audio_player.play()


func _update_slide_visual() -> void:
	if not animated_sprite or animated_sprite.sprite_frames == null:
		return
	if not animated_sprite.sprite_frames.has_animation("sliding"):
		play_animation("sliding")
		return
	if animated_sprite.animation != "sliding":
		animated_sprite.play("sliding")

	var frame_count: int = animated_sprite.sprite_frames.get_frame_count("sliding")
	if frame_count <= 0:
		return

	var elapsed: float = SLIDE_TOTAL_DURATION - slide_timer
	animated_sprite.stop()

	if frame_count < 6:
		var normalized: float = clampf(elapsed / SLIDE_TOTAL_DURATION, 0.0, 0.999)
		animated_sprite.frame = mini(frame_count - 1, int(floor(normalized * frame_count)))
		return

	if elapsed < SLIDE_CORE_POSE_START_TIME:
		animated_sprite.frame = 3
		return

	var toggle_index: int = int(floor((elapsed - SLIDE_CORE_POSE_START_TIME) / SLIDE_CORE_POSE_TOGGLE_TIME)) % 2
	animated_sprite.frame = 4 + toggle_index


func _stop_sneak() -> void:
	_cancel_sneak_mode()


func _cancel_sneak_mode() -> void:
	sneak_mode_enabled = false
	is_sneaking = false


func _toggle_sneak_mode() -> void:
	if is_dead or is_inventory_open or is_using_consumable:
		return
	if is_attacking or is_casting or is_sliding or is_hurt:
		return
	if block_phase != BlockPhase.NONE or crouch_phase != CrouchPhase.NONE:
		return
	sneak_mode_enabled = not sneak_mode_enabled
	if not sneak_mode_enabled:
		is_sneaking = false


func _start_crouch_action() -> void:
	if is_dead or is_inventory_open or is_using_consumable:
		return
	if not is_on_floor():
		return
	if is_attacking or is_casting or is_sliding or is_hurt:
		return
	if block_phase != BlockPhase.NONE or crouch_phase != CrouchPhase.NONE:
		return
	if crouch_cooldown > 0.0:
		return

	_cancel_sneak_mode()
	is_crouching = false
	crouch_phase = CrouchPhase.STARTUP
	crouch_phase_timer = CROUCH_STARTUP_TIME
	velocity.x = 0.0
	play_animation("crouch")
	if animated_sprite:
		animated_sprite.play()


func _update_crouch_state(delta: float) -> void:
	if crouch_phase == CrouchPhase.NONE:
		is_crouching = false
		return

	crouch_phase_timer = maxf(0.0, crouch_phase_timer - delta)

	match crouch_phase:
		CrouchPhase.STARTUP:
			is_crouching = false
			if crouch_phase_timer <= 0.0:
				crouch_phase = CrouchPhase.ACTIVE
				crouch_phase_timer = CROUCH_ACTIVE_TIME
				is_crouching = true
				_hold_crouch_pose_frame()
		CrouchPhase.ACTIVE:
			is_crouching = true
			_hold_crouch_pose_frame()
			if crouch_phase_timer <= 0.0:
				crouch_phase = CrouchPhase.RECOVERY
				crouch_phase_timer = CROUCH_RECOVERY_TIME
				is_crouching = false
		CrouchPhase.RECOVERY:
			is_crouching = false
			if crouch_phase_timer <= 0.0:
				crouch_phase = CrouchPhase.NONE
				crouch_phase_timer = 0.0
				crouch_cooldown = CROUCH_COOLDOWN_TIME


func _hold_crouch_pose_frame() -> void:
	if not animated_sprite or animated_sprite.sprite_frames == null:
		return
	var anim_name: String = animated_sprite.animation
	if anim_name == "":
		anim_name = "crouch"
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		return
	var frame_count: int = animated_sprite.sprite_frames.get_frame_count(anim_name)
	var hold_frame: int = max(0, frame_count - 1)
	animated_sprite.stop()
	animated_sprite.frame = hold_frame


func _update_block_cooldown_ui() -> void:
	if Global and Global.game_ui and Global.game_ui.has_method("update_ability_cooldown"):
		var block_percent: float = 1.0
		if block_phase != BlockPhase.NONE:
			block_percent = 0.0
		elif block_cooldown > 0.0:
			block_percent = 1.0 - (block_cooldown / BLOCK_COOLDOWN_TIME)
		Global.game_ui.update_ability_cooldown("block", clampf(block_percent, 0.0, 1.0))

		var slide_percent: float = 1.0
		if is_sliding:
			slide_percent = 0.0
		elif slide_cooldown > 0.0:
			slide_percent = 1.0 - (slide_cooldown / SLIDE_COOLDOWN_TIME)
		Global.game_ui.update_ability_cooldown("slide", clampf(slide_percent, 0.0, 1.0))


func _configure_skill_ui() -> void:
	if not Global or not Global.game_ui:
		return
	if Global.game_ui.has_method("configure_ability_slot"):
		Global.game_ui.configure_ability_slot("block", "Блок", "E", BLOCK_ICON_PATH)
		Global.game_ui.configure_ability_slot("slide", "Подкат", "ПКМ", SLIDE_ICON_PATH)


func apply_artifacts() -> void:
	super.apply_artifacts()
	recalculate_armor()
