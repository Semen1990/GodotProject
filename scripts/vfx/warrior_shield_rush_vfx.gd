extends Node2D

const IMPACT_COLOR: Color = Color(1.0, 0.95, 0.68, 0.95)
const HEAVY_IMPACT_COLOR: Color = Color(1.0, 0.88, 0.48, 1.0)
const RUSH_TRAIL_TEXTURE_PATH := "res://assets/warrior/effects/The jerk.png"
const RUSH_TRAIL_HFRAMES := 11
const RUSH_TRAIL_VFRAMES := 9
const RUSH_TRAIL_FRAME_COUNT := 11
const RUSH_TRAIL_ROW_FROM_TOP := 7 # 8th row from the top.
const RUSH_TRAIL_FPS := 20.0
const RUSH_TRAIL_GROUND_OFFSET_Y := 92.0
const RUSH_TRAIL_SCALE_Y := 1.8
const RUSH_TRAIL_MIN_SCALE_X := 1.15
const RUSH_TRAIL_PADDING := 22.0

var owner_body: Node2D = null
var rush_active: bool = false
var rush_facing: float = 1.0
var rush_start_position: Vector2 = Vector2.ZERO
var rush_frame_timer: float = 0.0
var trail_sprite: Sprite2D = null


func setup(body: Node2D) -> Node:
	owner_body = body
	top_level = true
	z_as_relative = false
	z_index = 120
	global_position = Vector2.ZERO
	_build_runtime_nodes()
	set_process(true)
	return self


func start_rush(_world_position: Vector2, facing_direction: float) -> void:
	rush_active = true
	rush_facing = signf(facing_direction)
	if rush_facing == 0.0:
		rush_facing = 1.0
	rush_start_position = _get_ground_anchor_position()
	rush_frame_timer = 0.0
	if trail_sprite != null:
		trail_sprite.visible = true
		trail_sprite.frame = _get_row_start_frame()
		_apply_trail_visual(rush_start_position, rush_start_position)


func stop_rush() -> void:
	rush_active = false
	if trail_sprite != null:
		trail_sprite.visible = false


func emit_contact_flash(world_position: Vector2, heavy: bool) -> void:
	var flash_root := Node2D.new()
	flash_root.top_level = true
	flash_root.global_position = world_position
	add_child(flash_root)

	var ring := Line2D.new()
	ring.closed = true
	ring.width = 4.0 if heavy else 3.0
	ring.default_color = HEAVY_IMPACT_COLOR if heavy else IMPACT_COLOR
	ring.points = _make_ring_points(18, 14.0 if heavy else 11.0)
	flash_root.add_child(ring)

	var cross := Line2D.new()
	cross.width = 3.0
	cross.default_color = ring.default_color
	cross.points = PackedVector2Array([
		Vector2(-18.0, 0.0),
		Vector2(18.0, 0.0),
		Vector2(0.0, 0.0),
		Vector2(0.0, -18.0),
		Vector2(0.0, 18.0),
	])
	flash_root.add_child(cross)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash_root, "scale", Vector2(1.55, 1.55) if heavy else Vector2(1.35, 1.35), 0.18)
	tween.tween_property(flash_root, "modulate:a", 0.0, 0.18)
	tween.finished.connect(flash_root.queue_free)


func _process(delta: float) -> void:
	if owner_body == null or not is_instance_valid(owner_body):
		queue_free()
		return

	global_position = Vector2.ZERO

	if rush_active:
		_update_trail_animation(delta)
		var current_position: Vector2 = _get_ground_anchor_position()
		_apply_trail_visual(rush_start_position, current_position)
	elif trail_sprite != null and trail_sprite.visible:
		trail_sprite.visible = false


func _build_runtime_nodes() -> void:
	trail_sprite = Sprite2D.new()
	var trail_texture := load(RUSH_TRAIL_TEXTURE_PATH) as Texture2D
	trail_sprite.texture = trail_texture
	trail_sprite.hframes = RUSH_TRAIL_HFRAMES
	trail_sprite.vframes = RUSH_TRAIL_VFRAMES
	trail_sprite.centered = true
	trail_sprite.visible = false
	trail_sprite.z_as_relative = false
	trail_sprite.z_index = 105
	trail_sprite.top_level = true
	trail_sprite.modulate = Color(0.98, 0.84, 1.0, 0.95)
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	trail_sprite.material = material
	add_child(trail_sprite)


func _get_ground_anchor_position() -> Vector2:
	if owner_body == null:
		return Vector2.ZERO
	return owner_body.global_position + Vector2(0.0, RUSH_TRAIL_GROUND_OFFSET_Y)


func _update_trail_animation(delta: float) -> void:
	if trail_sprite == null:
		return

	rush_frame_timer += delta
	var frame_duration: float = 1.0 / RUSH_TRAIL_FPS
	var row_start: int = _get_row_start_frame()
	while rush_frame_timer >= frame_duration:
		rush_frame_timer -= frame_duration
		var current_column: int = trail_sprite.frame - row_start
		current_column = posmod(current_column + 1, RUSH_TRAIL_FRAME_COUNT)
		trail_sprite.frame = row_start + current_column


func _apply_trail_visual(from_position: Vector2, to_position: Vector2) -> void:
	if trail_sprite == null:
		return

	var trail_vector: Vector2 = to_position - from_position
	var distance: float = absf(trail_vector.x)
	var midpoint: Vector2 = from_position.lerp(to_position, 0.5)
	trail_sprite.global_position = midpoint
	trail_sprite.flip_h = rush_facing < 0.0

	var frame_width: float = 64.0
	var scale_x: float = maxf((distance + RUSH_TRAIL_PADDING) / frame_width, RUSH_TRAIL_MIN_SCALE_X)
	trail_sprite.scale = Vector2(scale_x, RUSH_TRAIL_SCALE_Y)


func _get_row_start_frame() -> int:
	return RUSH_TRAIL_ROW_FROM_TOP * RUSH_TRAIL_HFRAMES


func _make_ring_points(segments: int, radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var segment_count: int = max(segments, 6)
	for index in range(segment_count):
		var angle: float = TAU * float(index) / float(segment_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
