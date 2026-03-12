extends CharacterBody2D

signal died()
signal health_changed(new_health)
signal repeat_potion_blocking_changed(is_blocking)

@export_enum("simple", "elite", "boss") var enemy_type: String = "simple"
@export var blocks_repeat_potions: bool = true
@export var require_engagement_to_block_repeat_potions: bool = false

@export var max_health: int = 20
@export var current_health: int = 20
@export var damage: int = 5
@export var move_speed: float = 100.0
@export var chase_speed: float = 120.0
@export var attack_range: float = 120.0
@export var detection_range: float = 150.0
@export var patrol_distance: float = 100.0

enum State { IDLE, PATROL, CHASE, ATTACK, HURT, DEAD, RETREAT, PARRY, KNOCKDOWN, PRESSURE, RECOVER }
enum AttackProfile { NORMAL, PUNISH_RUSH, PUNISH_HEAVY }
enum ParryPhase { NONE, STARTUP, ACTIVE }
var current_state: State = State.IDLE

const PERSISTENCE_COMPONENT := preload("res://scripts/persistence/persistence_component.gd")
const IDLE_TIME: float = 2.4
const PATROL_TURN_IDLE_TIME: float = 1.0
const MIN_DISTANCE_TO_PLAYER: float = 40.0
const PRESSURE_DISTANCE: float = 162.0
const PRESSURE_REEVALUATE_MIN: float = 0.12
const PRESSURE_REEVALUATE_MAX: float = 0.24
const COMBO_MIN_HITS: int = 2
const COMBO_MAX_HITS: int = 3
const COMBO_CHAIN_DELAY_TIME: float = 0.12
const NORMAL_COMBO_RECOVER_TIME: float = 0.82
const RETREAT_TIME_MIN: float = 0.28
const RETREAT_TIME_MAX: float = 0.38
const RETREAT_SPEED_MULTIPLIER: float = 0.92
const RETREAT_DISTANCE_TARGET: float = 138.0
const PARRY_STARTUP_TIME: float = 0.10
const PARRY_ACTIVE_TIME: float = 0.30
const PARRY_RECOVER_TIME: float = 0.22
const PARRY_COOLDOWN_TIME: float = 3.8
const PARRY_TRIGGER_DISTANCE: float = 136.0
const PARRY_TRIGGER_CHANCE: float = 0.42
const ALERT_RUSH_SPEED_MULTIPLIER: float = 2.6
const PLAYER_GUARD_FEEDBACK_TIME: float = 1.2
const BACKSTAB_KNOCKDOWN_DEFAULT: float = 0.95
const BACKSTAB_RECOVER_TIME: float = 0.65
const ATTACK_HIT_FRAME: int = 3
const NORMAL_ATTACK_HIT_TELL: float = 0.24
const NORMAL_ATTACK_SPEED_SCALE: float = 1.05
const PUNISH_RUSH_HIT_TELL: float = 0.18
const PUNISH_RUSH_SPEED_SCALE: float = 1.42
const PUNISH_HEAVY_HIT_TELL: float = 0.34
const PUNISH_HEAVY_SPEED_SCALE: float = 0.9
const PUNISH_HEAVY_DAMAGE_MULTIPLIER: float = 1.6
const PUNISH_HEAVY_RECOVER_TIME: float = 1.0
const PUNISH_RUSH_RECOVER_TIME: float = 0.95

var start_position: Vector2
var patrol_direction: int = 1
var target: Node2D = null
var can_attack: bool = true
var damage_dealt_this_attack: bool = false

