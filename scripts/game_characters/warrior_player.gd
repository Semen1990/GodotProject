extends "res://scripts/game_characters/base_game_character.gd"

const WarriorShieldRushVfxScript := preload("res://scripts/vfx/warrior_shield_rush_vfx.gd")

enum BlockPhase { NONE, STARTUP, ACTIVE, RECOVERY }
enum CrouchPhase { NONE, STARTUP, ACTIVE, RECOVERY }
enum ShieldRushPhase { NONE, APPROACH, FOLLOW_THROUGH }

enum HitReaction { LIGHT, HURT, HEAVY }

const BASE_DAMAGE: int = 2
const ATTACK_RANGE: float = 60.0
const COUNTER_ATTACK_RANGE: float = 68.0
const ENEMY_HIT_COLLISION_MASK: int = 4
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
const SHIELD_RUSH_ICON_PATH: String = "res://assets/Spell/Icon43.png"
const BLOCK_LIGHT_THRESHOLD: int = 4
const BLOCK_MEDIUM_THRESHOLD: int = 6

const SHIELD_RUSH_TRAVEL_TIME: float = 0.34
const SHIELD_RUSH_FOLLOW_THROUGH_TIME: float = 0.26
const SHIELD_RUSH_TOTAL_DURATION: float = SHIELD_RUSH_TRAVEL_TIME + SHIELD_RUSH_FOLLOW_THROUGH_TIME
const SHIELD_RUSH_COOLDOWN_TIME: float = 4.5
const SHIELD_RUSH_TRAVEL_VISUAL_FRAMES: int = 8
const SHIELD_RUSH_TOTAL_VISUAL_FRAMES: int = 13
const SHIELD_RUSH_FINAL_IMPACT_VISUAL_FRAME: int = 12
const SHIELD_RUSH_MAX_DISTANCE: float = 420.0
const SHIELD_RUSH_STOP_DISTANCE: float = 42.0
const SHIELD_RUSH_MAX_SPEED: float = 900.0
const SHIELD_RUSH_MICRO_STAGGER_DURATION: float = 0.18
const SHIELD_RUSH_FINAL_STUN_DURATION: float = 1.15
const SHIELD_RUSH_FINAL_PUSHBACK: float = 180.0
const SHIELD_RUSH_IMPACT_OFFSET_Y: float = -18.0
const ENEMY_COLLISION_LAYER_BIT: int = 4

const LIGHT_HIT_LOCK: float = 0.08
const HURT_LOCK: float = 0.20
const HEAVY_LOCK: float = 0.56
const MEDIUM_HURT_SPEED_SCALE: float = 1.75
const HEAVY_HURT_SPEED_SCALE: float = 1.0
const HEAVY_PUSHBACK: float = 360.0
const HEAVY_PUSHBACK_DECAY: float = 260.0
const HEAVY_PUSHBACK_HOLD_TIME: float = 0.14
const PARRY_EXPOSURE_TIME: float = 0.42

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

var shield_rush_cooldown: float = 0.0
var shield_rush_timer: float = 0.0
var shield_rush_phase: int = ShieldRushPhase.NONE
var shield_rush_direction: float = 1.0
var shield_rush_target: Node2D = null
var shield_rush_micro_stagger_applied: bool = false
var shield_rush_final_stun_applied: bool = false
var slide_iframe_active: bool = false
var default_collision_mask: int = 0
var default_collision_layer: int = 0
var slide_enemy_collision_disabled: bool = false
var last_incoming_attacker: Node2D = null
var block_audio_player: AudioStreamPlayer2D = null
var shield_rush_vfx: Node = null

var reaction_lock_timer: float = 0.0
var current_hit_reaction: int = HitReaction.LIGHT
var hurt_animation_speed_scale: float = 1.0
var heavy_pushback_hold_timer: float = 0.0
var parry_exposure_timer: float = 0.0
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
var _latched_backstab_target_ids: Array[int] = []


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
	jump_velocity = -560.0
	super()
	default_collision_mask = collision_mask
	default_collision_layer = collision_layer
	_setup_block_audio()
	_setup_shield_rush_vfx()
	_configure_skill_ui()
	_update_block_cooldown_ui()


