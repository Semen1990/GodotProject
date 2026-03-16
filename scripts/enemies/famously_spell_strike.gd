extends Node2D

const SPELL_FOLDER: String = "res://assets/enemies/Famously/Spell"
const SPELL_PREFIX: String = "Bringer-of-Death_Spell_"
const SPELL_FRAME_COUNT: int = 16

@export var animation_name: StringName = &"spell"
@export var tracking_end_frame: int = 7
@export var impact_frame: int = 8
@export var strike_spacing: float = 56.0
@export var impact_radius: float = 32.0

var target: Node2D = null
var damage_amount: int = 3
var madness_chance: float = 0.3
var madness_stacks: int = 1
var damage_source: String = "Famously"
var impact_applied: bool = false
var strike_offsets: Array[Vector2] = []
var hit_target_ids: Dictionary = {}
var impact_center_position: Vector2 = Vector2.ZERO
var impact_started: bool = false
var all_strikes_finished: bool = false
var completion_handled: bool = false
var tracking_locked: bool = false
var initial_visual_y: float = 0.0
var initial_impact_y: float = 0.0

@onready var template_sprite: AnimatedSprite2D = $AnimatedSprite2D

var strike_sprites: Array[AnimatedSprite2D] = []
var finished_sprite_count: int = 0


func _ready() -> void:
	_ensure_template_frames()
	if template_sprite == null or template_sprite.sprite_frames == null:
		push_warning("FamouslySpellStrike: AnimatedSprite2D or SpriteFrames is missing.")
		queue_free()
		return

	if not template_sprite.sprite_frames.has_animation(animation_name):
		push_warning("FamouslySpellStrike: animation '%s' was not created." % String(animation_name))
		queue_free()
		return

	if template_sprite.sprite_frames.get_frame_count(animation_name) <= 0:
		push_warning("FamouslySpellStrike: animation '%s' has no frames." % String(animation_name))
		queue_free()
		return

	template_sprite.visible = false
	_spawn_strike_sprites()


func setup_spell0(
	target_node: Node2D,
	damage: int,
	chance: float,
	stacks: int,
	source: String,
	visual_center_position: Vector2,
	impact_center: Vector2,
	spacing: float,
	hit_radius: float
) -> void:
	target = target_node
	damage_amount = damage
	madness_chance = chance
	madness_stacks = stacks
	damage_source = source
	global_position = visual_center_position
	impact_center_position = impact_center
	initial_visual_y = visual_center_position.y
	initial_impact_y = impact_center.y
	strike_spacing = spacing
	impact_radius = hit_radius
	strike_offsets = [
		Vector2(-strike_spacing, 0.0),
		Vector2.ZERO,
		Vector2(strike_spacing, 0.0),
	]


func _ensure_template_frames() -> void:
	if template_sprite == null:
		return
	if template_sprite.sprite_frames == null:
		template_sprite.sprite_frames = SpriteFrames.new()

	var sprite_frames: SpriteFrames = template_sprite.sprite_frames
	if not sprite_frames.has_animation(animation_name):
		sprite_frames.add_animation(animation_name)
	else:
		sprite_frames.clear(animation_name)

	sprite_frames.set_animation_loop(animation_name, false)
	sprite_frames.set_animation_speed(animation_name, 14.0)

	for frame_index in range(1, SPELL_FRAME_COUNT + 1):
		var texture_path: String = "%s/%s%d.png" % [SPELL_FOLDER, SPELL_PREFIX, frame_index]
		if not ResourceLoader.exists(texture_path):
			continue
		var texture: Texture2D = load(texture_path) as Texture2D
		if texture != null:
			sprite_frames.add_frame(animation_name, texture)