var idle_timer: float = 0.0
var attack_cooldown: float = 0.0
var gravity: int = int(ProjectSettings.get_setting("physics/2d/default_gravity"))
var is_alive: bool = true
var is_active: bool = true
var persistence: PersistenceComponent = null
var has_engaged_player: bool = false
var forced_stagger_timer: float = 0.0
var pressure_timer: float = 0.0
var retreat_timer: float = 0.0
var recover_timer: float = 0.0
var parry_phase: int = ParryPhase.NONE
var parry_timer: float = 0.0
var parry_cooldown: float = 0.0
var combo_hits_remaining: int = 0
var combo_chain_timer: float = 0.0
var engage_rush_timer: float = 0.0
var knockdown_timer: float = 0.0
var queued_counter_combo: bool = false
var target_attack_latched: bool = false
var retreat_target_side: int = 0
var attack_elapsed: float = 0.0
var attack_profile: int = AttackProfile.NORMAL
var attack_damage_multiplier: float = 1.0
var attack_hit_tell_time: float = NORMAL_ATTACK_HIT_TELL
var attack_post_recover_time: float = NORMAL_COMBO_RECOVER_TIME
var use_hurt_recover_pose: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea


func _ready() -> void:
	start_position = global_position
	add_to_group("encounter_enemy")

	if detection_area:
		if not detection_area.body_entered.is_connected(_on_detection_entered):
			detection_area.body_entered.connect(_on_detection_entered)
		if not detection_area.body_exited.is_connected(_on_detection_exited):
			detection_area.body_exited.connect(_on_detection_exited)

	if animated_sprite:
		animated_sprite.z_index = 10
		if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
			animated_sprite.animation_finished.connect(_on_animation_finished)
		if not animated_sprite.frame_changed.is_connected(_on_frame_changed):
			animated_sprite.frame_changed.connect(_on_frame_changed)

	_ensure_persistence()
	_configure_persistence()

	var saved_state: Dictionary = _load_persistent_state()
	if not saved_state.is_empty():
		apply_persistent_state(saved_state)
		if not is_alive:
			return
		return

	_change_state(State.IDLE)


func capture_persistent_state() -> Dictionary:
	var state: Dictionary = save_state()
	state["dead"] = not is_alive
	state["consumed"] = not is_alive
	return state


func apply_persistent_state(state: Dictionary) -> void:
	load_state(state)


func _ensure_persistence() -> void:
	persistence = get_node_or_null("Persistence") as PersistenceComponent
	if persistence != null:
		return

	persistence = PERSISTENCE_COMPONENT.new()
	persistence.name = "Persistence"
	add_child(persistence)


func _configure_persistence() -> void:
	if persistence:
		persistence.configure(name, "enemy", false)


func _load_persistent_state() -> Dictionary:
	if Global and not Global.run_started:
		return {}
	if persistence == null:
		return {}

	var saved_state: Dictionary = persistence.get_saved_state()
	if saved_state.is_empty():
		var was_killed: bool = false
		if Global and name in Global.killed_enemies:
			was_killed = true
		if was_killed:
			saved_state = persistence.mark_consumed({
				"dead": true,
				"is_alive": false,
				"current_health": 0,
				"current_state": State.DEAD,
				"start_position": start_position,
		"has_engaged_player": has_engaged_player,
			})

	return saved_state