func _physics_process(delta: float) -> void:
	if is_dead:
		if animated_sprite:
			animated_sprite.speed_scale = 1.0
		super(delta)
		return

	if block_cooldown > 0.0:
		block_cooldown = maxf(0.0, block_cooldown - delta)

	if shield_rush_cooldown > 0.0:
		shield_rush_cooldown = maxf(0.0, shield_rush_cooldown - delta)

	if crouch_cooldown > 0.0:
		crouch_cooldown = maxf(0.0, crouch_cooldown - delta)

	if counter_window_timer > 0.0:
		counter_window_timer = maxf(0.0, counter_window_timer - delta)
		if counter_window_timer <= 0.0:
			is_counter_attack_ready = false

	if parry_exposure_timer > 0.0:
		parry_exposure_timer = maxf(0.0, parry_exposure_timer - delta)

	if reaction_lock_timer > 0.0:
		reaction_lock_timer = maxf(0.0, reaction_lock_timer - delta)
		if reaction_lock_timer <= 0.0:
			is_hurt = false
			hurt_animation_speed_scale = 1.0
			heavy_pushback_hold_timer = 0.0
			if animated_sprite:
				animated_sprite.speed_scale = 1.0

	_update_block_state(delta)
	_update_shield_rush_state(delta)
	_update_crouch_state(delta)
	_update_block_cooldown_ui()

	super(delta)


func die():
	if is_dead:
		return

	_interrupt_warrior_actions_on_death()
	super.die()


func handle_movement(delta: float) -> void:
	if is_inventory_open:
		_cancel_sneak_mode()
		velocity.x = move_toward(velocity.x, 0.0, _get_horizontal_friction_step(delta))
		return

	var direction: float = Input.get_axis("move_left", "move_right")
	var is_jumping: bool = Input.is_action_just_pressed("jump")
	var crouch_pressed: bool = Input.is_action_just_pressed("crouch")

	if Input.is_action_just_pressed("sneak_toggle"):
		_toggle_sneak_mode()

	if is_sliding:
		_update_shield_rush_movement(delta)
		return

	if reaction_lock_timer > 0.0:
		_cancel_sneak_mode()
		if current_hit_reaction == HitReaction.HEAVY:
			if heavy_pushback_hold_timer > 0.0:
				heavy_pushback_hold_timer = maxf(0.0, heavy_pushback_hold_timer - delta)
			else:
				velocity.x = move_toward(velocity.x, 0.0, HEAVY_PUSHBACK_DECAY * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta * 0.75)
		return

	if is_attacking or block_phase != BlockPhase.NONE or (is_casting and not is_using_consumable):
		_cancel_sneak_mode()
		velocity.x = move_toward(velocity.x, 0.0, _get_horizontal_friction_step(delta))
		return

	if crouch_pressed:
		_start_crouch_action()

	if crouch_phase != CrouchPhase.NONE:
		_cancel_sneak_mode()
		velocity.x = move_toward(velocity.x, 0.0, _get_horizontal_friction_step(delta) * 1.2)
		return

	is_sneaking = sneak_mode_enabled and is_on_floor() and direction != 0.0 and not is_blocking and not is_attacking and not is_using_consumable

	if direction != 0.0:
		var target_speed: float = current_speed
		if is_sneaking:
			target_speed *= SNEAK_SPEED_MULTIPLIER
		if is_using_consumable:
			target_speed *= consumable_move_speed_multiplier
		velocity.x = move_toward(velocity.x, direction * target_speed, _get_horizontal_acceleration_step(delta))
		if animated_sprite:
			animated_sprite.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, _get_horizontal_friction_step(delta))

	if is_jumping and not is_blocking and not is_using_consumable:
		_cancel_sneak_mode()
		_try_perform_jump()


