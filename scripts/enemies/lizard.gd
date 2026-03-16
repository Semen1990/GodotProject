extends CharacterBody2D

const EnemyMeleeControllerScript := preload("res://scripts/enemies/melee/enemy_melee_controller.gd")
const EnemyMeleeProfileScript := preload("res://scripts/enemies/melee/enemy_melee_profile.gd")

signal died()
signal health_changed(new_health)
signal repeat_potion_blocking_changed(is_blocking)
signal ui_target_requested(enemy: Node)
signal enemy_ui_changed(snapshot: Dictionary)

@export_enum("simple", "elite", "boss") var enemy_type: String = "simple"
@export var blocks_repeat_potions: bool = true
@export var require_engagement_to_block_repeat_potions: bool = false

@export var max_health: int = 20
@export var current_health: int = 20
@export var damage: int = 5
@export var armor: int = 0
@export var move_speed: float = 100.0
@export var chase_speed: float = 120.0
@export var attack_range: float = 120.0
@export var detection_range: float = 150.0
@export var patrol_distance: float = 100.0
@export var ui_display_name: String = "Ящер-копейщик"
@export var ui_icon_texture: Texture2D
@export var require_line_of_sight_before_engage: bool = true
@export var require_line_of_sight_for_melee: bool = true
@export_flags_2d_physics var line_of_sight_collision_mask: int = 1
@export var line_of_sight_height_offset: float = -28.0
@export var pre_engage_vertical_tolerance: float = 96.0
@export var melee_vertical_tolerance: float = 48.0
@export var use_combat_lane_before_engage: bool = false
@export var use_combat_lane_for_melee: bool = true
@export var combat_lane_probe_depth: float = 96.0
@export var combat_lane_tolerance: float = 20.0
@export var combat_lane_probe_offset_y: float = -6.0
@export var melee_profile: EnemyMeleeProfile

enum State { IDLE, PATROL, CHASE, ATTACK, HURT, DEAD, RETREAT, PARRY, KNOCKDOWN, PRESSURE, RECOVER }
enum AttackProfile { NORMAL, PUNISH_RUSH, PUNISH_HEAVY }
enum ParryPhase { NONE, STARTUP, ACTIVE }
enum PostComboExit { NONE, RETREAT, HOLD, PARRY }
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
const COMBO_FATIGUE_RECOVER_TIME: float = 0.96
const COMBO_FATIGUE_COOLDOWN_TIME: float = 1.18
const COMBO_FATIGUE_RETREAT_CHANCE: float = 0.30
const COMBO_FATIGUE_HOLD_CHANCE: float = 0.15
const RETREAT_TIME_MIN: float = 0.88
const RETREAT_TIME_MAX: float = 1.16
const RETREAT_MIN_COMMIT_TIME: float = 0.72
const RETREAT_SPEED_MULTIPLIER: float = 0.92
const RETREAT_DISTANCE_TARGET: float = 138.0
const PARRY_STARTUP_TIME: float = 0.16
const PARRY_ACTIVE_TIME: float = 2.00
const PARRY_RECOVER_TIME: float = 0.30
const PARRY_COOLDOWN_TIME: float = 3.8
const PARRY_TRIGGER_DISTANCE: float = 136.0
const PARRY_TRIGGER_CHANCE: float = 1.0
const PARRY_ICON_PATH: String = "res://assets/Spell/shield_defence.png"
const SEARCH_IDLE_TIME_MIN: float = 3.0
const SEARCH_IDLE_TIME_MAX: float = 4.0
const ENGAGED_DETECTION_RANGE_MULTIPLIER: float = 2.0
const ALERT_RUSH_SPEED_MULTIPLIER: float = 2.6
const PLAYER_GUARD_FEEDBACK_TIME: float = 1.2
const BACKSTAB_KNOCKDOWN_DEFAULT: float = 0.95
const BACKSTAB_RECOVER_TIME: float = 0.65
const SHIELD_RUSH_PUSHBACK_TIME: float = 0.22
const ATTACK_HIT_FRAME: int = 3
const FACING_DEADZONE_X: float = 12.0
const NORMAL_ATTACK_HIT_TELL: float = 0.24
const NORMAL_ATTACK_SPEED_SCALE: float = 1.05
const NORMAL_MEDIUM_ATTACK_CHANCE: float = 0.35
const NORMAL_MEDIUM_ATTACK_DAMAGE_MULTIPLIER: float = 1.2
const NORMAL_MEDIUM_HIT_TELL: float = 0.34
const NORMAL_MEDIUM_HOLD_TIME: float = 0.16
const PUNISH_RUSH_HIT_TELL: float = 0.18
const PUNISH_RUSH_SPEED_SCALE: float = 1.42
const PUNISH_HEAVY_HIT_TELL: float = 0.34
const PUNISH_HEAVY_SPEED_SCALE: float = 0.9
const PUNISH_HEAVY_HOLD_TIME: float = 0.12
const PUNISH_HEAVY_DAMAGE_MULTIPLIER: float = 1.8
const PUNISH_HEAVY_RECOVER_TIME: float = 1.0
const PUNISH_RUSH_RECOVER_TIME: float = 0.95
const NORMAL_ATTACK_LUNGE_SPEED_MULTIPLIER: float = 0.58
const PUNISH_RUSH_LUNGE_SPEED_MULTIPLIER: float = 0.82
const ATTACK_LUNGE_TIME_FACTOR: float = 0.9

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
var shield_rush_pushback_timer: float = 0.0
var shield_rush_pushback_velocity: float = 0.0
var pressure_timer: float = 0.0
var retreat_timer: float = 0.0
var recover_timer: float = 0.0
var retreat_commit_timer: float = 0.0
var parry_phase: int = ParryPhase.NONE
var parry_timer: float = 0.0
var parry_cooldown: float = 0.0
var combo_hits_remaining: int = 0
var combo_chain_timer: float = 0.0
var combo_continuation_pending: bool = false
var engage_rush_timer: float = 0.0
var knockdown_timer: float = 0.0
var queued_counter_combo: bool = false
var target_attack_latched: bool = false
var retreat_target_side: int = 0
var pending_post_combo_exit: int = PostComboExit.NONE
var attack_elapsed: float = 0.0
var attack_profile: int = AttackProfile.NORMAL
var attack_damage_multiplier: float = 1.0
var attack_hit_tell_time: float = NORMAL_ATTACK_HIT_TELL
var attack_post_recover_time: float = NORMAL_COMBO_RECOVER_TIME
var attack_reaction_tag: String = "light"
var attack_pre_hit_pause_time: float = 0.0
var use_hurt_recover_pose: bool = false
var heavy_attack_pause_active: bool = false
var heavy_attack_pause_used: bool = false
var heavy_attack_pause_timer: float = 0.0
var attack_commit_direction: float = 0.0
var queued_counter_is_heavy: bool = false
var queued_counter_popup: bool = false
var parry_indicator: Sprite2D = null
var parry_visual_cue_shown: bool = false
var question_indicator_root: Node2D = null
var question_indicator_labels: Array[Label] = []
var is_searching_for_player: bool = false
var base_detection_radius: float = 0.0
var last_damage_attempt_info: Dictionary = {}
var _debug_last_detection_signature: String = ""
var _debug_last_melee_signature: String = ""
var _debug_last_shield_rush_signature: String = ""
var melee_controller: EnemyMeleeController = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var combat_floor_tracker: CombatFloorTracker = get_node_or_null("CombatFloorTracker") as CombatFloorTracker


