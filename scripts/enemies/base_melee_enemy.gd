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

@export var max_health: int = 6
@export var current_health: int = 6
@export var attack_damage: int = 1
@export var move_speed: float = 80.0
@export var chase_speed: float = 110.0
@export var attack_range: float = 96.0
@export var detection_range: float = 220.0
@export var patrol_distance: float = 0.0
@export var attack_cooldown_time: float = 1.0
@export var idle_time: float = 1.2
@export var minimum_distance_to_player: float = 42.0
@export var enable_patrol: bool = false
@export var armor: int = 0
@export var ui_display_name: String = ""
@export var ui_icon_texture: Texture2D
@export var require_line_of_sight_before_engage: bool = true
@export var require_line_of_sight_for_melee: bool = true
@export_flags_2d_physics var line_of_sight_collision_mask: int = 1
@export var line_of_sight_height_offset: float = -28.0
@export var pre_engage_vertical_tolerance: float = 56.0
@export var melee_vertical_tolerance: float = 48.0
@export var use_combat_lane_before_engage: bool = true
@export var use_combat_lane_for_melee: bool = true
@export var combat_lane_probe_depth: float = 96.0
@export var combat_lane_tolerance: float = 20.0
@export var combat_lane_probe_offset_y: float = -6.0
@export var facing_deadzone_x: float = 12.0
@export var melee_profile: EnemyMeleeProfile

enum State { IDLE, PATROL, CHASE, ATTACK, HURT, DEAD }

const PERSISTENCE_COMPONENT := preload("res://scripts/persistence/persistence_component.gd")

var current_state: State = State.IDLE
var start_position: Vector2
var patrol_direction: int = 1
var target: Node2D = null
var can_attack: bool = true
var damage_dealt_this_attack: bool = false
var idle_timer: float = 0.0
var attack_cooldown: float = 0.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_alive: bool = true
var is_active: bool = true
var has_engaged_player: bool = false
var current_attack_animation: StringName = &"attack_1"
var current_attack_damage: int = 0
var current_attack_damage_frame: int = 3
var persistence: PersistenceComponent = null
var _debug_last_detection_signature: String = ""
var _debug_last_melee_signature: String = ""
var melee_controller: EnemyMeleeController = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea
@onready var combat_floor_tracker: CombatFloorTracker = get_node_or_null("CombatFloorTracker") as CombatFloorTracker


func _ready() -> void:
	start_position = global_position
	current_health = clampi(current_health, 1, max_health)
	add_to_group("encounter_enemy")
	_setup_melee_controller()

	_initialize_enemy()
	_update_detection_range()

	if detection_area != null:
		if not detection_area.body_entered.is_connected(_on_detection_entered):
			detection_area.body_entered.connect(_on_detection_entered)
		if not detection_area.body_exited.is_connected(_on_detection_exited):
			detection_area.body_exited.connect(_on_detection_exited)

	if animated_sprite != null:
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
		return

	_change_state(State.IDLE)


func _initialize_enemy() -> void:
	pass


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
	facing_deadzone_x = melee_profile.facing_deadzone_x


func get_current_combat_floor_id() -> int:
	return combat_floor_tracker.get_current_floor_id() if combat_floor_tracker != null else -1


func get_last_stable_combat_floor_id() -> int:
	return combat_floor_tracker.get_last_stable_floor_id() if combat_floor_tracker != null else -1


func get_effective_combat_floor_id() -> int:
	return combat_floor_tracker.get_effective_floor_id() if combat_floor_tracker != null else -1


func is_between_combat_floors() -> bool:
	return combat_floor_tracker.is_between_floors() if combat_floor_tracker != null else false


func is_on_same_combat_floor(other: Node) -> bool:
	if other == null or not other.has_method("get_effective_combat_floor_id"):
		return false
	var my_floor: int = get_effective_combat_floor_id()
	var other_floor: int = int(other.call("get_effective_combat_floor_id"))
	return my_floor != -1 and my_floor == other_floor


func capture_persistent_state() -> Dictionary:
	var state: Dictionary = save_state()
	state["dead"] = not is_alive
	state["consumed"] = not is_alive
	return state


func apply_persistent_state(state: Dictionary) -> void:
	load_state(state)


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

	if collision_shape != null:
		collision_shape.set_deferred("disabled", false)
	if detection_area != null:
		detection_area.set_deferred("monitoring", true)
		detection_area.set_deferred("monitorable", true)
	if animated_sprite != null:
		animated_sprite.modulate = Color.WHITE

	health_changed.emit(current_health)
	_emit_enemy_ui_snapshot()

	var saved_state: int = int(state.get("current_state", State.IDLE))
	current_state = State.IDLE
	_change_state(saved_state)