func handle_animations() -> void:
	if not animated_sprite:
		return

	if is_dead:
		play_animation("death")
		return

	if is_attacking:
		return

	if is_sliding:
		_update_shield_rush_visual()
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
	combat_action_performed.emit("block_started", {})
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
	_latched_backstab_target_ids.clear()
	if _current_attack_started_from_sneak:
		_latched_backstab_target_ids = _capture_backstab_targets()
	_cancel_sneak_mode()
	is_attacking = true
	parry_exposure_timer = PARRY_EXPOSURE_TIME
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
	_latched_backstab_target_ids.clear()
	handle_animations()


func slide() -> void:
	if is_dead or is_attacking or is_casting or is_hurt:
		return
	if is_sliding or block_phase != BlockPhase.NONE or shield_rush_cooldown > 0.0 or crouch_phase != CrouchPhase.NONE:
		return
	if not is_on_floor():
		return

	var rush_target: Node2D = _get_shield_rush_target()
	if rush_target == null:
		return

	_cancel_sneak_mode()
	is_sliding = true
	shield_rush_timer = SHIELD_RUSH_TOTAL_DURATION
	shield_rush_phase = ShieldRushPhase.APPROACH
	shield_rush_target = rush_target
	shield_rush_micro_stagger_applied = false
	shield_rush_final_stun_applied = false
	slide_iframe_active = false
	_set_enemy_slide_collision_enabled(false)
	shield_rush_direction = _resolve_shield_rush_direction(rush_target)
	if animated_sprite:
		animated_sprite.flip_h = shield_rush_direction < 0.0
	if shield_rush_target != null and shield_rush_target.has_method("force_alert"):
		shield_rush_target.force_alert(self)
	if shield_rush_vfx != null and shield_rush_vfx.has_method("start_rush"):
		shield_rush_vfx.start_rush(global_position + Vector2(0.0, SHIELD_RUSH_IMPACT_OFFSET_Y), shield_rush_direction)
	if CombatRuntimeLogger:
		CombatRuntimeLogger.log_event("shield_rush", character_name, "start", {
			"target": shield_rush_target,
			"distance": global_position.distance_to(shield_rush_target.global_position) if shield_rush_target != null else -1.0,
			"player_floor": get_effective_combat_floor_id(),
			"target_floor": int(shield_rush_target.call("get_effective_combat_floor_id")) if shield_rush_target != null and shield_rush_target.has_method("get_effective_combat_floor_id") else -1,
			"direction": shield_rush_direction,
		})
	combat_action_performed.emit("shield_rush_started", {
		"target_name": shield_rush_target.name if shield_rush_target != null else "",
		"cooldown": SHIELD_RUSH_COOLDOWN_TIME,
	})
	_update_shield_rush_visual()


func take_damage(amount: int, damage_type: String = "physical", source: String = "Неизвестно", reaction_hint: String = "") -> void:
	if is_dead:
		return
	if slide_iframe_active:
		return

	last_damage_source = source

	var incoming_amount: int = max(0, amount)
	var was_successfully_blocked: bool = _can_successfully_block(damage_type)
	var hp_before: int = current_health
	if was_successfully_blocked:
		incoming_amount = _resolve_blocked_damage(incoming_amount)
		_register_successful_block()
		if incoming_amount <= 0:
			_show_block_flash()
			if CombatRuntimeLogger:
				CombatRuntimeLogger.log_event("player_damage", character_name, "blocked_hit", {
					"source": source,
					"amount": amount,
					"damage_type": damage_type,
					"reaction_hint": reaction_hint,
					"hp_before": hp_before,
					"hp_after": current_health,
				})
			return

	var final_damage: int = incoming_amount
	if _is_magical_damage_type(damage_type):
		final_damage -= int(armor * 0.5)
	elif not _is_true_damage_type(damage_type):
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
	if CombatRuntimeLogger:
		CombatRuntimeLogger.log_event("player_damage", character_name, "take_damage", {
			"source": source,
			"amount": amount,
			"final_damage": final_damage,
			"damage_type": damage_type,
			"reaction_hint": reaction_hint,
			"blocked": was_successfully_blocked,
			"hp_before": hp_before,
			"hp_after": current_health,
		})

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
	if enemy == null:
		return false
	if is_sneaking and _is_behind_target(enemy):
		return true
	# Keep stealth against the latched backstab target until the hit-frame lands,
	# otherwise the enemy can turn during attack startup and visually counter first.
	if is_stealth_backstab_attack_active_against(enemy) and not _attack_damage_dealt:
		return true
	return false