func _ready() -> void:
	start_position = global_position
	add_to_group("encounter_enemy")
	_setup_melee_controller()

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

	_setup_parry_indicator()
	_setup_question_indicator()
	_cache_detection_radius()
	_ensure_persistence()
	_configure_persistence()

	var saved_state: Dictionary = _load_persistent_state()
	if not saved_state.is_empty():
		apply_persistent_state(saved_state)
		if not is_alive:
			return
		_set_engaged_detection_range_enabled(has_engaged_player)
		return

	_set_engaged_detection_range_enabled(has_engaged_player)
	_change_state(State.IDLE)


func _setup_melee_controller() -> void:
	if melee_profile == null:
		melee_profile = EnemyMeleeProfileScript.new()
	_apply_melee_profile_overrides()
	melee_controller = EnemyMeleeControllerScript.new().setup(self, melee_profile)


func _apply_melee_profile_overrides() -> void:
	if melee_profile == null:
		return
	require_line_of_sight_before_engage = melee_profile.require_line_of_sight_before_engage
	require_line_of_sight_for_melee = melee_profile.require_line_of_sight_for_melee
	line_of_sight_collision_mask = melee_profile.line_of_sight_collision_mask
	line_of_sight_height_offset = melee_profile.line_of_sight_height_offset
	pre_engage_vertical_tolerance = melee_profile.pre_engage_vertical_tolerance
	melee_vertical_tolerance = melee_profile.melee_vertical_tolerance
	use_combat_lane_before_engage = melee_profile.use_combat_lane_before_engage
	use_combat_lane_for_melee = melee_profile.use_combat_lane_for_melee
	combat_lane_probe_depth = melee_profile.combat_lane_probe_depth
	combat_lane_tolerance = melee_profile.combat_lane_tolerance
	combat_lane_probe_offset_y = melee_profile.combat_lane_probe_offset_y


func capture_persistent_state() -> Dictionary:
	var state: Dictionary = save_state()
	state["dead"] = not is_alive
	state["consumed"] = not is_alive
	return state


func get_current_combat_floor_id() -> int:
	if combat_floor_tracker != null:
		var tracker_floor: int = combat_floor_tracker.get_current_floor_id()
		if tracker_floor != -1:
			return tracker_floor
	return _resolve_combat_floor_id_from_world()


func get_last_stable_combat_floor_id() -> int:
	if combat_floor_tracker != null:
		var tracker_floor: int = combat_floor_tracker.get_last_stable_floor_id()
		if tracker_floor != -1:
			return tracker_floor
	return _resolve_combat_floor_id_from_world()


func get_effective_combat_floor_id() -> int:
	if combat_floor_tracker != null:
		var tracker_floor: int = combat_floor_tracker.get_effective_floor_id()
		if tracker_floor != -1:
			return tracker_floor
	return _resolve_combat_floor_id_from_world()


func is_between_combat_floors() -> bool:
	if combat_floor_tracker != null and combat_floor_tracker.get_effective_floor_id() != -1:
		return combat_floor_tracker.is_between_floors()
	return false


func is_on_same_combat_floor(other: Node) -> bool:
	if other == null or not other.has_method("get_effective_combat_floor_id"):
		return false
	var my_floor: int = get_effective_combat_floor_id()
	var other_floor: int = int(other.call("get_effective_combat_floor_id"))
	return my_floor != -1 and my_floor == other_floor


func _resolve_combat_floor_id_from_world() -> int:
	var tree := get_tree()
	if tree == null:
		return -1

	var probe_point: Vector2 = _get_combat_floor_probe_world_point()
	var best_floor_id: int = -1
	var best_priority: int = -2147483648

	for node in tree.get_nodes_in_group("combat_floor_areas"):
		if node == null or not is_instance_valid(node):
			continue
		if not _combat_floor_area_contains_point(node as Node2D, probe_point):
			continue

		var area_priority: int = int(node.get("floor_priority"))
		var area_floor_id: int = int(node.get("floor_id"))
		if area_priority > best_priority or (area_priority == best_priority and area_floor_id > best_floor_id):
			best_priority = area_priority
			best_floor_id = area_floor_id

	return best_floor_id


func _get_combat_floor_probe_world_point() -> Vector2:
	if collision_shape == null or collision_shape.shape == null:
		return global_position + Vector2(0.0, 12.0)
	var local_offset := Vector2(0.0, _get_collision_bottom_extent(collision_shape.shape) + 2.0)
	return collision_shape.to_global(local_offset)


func _get_collision_bottom_extent(shape: Shape2D) -> float:
	if shape is CapsuleShape2D:
		var capsule := shape as CapsuleShape2D
		return capsule.radius + capsule.height * 0.5
	if shape is RectangleShape2D:
		var rectangle := shape as RectangleShape2D
		return rectangle.size.y * 0.5
	if shape is CircleShape2D:
		var circle := shape as CircleShape2D
		return circle.radius
	return 0.0