func _spawn_strike_sprites() -> void:
	if strike_offsets.is_empty():
		strike_offsets = [
			Vector2(-strike_spacing, 0.0),
			Vector2.ZERO,
			Vector2(strike_spacing, 0.0),
		]

	strike_sprites.clear()
	finished_sprite_count = 0

	for strike_index in range(strike_offsets.size()):
		var sprite: AnimatedSprite2D = template_sprite.duplicate() as AnimatedSprite2D
		if sprite == null:
			continue
		sprite.name = "StrikeSprite_%d" % strike_index
		sprite.visible = true
		sprite.position = strike_offsets[strike_index]
		add_child(sprite)
		strike_sprites.append(sprite)

		if not sprite.frame_changed.is_connected(_on_strike_frame_changed.bind(strike_index)):
			sprite.frame_changed.connect(_on_strike_frame_changed.bind(strike_index))
		if not sprite.animation_finished.is_connected(_on_strike_animation_finished):
			sprite.animation_finished.connect(_on_strike_animation_finished)

		sprite.play(animation_name)


func _on_strike_frame_changed(strike_index: int) -> void:
	if impact_started:
		return
	var sprite: AnimatedSprite2D = _get_strike_sprite(strike_index)
	if sprite == null:
		return
	_update_tracking_from_sprite(sprite)
	if sprite.frame >= impact_frame:
		_start_impact_window()


func _process(delta: float) -> void:
	if completion_handled:
		return
	if not impact_started:
		var tracking_sprite: AnimatedSprite2D = _get_tracking_sprite()
		if tracking_sprite != null:
			_update_tracking_from_sprite(tracking_sprite)


func _start_impact_window() -> void:
	if impact_started:
		return
	impact_started = true
	tracking_locked = true
	_try_apply_impact()
	_finish_if_ready()


func _try_apply_impact() -> void:
	var target_node: Node2D = _resolve_target()
	if target_node == null:
		return

	var target_id: int = target_node.get_instance_id()
	if hit_target_ids.has(target_id):
		return

	var max_horizontal_distance: float = strike_spacing + impact_radius
	var horizontal_distance: float = absf(target_node.global_position.x - impact_center_position.x)
	var vertical_distance: float = absf(target_node.global_position.y - impact_center_position.y)
	if horizontal_distance <= max_horizontal_distance and vertical_distance <= impact_radius:
		impact_applied = true
		hit_target_ids[target_id] = true
		if target_node.has_method("take_damage"):
			target_node.take_damage(damage_amount, "magical_unblockable", damage_source)

		if target_node.has_method("apply_effect_template"):
			target_node.apply_effect_template("apply_madness", {
				"power": madness_stacks,
				"chance": madness_chance,
				"source": "Безумие",
			})

		if CombatRuntimeLogger:
			CombatRuntimeLogger.log_event("spell", name, "spell0_hit", {
				"target": target_node.name,
				"impact_center": impact_center_position,
				"horizontal_distance": horizontal_distance,
				"vertical_distance": vertical_distance,
				"damage": damage_amount,
			})


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


func _on_strike_animation_finished() -> void:
	finished_sprite_count += 1
	if finished_sprite_count >= strike_offsets.size():
		all_strikes_finished = true
		if not impact_started:
			_start_impact_window()
		_finish_if_ready()


func _get_strike_sprite(strike_index: int) -> AnimatedSprite2D:
	if strike_index < 0 or strike_index >= strike_sprites.size():
		return null
	return strike_sprites[strike_index]


func _finish_if_ready() -> void:
	if completion_handled:
		return
	if not all_strikes_finished:
		return
	completion_handled = true

	if not impact_applied and CombatRuntimeLogger:
		var target_node: Node2D = _resolve_target()
		CombatRuntimeLogger.log_event("spell", name, "spell0_miss", {
			"target": target_node.name if target_node != null else "none",
			"target_position": target_node.global_position if target_node != null else Vector2.ZERO,
			"impact_center": impact_center_position,
		})

	queue_free()


func _get_tracking_sprite() -> AnimatedSprite2D:
	for sprite in strike_sprites:
		if sprite != null and is_instance_valid(sprite):
			return sprite
	return null


func _update_tracking_from_sprite(sprite: AnimatedSprite2D) -> void:
	if sprite == null or tracking_locked:
		return
	if sprite.frame > tracking_end_frame:
		tracking_locked = true
		return
	var target_node: Node2D = _resolve_target()
	if target_node == null:
		return
	var tracked_x: float = target_node.global_position.x
	global_position = Vector2(tracked_x, initial_visual_y)
	impact_center_position = Vector2(tracked_x, initial_impact_y)