func _update_block_state(delta: float) -> void:
	if is_dead:
		return
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


func _update_shield_rush_state(delta: float) -> void:
	if not is_sliding:
		slide_iframe_active = false
		_set_enemy_slide_collision_enabled(true)
		shield_rush_phase = ShieldRushPhase.NONE
		return

	shield_rush_timer = maxf(0.0, shield_rush_timer - delta)
	slide_iframe_active = false
	var elapsed: float = SHIELD_RUSH_TOTAL_DURATION - shield_rush_timer
	var current_visual_frame: int = _get_shield_rush_visual_frame_index(elapsed)

	if shield_rush_phase == ShieldRushPhase.APPROACH and elapsed >= SHIELD_RUSH_TRAVEL_TIME:
		shield_rush_phase = ShieldRushPhase.FOLLOW_THROUGH
		velocity.x = 0.0
		if not shield_rush_micro_stagger_applied:
			_apply_shield_rush_micro_stagger()
			shield_rush_micro_stagger_applied = true

	if not shield_rush_final_stun_applied and current_visual_frame >= SHIELD_RUSH_FINAL_IMPACT_VISUAL_FRAME - 1:
		_apply_shield_rush_final_stun()
		shield_rush_final_stun_applied = true

	if shield_rush_timer <= 0.0:
		is_sliding = false
		shield_rush_phase = ShieldRushPhase.NONE
		shield_rush_timer = 0.0
		shield_rush_cooldown = SHIELD_RUSH_COOLDOWN_TIME
		shield_rush_target = null
		velocity.x = 0.0
		slide_iframe_active = false
		_set_enemy_slide_collision_enabled(true)
		if shield_rush_vfx != null and shield_rush_vfx.has_method("stop_rush"):
			shield_rush_vfx.stop_rush()


func _finish_block_sequence(force_cooldown: bool) -> void:
	if block_phase == BlockPhase.NONE and not force_cooldown:
		return

	is_blocking = false
	is_block_active = false
	block_phase = BlockPhase.NONE
	block_phase_timer = 0.0
	if force_cooldown or block_cooldown <= 0.0:
		block_cooldown = BLOCK_COOLDOWN_TIME


func _interrupt_warrior_actions_on_death() -> void:
	is_blocking = false
	is_block_active = false
	block_phase = BlockPhase.NONE
	block_phase_timer = 0.0

	is_crouching = false
	crouch_phase = CrouchPhase.NONE
	crouch_phase_timer = 0.0

	is_sliding = false
	slide_iframe_active = false
	shield_rush_phase = ShieldRushPhase.NONE
	shield_rush_timer = 0.0
	shield_rush_target = null
	shield_rush_micro_stagger_applied = false
	shield_rush_final_stun_applied = false
	_set_enemy_slide_collision_enabled(true)

	if shield_rush_vfx != null and shield_rush_vfx.has_method("stop_rush"):
		shield_rush_vfx.stop_rush()
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


func _can_successfully_block(damage_type: String = "physical") -> bool:
	if not _is_blockable_damage_type(damage_type):
		return false
	if not _is_attack_in_front():
		return false
	if block_phase == BlockPhase.ACTIVE and is_block_active:
		return true
	if block_phase == BlockPhase.STARTUP and block_phase_timer <= BLOCK_EARLY_GRACE_TIME:
		return true
	return false


