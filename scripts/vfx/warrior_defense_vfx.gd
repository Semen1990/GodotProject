extends Node2D

const EFFECT_SHEET_PATH := "res://assets/warrior/effects/466.png"
const EFFECT_FRAME_COUNT: int = 11
const EFFECT_HFRAMES: int = 11
const EFFECT_VFRAMES: int = 9
const BARRIER_ROW: int = 0
const BASTION_ROW: int = 2
const BARRIER_FPS: float = 16.0
const BASTION_FPS: float = 14.0
const BARRIER_HIT_FLASH_TIME: float = 0.14
const BARRIER_BREAK_FLASH_TIME: float = 0.22
const EFFECT_CENTER_OFFSET := Vector2(0.0, 58.0)
const STACKED_VERTICAL_SPACING: float = 24.0
const BARRIER_SCALE_MIN: float = 1.28
const BARRIER_SCALE_MAX: float = 1.46
const BASTION_SCALE: float = 1.34

var owner_body: Node2D = null
var owner_sprite: Node2D = null

var barrier_sprite: Sprite2D = null
var bastion_sprite: Sprite2D = null

var barrier_active: bool = false
var barrier_strength_ratio: float = 1.0
var barrier_frame_timer: float = 0.0
var barrier_current_frame: int = 0
var barrier_hit_flash_timer: float = 0.0
var barrier_break_flash_timer: float = 0.0

var bastion_active: bool = false
var bastion_frame_timer: float = 0.0
var bastion_current_frame: int = 0


func setup(body: Node2D) -> Node:
	owner_body = body
	owner_sprite = body.get_node_or_null("AnimatedSprite2D") as Node2D
	top_level = true
	z_as_relative = false
	z_index = 118
	global_position = Vector2.ZERO
	_build_runtime_nodes()
	set_process(true)
	return self


func activate_barrier(strength_ratio: float = 1.0) -> void:
	barrier_active = true
	barrier_strength_ratio = clampf(strength_ratio, 0.0, 1.0)
	barrier_hit_flash_timer = 0.0
	barrier_break_flash_timer = 0.0
	barrier_current_frame = 0
	barrier_frame_timer = 0.0
	_apply_barrier_visual_state()


func update_barrier_strength(strength_ratio: float) -> void:
	barrier_strength_ratio = clampf(strength_ratio, 0.0, 1.0)
	_apply_barrier_visual_state()


func pulse_barrier_hit(strength_ratio: float, broken: bool = false) -> void:
	barrier_strength_ratio = clampf(strength_ratio, 0.0, 1.0)
	barrier_hit_flash_timer = BARRIER_HIT_FLASH_TIME
	if broken:
		barrier_break_flash_timer = BARRIER_BREAK_FLASH_TIME
		barrier_active = false
	_apply_barrier_visual_state()


func deactivate_barrier(broken: bool = false) -> void:
	barrier_active = false
	if broken:
		barrier_break_flash_timer = maxf(barrier_break_flash_timer, BARRIER_BREAK_FLASH_TIME)
	_apply_barrier_visual_state()


func activate_bastion() -> void:
	bastion_active = true
	bastion_current_frame = 0
	bastion_frame_timer = 0.0
	_apply_bastion_visual_state()


func deactivate_bastion() -> void:
	bastion_active = false
	_apply_bastion_visual_state()


func _process(delta: float) -> void:
	if owner_body == null or not is_instance_valid(owner_body):
		queue_free()
		return

	_update_position()
	_update_barrier(delta)
	_update_bastion(delta)


func _build_runtime_nodes() -> void:
	barrier_sprite = _create_effect_sprite()
	if barrier_sprite != null:
		barrier_sprite.name = "BarrierEffect"
		add_child(barrier_sprite)

	bastion_sprite = _create_effect_sprite()
	if bastion_sprite != null:
		bastion_sprite.name = "BastionEffect"
		add_child(bastion_sprite)

	_apply_barrier_visual_state()
	_apply_bastion_visual_state()


