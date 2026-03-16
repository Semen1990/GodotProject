extends "res://scripts/enemies/base_melee_enemy.gd"

const FAMOUSLY_SPELL_SCENE: PackedScene = preload("res://prefabs/enemies/FamouslySpellStrike.tscn")
const FAMOUSLY_SPELL1_SCENE: PackedScene = preload("res://prefabs/enemies/FamouslySpell1Volley.tscn")
const CyclopsMagicControllerScript := preload("res://scripts/enemies/magic/cyclops_magic_controller.gd")
const CyclopsMagicProfileScript := preload("res://scripts/enemies/magic/cyclops_magic_profile.gd")
const MELEE_ATTACK_DAMAGE: int = 2
const SPELL_ATTACK_DAMAGE: int = 3
const SPELL1_ATTACK_DAMAGE: int = 2

const IDLE_FOLDER: String = "res://assets/enemies/Famously/Idle"
const WALK_FOLDER: String = "res://assets/enemies/Famously/Walk"
const ATTACK_FOLDER: String = "res://assets/enemies/Famously/Attack"
const CAST_FOLDER: String = "res://assets/enemies/Famously/Cast"
const HURT_FOLDER: String = "res://assets/enemies/Famously/Hurt"
const DEATH_FOLDER: String = "res://assets/enemies/Famously/Death"

@export var idle_animation_name: StringName = &"idle"
@export var walk_animation_name: StringName = &"walk"
@export var melee_attack_animation_name: StringName = &"attack_1"
@export var cast_animation_name: StringName = &"cast"
@export var hurt_animation_name: StringName = &"hurt"
@export var death_animation_name: StringName = &"death"
@export var melee_damage_frame: int = 4
@export var cast_release_frame: int = 6
@export var retreat_cast_distance: float = 176.0
@export var cast_cooldown_time: float = 5.0
@export var melee_hit_range: float = 235.0
@export var engaged_detection_multiplier: float = 1.3
@export var engaged_cast_distance_multiplier: float = 1.3
@export var spell_vertical_offset: Vector2 = Vector2(0.0, -96.0)
@export var spell_madness_chance: float = 0.3
@export var spell_madness_stacks: int = 1
@export var line_spell_vertical_tolerance: float = 54.0
@export var art_faces_left_by_default: bool = false
@export var visual_offset_when_facing_left: Vector2 = Vector2(81.0, -112.0)
@export var visual_offset_when_facing_right: Vector2 = Vector2(-81.0, -112.0)
@export var combat_floor_probe_offset: Vector2 = Vector2(0.0, 8.0)
@export var magic_profile: CyclopsMagicProfile

var queued_attack_mode: StringName = &"melee"
var queued_magic_spell_id: StringName = &""
var has_seen_target_in_melee: bool = false
var next_cast_allowed_at_msec: int = 0
var base_detection_range_value: float = 0.0
var base_retreat_cast_distance: float = 0.0
var magic_controller: CyclopsMagicController = null


func _initialize_enemy() -> void:
	_setup_magic_controller()
	base_detection_range_value = detection_range
	base_retreat_cast_distance = retreat_cast_distance
	_ensure_sprite_frames()
	if animated_sprite != null:
		var normalized_scale_x: float = absf(animated_sprite.scale.x)
		if is_zero_approx(normalized_scale_x):
			normalized_scale_x = 1.0
		animated_sprite.scale = Vector2(normalized_scale_x, animated_sprite.scale.y)
		_apply_visual_facing(-1.0)
	_sync_engaged_ranges()
	_validate_animation_setup()


func _setup_magic_controller() -> void:
	if magic_profile == null:
		magic_profile = CyclopsMagicProfileScript.new()
	if magic_controller == null:
		magic_controller = CyclopsMagicControllerScript.new().setup(self, magic_profile)
	else:
		magic_controller.setup(self, magic_profile)
	cast_cooldown_time = magic_profile.spell0_cooldown_time
	retreat_cast_distance = magic_profile.spell0_max_distance
	next_cast_allowed_at_msec = magic_controller.get_spell_ready_time_msec(CyclopsMagicControllerScript.SPELL0)


