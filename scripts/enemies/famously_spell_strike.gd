extends Node2D

const SPELL_FOLDER: String = "res://assets/enemies/Famously/Spell"
const SPELL_PREFIX: String = "Bringer-of-Death_Spell_"
const SPELL_FRAME_COUNT: int = 16

@export var animation_name: StringName = &"spell"
@export var impact_frame: int = 11
@export var target_offset: Vector2 = Vector2(0.0, -96.0)
@export var track_target_until_impact: bool = true

var target: Node2D = null
var damage_amount: int = 3
var madness_chance: float = 0.3
var madness_stacks: int = 1
var damage_source: String = "Famously"
var impact_applied: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_ensure_sprite_frames()
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		push_warning("FamouslySpellStrike: AnimatedSprite2D or SpriteFrames is missing.")
		queue_free()
		return

	if not animated_sprite.sprite_frames.has_animation(animation_name):
		push_warning("FamouslySpellStrike: animation '%s' was not created." % String(animation_name))
		queue_free()
		return

	if animated_sprite.sprite_frames.get_frame_count(animation_name) <= 0:
		push_warning("FamouslySpellStrike: animation '%s' has no frames." % String(animation_name))
		queue_free()
		return

	if not animated_sprite.frame_changed.is_connected(_on_frame_changed):
		animated_sprite.frame_changed.connect(_on_frame_changed)
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)

	_update_position()
	animated_sprite.play(animation_name)


func _process(_delta: float) -> void:
	if not impact_applied and track_target_until_impact:
		_update_position()


func setup(target_node: Node2D, damage: int, chance: float, stacks: int, source: String, offset: Vector2) -> void:
	target = target_node
	damage_amount = damage
	madness_chance = chance
	madness_stacks = stacks
	damage_source = source
	target_offset = offset
	_update_position()


func _ensure_sprite_frames() -> void:
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
	sprite_frames.set_animation_speed(animation_name, 14.0)

	for frame_index in range(1, SPELL_FRAME_COUNT + 1):
		var texture_path: String = "%s/%s%d.png" % [SPELL_FOLDER, SPELL_PREFIX, frame_index]
		if not ResourceLoader.exists(texture_path):
			continue
		var texture: Texture2D = load(texture_path) as Texture2D
		if texture != null:
			sprite_frames.add_frame(animation_name, texture)


func _update_position() -> void:
	if target == null or not is_instance_valid(target):
		return
	global_position = target.global_position + target_offset


func _on_frame_changed() -> void:
	if impact_applied:
		return
	if animated_sprite.frame >= impact_frame:
		_apply_impact()


func _apply_impact() -> void:
	impact_applied = true
	_update_position()

	if target == null or not is_instance_valid(target):
		return

	if target.has_method("take_damage"):
		target.take_damage(damage_amount, "magical", damage_source)

	if target.has_method("apply_effect_template"):
		target.apply_effect_template("apply_madness", {
			"power": madness_stacks,
			"chance": madness_chance,
			"source": "Безумие",
		})


func _on_animation_finished() -> void:
	if not impact_applied:
		_apply_impact()
	queue_free()