func _combat_floor_area_contains_point(area_node: Node2D, world_point: Vector2) -> bool:
	if area_node == null or not is_instance_valid(area_node):
		return false
	var shape_node: CollisionShape2D = area_node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or not shape_node.shape is RectangleShape2D:
		return false
	var rect_shape := shape_node.shape as RectangleShape2D
	var scaled_size: Vector2 = rect_shape.size * area_node.global_scale.abs()
	var half_size: Vector2 = scaled_size * 0.5
	var delta: Vector2 = world_point - area_node.global_position
	return absf(delta.x) <= half_size.x and absf(delta.y) <= half_size.y


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

	if target == null and not has_engaged_player:
		_try_acquire_visible_player()

	if not is_on_floor():
		velocity.y += gravity * delta

	if attack_cooldown > 0.0:
		attack_cooldown = maxf(0.0, attack_cooldown - delta)
		if attack_cooldown <= 0.0:
			can_attack = true

	if parry_cooldown > 0.0:
		parry_cooldown = maxf(0.0, parry_cooldown - delta)

	if not _is_target_attack_pressure_active():
		target_attack_latched = false

	if engage_rush_timer > 0.0:
		engage_rush_timer = maxf(0.0, engage_rush_timer - delta)

	if combo_chain_timer > 0.0:
		combo_chain_timer = maxf(0.0, combo_chain_timer - delta)

	if pressure_timer > 0.0:
		pressure_timer = maxf(0.0, pressure_timer - delta)

	if retreat_timer > 0.0:
		retreat_timer = maxf(0.0, retreat_timer - delta)

	if retreat_commit_timer > 0.0:
		retreat_commit_timer = maxf(0.0, retreat_commit_timer - delta)

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

	if shield_rush_pushback_timer > 0.0:
		shield_rush_pushback_timer = maxf(0.0, shield_rush_pushback_timer - delta)
	elif not is_zero_approx(shield_rush_pushback_velocity):
		shield_rush_pushback_velocity = 0.0

	_debug_log_shield_rush_state()

	if current_state == State.ATTACK:
		if heavy_attack_pause_active:
			heavy_attack_pause_timer = maxf(0.0, heavy_attack_pause_timer - delta)
			if heavy_attack_pause_timer <= 0.0:
				heavy_attack_pause_active = false
				if animated_sprite:
					animated_sprite.play()
		else:
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
			_process_attack()
		State.RETREAT:
			_process_retreat()
		State.PARRY:
			_process_parry()
		State.RECOVER:
			_process_recover()
		State.HURT:
			if shield_rush_pushback_timer > 0.0:
				velocity.x = shield_rush_pushback_velocity
			else:
				velocity.x = 0.0
		State.KNOCKDOWN:
			velocity.x = 0.0
		State.DEAD:
			velocity = Vector2.ZERO
			return

	_update_parry_indicator_visual()
	_update_question_indicator_visual()
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
	_emit_enemy_ui_snapshot()
	_clear_searching_for_player()
	_set_engaged_detection_range_enabled(has_engaged_player)

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

	if new_state != State.PARRY:
		parry_visual_cue_shown = false
		_set_parry_indicator_visible(false)

	current_state = new_state
	_debug_log_combat("state", "change_state", {
		"state": _state_to_string(new_state),
		"target": target.name if target != null and is_instance_valid(target) else "<null>",
		"position": global_position,
	})
	if animated_sprite:
		animated_sprite.speed_scale = 1.0

	match new_state:
		State.IDLE:
			_play_anim("idle")
			velocity.x = 0.0
			idle_timer = randf_range(SEARCH_IDLE_TIME_MIN, SEARCH_IDLE_TIME_MAX) if is_searching_for_player else IDLE_TIME
			_set_question_indicator_visible(is_searching_for_player)
		State.PATROL:
			_set_question_indicator_visible(false)
			if animated_sprite:
				animated_sprite.speed_scale = 1.0
			_play_anim("walk")
		State.CHASE:
			_set_question_indicator_visible(false)
			if animated_sprite:
				animated_sprite.speed_scale = 1.1
			_play_anim("walk")
		State.PRESSURE:
			_set_question_indicator_visible(false)
			pressure_timer = randf_range(PRESSURE_REEVALUATE_MIN, PRESSURE_REEVALUATE_MAX)
			velocity.x = 0.0
			_play_anim("walk")
		State.ATTACK:
			_set_question_indicator_visible(false)
			velocity.x = 0.0
			damage_dealt_this_attack = false
			attack_elapsed = 0.0
			heavy_attack_pause_active = false
			heavy_attack_pause_used = false
			heavy_attack_pause_timer = 0.0
			attack_commit_direction = _resolve_attack_commit_direction()
			_face_target()
			_configure_attack_profile()
			if queued_counter_popup:
				_show_combat_popup("Контратака", Color(1.0, 0.72, 0.32, 1.0), 0.95, 42.0, 1.08)
				queued_counter_popup = false
			if animated_sprite:
				animated_sprite.speed_scale = _get_attack_speed_scale()
			_play_anim("attack")
		State.RETREAT:
			_set_question_indicator_visible(false)
			retreat_timer = randf_range(RETREAT_TIME_MIN, RETREAT_TIME_MAX)
			retreat_commit_timer = RETREAT_MIN_COMMIT_TIME
			retreat_target_side = 0
			if target and is_instance_valid(target):
				retreat_target_side = int(signf(target.global_position.x - global_position.x))
			velocity.x = 0.0
			if animated_sprite:
				animated_sprite.speed_scale = 1.1
			_play_anim("Back away")
		State.PARRY:
			_set_question_indicator_visible(false)
			parry_phase = ParryPhase.STARTUP
			parry_timer = PARRY_STARTUP_TIME
			velocity.x = 0.0
			_face_target()
			_play_anim("block")
			parry_visual_cue_shown = false
			_set_parry_indicator_visible(false)
			if animated_sprite:
				animated_sprite.speed_scale = 1.0
				animated_sprite.stop()
				animated_sprite.frame = 0
		State.RECOVER:
			_set_question_indicator_visible(false)
			_set_parry_indicator_visible(false)
			velocity.x = 0.0
			if use_hurt_recover_pose:
				_play_anim("hurt")
			else:
				_play_anim("idle")
		State.HURT:
			_set_question_indicator_visible(false)
			_set_parry_indicator_visible(false)
			_play_anim("hurt")
			velocity.x = 0.0
		State.KNOCKDOWN:
			_set_question_indicator_visible(false)
			_set_parry_indicator_visible(false)
			velocity.x = 0.0
			_play_anim(_get_knockdown_animation_name())
		State.DEAD:
			_set_question_indicator_visible(false)
			_set_parry_indicator_visible(false)
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
		if is_searching_for_player:
			_clear_searching_for_player()
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
		_start_searching_for_player()
		return
	if target.get("is_dead") == true:
		target = null
		_start_searching_for_player()
		return

	var dist: float = global_position.distance_to(target.global_position)
	var dir_x: float = target.global_position.x - global_position.x
	var move_dir: float = signf(dir_x)
	if move_dir == 0.0:
		move_dir = 1.0

	if _is_target_stealth_backstab_active():
		velocity.x = 0.0
		_play_anim("idle")
		return

	_apply_facing(dir_x)

	if not _is_target_in_pressure_lane():
		velocity.x = 0.0
		_play_anim("idle")
		return

	if dist <= PRESSURE_DISTANCE and _is_target_in_pressure_lane():
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
		_start_searching_for_player()
		return
	if target.get("is_dead") == true:
		target = null
		_start_searching_for_player()
		return

	var dist: float = global_position.distance_to(target.global_position)
	var dir_x: float = target.global_position.x - global_position.x
	var move_dir: float = signf(dir_x)
	if move_dir == 0.0:
		move_dir = 1.0

	if _is_target_stealth_backstab_active():
		velocity.x = 0.0
		_play_anim("idle")
		return

	_face_target()

	if not _is_target_in_pressure_lane():
		_change_state(State.CHASE)
		return

	if dist > PRESSURE_DISTANCE + 22.0:
		_change_state(State.CHASE)
		return

	if combo_continuation_pending:
		if combo_chain_timer > 0.0:
			velocity.x = 0.0
			return
		combo_continuation_pending = false
		if combo_hits_remaining > 0 and dist <= attack_range + 18.0 and _can_melee_attack_target():
			_change_state(State.ATTACK)
			return
		combo_hits_remaining = 0
		_begin_combo_fatigue()
		return

	if combo_hits_remaining > 0:
		combo_hits_remaining = 0
		_begin_combo_fatigue()
		return

	if dist <= PARRY_TRIGGER_DISTANCE and _should_enter_parry(dist):
		_change_state(State.PARRY)
		return

	if dist <= attack_range + 18.0 and can_attack and _can_melee_attack_target():
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

	if dist <= attack_range + 14.0 and can_attack and _can_melee_attack_target():
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
		_start_searching_for_player()
		return

	var dir_x: float = target.global_position.x - global_position.x
	var current_target_side: int = int(signf(dir_x))
	if retreat_commit_timer <= 0.0 and retreat_target_side != 0 and current_target_side != 0 and current_target_side != retreat_target_side:
		_change_state(State.PRESSURE)
		return
	if (retreat_commit_timer <= 0.0 and (retreat_timer <= 0.0 or absf(dir_x) >= RETREAT_DISTANCE_TARGET)) or is_on_wall():
		var can_resume_pressure: bool = absf(dir_x) <= PRESSURE_DISTANCE and _is_target_in_pressure_lane()
		_change_state(State.PRESSURE if can_resume_pressure else State.CHASE)
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
		_start_searching_for_player()
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
			parry_visual_cue_shown = true
			_set_parry_indicator_visible(true)
			return
		ParryPhase.ACTIVE:
			_hold_parry_frame(1)
			if parry_timer > 0.0 and not queued_counter_combo:
				return
		_:
			pass

	parry_phase = ParryPhase.NONE
	parry_visual_cue_shown = false
	_set_parry_indicator_visible(false)
	parry_timer = 0.0
	parry_cooldown = PARRY_COOLDOWN_TIME
	if queued_counter_combo:
		queued_counter_combo = false
		_setup_punish_attack(queued_counter_is_heavy)
		queued_counter_is_heavy = false
		_change_state(State.ATTACK)
		return

	queued_counter_is_heavy = false
	queued_counter_popup = false
	_enter_recover(PARRY_RECOVER_TIME, false)


