extends "res://scripts/enemies/base_melee_enemy.gd"

const WALK_SPEED: float = 92.0
const RUN_SPEED: float = 150.0
const LOW_HEALTH_RATIO: float = 0.5
const ATTACK_1_DAMAGE: int = 2
const ATTACK_2_DAMAGE: int = 3

@export var idle_animation_name: StringName = &"idle"
@export var secondary_idle_animation_name: StringName = &"idle_2"
@export var walk_animation_name: StringName = &"walk"
@export var run_animation_name: StringName = &"run"
@export var attack_1_animation_name: StringName = &"attack_1"
@export var attack_2_animation_name: StringName = &"attack_2"
@export var hurt_animation_name: StringName = &"hurt"
@export var death_animation_name: StringName = &"death"
@export var attack_1_damage_frame: int = 3
@export var attack_2_damage_frame: int = 2


func _initialize_enemy() -> void:
	_validate_animation_setup()


func _select_idle_animation() -> StringName:
	if randf() < 0.5:
		return idle_animation_name
	return secondary_idle_animation_name


func _select_chase_animation() -> StringName:
	if _should_run_to_target():
		return run_animation_name
	return walk_animation_name


func _select_attack_profile() -> Dictionary:
	if _can_use_attack_2() and randf() < 0.5:
		return {
			"animation": String(attack_2_animation_name),
			"damage": ATTACK_2_DAMAGE,
			"damage_frame": attack_2_damage_frame,
		}

	return {
		"animation": String(attack_1_animation_name),
		"damage": ATTACK_1_DAMAGE,
		"damage_frame": attack_1_damage_frame,
	}


func _get_hurt_animation() -> StringName:
	return hurt_animation_name


func _get_death_animation() -> StringName:
	return death_animation_name


func _get_effective_chase_speed() -> float:
	if _should_run_to_target():
		return RUN_SPEED
	return WALK_SPEED


func _get_idle_duration() -> float:
	return 1.0 + randf_range(0.15, 0.55)


func _can_use_attack_2() -> bool:
	return current_health * 2 <= max_health


func _should_run_to_target() -> bool:
	if target == null or not is_instance_valid(target):
		return false

	var target_max_health_variant: Variant = target.get("max_health")
	var target_health_variant: Variant = target.get("current_health")
	if not (target_max_health_variant is int) or not (target_health_variant is int):
		return false

	var target_max_health: int = int(target_max_health_variant)
	var target_health: int = int(target_health_variant)
	if target_max_health <= 0:
		return false

	return float(target_health) / float(target_max_health) <= LOW_HEALTH_RATIO


func _validate_animation_setup() -> void:
	if animated_sprite == null:
		push_warning("Gorgon1: missing AnimatedSprite2D node.")
		return
	if animated_sprite.sprite_frames == null:
		push_warning("Gorgon1: SpriteFrames are not assigned. Configure animations in the scene.")
		return

	var required_animations: Array[StringName] = [
		idle_animation_name,
		secondary_idle_animation_name,
		walk_animation_name,
		run_animation_name,
		attack_1_animation_name,
		attack_2_animation_name,
		hurt_animation_name,
		death_animation_name,
	]

	for animation_name in required_animations:
		if not animated_sprite.sprite_frames.has_animation(animation_name):
			push_warning("Gorgon1: missing animation '%s' in AnimatedSprite2D." % [String(animation_name)])
