@tool
extends Area2D

class_name CombatFloorArea

const COMBAT_FLOOR_LAYER: int = 1 << 4
const DEFAULT_COLORS: Array[Color] = [
	Color(0.34, 0.94, 0.55, 0.22),
	Color(0.36, 0.74, 1.0, 0.22),
	Color(1.0, 0.77, 0.32, 0.22),
	Color(0.94, 0.46, 0.84, 0.22),
]

@export_range(1, 8, 1) var floor_id: int = 1:
	set(value):
		floor_id = maxi(1, value)
		queue_redraw()

@export var floor_label: String = "":
	set(value):
		floor_label = value
		queue_redraw()

@export var floor_priority: int = 0

@export var area_size: Vector2 = Vector2(1856.0, 64.0):
	set(value):
		area_size = Vector2(maxf(32.0, value.x), maxf(16.0, value.y))
		_update_shape()
		queue_redraw()

@export var debug_visible: bool = true:
	set(value):
		debug_visible = value
		queue_redraw()

@export var editor_only_visuals: bool = true:
	set(value):
		editor_only_visuals = value
		queue_redraw()

@export var debug_color: Color = Color(1.0, 1.0, 1.0, 0.2):
	set(value):
		debug_color = value
		queue_redraw()

@export var label_offset: Vector2 = Vector2(12.0, -10.0):
	set(value):
		label_offset = value
		queue_redraw()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	collision_layer = COMBAT_FLOOR_LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true
	add_to_group("combat_floor_areas")
	_update_shape()
	queue_redraw()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_update_shape()
		queue_redraw()


func _draw() -> void:
	if not debug_visible:
		return
	if editor_only_visuals and not Engine.is_editor_hint():
		return

	var rect := Rect2(-area_size * 0.5, area_size)
	var fill_color: Color = _resolve_debug_color()
	var border_color: Color = fill_color
	border_color.a = 0.9
	draw_rect(rect, fill_color, true)
	draw_rect(rect, border_color, false, 2.0)

	var font: Font = ThemeDB.fallback_font
	if font == null:
		return

	var font_size: int = ThemeDB.fallback_font_size
	if font_size <= 0:
		font_size = 16

	var label_text: String = floor_label if not floor_label.is_empty() else "Этаж %d" % floor_id
	draw_string(
		font,
		Vector2(rect.position.x, rect.position.y) + label_offset + Vector2(1.0, 1.0),
		label_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		Color(0.0, 0.0, 0.0, 0.85)
	)
	draw_string(
		font,
		Vector2(rect.position.x, rect.position.y) + label_offset,
		label_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		border_color
	)


func _update_shape() -> void:
	if collision_shape == null:
		return

	var rect_shape := collision_shape.shape as RectangleShape2D
	if rect_shape == null:
		rect_shape = RectangleShape2D.new()
		collision_shape.shape = rect_shape
	rect_shape.size = area_size


func _resolve_debug_color() -> Color:
	if debug_color.a > 0.0 and debug_color != Color(1.0, 1.0, 1.0, 0.2):
		return debug_color
	return DEFAULT_COLORS[(floor_id - 1) % DEFAULT_COLORS.size()]


func contains_world_point(world_point: Vector2) -> bool:
	var local_point: Vector2 = to_local(world_point)
	return Rect2(-area_size * 0.5, area_size).has_point(local_point)