func _process_recover() -> void:
	velocity.x = 0.0
	if current_state != State.RECOVER:
		return
	if recover_timer > 0.0:
		return
	_resolve_post_recover_state()


func _process_attack() -> void:
	if heavy_attack_pause_active:
		velocity.x = 0.0
		return

	var lunge_window: float = attack_hit_tell_time * ATTACK_LUNGE_TIME_FACTOR
	if attack_elapsed >= lunge_window:
		velocity.x = 0.0
		return

	var lunge_multiplier: float = NORMAL_ATTACK_LUNGE_SPEED_MULTIPLIER
	if attack_profile == AttackProfile.PUNISH_RUSH:
		lunge_multiplier = PUNISH_RUSH_LUNGE_SPEED_MULTIPLIER
	elif attack_profile == AttackProfile.PUNISH_HEAVY:
		lunge_multiplier = 0.0

	velocity.x = attack_commit_direction * chase_speed * lunge_multiplier


func _face_target() -> void:
	if target and animated_sprite:
		var dir: float = target.global_position.x - global_position.x
		_apply_facing(dir)


func _apply_facing(dir_x: float) -> void:
	if not animated_sprite:
		return
	if absf(dir_x) < FACING_DEADZONE_X:
		return
	animated_sprite.flip_h = dir_x < 0


func _resolve_attack_commit_direction() -> float:
	if target != null and is_instance_valid(target):
		var dir_x: float = signf(target.global_position.x - global_position.x)
		if dir_x != 0.0:
			return dir_x
	return -1.0 if animated_sprite and animated_sprite.flip_h else 1.0


func _on_detection_entered(body: Node2D) -> void:
	if not is_alive:
		return
	if body.is_in_group("player"):
		if body.get("is_dead") == true:
			return
		if body.has_method("is_hidden_from_enemy") and body.is_hidden_from_enemy(self):
			return
		if not has_engaged_player and not _can_detect_player_before_engage(body):
			return
		target = body
		_debug_log_combat("detect", "entered", {
			"player": body.name,
			"position": body.global_position,
		})
		_clear_searching_for_player()
		if not has_engaged_player:
			has_engaged_player = true
			_set_engaged_detection_range_enabled(true)
			repeat_potion_blocking_changed.emit(is_repeat_potion_blocker())
		_request_ui_target()
		engage_rush_timer = 0.65
		combo_hits_remaining = 0
		combo_continuation_pending = false
		queued_counter_combo = false
		pending_post_combo_exit = PostComboExit.NONE
		if _is_knockdown_locked():
			return
		if current_state == State.HURT and (forced_stagger_timer > 0.0 or shield_rush_pushback_timer > 0.0):
			return
		_change_state(State.CHASE)


func _on_detection_exited(body: Node2D) -> void:
	if not is_alive:
		return
	if body == target:
		_debug_log_combat("detect", "exited", {
			"player": body.name,
			"position": body.global_position,
		})
		if _is_knockdown_locked():
			return
		_start_searching_for_player()


func _play_anim(anim_name: String) -> void:
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name or not animated_sprite.is_playing():
			animated_sprite.play(anim_name)


func _on_frame_changed() -> void:
	if current_state != State.ATTACK or damage_dealt_this_attack:
		return
	if attack_pre_hit_pause_time > 0.0 and not heavy_attack_pause_used and animated_sprite and animated_sprite.frame >= max(0, ATTACK_HIT_FRAME - 1):
		heavy_attack_pause_used = true
		heavy_attack_pause_active = true
		heavy_attack_pause_timer = attack_pre_hit_pause_time
		animated_sprite.stop()
		animated_sprite.frame = max(0, ATTACK_HIT_FRAME - 1)
		return
	if attack_elapsed >= attack_hit_tell_time and animated_sprite.frame >= ATTACK_HIT_FRAME:
		damage_dealt_this_attack = _deal_damage()


func _on_animation_finished() -> void:
	match current_state:
		State.ATTACK:
			if not damage_dealt_this_attack:
				damage_dealt_this_attack = _deal_damage()

			combo_hits_remaining = maxi(0, combo_hits_remaining - 1)
			if combo_hits_remaining > 0 and target and is_instance_valid(target) and target.get("is_dead") != true and global_position.distance_to(target.global_position) <= attack_range + 18.0:
				combo_chain_timer = COMBO_CHAIN_DELAY_TIME
				combo_continuation_pending = true
				_change_state(State.PRESSURE)
				velocity.x = 0.0
				return

			combo_hits_remaining = 0
			combo_continuation_pending = false
			can_attack = false
			queued_counter_combo = false
			if attack_profile == AttackProfile.NORMAL:
				_begin_combo_fatigue()
			else:
				attack_cooldown = attack_post_recover_time
				pending_post_combo_exit = PostComboExit.NONE
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


func _deal_damage() -> bool:
	if not target or not is_instance_valid(target):
		last_damage_attempt_info = {"result": "no_target"}
		_debug_log_combat("damage", "melee_attempt", last_damage_attempt_info)
		return false
	if target.get("is_dead") == true:
		last_damage_attempt_info = {"result": "dead_target"}
		_debug_log_combat("damage", "melee_attempt", last_damage_attempt_info)
		return false

	var dist: float = global_position.distance_to(target.global_position)
	var can_confirm_hit: bool = _can_confirm_committed_melee_hit(target)
	last_damage_attempt_info = {
		"result": "gate_check",
		"dist": dist,
		"can_confirm": can_confirm_hit,
		"target_has_take_damage": target.has_method("take_damage"),
		"player_hp_before": target.get("current_health")
	}
	if dist <= attack_range + 42.0 and can_confirm_hit and target.has_method("take_damage"):
		if target.has_method("register_incoming_attacker"):
			target.register_incoming_attacker(self)
		var total_damage: int = maxi(1, int(round(damage * attack_damage_multiplier)))
		var reaction_tag: String = attack_reaction_tag
		if _is_target_hit_in_back():
			reaction_tag = "heavy"
			total_damage = maxi(total_damage, int(round(damage * PUNISH_HEAVY_DAMAGE_MULTIPLIER)))
		target.take_damage(total_damage, "physical", "Ящерица с копьём", reaction_tag)
		last_damage_attempt_info = {
			"result": "applied",
			"dist": dist,
			"can_confirm": can_confirm_hit,
			"damage": total_damage,
			"reaction": reaction_tag,
			"player_hp_after": target.get("current_health")
		}
		_debug_log_combat("damage", "melee_attempt", last_damage_attempt_info)
		return true
	last_damage_attempt_info = {
		"result": "miss_gate",
		"dist": dist,
		"can_confirm": can_confirm_hit,
		"target_has_take_damage": target.has_method("take_damage")
	}
	_debug_log_combat("damage", "melee_attempt", last_damage_attempt_info)
	return false

func _try_acquire_visible_player() -> void:
	if detection_area == null or not detection_area.monitoring:
		return

	for body in detection_area.get_overlapping_bodies():
		if not (body is Node2D):
			continue
		var player_body: Node2D = body as Node2D
		if not player_body.is_in_group("player"):
			continue
		if player_body.get("is_dead") == true:
			continue
		if player_body.has_method("is_hidden_from_enemy") and player_body.is_hidden_from_enemy(self):
			continue
		if _can_detect_player_before_engage(player_body):
			_on_detection_entered(player_body)
			return