func _is_blockable_damage_type(damage_type: String) -> bool:
	return damage_type != "magical_unblockable"


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
	combat_action_performed.emit("block_success", {
		"counter_window": COUNTER_WINDOW_TIME,
	})
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
			heavy_pushback_hold_timer = HEAVY_PUSHBACK_HOLD_TIME
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
	for body in _get_attack_hit_targets(attack_dir, attack_range):
		if body == null or body == self or not body.has_method("take_damage"):
			continue

		var damage_amount: int = maxi(1, int(round(current_damage * _current_attack_damage_multiplier)))
		if body.has_method("register_incoming_attacker"):
			body.register_incoming_attacker(self)
		body.take_damage(damage_amount, "physical")

		if Global and Global.has_method("add_damage_dealt"):
			Global.add_damage_dealt(damage_amount)

		var is_backstab: bool = _current_attack_animation == "attack" and _current_attack_started_from_sneak and _is_backstab_latched_for_target(body)
		combat_action_performed.emit("damage_dealt", {
			"amount": damage_amount,
			"damage_type": "physical",
			"counter": _current_attack_animation == "attack2",
			"backstab": is_backstab,
			"target_name": body.name,
			"target_node": body,
		})
		if is_backstab and body.has_method("apply_backstab_knockdown"):
			body.apply_backstab_knockdown(BACKSTAB_KNOCKDOWN_DURATION, global_position.x)
		elif is_backstab and body.has_method("apply_short_stagger"):
			body.apply_short_stagger(BACKSTAB_STAGGER_DURATION, global_position.x)
		if is_backstab and body.has_method("force_alert"):
			body.force_alert(self)
			combat_action_performed.emit("backstab", {
				"amount": damage_amount,
				"target_name": body.name,
				"target_node": body,
			})
		elif _current_attack_stagger_duration > 0.0 and body.has_method("apply_short_stagger"):
			body.apply_short_stagger(_current_attack_stagger_duration, global_position.x)


func _capture_backstab_targets() -> Array[int]:
	var captured_ids: Array[int] = []
	var attack_dir: float = _get_facing_direction()
	for body in _get_attack_hit_targets(attack_dir, ATTACK_RANGE):
		if body == null or not is_instance_valid(body):
			continue
		if _is_behind_target(body):
			captured_ids.append(body.get_instance_id())
	return captured_ids


func _is_backstab_latched_for_target(target: Node) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if _latched_backstab_target_ids.has(target.get_instance_id()):
		return true
	return _is_behind_target(target)


func _get_attack_hit_targets(attack_dir: float, attack_range: float) -> Array[Node]:
	var center: Vector2 = global_position + Vector2(attack_range * 0.72 * attack_dir, 0.0)
	var space := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = attack_range
	query.shape = shape
	query.transform = Transform2D(0.0, center)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.collision_mask = ENEMY_HIT_COLLISION_MASK
	query.exclude = [get_rid()]

	var targets: Array[Node] = []
	for result in space.intersect_shape(query):
		var body: Node = result.get("collider")
		if body != null:
			targets.append(body)
	return targets


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


func get_facing_direction() -> float:
	return _get_facing_direction()


func is_parryable_attack_active() -> bool:
	return is_attacking or parry_exposure_timer > 0.0


func is_stealth_backstab_attack_active_against(target: Node) -> bool:
	if not is_attacking or not _current_attack_started_from_sneak:
		return false
	if _current_attack_animation != "attack":
		return false
	return _is_backstab_latched_for_target(target)


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


func _update_shield_rush_visual() -> void:
	if not animated_sprite or animated_sprite.sprite_frames == null:
		return
	var anim_name: String = _get_shield_rush_animation_name()
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		play_animation(anim_name)
		return
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

	var frame_count: int = animated_sprite.sprite_frames.get_frame_count(anim_name)
	if frame_count <= 0:
		return

	var elapsed: float = SHIELD_RUSH_TOTAL_DURATION - shield_rush_timer
	animated_sprite.stop()
	animated_sprite.frame = _get_shield_rush_visual_frame_index(elapsed, frame_count)