func _physics_process(delta: float) -> void:
	if not is_alive or not is_active:
		velocity = Vector2.ZERO
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if attack_cooldown > 0.0:
		attack_cooldown = maxf(0.0, attack_cooldown - delta)
		if attack_cooldown <= 0.0:
			can_attack = true

	if parry_cooldown > 0.0:
		parry_cooldown = maxf(0.0, parry_cooldown - delta)

	if target == null or not is_instance_valid(target) or target.get("is_attacking") != true:
		target_attack_latched = false

	if engage_rush_timer > 0.0:
		engage_rush_timer = maxf(0.0, engage_rush_timer - delta)

	if combo_chain_timer > 0.0:
		combo_chain_timer = maxf(0.0, combo_chain_timer - delta)

	if pressure_timer > 0.0:
		pressure_timer = maxf(0.0, pressure_timer - delta)

	if retreat_timer > 0.0:
		retreat_timer = maxf(0.0, retreat_timer - delta)

	if recover_timer > 0.0:
		recover_timer = maxf(0.0, recover_timer - delta)

	if parry_timer > 0.0:
		parry_timer = maxf(0.0, parry_timer - delta)

	if knockdown_timer > 0.0:
		knockdown_timer = maxf(0.0, knockdown_timer - delta)

	if forced_stagger_timer > 0.0:
		forced_stagger_timer = maxf(0.0, forced_stagger_timer - delta)
		if forced_stagger_timer <= 0.0 and current_state == State.HURT:
			_resolve_post_recover_state()

	if current_state == State.ATTACK:
		attack_elapsed += delta

	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.PATROL:
			_process_patrol()
		State.CHASE:
			_process_chase()
		State.PRESSURE:
			_process_pressure()
		State.ATTACK:
			velocity.x = 0.0
		State.RETREAT:
			_process_retreat()
		State.PARRY:
			_process_parry()
		State.RECOVER:
			_process_recover()
		State.HURT:
			velocity.x = 0.0
		State.KNOCKDOWN:
			velocity.x = 0.0
		State.DEAD:
			velocity = Vector2.ZERO
			return

	move_and_slide()


func save_state() -> Dictionary:
	return {
		"is_alive": is_alive,
		"current_health": current_health,
		"global_position": global_position,
		"current_state": current_state,
		"patrol_direction": patrol_direction,
		"start_position": start_position,
		"has_engaged_player": has_engaged_player,
	}


func load_state(state: Dictionary) -> void:
	is_alive = bool(state.get("is_alive", true)) and not bool(state.get("dead", false))
	current_health = int(state.get("current_health", max_health))

	if state.has("start_position"):
		start_position = state["start_position"]
	if state.has("global_position"):
		global_position = state["global_position"]
	if state.has("patrol_direction"):
		patrol_direction = int(state["patrol_direction"])
	has_engaged_player = bool(state.get("has_engaged_player", false))

	if not is_alive:
		_set_dead_state()
		return

	is_active = true
	visible = true
	set_physics_process(true)
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if detection_area:
		detection_area.set_deferred("monitoring", true)
		detection_area.set_deferred("monitorable", true)
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE

	health_changed.emit(current_health)

	var saved_state: int = int(state.get("current_state", State.IDLE))
	current_state = State.IDLE
	_change_state(saved_state)



func is_repeat_potion_blocker() -> bool:
	if not blocks_repeat_potions or not is_alive:
		return false
	if require_engagement_to_block_repeat_potions and not has_engaged_player:
		return false
	return true


func _set_dead_state() -> void:
	is_alive = false
	repeat_potion_blocking_changed.emit(false)
	is_active = false
	current_state = State.DEAD
	visible = false

	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if detection_area:
		detection_area.set_deferred("monitoring", false)
		detection_area.set_deferred("monitorable", false)

	set_physics_process(false)

