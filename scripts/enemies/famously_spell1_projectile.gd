extends Node2D

const SPELL_FOLDER: String = "res://assets/enemies/Famously/Spell/Spell1"
const SPELL_PREFIX: String = "Starcaller_spell_2_frame_"
const SPELL_FRAME_COUNT: int = 8

@export var animation_name: StringName = &"spell1"

var owner_volley: Node = null
var target: Node2D = null
var direction: Vector2 = Vector2.RIGHT
var projectile_speed: float = 560.0
var hit_radius: float = 28.0
var max_lifetime: float = 1.05
var hit_applied: bool = false
var impact_point: Vector2 = Vector2.ZERO
var target_body_offset: Vector2 = Vector2.ZERO

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_ensure_frames()
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		push_warning("FamouslySpell1Projectile: AnimatedSprite2D or SpriteFrames is missing.")
		queue_free()
		return
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		push_warning("FamouslySpell1Projectile: animation '%s' was not created." % String(animation_name))
		queue_free()
		return
	animated_sprite.play(animation_name)
	_update_visual_facing()


func setup_spell1_bolt(
	volley_owner: Node,
	target_node: Node2D,
	spawn_position: Vector2,
	impact_point: Vector2,
	speed: float,
	radius: float,
	lifetime: float,
	body_offset: Vector2
) -> void:
	owner_volley = volley_owner
	target = target_node
	global_position = spawn_position
	self.impact_point = impact_point
	projectile_speed = maxf(1.0, speed)
	hit_radius = maxf(4.0, radius)
	max_lifetime = maxf(0.1, lifetime)
	target_body_offset = body_offset

	var delta: Vector2 = impact_point - spawn_position
	if delta.length_squared() <= 0.0001:
		direction = Vector2.RIGHT
	else:
		direction = delta.normalized()
	_update_visual_facing()


func _physics_process(delta: float) -> void:
	if hit_applied:
		return

	var target_node: Node2D = _resolve_target()
	max_lifetime = maxf(0.0, max_lifetime - delta)

	global_position += direction * projectile_speed * delta

	if target_node != null and _is_target_inside_hit_radius(target_node):
		_apply_hit(target_node)
		return

	if max_lifetime <= 0.0:
		if CombatRuntimeLogger:
			CombatRuntimeLogger.log_event("spell", name, "spell1_miss", {
				"position": global_position,
				"direction": direction,
			})
		queue_free()


func _ensure_frames() -> void:
	if animated_sprite == null:
		return
	if animated_sprite.sprite_frames == null:
		animated_sprite.sprite_frames = SpriteFrames.new()

	var sprite_frames: SpriteFrames = animated_sprite.sprite_frames
	if not sprite_frames.has_animation(animation_name):
		sprite_frames.add_animation(animation_name)
	else:
		sprite_frames.clear(animation_name)

	sprite_frames.set_animation_loop(animation_name, false)
	sprite_frames.set_animation_speed(animation_name, 16.0)

	for frame_index in range(1, SPELL_FRAME_COUNT + 1):
		var texture_path: String = "%s/%s%d.png" % [SPELL_FOLDER, SPELL_PREFIX, frame_index]
		if not ResourceLoader.exists(texture_path):
			continue
		var texture: Texture2D = load(texture_path) as Texture2D
		if texture != null:
			sprite_frames.add_frame(animation_name, texture)


func _update_visual_facing() -> void:
	if animated_sprite == null:
		return
	rotation = direction.angle() + PI
	animated_sprite.flip_h = false
	animated_sprite.flip_v = false


func _resolve_target() -> Node2D:
	if target != null and is_instance_valid(target):
		return target
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	var player: Node = tree.get_first_node_in_group("player")
	if player is Node2D:
		return player as Node2D
	return null


func _apply_hit(target_node: Node2D) -> void:
	if hit_applied:
		return
	hit_applied = true

	if owner_volley != null and is_instance_valid(owner_volley) and owner_volley.has_method("request_hit"):
		owner_volley.request_hit(self, target_node)
		return

	queue_free()


func _exit_tree() -> void:
	if owner_volley != null and is_instance_valid(owner_volley) and owner_volley.has_method("notify_bolt_finished"):
		owner_volley.notify_bolt_finished(self)


func _is_target_inside_hit_radius(target_node: Node2D) -> bool:
	if target_node == null or not is_instance_valid(target_node):
		return false
	var body_point: Vector2 = target_node.global_position + target_body_offset
	return global_position.distance_to(body_point) <= hit_radius