func _can_detect_player_before_engage(player_body: Node2D) -> bool:
	var result: Dictionary = melee_controller.can_detect_player_before_engage(player_body)
	_debug_log_detection_result(player_body, bool(result.get("result", false)), str(result.get("reason", "unknown")), result.get("data", {}))
	return bool(result.get("result", false))


func _can_melee_attack_target() -> bool:
	var result: Dictionary = melee_controller.can_melee_attack_target(target)
	_debug_log_melee_result(bool(result.get("result", false)), str(result.get("reason", "unknown")), result.get("data", {}))
	return bool(result.get("result", false))


func _is_target_in_pressure_lane() -> bool:
	return melee_controller.is_target_in_pressure_lane(target)


func _can_confirm_committed_melee_hit(target_node: Node2D) -> bool:
	return melee_controller.can_confirm_committed_melee_hit(target_node)


func _uses_explicit_combat_floors(target_node: Node2D) -> bool:
	if target_node == null or not is_instance_valid(target_node):
		return false
	return get_effective_combat_floor_id() != -1 and _get_node_effective_combat_floor_id(target_node) != -1


func _get_node_effective_combat_floor_id(target_node: Node) -> int:
	if target_node == null or not is_instance_valid(target_node):
		return -1
	if target_node.has_method("get_effective_combat_floor_id"):
		return int(target_node.call("get_effective_combat_floor_id"))
	return -1


func _is_same_combat_lane(target_node: Node2D) -> bool:
	return melee_controller.is_same_combat_lane(target_node)


func _get_support_surface_y(node: Node2D) -> float:
	return melee_controller.get_support_surface_y(node)


func _build_lane_probe_exclusions(node: Node) -> Array:
	var exclusions: Array = []
	if self is CollisionObject2D:
		exclusions.append((self as CollisionObject2D).get_rid())
	if node is CollisionObject2D and node != self:
		exclusions.append((node as CollisionObject2D).get_rid())
	return exclusions


func _estimate_body_half_height(node: Node2D) -> float:
	var shape_node: CollisionShape2D = node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or shape_node.shape == null:
		return 24.0

	if shape_node.shape is RectangleShape2D:
		return (shape_node.shape as RectangleShape2D).size.y * 0.5
	if shape_node.shape is CapsuleShape2D:
		var capsule: CapsuleShape2D = shape_node.shape as CapsuleShape2D
		return capsule.height * 0.5 + capsule.radius
	if shape_node.shape is CircleShape2D:
		return (shape_node.shape as CircleShape2D).radius

	return 24.0


func _estimate_body_half_width(node: Node2D) -> float:
	var shape_node: CollisionShape2D = node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or shape_node.shape == null:
		return 14.0

	if shape_node.shape is RectangleShape2D:
		return (shape_node.shape as RectangleShape2D).size.x * 0.5
	if shape_node.shape is CapsuleShape2D:
		return (shape_node.shape as CapsuleShape2D).radius
	if shape_node.shape is CircleShape2D:
		return (shape_node.shape as CircleShape2D).radius

	return 14.0


func _is_node_grounded(node: Node) -> bool:
	if node == null or not node.has_method("is_on_floor"):
		return false
	return bool(node.call("is_on_floor"))


func _has_line_of_sight_to(target_node: Node2D) -> bool:
	return melee_controller.has_line_of_sight_to(target_node)


func _get_line_of_sight_origin() -> Vector2:
	return melee_controller.get_line_of_sight_origin()


func _get_line_of_sight_target_position(target_node: Node2D) -> Vector2:
	return melee_controller.get_line_of_sight_target_position(target_node)


func take_damage(amount: int, _type: String = "physical") -> void:
	if not is_alive or current_state == State.DEAD:
		return
	if current_state == State.KNOCKDOWN:
		return
	if current_state == State.PARRY and parry_phase == ParryPhase.ACTIVE:
		queued_counter_combo = true
		queued_counter_is_heavy = true
		queued_counter_popup = true
		parry_timer = 0.0
		_show_combat_popup("ПАРИР.", Color(0.9, 0.95, 1.0, 1.0), 0.75)
		if target and is_instance_valid(target) and target.has_method("apply_guard_break_stun"):
			target.apply_guard_break_stun(0.55)
		return

	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)
	_emit_enemy_ui_snapshot()

	if persistence:
		persistence.save_from_owner()

	if Global and Global.has_method("add_damage_dealt"):
		Global.add_damage_dealt(amount)

	_show_damage_flash()
	_react_to_incoming_damage()

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
	_emit_enemy_ui_snapshot()
	died.emit()


func get_facing_direction() -> int:
	if animated_sprite and animated_sprite.flip_h:
		return -1
	return 1


func force_alert(player: Node2D) -> void:
	if not is_alive or player == null or not is_instance_valid(player):
		return
	target = player
	_clear_searching_for_player()
	engage_rush_timer = 0.65
	if not has_engaged_player:
		has_engaged_player = true
		_set_engaged_detection_range_enabled(true)
		repeat_potion_blocking_changed.emit(is_repeat_potion_blocker())
	_request_ui_target()
	if current_state not in [State.ATTACK, State.KNOCKDOWN, State.HURT, State.PARRY]:
		_change_state(State.CHASE)


func _resolve_damage_attacker() -> Node2D:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	var player: Node = tree.get_first_node_in_group("player")
	if player == null or not (player is Node2D):
		return null
	var player_node: Node2D = player as Node2D
	if player_node.get("is_dead") == true:
		return null
	return player_node


func _react_to_incoming_damage() -> void:
	var player: Node2D = _resolve_damage_attacker()
	if player == null or not is_instance_valid(player):
		return

	if not has_engaged_player:
		has_engaged_player = true
		_set_engaged_detection_range_enabled(true)
		repeat_potion_blocking_changed.emit(is_repeat_potion_blocker())
	_request_ui_target()

	target = player
	_clear_searching_for_player()
	engage_rush_timer = 0.65


func apply_short_stagger(duration: float = 0.45, attacker_x: float = 0.0) -> void:
	if not is_alive or current_state == State.DEAD or current_state == State.KNOCKDOWN:
		return
	forced_stagger_timer = maxf(forced_stagger_timer, duration)
	combo_hits_remaining = 0
	combo_continuation_pending = false
	queued_counter_combo = false
	queued_counter_is_heavy = false
	queued_counter_popup = false
	pending_post_combo_exit = PostComboExit.NONE
	combo_chain_timer = 0.0
	parry_phase = ParryPhase.NONE
	parry_timer = 0.0
	parry_visual_cue_shown = false
	shield_rush_pushback_timer = 0.0
	shield_rush_pushback_velocity = 0.0
	_set_parry_indicator_visible(false)
	if attacker_x != 0.0 and animated_sprite:
		animated_sprite.flip_h = attacker_x < global_position.x
	if current_state != State.HURT:
		_change_state(State.HURT)
	else:
		_play_anim("hurt")


