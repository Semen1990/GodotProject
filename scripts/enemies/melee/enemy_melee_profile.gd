extends Resource
class_name EnemyMeleeProfile

@export var require_line_of_sight_before_engage: bool = true
@export var require_line_of_sight_for_melee: bool = true
@export_flags_2d_physics var line_of_sight_collision_mask: int = 1
@export var line_of_sight_height_offset: float = -28.0

@export var prefer_explicit_combat_floors: bool = true
@export var pre_engage_vertical_tolerance: float = 56.0
@export var melee_vertical_tolerance: float = 48.0

@export var use_combat_lane_before_engage: bool = false
@export var use_combat_lane_for_melee: bool = true
@export var combat_lane_probe_depth: float = 96.0
@export var combat_lane_tolerance: float = 20.0
@export var combat_lane_probe_offset_y: float = -6.0

@export var facing_deadzone_x: float = 12.0