func _change_state(new_state: State) -> void:
	if current_state == State.DEAD and not is_alive:
		return
	if current_state == new_state:
		return

	current_state = new_state
	if animated_sprite:
		animated_sprite.speed_scale = 1.0

	match new_state:
		State.IDLE:
			_play_anim("idle")
			velocity.x = 0.0
			idle_timer = IDLE_TIME
		State.PATROL:
			if animated_sprite:
				animated_sprite.speed_scale = 1.0
			_play_anim("walk")
		State.CHASE:
			if animated_sprite:
				animated_sprite.speed_scale = 1.1
			_play_anim("walk")
		State.PRESSURE:
			pressure_timer = randf_range(PRESSURE_REEVALUATE_MIN, PRESSURE_REEVALUATE_MAX)
			velocity.x = 0.0
			_play_anim("walk")
		State.ATTACK:
			velocity.x = 0.0
			damage_dealt_this_attack = false
			attack_elapsed = 0.0
			_face_target()
			_configure_attack_profile()
			if animated_sprite:
				animated_sprite.speed_scale = _get_attack_speed_scale()
			_play_anim("attack")
		State.RETREAT:
			retreat_timer = randf_range(RETREAT_TIME_MIN, RETREAT_TIME_MAX)
			retreat_target_side = 0
			if target and is_instance_valid(target):
				retreat_target_side = int(signf(target.global_position.x - global_position.x))
			velocity.x = 0.0
			if animated_sprite:
				animated_sprite.speed_scale = 1.1
			_play_anim("Back away")
		State.PARRY:
			parry_phase = ParryPhase.STARTUP
			parry_timer = PARRY_STARTUP_TIME
			velocity.x = 0.0
			_face_target()
			_play_anim("block")
			if animated_sprite:
				animated_sprite.speed_scale = 1.0
				animated_sprite.stop()
				animated_sprite.frame = 0
		State.RECOVER:
			velocity.x = 0.0
			if use_hurt_recover_pose:
				_play_anim("hurt")
			else:
				_play_anim("idle")
		State.HURT:
			_play_anim("hurt")
			velocity.x = 0.0
		State.KNOCKDOWN:
			velocity.x = 0.0
			_play_anim(_get_knockdown_animation_name())
		State.DEAD:
			_disable_collision()
			_play_anim("death")
			velocity = Vector2.ZERO


func _disable_collision() -> void:
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if detection_area:
		detection_area.monitoring = false
		detection_area.monitorable = false


func _process_idle(delta: float) -> void:
	velocity.x = 0.0
	idle_timer -= delta
	if idle_timer <= 0.0:
		_change_state(State.PATROL)


func _process_patrol() -> void:
	if is_on_wall():
		patrol_direction *= -1
		idle_timer = PATROL_TURN_IDLE_TIME
		_change_state(State.IDLE)
		return

	var dist_from_start: float = global_position.x - start_position.x
	if patrol_direction > 0 and dist_from_start >= patrol_distance:
		patrol_direction = -1
		idle_timer = PATROL_TURN_IDLE_TIME
		_change_state(State.IDLE)
		return
	if patrol_direction < 0 and dist_from_start <= -patrol_distance:
		patrol_direction = 1
		idle_timer = PATROL_TURN_IDLE_TIME
		_change_state(State.IDLE)
		return

	velocity.x = patrol_direction * move_speed * 0.55
	_play_anim("walk")
	if animated_sprite:
		animated_sprite.flip_h = patrol_direction < 0

func _process_chase() -> void:
	if not target or not is_instance_valid(target):
		_change_state(State.PATROL)
		return
	if target.get("is_dead") == true:
		target = null
		_change_state(State.PATROL)
		return

	var dist: float = global_position.distance_to(target.global_position)
	var dir_x: float = target.global_position.x - global_position.x
	var move_dir: float = signf(dir_x)
	if move_dir == 0.0:
		move_dir = 1.0

	if animated_sprite:
		animated_sprite.flip_h = dir_x < 0

	if dist <= PRESSURE_DISTANCE:
		_change_state(State.PRESSURE)
		return

	var chase_multiplier: float = ALERT_RUSH_SPEED_MULTIPLIER if engage_rush_timer > 0.0 else 1.35
	var target_speed_hint: float = 0.0
	var target_speed_value = target.get("current_speed")
	if typeof(target_speed_value) == TYPE_FLOAT or typeof(target_speed_value) == TYPE_INT:
		target_speed_hint = float(target_speed_value)

	var pressure_speed: float = chase_speed * chase_multiplier
	pressure_speed = maxf(pressure_speed, move_speed * 2.0)
	if dist > attack_range + 12.0 and target_speed_hint > 0.0:
		pressure_speed = maxf(pressure_speed, target_speed_hint * 1.15)

	velocity.x = move_dir * pressure_speed