func apply_shield_rush_opening_stagger(duration: float = 0.18, attacker_x: float = 0.0) -> void:
	if not is_alive or current_state == State.DEAD or current_state == State.KNOCKDOWN:
		return
	forced_stagger_timer = maxf(forced_stagger_timer, duration)
	combo_hits_remaining = 0
	combo_continuation_pending = false
	queued_counter_combo = false
	queued_counter_is_heavy = false
	queued_counter_popup = false
	pending_post_combo_exit = PostComboExit.NONE
	combo_chain_timer = 0.0
	parry_phase = ParryPhase.NONE
	parry_timer = 0.0
	parry_visual_cue_shown = false
	can_attack = false
	attack_cooldown = maxf(attack_cooldown, duration)
	shield_rush_pushback_timer = 0.0
	shield_rush_pushback_velocity = 0.0
	_set_parry_indicator_visible(false)
	if attacker_x != 0.0 and animated_sprite:
		animated_sprite.flip_h = attacker_x < global_position.x
	if current_state != State.HURT:
		_change_state(State.HURT)
	else:
		_play_anim("hurt")
	if CombatRuntimeLogger:
		CombatRuntimeLogger.log_event("shield_rush", name, "opening_applied", {
			"duration": duration,
			"attacker_x": attacker_x,
			"state": _state_to_string(current_state),
			"forced_stagger_timer": forced_stagger_timer,
			"attack_cooldown": attack_cooldown,
			"position": global_position,
		})


func apply_backstab_knockdown(duration: float = BACKSTAB_KNOCKDOWN_DEFAULT, attacker_x: float = 0.0) -> void:
	if not is_alive or current_state == State.DEAD:
		return
	if not _has_animation("fall"):
		apply_short_stagger(maxf(0.45, duration * 0.5), attacker_x)
		return

	knockdown_timer = maxf(knockdown_timer, duration)
	forced_stagger_timer = 0.0
	combo_hits_remaining = 0
	combo_continuation_pending = false
	queued_counter_combo = false
	queued_counter_is_heavy = false
	queued_counter_popup = false
	pending_post_combo_exit = PostComboExit.NONE
	combo_chain_timer = 0.0
	velocity.x = 0.0
	parry_phase = ParryPhase.NONE
	parry_timer = 0.0
	parry_visual_cue_shown = false
	_set_parry_indicator_visible(false)
	if attacker_x != 0.0 and animated_sprite:
		animated_sprite.flip_h = attacker_x > global_position.x
	_change_state(State.KNOCKDOWN)
	_show_combat_popup("✦", Color(1.0, 0.92, 0.45, 1.0), maxf(0.7, duration))


func show_player_guard_feedback(duration: float = PLAYER_GUARD_FEEDBACK_TIME) -> void:
	if not is_alive or current_state == State.DEAD:
		return
	combo_hits_remaining = 0
	combo_continuation_pending = false
	queued_counter_combo = false
	queued_counter_is_heavy = false
	queued_counter_popup = false
	pending_post_combo_exit = PostComboExit.NONE
	combo_chain_timer = 0.0
	parry_phase = ParryPhase.NONE
	parry_timer = 0.0
	can_attack = false
	attack_cooldown = maxf(attack_cooldown, duration * 0.9)
	shield_rush_pushback_timer = 0.0
	shield_rush_pushback_velocity = 0.0
	_show_combat_popup("✦ ✦ ✦", Color(1.0, 0.95, 0.55, 1.0), maxf(1.0, duration))
	use_hurt_recover_pose = true
	_enter_recover(duration, true)


func apply_shield_rush_impact(duration: float = PLAYER_GUARD_FEEDBACK_TIME, pushback: float = 96.0, attacker_x: float = 0.0) -> void:
	if not is_alive or current_state == State.DEAD or current_state == State.KNOCKDOWN:
		return

	forced_stagger_timer = maxf(forced_stagger_timer, duration)
	combo_hits_remaining = 0
	combo_continuation_pending = false
	queued_counter_combo = false
	queued_counter_is_heavy = false
	queued_counter_popup = false
	pending_post_combo_exit = PostComboExit.NONE
	combo_chain_timer = 0.0
	parry_phase = ParryPhase.NONE
	parry_timer = 0.0
	parry_visual_cue_shown = false
	can_attack = false
	attack_cooldown = maxf(attack_cooldown, duration * 0.9)
	_set_parry_indicator_visible(false)

	var push_dir: float = 0.0
	if attacker_x != 0.0:
		push_dir = signf(global_position.x - attacker_x)
		if animated_sprite:
			animated_sprite.flip_h = attacker_x < global_position.x
	if push_dir == 0.0:
		push_dir = -1.0 if animated_sprite and animated_sprite.flip_h else 1.0

	shield_rush_pushback_timer = SHIELD_RUSH_PUSHBACK_TIME
	shield_rush_pushback_velocity = push_dir * absf(pushback)
	_show_combat_popup("✦ ✦ ✦", Color(1.0, 0.95, 0.55, 1.0), maxf(1.0, duration))

	if current_state != State.HURT:
		_change_state(State.HURT)
	else:
		_play_anim("hurt")
	if CombatRuntimeLogger:
		CombatRuntimeLogger.log_event("shield_rush", name, "impact_applied", {
			"duration": duration,
			"pushback": pushback,
			"push_dir": push_dir,
			"pushback_timer": shield_rush_pushback_timer,
			"pushback_velocity": shield_rush_pushback_velocity,
			"state": _state_to_string(current_state),
			"forced_stagger_timer": forced_stagger_timer,
			"attack_cooldown": attack_cooldown,
			"position": global_position,
		})


func _debug_log_shield_rush_state() -> void:
	if CombatRuntimeLogger == null:
		return
	var signature: String = "%s|%.2f|%.1f|%.1f|%s" % [
		_state_to_string(current_state),
		shield_rush_pushback_timer,
		shield_rush_pushback_velocity,
		velocity.x,
		str(can_attack),
	]
	if signature == _debug_last_shield_rush_signature:
		return
	_debug_last_shield_rush_signature = signature
	if shield_rush_pushback_timer <= 0.0 and is_zero_approx(shield_rush_pushback_velocity) and current_state != State.HURT:
		return
	CombatRuntimeLogger.log_event("shield_rush", name, "pushback_state", {
		"state": _state_to_string(current_state),
		"pushback_timer": shield_rush_pushback_timer,
		"pushback_velocity": shield_rush_pushback_velocity,
		"velocity_x": velocity.x,
		"forced_stagger_timer": forced_stagger_timer,
		"can_attack": can_attack,
		"position": global_position,
	})
func _has_animation(anim_name: String) -> bool:
	return animated_sprite != null and animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(anim_name)


func _get_knockdown_animation_name() -> String:
	if _has_animation("fall"):
		return "fall"
	return "hurt"


func _should_enter_parry(dist: float) -> bool:
	if parry_cooldown > 0.0 or dist > PARRY_TRIGGER_DISTANCE:
		return false
	if target != null and is_instance_valid(target) and target.has_method("is_stealth_backstab_attack_active_against"):
		if bool(target.is_stealth_backstab_attack_active_against(self)):
			return false
	if not _is_target_in_pressure_lane():
		return false
	if not _is_target_attack_pressure_active():
		return false
	if target_attack_latched:
		return false
	target_attack_latched = true
	return randf() <= PARRY_TRIGGER_CHANCE


func _is_target_attack_pressure_active() -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if target.has_method("is_parryable_attack_active"):
		return bool(target.is_parryable_attack_active())
	return target.get("is_attacking") == true