func get_current_combat_floor_id() -> int:
	var resolved_floor: int = _resolve_combat_floor_id_from_world()
	if resolved_floor != -1:
		return resolved_floor
	if combat_floor_tracker != null:
		var tracker_floor: int = combat_floor_tracker.get_current_floor_id()
		if tracker_floor != -1:
			return tracker_floor
	return -1


func get_last_stable_combat_floor_id() -> int:
	var resolved_floor: int = _resolve_combat_floor_id_from_world()
	if resolved_floor != -1:
		return resolved_floor
	if combat_floor_tracker != null:
		var tracker_floor: int = combat_floor_tracker.get_last_stable_floor_id()
		if tracker_floor != -1:
			return tracker_floor
	return -1


func get_effective_combat_floor_id() -> int:
	var resolved_floor: int = _resolve_combat_floor_id_from_world()
	if resolved_floor != -1:
		return resolved_floor
	if combat_floor_tracker != null:
		var tracker_floor: int = combat_floor_tracker.get_effective_floor_id()
		if tracker_floor != -1:
			return tracker_floor
	return -1


func is_between_combat_floors() -> bool:
	if combat_floor_tracker != null and combat_floor_tracker.get_effective_floor_id() != -1:
		return combat_floor_tracker.is_between_floors()
	return false


func save_state() -> Dictionary:
	var state: Dictionary = super.save_state()
	state["has_seen_target_in_melee"] = has_seen_target_in_melee
	var now_msec: int = Time.get_ticks_msec()
	state["next_cast_cooldown_remaining_msec"] = max(0, next_cast_allowed_at_msec - now_msec)
	state["magic_state"] = magic_controller.get_state() if magic_controller != null else {}
	return state


func load_state(state: Dictionary) -> void:
	_setup_magic_controller()
	has_seen_target_in_melee = bool(state.get("has_seen_target_in_melee", false))
	if magic_controller != null:
		var magic_state: Dictionary = state.get("magic_state", {})
		if magic_state.is_empty():
			var next_cast_remaining_msec: int = int(state.get("next_cast_cooldown_remaining_msec", 0))
			magic_controller.set_spell_ready_time_msec(
				CyclopsMagicControllerScript.SPELL0,
				Time.get_ticks_msec() + next_cast_remaining_msec
			)
		else:
			magic_controller.load_state(magic_state)
		next_cast_allowed_at_msec = magic_controller.get_spell_ready_time_msec(CyclopsMagicControllerScript.SPELL0)
	super.load_state(state)
	_sync_engaged_ranges()


func _select_idle_animation() -> StringName:
	return idle_animation_name


func _select_chase_animation() -> StringName:
	return walk_animation_name


func _select_attack_profile() -> Dictionary:
	if queued_attack_mode == cast_animation_name:
		return {
			"animation": String(cast_animation_name),
			"damage": SPELL_ATTACK_DAMAGE,
			"damage_frame": cast_release_frame,
		}

	return {
		"animation": String(melee_attack_animation_name),
		"damage": MELEE_ATTACK_DAMAGE,
		"damage_frame": melee_damage_frame,
	}


func _get_hurt_animation() -> StringName:
	return hurt_animation_name


func _get_death_animation() -> StringName:
	return death_animation_name


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
	_apply_visual_facing(float(patrol_direction))
	_play_anim(walk_animation_name)