func _process_pressure() -> void:
	if not target or not is_instance_valid(target):
		_change_state(State.PATROL)
		return
	if target.get("is_dead") == true:
		target = null
		_change_state(State.PATROL)
		return

	var dist: float = global_position.distance_to(target.global_position)
	var dir_x: float = target.global_position.x - global_position.x
	var move_dir: float = signf(dir_x)
	if move_dir == 0.0:
		move_dir = 1.0

	_face_target()

	if dist > PRESSURE_DISTANCE + 22.0:
		_change_state(State.CHASE)
		return

	if combo_hits_remaining > 0 and combo_chain_timer <= 0.0 and dist <= attack_range + 18.0:
		_change_state(State.ATTACK)
		return

	if dist <= attack_range + 18.0 and can_attack:
		_setup_normal_combo()
		_change_state(State.ATTACK)
		return

	if pressure_timer > 0.0:
		if dist > attack_range + 16.0:
			velocity.x = move_dir * chase_speed * 0.78
		elif dist < MIN_DISTANCE_TO_PLAYER + 12.0:
			velocity.x = -move_dir * move_speed * 0.48
		else:
			velocity.x = move_toward(velocity.x, 0.0, move_speed * 0.28)
		return

	pressure_timer = randf_range(PRESSURE_REEVALUATE_MIN, PRESSURE_REEVALUATE_MAX)

	if _should_enter_parry(dist):
		_change_state(State.PARRY)
		return

	if dist <= attack_range + 14.0 and can_attack:
		_setup_normal_combo()
		_change_state(State.ATTACK)
		return

	if dist <= MIN_DISTANCE_TO_PLAYER + 10.0 or (dist <= attack_range * 0.85 and randf() < 0.32):
		_change_state(State.RETREAT)
		return

	if dist > attack_range + 20.0:
		velocity.x = move_dir * chase_speed * 0.72
	else:
		velocity.x = 0.0


func _process_retreat() -> void:
	if not target or not is_instance_valid(target) or target.get("is_dead") == true:
		target = null
		_change_state(State.PATROL)
		return

	var dir_x: float = target.global_position.x - global_position.x
	var current_target_side: int = int(signf(dir_x))
	if retreat_target_side != 0 and current_target_side != 0 and current_target_side != retreat_target_side:
		_change_state(State.PRESSURE)
		return
	if retreat_timer <= 0.0 or absf(dir_x) >= RETREAT_DISTANCE_TARGET or is_on_wall():
		_change_state(State.PRESSURE if absf(dir_x) <= PRESSURE_DISTANCE else State.CHASE)
		return

	var retreat_dir: float = -signf(dir_x)
	if retreat_dir == 0.0:
		retreat_dir = -1.0 if animated_sprite and animated_sprite.flip_h else 1.0
	velocity.x = retreat_dir * move_speed * RETREAT_SPEED_MULTIPLIER
	_face_target()
	_play_anim("Back away")


func _process_parry() -> void:
	if not target or not is_instance_valid(target) or target.get("is_dead") == true:
		queued_counter_combo = false
		parry_phase = ParryPhase.NONE
		_enter_recover(PARRY_RECOVER_TIME, false)
		return

	velocity.x = 0.0
	_face_target()

	match parry_phase:
		ParryPhase.STARTUP:
			_hold_parry_frame(0)
			if parry_timer > 0.0:
				return
			parry_phase = ParryPhase.ACTIVE
			parry_timer = PARRY_ACTIVE_TIME
			_hold_parry_frame(1)
		ParryPhase.ACTIVE:
			_hold_parry_frame(1)
			if parry_timer > 0.0 and not queued_counter_combo:
				return
		_:
			pass

	parry_phase = ParryPhase.NONE
	parry_cooldown = PARRY_COOLDOWN_TIME
	if queued_counter_combo:
		queued_counter_combo = false
		_setup_punish_attack()
		_change_state(State.ATTACK)
		return

	_enter_recover(PARRY_RECOVER_TIME, false)


func _process_recover() -> void:
	velocity.x = 0.0
	if current_state != State.RECOVER:
		return
	if recover_timer > 0.0:
		return
	_resolve_post_recover_state()


