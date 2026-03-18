extends Node2D

@export var barrier_fps: float = 16.0
@export var bastion_fps: float = 14.0
@export var frame_count: int = 11
@export var hframes_count: int = 11
@export var barrier_row: int = 0
@export var bastion_row: int = 2

@onready var barrier_sprite: Sprite2D = $BarrierPreview/BarrierSprite
@onready var bastion_sprite: Sprite2D = $BastionPreview/BastionSprite

var _barrier_timer: float = 0.0
var _bastion_timer: float = 0.0


func _ready() -> void:
	if barrier_sprite != null:
		barrier_sprite.frame = barrier_row * hframes_count
	if bastion_sprite != null:
		bastion_sprite.frame = bastion_row * hframes_count


func _process(delta: float) -> void:
	_update_sprite_frame(delta, barrier_sprite, barrier_fps, "_barrier_timer")
	_update_sprite_frame(delta, bastion_sprite, bastion_fps, "_bastion_timer")


func _update_sprite_frame(delta: float, sprite: Sprite2D, fps: float, timer_property: String) -> void:
	if sprite == null or fps <= 0.0 or frame_count <= 0:
		return

	var timer_value: float = float(get(timer_property)) + delta
	var frame_duration: float = 1.0 / fps
	var row_index: int = barrier_row if sprite == barrier_sprite else bastion_row
	var start_frame: int = row_index * hframes_count
	while timer_value >= frame_duration:
		timer_value -= frame_duration
		var next_column: int = ((sprite.frame - start_frame) + 1) % frame_count
		sprite.frame = start_frame + next_column
	set(timer_property, timer_value)