func _process_chase() -> void:
	if not _is_target_valid():
		target = null
		_change_state(_get_lost_target_state())
		return

	var dir_x: float = target.global_position.x - global_position.x
	var horizontal_dist: float = absf(dir_x)
	var planar_dist: float = global_position.distance_to(target.global_position)

	if animated_sprite != null:
		_apply_visual_facing(dir_x)
		_play_anim(_select_chase_animation())

	var floor_delta: int = _get_floor_delta_to_target()

	if floor_delta == 0 and horizontal_dist <= attack_range and _can_melee_attack_target():
		has_seen_target_in_melee = true
		if can_attack:
			queued_attack_mode = melee_attack_animation_name
			queued_magic_spell_id = CyclopsMagicControllerScript.SPELL_NONE
			if CombatRuntimeLogger:
				CombatRuntimeLogger.log_event("decision", name, "queue_melee_attack", {
					"distance": horizontal_dist,
					"target": target.name,
				})
			_change_state(State.ATTACK)
			return

		velocity.x = 0.0
		return

	var queued_spell_id: StringName = _choose_magic_spell(planar_dist)
	if queued_spell_id != CyclopsMagicControllerScript.SPELL_NONE and can_attack:
		queued_attack_mode = cast_animation_name
		queued_magic_spell_id = queued_spell_id
		velocity.x = 0.0
		if CombatRuntimeLogger:
			CombatRuntimeLogger.log_event("decision", name, "queue_cast_attack", {
				"distance": planar_dist,
				"distance_x": horizontal_dist,
				"floor_delta": floor_delta,
				"spell_id": String(queued_spell_id),
				"target": target.name,
			})
		_change_state(State.ATTACK)
		return

	if floor_delta >= 2:
		velocity.x = 0.0
		return

	if horizontal_dist <= minimum_distance_to_player:
		velocity.x = -signf(dir_x) * move_speed * 0.5
		return

	velocity.x = signf(dir_x) * _get_effective_chase_speed()


func _can_detect_player_before_engage(player_body: Node2D) -> bool:
	if player_body == null or not is_instance_valid(player_body):
		return false
	if player_body.get("is_dead") == true:
		return false
	if player_body.has_method("is_hidden_from_enemy") and bool(player_body.call("is_hidden_from_enemy", self)):
		return false
	if super._can_detect_player_before_engage(player_body):
		return true
	if magic_controller == null:
		return false
	if not magic_controller.can_use_overhead_spell(player_body):
		return false
	return global_position.distance_to(player_body.global_position) <= detection_range


func _face_target() -> void:
	if target == null or animated_sprite == null:
		return
	var dir_x: float = target.global_position.x - global_position.x
	_apply_visual_facing(dir_x)


func _get_combat_floor_probe_world_point() -> Vector2:
	if collision_shape != null:
		return collision_shape.global_position + combat_floor_probe_offset
	return global_position + combat_floor_probe_offset


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


func _apply_visual_facing(dir_x: float) -> void:
	if animated_sprite == null:
		return

	var facing_left: bool = dir_x < 0.0
	var should_flip: bool = facing_left == (not art_faces_left_by_default)
	animated_sprite.flip_h = should_flip
	animated_sprite.position = visual_offset_when_facing_left if facing_left else visual_offset_when_facing_right


func _get_facing_direction() -> float:
	if animated_sprite == null:
		return -1.0
	var facing_left: bool = animated_sprite.position == visual_offset_when_facing_left
	return -1.0 if facing_left else 1.0


func _get_target_facing_direction(target_node: Node) -> float:
	if target_node == null or not is_instance_valid(target_node):
		return 1.0
	if target_node.has_method("get_facing_direction"):
		return float(target_node.call("get_facing_direction"))
	var target_sprite: AnimatedSprite2D = target_node.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if target_sprite == null:
		return 1.0
	return -1.0 if target_sprite.flip_h else 1.0


func _sync_engaged_ranges() -> void:
	var detection_multiplier: float = engaged_detection_multiplier if has_engaged_player else 1.0
	detection_range = base_detection_range_value * detection_multiplier
	_update_detection_range()


func _get_effective_retreat_cast_distance() -> float:
	var cast_multiplier: float = engaged_cast_distance_multiplier if has_engaged_player else 1.0
	return base_retreat_cast_distance * cast_multiplier


func _on_detection_entered(body: Node2D) -> void:
	super._on_detection_entered(body)
	if body == null or not body.is_in_group("player"):
		return
	if has_engaged_player:
		_sync_engaged_ranges()