func _face_target() -> void:
	if target and animated_sprite:
		var dir: float = target.global_position.x - global_position.x
		animated_sprite.flip_h = dir < 0


func _on_detection_entered(body: Node2D) -> void:
	if not is_alive:
		return
	if body.is_in_group("player"):
		if body.get("is_dead") == true:
			return
		if body.has_method("is_hidden_from_enemy") and body.is_hidden_from_enemy(self):
			return
		target = body
		if not has_engaged_player:
			has_engaged_player = true
			repeat_potion_blocking_changed.emit(is_repeat_potion_blocker())
		engage_rush_timer = 0.65
		combo_hits_remaining = 0
		queued_counter_combo = false
		_change_state(State.CHASE)


func _on_detection_exited(body: Node2D) -> void:
	if not is_alive:
		return
	if body == target:
		target = null
		combo_hits_remaining = 0
		queued_counter_combo = false
		engage_rush_timer = 0.0
		if current_state in [State.CHASE, State.PRESSURE, State.RETREAT, State.PARRY, State.RECOVER]:
			_change_state(State.PATROL)


func _play_anim(anim_name: String) -> void:
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name:
			animated_sprite.play(anim_name)


func _on_frame_changed() -> void:
	if current_state != State.ATTACK or damage_dealt_this_attack:
		return
	if attack_elapsed >= attack_hit_tell_time and animated_sprite.frame >= ATTACK_HIT_FRAME:
		_deal_damage()
		damage_dealt_this_attack = true


func _on_animation_finished() -> void:
	match current_state:
		State.ATTACK:
			if not damage_dealt_this_attack:
				_deal_damage()
				damage_dealt_this_attack = true

			combo_hits_remaining = maxi(0, combo_hits_remaining - 1)
			if combo_hits_remaining > 0 and target and is_instance_valid(target) and target.get("is_dead") != true and global_position.distance_to(target.global_position) <= attack_range + 18.0:
				combo_chain_timer = COMBO_CHAIN_DELAY_TIME
				_change_state(State.PRESSURE)
				velocity.x = 0.0
				return

			combo_hits_remaining = 0
			can_attack = false
			attack_cooldown = attack_post_recover_time
			queued_counter_combo = false
			_enter_recover(attack_post_recover_time, false)
		State.HURT:
			if forced_stagger_timer > 0.0:
				_play_anim("hurt")
				return
			_resolve_post_recover_state()
		State.PARRY:
			_process_parry()
		State.KNOCKDOWN:
			if knockdown_timer <= 0.0:
				_enter_recover(BACKSTAB_RECOVER_TIME, true)
		State.DEAD:
			_on_death_completed()


func _on_death_completed() -> void:
	is_alive = false
	is_active = false

	var tw: Tween = create_tween()
	tw.tween_property(animated_sprite, "modulate:a", 0.0, 1.0)
	tw.tween_callback(_hide_enemy)


func _hide_enemy() -> void:
	visible = false
	if collision_shape:
		collision_shape.disabled = true
	if detection_area:
		detection_area.monitoring = false
		detection_area.monitorable = false
	set_physics_process(false)


func _deal_damage() -> void:
	if not target or not is_instance_valid(target):
		return
	if target.get("is_dead") == true:
		return

	var dist: float = global_position.distance_to(target.global_position)
	if dist <= attack_range + 42.0 and target.has_method("take_damage"):
		if target.has_method("register_incoming_attacker"):
			target.register_incoming_attacker(self)
		var total_damage: int = maxi(1, int(round(damage * attack_damage_multiplier)))
		target.take_damage(total_damage, "physical", "Ящерица с копьём")