func _ensure_persistence() -> void:
	persistence = get_node_or_null("Persistence")
	if persistence != null:
		return

	persistence = PERSISTENCE_COMPONENT.new()
	persistence.name = "Persistence"
	add_child(persistence)


func _configure_persistence() -> void:
	if persistence != null:
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
	else:
		velocity.y = 0.0

	if attack_cooldown > 0.0:
		attack_cooldown -= delta
		if attack_cooldown <= 0.0:
			can_attack = true

	if current_state == State.ATTACK and not _can_continue_current_attack():
		_interrupt_current_attack()
		move_and_slide()
		return

	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.PATROL:
			_process_patrol()
		State.CHASE:
			_process_chase()
		State.ATTACK:
			velocity.x = 0.0
		State.HURT:
			velocity.x = 0.0
		State.DEAD:
			velocity = Vector2.ZERO
			return

	move_and_slide()


func is_repeat_potion_blocker() -> bool:
	if not blocks_repeat_potions or not is_alive:
		return false
	if require_engagement_to_block_repeat_potions and not has_engaged_player:
		return false
	return true


func activate() -> void:
	if is_alive:
		is_active = true
		visible = true
		set_physics_process(true)


func deactivate() -> void:
	is_active = false
	set_physics_process(false)
	if animated_sprite != null:
		animated_sprite.stop()


func take_damage(amount: int, _damage_type: String = "physical") -> void:
	if not is_alive or current_state == State.DEAD:
		return

	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)
	_emit_enemy_ui_snapshot()

	if persistence != null:
		persistence.save_from_owner()

	if Global and Global.has_method("add_damage_dealt"):
		Global.add_damage_dealt(amount)

	_show_damage_flash()
	_react_to_incoming_damage()

	if current_health <= 0:
		_die()
	else:
		_change_state(State.HURT)


func _process_idle(delta: float) -> void:
	velocity.x = 0.0
	idle_timer -= delta
	if idle_timer <= 0.0:
		if _can_patrol():
			_change_state(State.PATROL)
		else:
			idle_timer = _get_idle_duration()
			_play_anim(_select_idle_animation())


func _process_patrol() -> void:
	if not _can_patrol():
		_change_state(State.IDLE)
		return

	if is_on_wall():
		patrol_direction *= -1
		_change_state(State.IDLE)
		return

	var dist_from_start: float = global_position.x - start_position.x
	if patrol_direction > 0 and dist_from_start >= patrol_distance:
		patrol_direction = -1
		_change_state(State.IDLE)
		return
	if patrol_direction < 0 and dist_from_start <= -patrol_distance:
		patrol_direction = 1
		_change_state(State.IDLE)
		return

	velocity.x = patrol_direction * move_speed
	if animated_sprite != null:
		animated_sprite.flip_h = patrol_direction < 0


func _process_chase() -> void:
	if not _is_target_valid():
		target = null
		_change_state(_get_lost_target_state())
		return

	var dir_x: float = target.global_position.x - global_position.x
	var dist: float = absf(dir_x)

	if animated_sprite != null:
		animated_sprite.flip_h = dir_x < 0.0
		_play_anim(_select_chase_animation())

	if dist <= attack_range and can_attack and _can_melee_attack_target():
		_change_state(State.ATTACK)
		return

	if dist <= attack_range and not can_attack and _can_melee_attack_target():
		velocity.x = 0.0
		return

	if dist <= minimum_distance_to_player:
		velocity.x = -signf(dir_x) * move_speed * 0.5
		return

	velocity.x = signf(dir_x) * _get_effective_chase_speed()


