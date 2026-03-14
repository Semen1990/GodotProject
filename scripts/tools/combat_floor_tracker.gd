@tool
extends Area2D

class_name CombatFloorTracker

signal combat_floor_changed(current_floor_id: int, last_stable_floor_id: int)

const COMBAT_FLOOR_LAYER: int = 1 << 4

@export var follow_parent_collision_shape: bool = true
@export var probe_size: Vector2 = Vector2(28.0, 10.0):
	set(value):
		probe_size = Vector2(maxf(8.0, value.x), maxf(4.0, value.y))
		_update_probe_shape()
		queue_redraw()

@export var probe_bottom_padding: float = 2.0:
	set(value):
		probe_bottom_padding = value
		queue_redraw()

@export var debug_visible: bool = true:
	set(value):
		debug_visible = value
		queue_redraw()

@export var editor_only_visuals: bool = true:
	set(value):
		editor_only_visuals = value
		queue_redraw()

var current_floor_id: int = -1
var last_stable_floor_id: int = -1

var _tracked_floor_areas: Array[CombatFloorArea] = []

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	top_level = true
	collision_layer = 0
	collision_mask = COMBAT_FLOOR_LAYER
	monitoring = true
	monitorable = false
	set_physics_process(true)
	_update_probe_shape()
	if follow_parent_collision_shape:
		_sync_to_parent_collision_shape()
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not area_exited.is_connected(_on_area_exited):
		area_exited.connect(_on_area_exited)
	call_deferred("_refresh_from_current_overlaps")


func _physics_process(_delta: float) -> void:
	if follow_parent_collision_shape:
		_sync_to_parent_collision_shape()
	_refresh_from_current_overlaps()
	if Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	if not debug_visible:
		return
	if editor_only_visuals and not Engine.is_editor_hint():
		return
	var rect := Rect2(-probe_size * 0.5, probe_size)
	draw_rect(rect, Color(1.0, 0.95, 0.25, 0.16), true)
	draw_rect(rect, Color(1.0, 0.95, 0.25, 0.95), false, 2.0)


func get_current_floor_id() -> int:
	return current_floor_id


func get_last_stable_floor_id() -> int:
	return last_stable_floor_id


func get_effective_floor_id() -> int:
	return current_floor_id if current_floor_id != -1 else last_stable_floor_id


func is_between_floors() -> bool:
	return current_floor_id == -1 and last_stable_floor_id != -1


func _refresh_from_current_overlaps() -> void:
	_tracked_floor_areas.clear()
	var tree := get_tree()
	if tree == null:
		_refresh_floor_state()
		return
	for node in tree.get_nodes_in_group("combat_floor_areas"):
		var area := node as CombatFloorArea
		if area == null or not is_instance_valid(area):
			continue
		if area.contains_world_point(global_position):
			_tracked_floor_areas.append(area)
	_refresh_floor_state()


func _on_area_entered(area: Area2D) -> void:
	if not area is CombatFloorArea:
		return
	var floor_area := area as CombatFloorArea
	if _tracked_floor_areas.has(floor_area):
		return
	_tracked_floor_areas.append(floor_area)
	_refresh_floor_state()


func _on_area_exited(area: Area2D) -> void:
	if not area is CombatFloorArea:
		return
	var floor_area := area as CombatFloorArea
	_tracked_floor_areas.erase(floor_area)
	_refresh_floor_state()


func _refresh_floor_state() -> void:
	var best_area: CombatFloorArea = _select_best_floor_area()
	var next_floor_id: int = best_area.floor_id if best_area != null else -1
	if next_floor_id == current_floor_id:
		return

	current_floor_id = next_floor_id
	if current_floor_id != -1:
		last_stable_floor_id = current_floor_id

	if CombatRuntimeLogger and not Engine.is_editor_hint():
		CombatRuntimeLogger.log_event(
			"floor",
			get_parent().name if get_parent() != null else name,
			"floor_changed",
			{
				"current_floor_id": current_floor_id,
				"last_stable_floor_id": last_stable_floor_id,
			}
		)

	combat_floor_changed.emit(current_floor_id, last_stable_floor_id)


func _select_best_floor_area() -> CombatFloorArea:
	var best_area: CombatFloorArea = null
	for area in _tracked_floor_areas:
		if not is_instance_valid(area):
			continue
		if best_area == null:
			best_area = area
			continue
		if area.floor_priority > best_area.floor_priority:
			best_area = area
			continue
		if area.floor_priority == best_area.floor_priority and area.floor_id > best_area.floor_id:
			best_area = area
	return best_area


func _sync_to_parent_collision_shape() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	var parent_collision_shape := parent_node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if parent_collision_shape == null or parent_collision_shape.shape == null:
		global_position = parent_node.global_position
		return

	var local_offset := Vector2(0.0, _get_collision_bottom_extent(parent_collision_shape.shape) + probe_bottom_padding)
	global_position = parent_collision_shape.to_global(local_offset)


func _get_collision_bottom_extent(shape: Shape2D) -> float:
	if shape is CapsuleShape2D:
		var capsule := shape as CapsuleShape2D
		return capsule.radius + capsule.height * 0.5
	if shape is RectangleShape2D:
		var rectangle := shape as RectangleShape2D
		return rectangle.size.y * 0.5
	if shape is CircleShape2D:
		var circle := shape as CircleShape2D
		return circle.radius
	return 0.0


func _update_probe_shape() -> void:
	if collision_shape == null:
		return
	var rect_shape := collision_shape.shape as RectangleShape2D
	if rect_shape == null:
		rect_shape = RectangleShape2D.new()
		collision_shape.shape = rect_shape
	rect_shape.size = probe_size