func take_damage(amount: int, _type: String = "physical") -> void:
	if not is_alive or current_state == State.DEAD:
		return
	if current_state == State.KNOCKDOWN:
		return
	if current_state == State.PARRY and parry_phase == ParryPhase.ACTIVE:
		queued_counter_combo = true
		parry_timer = 0.0
		_show_combat_popup("ПАРИР.", Color(0.9, 0.95, 1.0, 1.0), 0.75)
		if target and is_instance_valid(target) and target.has_method("apply_guard_break_stun"):
			target.apply_guard_break_stun(0.55)
		return

	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)

	if persistence:
		persistence.save_from_owner()

	if Global and Global.has_method("add_damage_dealt"):
		Global.add_damage_dealt(amount)

	_show_damage_flash()

	if current_health <= 0:
		_die()
	else:
		_change_state(State.HURT)


func _show_damage_flash() -> void:
	if not animated_sprite:
		return

	animated_sprite.modulate = Color(2, 0.5, 0.5)
	var tw: Tween = create_tween()
	tw.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)


func _die() -> void:
	if Global and Global.has_method("add_enemy_killed"):
		Global.add_enemy_killed(enemy_type)
	if Global:
		Global.register_killed_enemy(name)

	is_alive = false
	_change_state(State.DEAD)

	if persistence:
		persistence.mark_consumed(capture_persistent_state())

	repeat_potion_blocking_changed.emit(false)
	died.emit()


func get_facing_direction() -> int:
	if animated_sprite and animated_sprite.flip_h:
		return -1
	return 1


func force_alert(player: Node2D) -> void:
	if not is_alive or player == null or not is_instance_valid(player):
		return
	target = player
	engage_rush_timer = 0.65
	if not has_engaged_player:
		has_engaged_player = true
		repeat_potion_blocking_changed.emit(is_repeat_potion_blocker())
	if current_state not in [State.ATTACK, State.KNOCKDOWN, State.HURT, State.PARRY]:
		_change_state(State.CHASE)


func apply_short_stagger(duration: float = 0.45, attacker_x: float = 0.0) -> void:
	if not is_alive or current_state == State.DEAD or current_state == State.KNOCKDOWN:
		return
	forced_stagger_timer = maxf(forced_stagger_timer, duration)
	combo_hits_remaining = 0
	queued_counter_combo = false
	combo_chain_timer = 0.0
	parry_phase = ParryPhase.NONE
	parry_timer = 0.0
	if attacker_x != 0.0 and animated_sprite:
		animated_sprite.flip_h = attacker_x < global_position.x
	if current_state != State.HURT:
		_change_state(State.HURT)
	else:
		_play_anim("hurt")


func apply_backstab_knockdown(duration: float = BACKSTAB_KNOCKDOWN_DEFAULT, attacker_x: float = 0.0) -> void:
	if not is_alive or current_state == State.DEAD:
		return
	if not _has_animation("fall"):
		apply_short_stagger(maxf(0.45, duration * 0.5), attacker_x)
		return

	knockdown_timer = maxf(knockdown_timer, duration)
	forced_stagger_timer = 0.0
	combo_hits_remaining = 0
	queued_counter_combo = false
	combo_chain_timer = 0.0
	velocity.x = 0.0
	parry_phase = ParryPhase.NONE
	parry_timer = 0.0
	if attacker_x != 0.0 and animated_sprite:
		animated_sprite.flip_h = attacker_x > global_position.x
	_change_state(State.KNOCKDOWN)
	_show_combat_popup("✦", Color(1.0, 0.92, 0.45, 1.0), maxf(0.7, duration))


func show_player_guard_feedback(duration: float = PLAYER_GUARD_FEEDBACK_TIME) -> void:
	if not is_alive or current_state == State.DEAD:
		return
	combo_hits_remaining = 0
	queued_counter_combo = false
	combo_chain_timer = 0.0
	parry_phase = ParryPhase.NONE
	parry_timer = 0.0
	can_attack = false
	attack_cooldown = maxf(attack_cooldown, duration * 0.9)
	_show_combat_popup("✦ ✦ ✦", Color(1.0, 0.95, 0.55, 1.0), maxf(1.0, duration))
	use_hurt_recover_pose = true
	_enter_recover(duration, true)