func _change_state(new_state: State) -> void:
	if current_state == State.DEAD and not is_alive:
		return
	if current_state == new_state and new_state != State.IDLE:
		return

	current_state = new_state
	_debug_log_combat("state", "change_state", {
		"state": _state_to_string(new_state),
		"target": target.name if target != null and is_instance_valid(target) else "<null>",
		"position": global_position,
	})

	match new_state:
		State.IDLE:
			idle_timer = _get_idle_duration()
			velocity.x = 0.0
			_play_anim(_select_idle_animation())
		State.PATROL:
			_play_anim(_select_patrol_animation())
		State.CHASE:
			_play_anim(_select_chase_animation())
		State.ATTACK:
			velocity.x = 0.0
			damage_dealt_this_attack = false
			_face_target()
			var attack_profile: Dictionary = _select_attack_profile()
			current_attack_animation = StringName(String(attack_profile.get("animation", "attack_1")))
			current_attack_damage = int(attack_profile.get("damage", attack_damage))
			current_attack_damage_frame = int(attack_profile.get("damage_frame", 3))
			_play_anim(current_attack_animation)
		State.HURT:
			velocity.x = 0.0
			_play_anim(_get_hurt_animation())
		State.DEAD:
			velocity = Vector2.ZERO
			_disable_collision()
			_play_anim(_get_death_animation())


func _select_idle_animation() -> StringName:
	return &"idle"


func _select_patrol_animation() -> StringName:
	return &"walk"


func _select_chase_animation() -> StringName:
	return &"walk"


func _select_attack_profile() -> Dictionary:
	return {
		"animation": "attack_1",
		"damage": attack_damage,
		"damage_frame": 3,
	}


func _get_hurt_animation() -> StringName:
	return &"hurt"


func _get_death_animation() -> StringName:
	return &"death"


func _get_idle_duration() -> float:
	return idle_time


func _get_effective_chase_speed() -> float:
	return chase_speed


func _can_patrol() -> bool:
	return enable_patrol and patrol_distance > 0.0


func _get_lost_target_state() -> State:
	if _can_patrol():
		return State.PATROL
	return State.IDLE


func _is_target_valid() -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if target.get("is_dead") == true:
		return false
	return true


func _face_target() -> void:
	if target != null and animated_sprite != null:
		var dir_x: float = target.global_position.x - global_position.x
		if absf(dir_x) < facing_deadzone_x:
			return
		animated_sprite.flip_h = dir_x < 0.0


func _play_anim(anim_name: StringName) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		return
	if animated_sprite.animation != anim_name or not animated_sprite.is_playing():
		animated_sprite.play(anim_name)


func _disable_collision() -> void:
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	if detection_area != null:
		detection_area.monitoring = false
		detection_area.monitorable = false


func _set_dead_state() -> void:
	is_alive = false
	is_active = false
	current_state = State.DEAD
	visible = false
	repeat_potion_blocking_changed.emit(false)

	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	if detection_area != null:
		detection_area.set_deferred("monitoring", false)
		detection_area.set_deferred("monitorable", false)

	set_physics_process(false)


func _on_detection_entered(body: Node2D) -> void:
	if not is_alive:
		return
	if not body.is_in_group("player"):
		return
	if body.get("is_dead") == true:
		return
	if not has_engaged_player and not _can_detect_player_before_engage(body):
		return

	target = body
	_debug_log_combat("detect", "entered", {
		"player": body.name,
		"position": body.global_position,
	})
	if not has_engaged_player:
		has_engaged_player = true
		repeat_potion_blocking_changed.emit(is_repeat_potion_blocker())
	_request_ui_target()

	_change_state(State.CHASE)


func _on_detection_exited(body: Node2D) -> void:
	if not is_alive:
		return
	if body != target:
		return

	target = null
	_debug_log_combat("detect", "exited", {
		"player": body.name,
		"position": body.global_position,
	})
	_change_state(_get_lost_target_state())


func _on_frame_changed() -> void:
	if current_state != State.ATTACK or damage_dealt_this_attack:
		return
	if animated_sprite != null and animated_sprite.frame == current_attack_damage_frame:
		damage_dealt_this_attack = _deal_damage()


func _on_animation_finished() -> void:
	match current_state:
		State.ATTACK:
			if not damage_dealt_this_attack:
				damage_dealt_this_attack = _deal_damage()

			can_attack = false
			attack_cooldown = attack_cooldown_time

			if _is_target_valid():
				_change_state(State.CHASE)
			else:
				target = null
				_change_state(_get_lost_target_state())
		State.HURT:
			if _is_target_valid():
				_change_state(State.CHASE)
			else:
				_change_state(_get_lost_target_state())
		State.DEAD:
			_on_death_completed()