func _deal_damage() -> bool:
	if current_attack_animation == cast_animation_name:
		var spell_instance: Node = _spawn_spell_strike(queued_magic_spell_id)
		if spell_instance != null and magic_controller != null:
			magic_controller.register_spell_started(queued_magic_spell_id, spell_instance)
			next_cast_allowed_at_msec = magic_controller.get_spell_ready_time_msec(queued_magic_spell_id)
		if CombatRuntimeLogger:
			CombatRuntimeLogger.log_event("damage", name, "cast_release", {
				"spell_id": String(queued_magic_spell_id),
				"target": target.name if target != null and is_instance_valid(target) else "<null>",
			})
		queued_magic_spell_id = CyclopsMagicControllerScript.SPELL_NONE
		return true

	if not _is_target_valid():
		if CombatRuntimeLogger:
			CombatRuntimeLogger.log_event("damage", name, "melee_attempt", {"result": "no_target"})
		return false

	var horizontal_distance: float = absf(target.global_position.x - global_position.x)
	if horizontal_distance <= melee_hit_range and _can_confirm_committed_melee_hit(target) and target.has_method("take_damage"):
		target.take_damage(current_attack_damage, "physical", name)
		if CombatRuntimeLogger:
			CombatRuntimeLogger.log_event("damage", name, "melee_attempt", {
				"result": "applied",
				"distance_x": horizontal_distance,
				"damage": current_attack_damage,
				"target": target.name,
				"target_hp_after": target.get("current_health"),
			})
		return true

	if CombatRuntimeLogger:
		CombatRuntimeLogger.log_event("damage", name, "melee_attempt", {
			"result": "blocked",
			"distance_x": horizontal_distance,
			"target": target.name if target != null and is_instance_valid(target) else "<null>",
		})
	return false


func _choose_magic_spell(distance_to_target: float) -> StringName:
	if not _is_target_valid():
		return CyclopsMagicControllerScript.SPELL_NONE
	if magic_controller == null:
		return CyclopsMagicControllerScript.SPELL_NONE
	return magic_controller.choose_spell_for_target(
		target,
		distance_to_target,
		_get_effective_retreat_cast_distance()
	)


func _spawn_spell_strike(spell_id: StringName) -> Node:
	if not _is_target_valid():
		return null

	var spell_instance: Node = null
	match spell_id:
		CyclopsMagicControllerScript.SPELL0:
			if FAMOUSLY_SPELL_SCENE == null:
				return null
			spell_instance = FAMOUSLY_SPELL_SCENE.instantiate()
		CyclopsMagicControllerScript.SPELL1:
			if FAMOUSLY_SPELL1_SCENE == null:
				return null
			spell_instance = FAMOUSLY_SPELL1_SCENE.instantiate()
		_:
			return null

	if spell_id == CyclopsMagicControllerScript.SPELL0 and spell_instance.has_method("setup_spell0"):
		spell_instance.setup_spell0(
			target,
			SPELL_ATTACK_DAMAGE,
			spell_madness_chance,
			spell_madness_stacks,
			"%s: dark spell" % name,
			target.global_position + spell_vertical_offset,
			target.global_position,
			magic_profile.spell0_strike_spacing,
			magic_profile.spell0_hit_radius
		)
	elif spell_id == CyclopsMagicControllerScript.SPELL1 and spell_instance.has_method("setup_spell1"):
		var target_facing: float = _get_target_facing_direction(target)
		var target_body_point: Vector2 = target.global_position + magic_profile.spell1_target_body_offset
		spell_instance.setup_spell1(
			target,
			target_body_point,
			target_facing,
			magic_profile.spell1_projectile_count,
			magic_profile.spell1_projectile_speed,
			magic_profile.spell1_hit_radius,
			magic_profile.spell1_lifetime,
			SPELL1_ATTACK_DAMAGE,
			"%s: arcane bolt" % name,
			magic_profile.spell1_face_side_distance,
			magic_profile.spell1_spawn_vertical_offset,
			magic_profile.spell1_spawn_horizontal_step,
			magic_profile.spell1_spawn_vertical_step,
			magic_profile.spell1_impact_horizontal_step,
			magic_profile.spell1_target_body_offset
		)
	elif spell_id == CyclopsMagicControllerScript.SPELL1 and spell_instance.has_method("setup_spell1_volley"):
		var target_facing: float = _get_target_facing_direction(target)
		var target_body_point: Vector2 = target.global_position + magic_profile.spell1_target_body_offset
		spell_instance.setup_spell1_volley(
			target,
			target_body_point,
			target_facing,
			magic_profile.spell1_projectile_count,
			magic_profile.spell1_projectile_speed,
			magic_profile.spell1_hit_radius,
			magic_profile.spell1_lifetime,
			SPELL1_ATTACK_DAMAGE,
			"%s: arcane bolt volley" % name,
			magic_profile.spell1_face_side_distance,
			magic_profile.spell1_spawn_vertical_offset,
			magic_profile.spell1_spawn_horizontal_step,
			magic_profile.spell1_spawn_vertical_step,
			magic_profile.spell1_impact_horizontal_step,
			magic_profile.spell1_target_body_offset
		)

	var effect_parent: Node = _resolve_effect_parent()
	effect_parent.add_child(spell_instance)
	return spell_instance