func _has_animation(anim_name: String) -> bool:
	return animated_sprite != null and animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(anim_name)


func _get_knockdown_animation_name() -> String:
	if _has_animation("fall"):
		return "fall"
	return "hurt"


func _should_enter_parry(dist: float) -> bool:
	if parry_cooldown > 0.0 or dist > PARRY_TRIGGER_DISTANCE:
		return false
	if target == null or target.get("is_attacking") != true:
		return false
	if target_attack_latched:
		return false
	target_attack_latched = true
	return randf() <= PARRY_TRIGGER_CHANCE


func _setup_normal_combo() -> void:
	attack_profile = AttackProfile.NORMAL
	combo_hits_remaining = randi_range(COMBO_MIN_HITS, COMBO_MAX_HITS)
	attack_damage_multiplier = 1.0
	attack_hit_tell_time = NORMAL_ATTACK_HIT_TELL
	attack_post_recover_time = NORMAL_COMBO_RECOVER_TIME


func _setup_punish_attack() -> void:
	if randf() <= 0.72:
		attack_profile = AttackProfile.PUNISH_RUSH
		combo_hits_remaining = randi_range(COMBO_MIN_HITS, COMBO_MAX_HITS)
		attack_damage_multiplier = 1.1
		attack_hit_tell_time = PUNISH_RUSH_HIT_TELL
		attack_post_recover_time = PUNISH_RUSH_RECOVER_TIME
	else:
		attack_profile = AttackProfile.PUNISH_HEAVY
		combo_hits_remaining = 1
		attack_damage_multiplier = PUNISH_HEAVY_DAMAGE_MULTIPLIER
		attack_hit_tell_time = PUNISH_HEAVY_HIT_TELL
		attack_post_recover_time = PUNISH_HEAVY_RECOVER_TIME


func _configure_attack_profile() -> void:
	if combo_hits_remaining <= 0:
		_setup_normal_combo()


func _get_attack_speed_scale() -> float:
	match attack_profile:
		AttackProfile.PUNISH_RUSH:
			return PUNISH_RUSH_SPEED_SCALE
		AttackProfile.PUNISH_HEAVY:
			return PUNISH_HEAVY_SPEED_SCALE
		_:
			return NORMAL_ATTACK_SPEED_SCALE


func _enter_recover(duration: float, use_hurt_pose: bool) -> void:
	recover_timer = maxf(duration, 0.0)
	use_hurt_recover_pose = use_hurt_pose
	_change_state(State.RECOVER)


func _resolve_post_recover_state() -> void:
	use_hurt_recover_pose = false
	if target and is_instance_valid(target) and target.get("is_dead") != true:
		var dist: float = global_position.distance_to(target.global_position)
		if dist <= PRESSURE_DISTANCE:
			_change_state(State.PRESSURE)
		else:
			_change_state(State.CHASE)
	else:
		target = null
		_change_state(State.PATROL)


func _hold_parry_frame(frame_index: int) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if not animated_sprite.sprite_frames.has_animation("block"):
		return
	var frame_count: int = animated_sprite.sprite_frames.get_frame_count("block")
	if frame_count <= 0:
		return
	animated_sprite.stop()
	animated_sprite.frame = mini(frame_index, frame_count - 1)


func _show_combat_popup(text: String, color: Color, duration: float = 0.35) -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return

	var label := Label.new()
	label.text = text
	label.top_level = true
	label.z_index = 100
	label.position = global_position + Vector2(-24.0, -92.0)
	label.modulate = color
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	get_tree().current_scene.add_child(label)

	var tween: Tween = create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0.0, -18.0), duration)
	tween.parallel().tween_property(label, "modulate:a", 0.0, duration)
	tween.tween_callback(Callable(label, "queue_free"))


func activate() -> void:
	if is_alive:
		is_active = true
		set_physics_process(true)
		visible = true


func deactivate() -> void:
	is_active = false
	set_physics_process(false)
	if animated_sprite:
		animated_sprite.stop()
