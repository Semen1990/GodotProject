@tool
extends Node2D

class_name FloorGuides

const DEFAULT_GUIDE_COLORS: Array[Color] = [
	Color(0.34, 0.94, 0.55, 0.95),
	Color(0.36, 0.74, 1.0, 0.95),
	Color(1.0, 0.77, 0.32, 0.95),
	Color(0.94, 0.46, 0.84, 0.95),
]

@export var enabled: bool = true:
	set(value):
		enabled = value
		queue_redraw()

@export var editor_only: bool = true:
	set(value):
		editor_only = value
		queue_redraw()

@export_range(1, 8, 1) var floor_count: int = 4:
	set(value):
		floor_count = maxi(1, value)
		queue_redraw()

@export var base_floor_y: float = 1008.0:
	set(value):
		base_floor_y = value
		queue_redraw()

@export var floor_step: float = 144.0:
	set(value):
		floor_step = maxf(1.0, value)
		queue_redraw()

@export var guide_left_x: float = 0.0:
	set(value):
		guide_left_x = value
		queue_redraw()

@export var guide_right_x: float = -1.0:
	set(value):
		guide_right_x = value
		queue_redraw()

@export var line_width: float = 3.0:
	set(value):
		line_width = maxf(1.0, value)
		queue_redraw()

@export var label_prefix: String = "Этаж ":
	set(value):
		label_prefix = value
		queue_redraw()

@export var label_offset: Vector2 = Vector2(12.0, -10.0):
	set(value):
		label_offset = value
		queue_redraw()

@export var show_labels: bool = true:
	set(value):
		show_labels = value
		queue_redraw()

@export var show_bands: bool = true:
	set(value):
		show_bands = value
		queue_redraw()

@export var band_alpha: float = 0.08:
	set(value):
		band_alpha = clampf(value, 0.0, 1.0)
		queue_redraw()

@export var draw_tick_marks: bool = true:
	set(value):
		draw_tick_marks = value
		queue_redraw()

@export var tick_spacing: float = 128.0:
	set(value):
		tick_spacing = maxf(32.0, value)
		queue_redraw()

@export var tick_height: float = 10.0:
	set(value):
		tick_height = maxf(4.0, value)
		queue_redraw()


func _ready() -> void:
	queue_redraw()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	if not enabled:
		return
	if editor_only and not Engine.is_editor_hint():
		return

	var left_x: float = _resolve_left_bound()
	var right_x: float = _resolve_right_bound(left_x)
	if right_x <= left_x:
		return

	var floors: Array[float] = _build_floor_positions()
	if floors.is_empty():
		return

	if show_bands and floors.size() > 1:
		for index in range(floors.size() - 1):
			var top_y: float = floors[index + 1]
			var bottom_y: float = floors[index]
			var band_rect := Rect2(
				Vector2(left_x, top_y),
				Vector2(right_x - left_x, bottom_y - top_y)
			)
			var band_color: Color = _get_floor_color(index)
			band_color.a = band_alpha
			draw_rect(band_rect, band_color, true)

	for index in range(floors.size()):
		var floor_y: float = floors[index]
		var floor_color: Color = _get_floor_color(index)
		draw_line(Vector2(left_x, floor_y), Vector2(right_x, floor_y), floor_color, line_width, true)

		if draw_tick_marks:
			var tick_x: float = left_x
			while tick_x <= right_x:
				draw_line(
					Vector2(tick_x, floor_y - tick_height * 0.5),
					Vector2(tick_x, floor_y + tick_height * 0.5),
					floor_color,
					maxf(1.0, line_width - 1.0),
					true
				)
				tick_x += tick_spacing

		if show_labels:
			_draw_floor_label(index, floor_y, left_x, floor_color)


func _build_floor_positions() -> Array[float]:
	var floors: Array[float] = []
	for index in range(floor_count):
		floors.append(base_floor_y - floor_step * index)
	return floors


func _draw_floor_label(index: int, floor_y: float, left_x: float, floor_color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return

	var font_size: int = ThemeDB.fallback_font_size
	if font_size <= 0:
		font_size = 16

	var label_text: String = "%s%d  y=%.0f" % [label_prefix, index + 1, floor_y]
	var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.85)
	var label_position: Vector2 = Vector2(left_x, floor_y) + label_offset

	draw_string(font, label_position + Vector2(1.0, 1.0), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, shadow_color)
	draw_string(font, label_position, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, floor_color)


func _get_floor_color(index: int) -> Color:
	if index < DEFAULT_GUIDE_COLORS.size():
		return DEFAULT_GUIDE_COLORS[index]
	return DEFAULT_GUIDE_COLORS[index % DEFAULT_GUIDE_COLORS.size()]


func _resolve_left_bound() -> float:
	if guide_left_x != 0.0:
		return guide_left_x
	var scene_root: Node = _resolve_scene_root()
	if scene_root != null and "camera_limit_left" in scene_root:
		return float(scene_root.camera_limit_left)
	return 0.0


func _resolve_right_bound(left_x: float) -> float:
	if guide_right_x > left_x:
		return guide_right_x
	var scene_root: Node = _resolve_scene_root()
	if scene_root != null and "camera_limit_right" in scene_root:
		return float(scene_root.camera_limit_right)
	return left_x + 2000.0


func _resolve_scene_root() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	if Engine.is_editor_hint() and tree.edited_scene_root != null:
		return tree.edited_scene_root
	return tree.current_scene