func can_cast_line_spell_at_target() -> bool:
	if not _is_target_valid() or magic_controller == null:
		return false
	return magic_controller.can_begin_spell2(
		target,
		absf(target.global_position.x - global_position.x),
		_get_effective_retreat_cast_distance()
	)


func _get_floor_delta_to_target() -> int:
	if not _is_target_valid() or magic_controller == null:
		return 999
	return magic_controller.get_floor_delta_to_target(target)


func _is_cast_attack_animation(animation_name: StringName) -> bool:
	return animation_name == cast_animation_name


func _resolve_effect_parent() -> Node:
	var current_scene: Node = get_tree().current_scene
	if current_scene != null and current_scene.has_method("get_entities_root"):
		var entities_root: Node = current_scene.get_entities_root()
		if entities_root != null:
			return entities_root
	if get_parent() != null:
		return get_parent()
	return self


func _ensure_sprite_frames() -> void:
	if animated_sprite == null:
		return
	if animated_sprite.sprite_frames == null:
		animated_sprite.sprite_frames = SpriteFrames.new()

	_ensure_animation(idle_animation_name, IDLE_FOLDER, "Bringer-of-Death_Idle_", 8, true, 8.0)
	_ensure_animation(walk_animation_name, WALK_FOLDER, "Bringer-of-Death_Walk_", 8, true, 9.0)
	_ensure_animation(melee_attack_animation_name, ATTACK_FOLDER, "Bringer-of-Death_Attack_", 10, false, 12.0)
	_ensure_animation(cast_animation_name, CAST_FOLDER, "Bringer-of-Death_Cast_", 9, false, 11.0)
	_ensure_animation(hurt_animation_name, HURT_FOLDER, "Bringer-of-Death_Hurt_", 3, false, 8.0)
	_ensure_animation(death_animation_name, DEATH_FOLDER, "Bringer-of-Death_Death_", 10, false, 7.0)


func _ensure_animation(animation_name: StringName, folder: String, prefix: String, frame_count: int, should_loop: bool, speed: float) -> void:
	var sprite_frames: SpriteFrames = animated_sprite.sprite_frames
	if sprite_frames.has_animation(animation_name) and sprite_frames.get_frame_count(animation_name) > 0:
		sprite_frames.set_animation_loop(animation_name, should_loop)
		sprite_frames.set_animation_speed(animation_name, speed)
		return

	if sprite_frames.has_animation(animation_name):
		sprite_frames.remove_animation(animation_name)
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_loop(animation_name, should_loop)
	sprite_frames.set_animation_speed(animation_name, speed)

	for frame_index in range(1, frame_count + 1):
		var texture_path: String = "%s/%s%d.png" % [folder, prefix, frame_index]
		if not ResourceLoader.exists(texture_path):
			continue
		var texture: Texture2D = load(texture_path) as Texture2D
		if texture != null:
			sprite_frames.add_frame(animation_name, texture)


func _validate_animation_setup() -> void:
	if animated_sprite == null:
		push_warning("Famously: missing AnimatedSprite2D node.")
		return
	if animated_sprite.sprite_frames == null:
		push_warning("Famously: SpriteFrames are not assigned.")
		return

	var required_animations: Array[StringName] = [
		idle_animation_name,
		walk_animation_name,
		melee_attack_animation_name,
		cast_animation_name,
		hurt_animation_name,
		death_animation_name,
	]

	for animation_name in required_animations:
		if not animated_sprite.sprite_frames.has_animation(animation_name):
			push_warning("Famously: missing animation '%s'." % String(animation_name))