func _create_effect_sprite() -> Sprite2D:
	if not ResourceLoader.exists(EFFECT_SHEET_PATH):
		return null

	var sprite := Sprite2D.new()
	sprite.texture = load(EFFECT_SHEET_PATH)
	sprite.centered = true
	sprite.hframes = EFFECT_HFRAMES
	sprite.vframes = EFFECT_VFRAMES
	sprite.frame = 0
	sprite.visible = false
	sprite.position = Vector2.ZERO
	return sprite


func _update_position() -> void:
	if owner_sprite != null and is_instance_valid(owner_sprite):
		global_position = owner_sprite.global_position + EFFECT_CENTER_OFFSET
	else:
		global_position = owner_body.global_position + EFFECT_CENTER_OFFSET


func _update_barrier(delta: float) -> void:
	if barrier_hit_flash_timer > 0.0:
		barrier_hit_flash_timer = maxf(0.0, barrier_hit_flash_timer - delta)

	if barrier_break_flash_timer > 0.0:
		barrier_break_flash_timer = maxf(0.0, barrier_break_flash_timer - delta)
		if barrier_break_flash_timer <= 0.0 and not barrier_active and barrier_sprite != null:
			barrier_sprite.visible = false

	if not barrier_active:
		_apply_barrier_visual_state()
		return

	barrier_frame_timer += delta
	var frame_duration: float = 1.0 / BARRIER_FPS
	while barrier_frame_timer >= frame_duration:
		barrier_frame_timer -= frame_duration
		barrier_current_frame = (barrier_current_frame + 1) % EFFECT_FRAME_COUNT

	_apply_barrier_visual_state()


func _update_bastion(delta: float) -> void:
	if not bastion_active:
		_apply_bastion_visual_state()
		return

	bastion_frame_timer += delta
	var frame_duration: float = 1.0 / BASTION_FPS
	while bastion_frame_timer >= frame_duration:
		bastion_frame_timer -= frame_duration
		bastion_current_frame = (bastion_current_frame + 1) % EFFECT_FRAME_COUNT

	_apply_bastion_visual_state()


func _apply_barrier_visual_state() -> void:
	if barrier_sprite == null:
		return

	var should_show: bool = barrier_active or barrier_break_flash_timer > 0.0
	barrier_sprite.visible = should_show
	if not should_show:
		return

	barrier_sprite.frame = BARRIER_ROW * EFFECT_HFRAMES + clampi(barrier_current_frame, 0, EFFECT_FRAME_COUNT - 1)
	var stacked_offset := Vector2.ZERO
	if barrier_active and bastion_active:
		stacked_offset.y = -STACKED_VERTICAL_SPACING * 0.5
	barrier_sprite.position = stacked_offset
	barrier_sprite.scale = Vector2.ONE * lerpf(BARRIER_SCALE_MIN, BARRIER_SCALE_MAX, barrier_strength_ratio)

	var alpha: float = lerpf(0.45, 1.0, barrier_strength_ratio)
	if barrier_break_flash_timer > 0.0:
		alpha = maxf(alpha, barrier_break_flash_timer / BARRIER_BREAK_FLASH_TIME)
	if barrier_hit_flash_timer > 0.0:
		barrier_sprite.modulate = Color(1.45, 1.45, 1.65, alpha)
	else:
		barrier_sprite.modulate = Color(1.0, 1.0, 1.0, alpha)


func _apply_bastion_visual_state() -> void:
	if bastion_sprite == null:
		return

	bastion_sprite.visible = bastion_active
	if not bastion_active:
		return

	bastion_sprite.frame = BASTION_ROW * EFFECT_HFRAMES + clampi(bastion_current_frame, 0, EFFECT_FRAME_COUNT - 1)
	var stacked_offset := Vector2.ZERO
	if barrier_active and bastion_active:
		stacked_offset.y = STACKED_VERTICAL_SPACING * 0.5
	bastion_sprite.position = stacked_offset
	bastion_sprite.scale = Vector2.ONE * BASTION_SCALE
	bastion_sprite.modulate = Color(1.0, 1.0, 1.0, 0.94)