func _setup_normal_combo() -> void:
	attack_profile = AttackProfile.NORMAL
	combo_hits_remaining = randi_range(COMBO_MIN_HITS, COMBO_MAX_HITS)
	combo_continuation_pending = false
	pending_post_combo_exit = PostComboExit.NONE
	if randf() <= NORMAL_MEDIUM_ATTACK_CHANCE:
		attack_damage_multiplier = NORMAL_MEDIUM_ATTACK_DAMAGE_MULTIPLIER
		attack_hit_tell_time = NORMAL_MEDIUM_HIT_TELL
		attack_reaction_tag = "hurt"
		attack_pre_hit_pause_time = NORMAL_MEDIUM_HOLD_TIME
	else:
		attack_damage_multiplier = 1.0
		attack_hit_tell_time = NORMAL_ATTACK_HIT_TELL
		attack_reaction_tag = "light"
		attack_pre_hit_pause_time = 0.0
	attack_post_recover_time = NORMAL_COMBO_RECOVER_TIME


func _setup_punish_attack(force_heavy: bool = false) -> void:
	if force_heavy:
		attack_profile = AttackProfile.PUNISH_HEAVY
		combo_hits_remaining = 1
		combo_continuation_pending = false
		pending_post_combo_exit = PostComboExit.NONE
		attack_damage_multiplier = PUNISH_HEAVY_DAMAGE_MULTIPLIER
		attack_hit_tell_time = PUNISH_HEAVY_HIT_TELL
		attack_post_recover_time = PUNISH_HEAVY_RECOVER_TIME
		attack_reaction_tag = "heavy"
		attack_pre_hit_pause_time = PUNISH_HEAVY_HOLD_TIME
		return
	if randf() <= 0.72:
		attack_profile = AttackProfile.PUNISH_RUSH
		combo_hits_remaining = randi_range(COMBO_MIN_HITS, COMBO_MAX_HITS)
		combo_continuation_pending = false
		pending_post_combo_exit = PostComboExit.NONE
		attack_damage_multiplier = 1.1
		attack_hit_tell_time = PUNISH_RUSH_HIT_TELL
		attack_post_recover_time = PUNISH_RUSH_RECOVER_TIME
		attack_reaction_tag = "light"
		attack_pre_hit_pause_time = 0.0
	else:
		attack_profile = AttackProfile.PUNISH_HEAVY
		combo_hits_remaining = 1
		combo_continuation_pending = false
		pending_post_combo_exit = PostComboExit.NONE
		attack_damage_multiplier = PUNISH_HEAVY_DAMAGE_MULTIPLIER
		attack_hit_tell_time = PUNISH_HEAVY_HIT_TELL
		attack_post_recover_time = PUNISH_HEAVY_RECOVER_TIME
		attack_reaction_tag = "heavy"
		attack_pre_hit_pause_time = PUNISH_HEAVY_HOLD_TIME


func _configure_attack_profile() -> void:
	if combo_hits_remaining <= 0:
		_setup_normal_combo()


func _is_target_stealth_backstab_active() -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if not target.has_method("is_stealth_backstab_attack_active_against"):
		return false
	return bool(target.is_stealth_backstab_attack_active_against(self))


func _is_target_hit_in_back() -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if not target.has_method("get_facing_direction"):
		return false
	var target_facing: float = float(target.get_facing_direction())
	var attacker_side: float = signf(global_position.x - target.global_position.x)
	if attacker_side == 0.0:
		return false
	if absf(global_position.x - target.global_position.x) <= 10.0:
		return false
	return attacker_side != target_facing


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
	if pending_post_combo_exit != PostComboExit.NONE and target and is_instance_valid(target) and target.get("is_dead") != true:
		var post_combo_exit: int = pending_post_combo_exit
		pending_post_combo_exit = PostComboExit.NONE
		match post_combo_exit:
			PostComboExit.RETREAT:
				_change_state(State.RETREAT)
				return
			PostComboExit.HOLD:
				pressure_timer = randf_range(PRESSURE_REEVALUATE_MIN, PRESSURE_REEVALUATE_MAX) + 0.32
				_change_state(State.PRESSURE)
				return
			PostComboExit.PARRY:
				_change_state(State.PARRY)
				return
			_:
				pass

	if target and is_instance_valid(target) and target.get("is_dead") != true:
		var dist: float = global_position.distance_to(target.global_position)
		if dist <= PRESSURE_DISTANCE:
			_change_state(State.PRESSURE)
		else:
			_change_state(State.CHASE)
	else:
		_start_searching_for_player()


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


func _begin_combo_fatigue() -> void:
	attack_cooldown = maxf(attack_cooldown, COMBO_FATIGUE_COOLDOWN_TIME)
	combo_continuation_pending = false
	if target and is_instance_valid(target) and target.get("is_dead") != true:
		var dist: float = global_position.distance_to(target.global_position)
		if dist <= PRESSURE_DISTANCE:
			var roll: float = randf()
			if roll <= COMBO_FATIGUE_RETREAT_CHANCE:
				pending_post_combo_exit = PostComboExit.RETREAT
			elif roll <= COMBO_FATIGUE_RETREAT_CHANCE + COMBO_FATIGUE_HOLD_CHANCE:
				pending_post_combo_exit = PostComboExit.HOLD
			else:
				pending_post_combo_exit = PostComboExit.PARRY
		else:
			pending_post_combo_exit = PostComboExit.HOLD
	else:
		pending_post_combo_exit = PostComboExit.NONE
	_enter_recover(COMBO_FATIGUE_RECOVER_TIME, false)


func _setup_parry_indicator() -> void:
	if parry_indicator != null:
		return
	if not ResourceLoader.exists(PARRY_ICON_PATH):
		return

	parry_indicator = Sprite2D.new()
	parry_indicator.name = "ParryIndicator"
	parry_indicator.texture = load(PARRY_ICON_PATH)
	parry_indicator.position = Vector2(0.0, -88.0)
	parry_indicator.scale = Vector2(0.68, 0.68)
	parry_indicator.z_index = 18
	parry_indicator.modulate = Color(0.85, 0.95, 1.15, 0.0)
	parry_indicator.visible = false
	add_child(parry_indicator)


func _set_parry_indicator_visible(is_visible: bool) -> void:
	if parry_indicator == null:
		return
	parry_indicator.visible = is_visible
	if not is_visible:
		parry_indicator.modulate = Color(0.85, 0.95, 1.15, 0.0)
		parry_indicator.scale = Vector2(0.68, 0.68)
		return
	parry_indicator.modulate = Color(0.95, 1.05, 1.25, 0.95)


func _update_parry_indicator_visual() -> void:
	if parry_indicator == null:
		return
	if current_state != State.PARRY or parry_phase != ParryPhase.ACTIVE:
		if parry_indicator.visible:
			_set_parry_indicator_visible(false)
		return
	if not parry_indicator.visible:
		return
	var pulse_time: float = Time.get_ticks_msec() / 1000.0
	var pulse: float = 0.5 + 0.5 * sin(pulse_time * 8.0)
	var scale: float = 0.68 + (pulse * 0.16)
	parry_indicator.scale = Vector2(scale, scale)
	parry_indicator.modulate = Color(
		0.88 + pulse * 0.20,
		0.95 + pulse * 0.12,
		1.18 + pulse * 0.22,
		0.78 + pulse * 0.20
	)


func _show_combat_popup(text: String, color: Color, duration: float = 0.35, rise_distance: float = 18.0, popup_scale: float = 1.0) -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return

	var label := Label.new()
	label.text = text
	label.top_level = true
	label.z_index = 100
	label.position = global_position + Vector2(-24.0, -92.0)
	label.modulate = color
	label.scale = Vector2.ONE * popup_scale
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	get_tree().current_scene.add_child(label)

	var tween: Tween = create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0.0, -rise_distance), duration)
	tween.parallel().tween_property(label, "modulate:a", 0.0, duration)
	tween.tween_callback(Callable(label, "queue_free"))