func _get_shield_rush_visual_frame_index(elapsed: float, frame_count: int = -1) -> int:
	if not animated_sprite or animated_sprite.sprite_frames == null:
		return 0
	var anim_name: String = _get_shield_rush_animation_name()
	if frame_count < 0:
		if not animated_sprite.sprite_frames.has_animation(anim_name):
			return 0
		frame_count = animated_sprite.sprite_frames.get_frame_count(anim_name)
	if frame_count <= 0:
		return 0

	var travel_frames: int
	var follow_through_frames: int
	if anim_name == "The jerk" and frame_count >= SHIELD_RUSH_TOTAL_VISUAL_FRAMES:
		travel_frames = SHIELD_RUSH_TRAVEL_VISUAL_FRAMES
		follow_through_frames = SHIELD_RUSH_TOTAL_VISUAL_FRAMES - SHIELD_RUSH_TRAVEL_VISUAL_FRAMES
	else:
		follow_through_frames = mini(3, frame_count)
		travel_frames = max(1, frame_count - follow_through_frames)

	if elapsed < SHIELD_RUSH_TRAVEL_TIME or frame_count <= follow_through_frames:
		var travel_normalized: float = clampf(elapsed / maxf(SHIELD_RUSH_TRAVEL_TIME, 0.001), 0.0, 0.999)
		return mini(travel_frames - 1, int(floor(travel_normalized * travel_frames)))

	var follow_elapsed: float = elapsed - SHIELD_RUSH_TRAVEL_TIME
	var follow_normalized: float = clampf(follow_elapsed / maxf(SHIELD_RUSH_FOLLOW_THROUGH_TIME, 0.001), 0.0, 0.999)
	return mini(frame_count - 1, travel_frames + int(floor(follow_normalized * follow_through_frames)))


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
		elif shield_rush_cooldown > 0.0:
			slide_percent = 1.0 - (shield_rush_cooldown / SHIELD_RUSH_COOLDOWN_TIME)
		Global.game_ui.update_ability_cooldown("slide", clampf(slide_percent, 0.0, 1.0))


func _configure_skill_ui() -> void:
	if not Global or not Global.game_ui:
		return
	if Global.game_ui.has_method("configure_ability_slot"):
		Global.game_ui.configure_ability_slot("block", "Блок", "E", BLOCK_ICON_PATH)
		Global.game_ui.configure_ability_slot("slide", "Рывок", "ПКМ", SHIELD_RUSH_ICON_PATH)


func apply_artifacts() -> void:
	super.apply_artifacts()
	recalculate_armor()


func _setup_shield_rush_vfx() -> void:
	if shield_rush_vfx != null:
		return
	shield_rush_vfx = WarriorShieldRushVfxScript.new()
	if shield_rush_vfx == null:
		return
	shield_rush_vfx.name = "ShieldRushVfx"
	add_child(shield_rush_vfx)
	if shield_rush_vfx.has_method("setup"):
		shield_rush_vfx.setup(self)


func _update_shield_rush_movement(delta: float) -> void:
	if shield_rush_phase != ShieldRushPhase.APPROACH:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta * 4.0)
		return

	if not _is_valid_shield_rush_target(shield_rush_target):
		velocity.x = move_toward(velocity.x, 0.0, friction * delta * 4.0)
		return

	shield_rush_direction = _resolve_shield_rush_direction(shield_rush_target)
	if animated_sprite:
		animated_sprite.flip_h = shield_rush_direction < 0.0

	var desired_x: float = shield_rush_target.global_position.x - shield_rush_direction * SHIELD_RUSH_STOP_DISTANCE
	var delta_x: float = desired_x - global_position.x
	var desired_speed: float = clampf(delta_x / maxf(delta, 0.001), -SHIELD_RUSH_MAX_SPEED, SHIELD_RUSH_MAX_SPEED)
	velocity.x = desired_speed


func _get_shield_rush_target() -> Node2D:
	var level_root: Node = get_tree().current_scene
	if level_root == null:
		return null

	var candidate: Node = null
	if level_root.has_method("get_current_enemy_ui_target"):
		candidate = level_root.get_current_enemy_ui_target()
	else:
		candidate = level_root.get("current_enemy_ui_target")

	if candidate == null or not (candidate is Node2D):
		return null

	var candidate_body: Node2D = candidate as Node2D
	if not _is_valid_shield_rush_target(candidate_body):
		return null

	return candidate_body


