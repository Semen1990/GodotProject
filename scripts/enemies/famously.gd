extends "res://scripts/enemies/base_melee_enemy.gd"

const FAMOUSLY_SPELL_SCENE: PackedScene = preload("res://prefabs/enemies/FamouslySpellStrike.tscn")
const MELEE_ATTACK_DAMAGE: int = 2
const SPELL_ATTACK_DAMAGE: int = 3

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
@export var melee_vertical_tolerance: float = 120.0
@export var engaged_detection_multiplier: float = 1.3
@export var engaged_cast_distance_multiplier: float = 1.3
@export var spell_vertical_offset: Vector2 = Vector2(0.0, -96.0)
@export var spell_madness_chance: float = 0.3
@export var spell_madness_stacks: int = 1
@export var art_faces_left_by_default: bool = false
@export var visual_offset_when_facing_left: Vector2 = Vector2(81.0, -112.0)
@export var visual_offset_when_facing_right: Vector2 = Vector2(-81.0, -112.0)

var queued_attack_mode: StringName = &"melee"
var has_seen_target_in_melee: bool = false
var next_cast_allowed_at_msec: int = 0
var base_detection_range_value: float = 0.0
var base_retreat_cast_distance: float = 0.0


func _initialize_enemy() -> void:
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


func save_state() -> Dictionary:
	var state: Dictionary = super.save_state()
	state["has_seen_target_in_melee"] = has_seen_target_in_melee
	state["next_cast_allowed_at_msec"] = next_cast_allowed_at_msec
	return state


func load_state(state: Dictionary) -> void:
	has_seen_target_in_melee = bool(state.get("has_seen_target_in_melee", false))
	next_cast_allowed_at_msec = int(state.get("next_cast_allowed_at_msec", 0))
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
	var dist: float = absf(dir_x)

	if animated_sprite != null:
		_apply_visual_facing(dir_x)
		_play_anim(_select_chase_animation())

	if dist <= attack_range:
		has_seen_target_in_melee = true
		if can_attack:
			queued_attack_mode = melee_attack_animation_name
			_change_state(State.ATTACK)
			return

		velocity.x = 0.0
		return

	if _should_cast_on_retreat(dist) and can_attack:
		queued_attack_mode = cast_animation_name
		velocity.x = 0.0
		_change_state(State.ATTACK)
		return

	if dist <= minimum_distance_to_player:
		velocity.x = -signf(dir_x) * move_speed * 0.5
		return

	velocity.x = signf(dir_x) * _get_effective_chase_speed()


func _face_target() -> void:
	if target == null or animated_sprite == null:
		return
	var dir_x: float = target.global_position.x - global_position.x
	_apply_visual_facing(dir_x)


func _apply_visual_facing(dir_x: float) -> void:
	if animated_sprite == null:
		return

	var facing_left: bool = dir_x < 0.0
	var should_flip: bool = facing_left == (not art_faces_left_by_default)
	animated_sprite.flip_h = should_flip
	animated_sprite.position = visual_offset_when_facing_left if facing_left else visual_offset_when_facing_right


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


func _deal_damage() -> void:
	if current_attack_animation == cast_animation_name:
		_spawn_spell_strike()
		return

	if not _is_target_valid():
		return

	var horizontal_distance: float = absf(target.global_position.x - global_position.x)
	var vertical_distance: float = absf(target.global_position.y - global_position.y)
	if horizontal_distance <= melee_hit_range and vertical_distance <= melee_vertical_tolerance and target.has_method("take_damage"):
		target.take_damage(current_attack_damage, "physical", name)


func _should_cast_on_retreat(distance_to_target: float) -> bool:
	if not has_seen_target_in_melee:
		return false
	if not _is_target_valid():
		return false
	if Time.get_ticks_msec() < next_cast_allowed_at_msec:
		return false
	return distance_to_target >= _get_effective_retreat_cast_distance() and distance_to_target <= detection_range


func _spawn_spell_strike() -> void:
	if FAMOUSLY_SPELL_SCENE == null or not _is_target_valid():
		return

	var spell_instance: Node = FAMOUSLY_SPELL_SCENE.instantiate()
	if spell_instance == null:
		return

	next_cast_allowed_at_msec = Time.get_ticks_msec() + int(cast_cooldown_time * 1000.0)

	if spell_instance.has_method("setup"):
		spell_instance.setup(
			target,
			SPELL_ATTACK_DAMAGE,
			spell_madness_chance,
			spell_madness_stacks,
			"%s: dark spell" % name,
			spell_vertical_offset
		)

	var effect_parent: Node = _resolve_effect_parent()
	effect_parent.add_child(spell_instance)


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