func _deal_damage() -> bool:
	if not _is_target_valid():
		_debug_log_combat("damage", "melee_attempt", {"result": "no_target"})
		return false

	var dist: float = global_position.distance_to(target.global_position)
	if dist <= attack_range + 32.0 and _can_confirm_committed_melee_hit(target) and target.has_method("take_damage"):
		target.take_damage(current_attack_damage, "physical", name)
		_debug_log_combat("damage", "melee_attempt", {
			"result": "applied",
			"distance": dist,
			"damage": current_attack_damage,
			"target": target.name,
			"target_hp_after": target.get("current_health"),
		})
		return true
	_debug_log_combat("damage", "melee_attempt", {
		"result": "blocked",
		"distance": dist,
		"target": target.name if target != null else "<null>",
		"confirm_hit": _can_confirm_committed_melee_hit(target),
	})
	return false


func _show_damage_flash() -> void:
	if animated_sprite == null:
		return

	animated_sprite.modulate = Color(2.0, 0.5, 0.5)
	var tween: Tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)


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


func _can_confirm_committed_melee_hit(target_node: Node2D) -> bool:
	return melee_controller.can_confirm_committed_melee_hit(target_node)


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


func _can_continue_current_attack() -> bool:
	if _is_cast_attack_animation(current_attack_animation):
		return _can_continue_cast_attack()
	# Once a melee swing starts, let it finish; hit confirmation is handled separately
	# in _deal_damage(). Otherwise moving targets cancel the attack every frame.
	return _is_target_valid()


func _interrupt_current_attack() -> void:
	damage_dealt_this_attack = false
	if _is_target_valid():
		_change_state(State.CHASE)
	else:
		target = null
		_change_state(_get_lost_target_state())


func _is_cast_attack_animation(_animation_name: StringName) -> bool:
	return false


func _can_continue_cast_attack() -> bool:
	return _is_target_valid()


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

	target = player
	if not has_engaged_player:
		has_engaged_player = true
		repeat_potion_blocking_changed.emit(is_repeat_potion_blocker())
	_request_ui_target()


func _die() -> void:
	if Global and Global.has_method("add_enemy_killed"):
		Global.add_enemy_killed(enemy_type)
	if Global:
		Global.register_killed_enemy(name)

	is_alive = false
	_change_state(State.DEAD)

	if persistence != null:
		persistence.mark_consumed(capture_persistent_state())

	repeat_potion_blocking_changed.emit(false)
	_emit_enemy_ui_snapshot()
	died.emit()


func _on_death_completed() -> void:
	is_alive = false
	is_active = false

	if animated_sprite == null:
		_hide_enemy()
		return

	var tween: Tween = create_tween()
	tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.8)
	tween.tween_callback(_hide_enemy)


func _hide_enemy() -> void:
	visible = false
	if collision_shape != null:
		collision_shape.disabled = true
	if detection_area != null:
		detection_area.monitoring = false
		detection_area.monitorable = false

	set_physics_process(false)

	if persistence != null:
		persistence.mark_consumed(capture_persistent_state())


func _update_detection_range() -> void:
	if detection_area == null:
		return

	var shape_node: CollisionShape2D = detection_area.get_node_or_null("CollisionShape2D")
	if shape_node == null:
		return

	if shape_node.shape is CircleShape2D:
		var circle: CircleShape2D = shape_node.shape as CircleShape2D
		circle.radius = detection_range


func get_enemy_ui_snapshot() -> Dictionary:
	return {
		"enemy_id": persistence.get_persistent_id() if persistence != null else name,
		"display_name": _get_enemy_ui_display_name(),
		"icon_texture": _get_enemy_ui_icon(),
		"health": current_health,
		"max_health": max_health,
		"armor": armor,
		"status_effects": get_enemy_status_effects(),
	}


func get_enemy_status_effects() -> Array[Dictionary]:
	return []


func _get_enemy_ui_display_name() -> String:
	if not ui_display_name.is_empty():
		return ui_display_name
	return name


func _get_enemy_ui_icon() -> Texture2D:
	if ui_icon_texture != null:
		return ui_icon_texture
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return null

	var idle_animation: StringName = _select_idle_animation()
	if animated_sprite.sprite_frames.has_animation(idle_animation) and animated_sprite.sprite_frames.get_frame_count(idle_animation) > 0:
		return animated_sprite.sprite_frames.get_frame_texture(idle_animation, 0)

	var current_animation: StringName = animated_sprite.animation
	if animated_sprite.sprite_frames.has_animation(current_animation) and animated_sprite.sprite_frames.get_frame_count(current_animation) > 0:
		return animated_sprite.sprite_frames.get_frame_texture(current_animation, 0)

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