func _is_valid_shield_rush_target(candidate: Node2D) -> bool:
	if candidate == null or not is_instance_valid(candidate):
		return false
	if candidate.get("is_alive") == false:
		return false
	if not candidate.is_inside_tree():
		return false

	var my_floor: int = get_effective_combat_floor_id()
	var target_floor: int = -1
	if candidate.has_method("get_effective_combat_floor_id"):
		target_floor = int(candidate.call("get_effective_combat_floor_id"))
	if my_floor == -1 or target_floor == -1 or my_floor != target_floor:
		return false

	return global_position.distance_to(candidate.global_position) <= SHIELD_RUSH_MAX_DISTANCE


func _resolve_shield_rush_direction(candidate: Node2D) -> float:
	if candidate == null:
		return _get_facing_direction()
	var dir: float = signf(candidate.global_position.x - global_position.x)
	if dir == 0.0:
		dir = _get_facing_direction()
	return dir


func _apply_shield_rush_micro_stagger() -> void:
	if not _is_valid_shield_rush_target(shield_rush_target):
		return

	if shield_rush_target.has_method("force_alert"):
		shield_rush_target.force_alert(self)
	if shield_rush_target.has_method("apply_shield_rush_opening_stagger"):
		shield_rush_target.apply_shield_rush_opening_stagger(SHIELD_RUSH_MICRO_STAGGER_DURATION, global_position.x)
	elif shield_rush_target.has_method("apply_short_stagger"):
		shield_rush_target.apply_short_stagger(SHIELD_RUSH_MICRO_STAGGER_DURATION, global_position.x)
	if CombatRuntimeLogger:
		CombatRuntimeLogger.log_event("shield_rush", character_name, "opening_stagger", {
			"target": shield_rush_target,
			"duration": SHIELD_RUSH_MICRO_STAGGER_DURATION,
			"target_state": shield_rush_target.get("current_state") if shield_rush_target != null else -1,
			"target_position": shield_rush_target.global_position if shield_rush_target != null else Vector2.ZERO,
		})
	if shield_rush_vfx != null and shield_rush_vfx.has_method("emit_contact_flash"):
		shield_rush_vfx.emit_contact_flash(shield_rush_target.global_position + Vector2(0.0, SHIELD_RUSH_IMPACT_OFFSET_Y), false)


func _apply_shield_rush_final_stun() -> void:
	if not _is_valid_shield_rush_target(shield_rush_target):
		return

	if shield_rush_target.has_method("force_alert"):
		shield_rush_target.force_alert(self)
	if shield_rush_target.has_method("apply_shield_rush_impact"):
		shield_rush_target.apply_shield_rush_impact(SHIELD_RUSH_FINAL_STUN_DURATION, SHIELD_RUSH_FINAL_PUSHBACK, global_position.x)
	elif shield_rush_target.has_method("show_player_guard_feedback"):
		shield_rush_target.show_player_guard_feedback(SHIELD_RUSH_FINAL_STUN_DURATION)
	elif shield_rush_target.has_method("apply_short_stagger"):
		shield_rush_target.apply_short_stagger(SHIELD_RUSH_FINAL_STUN_DURATION, global_position.x)
	if CombatRuntimeLogger:
		CombatRuntimeLogger.log_event("shield_rush", character_name, "final_impact", {
			"target": shield_rush_target,
			"stun_duration": SHIELD_RUSH_FINAL_STUN_DURATION,
			"pushback": SHIELD_RUSH_FINAL_PUSHBACK,
			"target_state": shield_rush_target.get("current_state") if shield_rush_target != null else -1,
			"target_position": shield_rush_target.global_position if shield_rush_target != null else Vector2.ZERO,
		})

	if shield_rush_vfx != null and shield_rush_vfx.has_method("emit_contact_flash"):
		shield_rush_vfx.emit_contact_flash(shield_rush_target.global_position + Vector2(0.0, SHIELD_RUSH_IMPACT_OFFSET_Y), true)

	combat_action_performed.emit("shield_rush_connected", {
		"target_name": shield_rush_target.name,
		"stun_duration": SHIELD_RUSH_FINAL_STUN_DURATION,
	})


func _get_shield_rush_animation_name() -> String:
	if animated_sprite != null and animated_sprite.sprite_frames != null:
		if animated_sprite.sprite_frames.has_animation("The jerk"):
			return "The jerk"
	return "sliding"