func get_enemy_ui_snapshot() -> Dictionary:
	return {
		"enemy_id": persistence.get_persistent_id() if persistence != null else name,
		"display_name": ui_display_name if not ui_display_name.is_empty() else name,
		"icon_texture": _get_enemy_ui_icon(),
		"health": current_health,
		"max_health": max_health,
		"armor": armor,
		"status_effects": get_enemy_status_effects(),
	}


func get_enemy_status_effects() -> Array[Dictionary]:
	return []


func _get_enemy_ui_icon() -> Texture2D:
	if ui_icon_texture != null:
		return ui_icon_texture
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return null
	if animated_sprite.sprite_frames.has_animation("idle") and animated_sprite.sprite_frames.get_frame_count("idle") > 0:
		return animated_sprite.sprite_frames.get_frame_texture("idle", 0)
	if animated_sprite.sprite_frames.has_animation(animated_sprite.animation) and animated_sprite.sprite_frames.get_frame_count(animated_sprite.animation) > 0:
		return animated_sprite.sprite_frames.get_frame_texture(animated_sprite.animation, 0)
	return null


func _emit_enemy_ui_snapshot() -> void:
	enemy_ui_changed.emit(get_enemy_ui_snapshot())


func _request_ui_target() -> void:
	ui_target_requested.emit(self)
	_emit_enemy_ui_snapshot()


func _state_to_string(state_value: int) -> String:
	match state_value:
		State.IDLE:
			return "IDLE"
		State.PATROL:
			return "PATROL"
		State.CHASE:
			return "CHASE"
		State.ATTACK:
			return "ATTACK"
		State.HURT:
			return "HURT"
		State.DEAD:
			return "DEAD"
		State.RETREAT:
			return "RETREAT"
		State.PARRY:
			return "PARRY"
		State.KNOCKDOWN:
			return "KNOCKDOWN"
		State.PRESSURE:
			return "PRESSURE"
		State.RECOVER:
			return "RECOVER"
		_:
			return "UNKNOWN"


func _debug_log_combat(category: String, message: String, data: Dictionary = {}) -> void:
	if CombatRuntimeLogger:
		CombatRuntimeLogger.log_event(category, name, message, data)


func _debug_log_detection_result(player_body: Node2D, result: bool, reason: String, extra: Dictionary = {}) -> void:
	var signature: String = "%s|%s|%s" % [
		player_body.name if player_body != null else "<null>",
		str(result),
		reason,
	]
	if signature == _debug_last_detection_signature:
		return
	_debug_last_detection_signature = signature
	var payload: Dictionary = {
		"result": result,
		"reason": reason,
		"player": player_body.name if player_body != null else "<null>",
		"enemy_pos": global_position,
		"player_pos": player_body.global_position if player_body != null else Vector2.ZERO,
		"engaged": has_engaged_player,
	}
	payload.merge(extra, true)
	_debug_log_combat("detect", "pre_engage_check", payload)


func _debug_log_melee_result(result: bool, reason: String, extra: Dictionary = {}) -> void:
	var signature: String = "%s|%s|%s|%s" % [
		target.name if target != null and is_instance_valid(target) else "<null>",
		str(result),
		reason,
		_state_to_string(current_state),
	]
	if signature == _debug_last_melee_signature:
		return
	_debug_last_melee_signature = signature
	var payload: Dictionary = {
		"result": result,
		"reason": reason,
		"target": target.name if target != null and is_instance_valid(target) else "<null>",
		"enemy_pos": global_position,
		"target_pos": target.global_position if target != null and is_instance_valid(target) else Vector2.ZERO,
		"state": _state_to_string(current_state),
	}
	payload.merge(extra, true)
	_debug_log_combat("melee", "check", payload)


func _cache_detection_radius() -> void:
	if detection_shape == null:
		return
	var circle: CircleShape2D = detection_shape.shape as CircleShape2D
	if circle == null:
		return
	base_detection_radius = circle.radius


func _set_engaged_detection_range_enabled(is_enabled: bool) -> void:
	if detection_shape == null:
		return
	var circle: CircleShape2D = detection_shape.shape as CircleShape2D
	if circle == null:
		return
	if base_detection_radius <= 0.0:
		base_detection_radius = circle.radius
	circle.radius = base_detection_radius * ENGAGED_DETECTION_RANGE_MULTIPLIER if is_enabled else base_detection_radius


func _setup_question_indicator() -> void:
	if question_indicator_root != null:
		return
	question_indicator_root = Node2D.new()
	question_indicator_root.name = "QuestionIndicator"
	question_indicator_root.position = Vector2(0.0, -94.0)
	question_indicator_root.z_index = 18
	question_indicator_root.visible = false
	add_child(question_indicator_root)

	var positions: Array[Vector2] = [Vector2(-18.0, 10.0), Vector2(0.0, 0.0), Vector2(18.0, 10.0)]
	for index in positions.size():
		var marker := Label.new()
		marker.text = "?"
		marker.position = positions[index]
		marker.modulate = Color(1.0, 0.98, 0.78, 0.0)
		marker.z_index = 18
		marker.add_theme_color_override("font_color", Color(1.0, 0.98, 0.78, 1.0))
		marker.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		marker.add_theme_constant_override("outline_size", 4)
		question_indicator_root.add_child(marker)
		question_indicator_labels.append(marker)


func _set_question_indicator_visible(is_visible: bool) -> void:
	if question_indicator_root == null:
		return
	question_indicator_root.visible = is_visible
	for marker in question_indicator_labels:
		if marker == null:
			continue
		marker.modulate.a = 0.95 if is_visible else 0.0


func _update_question_indicator_visual() -> void:
	if question_indicator_root == null or not question_indicator_root.visible:
		return
	var time: float = Time.get_ticks_msec() / 1000.0
	var side_offset: float = sin(time * 6.0) * 5.0
	var center_offset: float = -side_offset
	var base_positions: Array[Vector2] = [Vector2(-18.0, 10.0), Vector2(0.0, 0.0), Vector2(18.0, 10.0)]
	for index in question_indicator_labels.size():
		var marker: Label = question_indicator_labels[index]
		if marker == null:
			continue
		var offset_y: float = center_offset if index == 1 else side_offset
		marker.position = base_positions[index] + Vector2(0.0, offset_y)
		marker.modulate.a = 0.82 + 0.13 * sin(time * 7.0 + index)


func _clear_searching_for_player() -> void:
	is_searching_for_player = false
	_set_question_indicator_visible(false)


func _start_searching_for_player() -> void:
	if _is_knockdown_locked():
		is_searching_for_player = has_engaged_player
		return
	target = null
	combo_hits_remaining = 0
	combo_continuation_pending = false
	queued_counter_combo = false
	queued_counter_is_heavy = false
	pending_post_combo_exit = PostComboExit.NONE
	combo_chain_timer = 0.0
	engage_rush_timer = 0.0
	pressure_timer = 0.0
	retreat_timer = 0.0
	retreat_commit_timer = 0.0
	parry_phase = ParryPhase.NONE
	parry_timer = 0.0
	target_attack_latched = false
	is_searching_for_player = has_engaged_player
	_change_state(State.IDLE)


func _is_knockdown_locked() -> bool:
	return current_state == State.KNOCKDOWN and knockdown_timer > 0.0


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
