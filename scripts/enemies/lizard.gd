extends CharacterBody2D

signal died()
signal health_changed(new_health)

@export_enum("simple", "elite", "boss") var enemy_type: String = "simple"

@export var max_health: int = 6
@export var current_health: int = 6
@export var damage: int = 5
@export var move_speed: float = 100.0
@export var chase_speed: float = 120.0
@export var attack_range: float = 120.0
@export var detection_range: float = 150.0
@export var patrol_distance: float = 100.0

enum State { IDLE, PATROL, CHASE, ATTACK, HURT, DEAD }
var current_state: State = State.IDLE

const PERSISTENCE_COMPONENT := preload("res://scripts/persistence/persistence_component.gd")
const ATTACK_COOLDOWN_TIME: float = 1.0
const IDLE_TIME: float = 1.5
const MIN_DISTANCE_TO_PLAYER: float = 40.0

var start_position: Vector2
var patrol_direction: int = 1
var target: Node2D = null
var can_attack: bool = true
var damage_dealt_this_attack: bool = false

var idle_timer: float = 0.0
var attack_cooldown: float = 0.0
var gravity: int = int(ProjectSettings.get_setting("physics/2d/default_gravity"))
var is_alive: bool = true
var is_active: bool = true
var persistence: PersistenceComponent = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea


func _ready() -> void:
	start_position = global_position

	if detection_area:
		if not detection_area.body_entered.is_connected(_on_detection_entered):
			detection_area.body_entered.connect(_on_detection_entered)
		if not detection_area.body_exited.is_connected(_on_detection_exited):
			detection_area.body_exited.connect(_on_detection_exited)

	if animated_sprite:
		if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
			animated_sprite.animation_finished.connect(_on_animation_finished)
		if not animated_sprite.frame_changed.is_connected(_on_frame_changed):
			animated_sprite.frame_changed.connect(_on_frame_changed)

	_ensure_persistence()
	_configure_persistence()

	var saved_state: Dictionary = _load_persistent_state()
	if not saved_state.is_empty():
		apply_persistent_state(saved_state)
		if not is_alive:
			return
		return

	_change_state(State.IDLE)


func capture_persistent_state() -> Dictionary:
	var state: Dictionary = save_state()
	state["dead"] = not is_alive
	state["consumed"] = not is_alive
	return state


func apply_persistent_state(state: Dictionary) -> void:
	load_state(state)


func _ensure_persistence() -> void:
	persistence = get_node_or_null("Persistence") as PersistenceComponent
	if persistence != null:
		return

	persistence = PERSISTENCE_COMPONENT.new()
	persistence.name = "Persistence"
	add_child(persistence)


func _configure_persistence() -> void:
	if persistence:
		persistence.configure(name, "enemy", false)


func _load_persistent_state() -> Dictionary:
	if Global and not Global.run_started:
		return {}
	if persistence == null:
		return {}

	var saved_state: Dictionary = persistence.get_saved_state()
	if saved_state.is_empty():
		var was_killed: bool = false
		if Global and name in Global.killed_enemies:
			was_killed = true
		if was_killed:
			saved_state = persistence.mark_consumed({
				"dead": true,
				"is_alive": false,
				"current_health": 0,
				"current_state": State.DEAD,
				"start_position": start_position,
			})

	return saved_state


func _physics_process(delta: float) -> void:
	if not is_alive or not is_active:
		velocity = Vector2.ZERO
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if attack_cooldown > 0.0:
		attack_cooldown -= delta
		if attack_cooldown <= 0.0:
			can_attack = true

	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.PATROL:
			_process_patrol()
		State.CHASE:
			_process_chase()
		State.ATTACK:
			velocity.x = 0.0
		State.HURT:
			velocity.x = 0.0
		State.DEAD:
			velocity = Vector2.ZERO
			return

	move_and_slide()


func save_state() -> Dictionary:
	return {
		"is_alive": is_alive,
		"current_health": current_health,
		"global_position": global_position,
		"current_state": current_state,
		"patrol_direction": patrol_direction,
		"start_position": start_position,
	}


func load_state(state: Dictionary) -> void:
	is_alive = bool(state.get("is_alive", true)) and not bool(state.get("dead", false))
	current_health = int(state.get("current_health", max_health))

	if state.has("start_position"):
		start_position = state["start_position"]
	if state.has("global_position"):
		global_position = state["global_position"]
	if state.has("patrol_direction"):
		patrol_direction = int(state["patrol_direction"])

	if not is_alive:
		_set_dead_state()
		return

	is_active = true
	visible = true
	set_physics_process(true)
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	if detection_area:
		detection_area.set_deferred("monitoring", true)
		detection_area.set_deferred("monitorable", true)
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE

	health_changed.emit(current_health)

	var saved_state: int = int(state.get("current_state", State.IDLE))
	current_state = State.IDLE
	_change_state(saved_state)


func _set_dead_state() -> void:
	is_alive = false
	is_active = false
	current_state = State.DEAD
	visible = false

	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if detection_area:
		detection_area.set_deferred("monitoring", false)
		detection_area.set_deferred("monitorable", false)

	set_physics_process(false)


func _change_state(new_state: State) -> void:
	if current_state == State.DEAD and not is_alive:
		return
	if current_state == new_state:
		return

	current_state = new_state

	match new_state:
		State.IDLE:
			_play_anim("idle")
			velocity.x = 0.0
			idle_timer = IDLE_TIME
		State.PATROL:
			_play_anim("walk")
		State.CHASE:
			_play_anim("walk")
		State.ATTACK:
			velocity.x = 0.0
			damage_dealt_this_attack = false
			_face_target()
			_play_anim("attack")
		State.HURT:
			_play_anim("hurt")
			velocity.x = 0.0
		State.DEAD:
			_disable_collision()
			_play_anim("death")
			velocity = Vector2.ZERO


func _disable_collision() -> void:
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if detection_area:
		detection_area.monitoring = false
		detection_area.monitorable = false


func _process_idle(delta: float) -> void:
	velocity.x = 0.0
	idle_timer -= delta
	if idle_timer <= 0.0:
		_change_state(State.PATROL)


func _process_patrol() -> void:
	if is_on_wall():
		patrol_direction *= -1
		idle_timer = 0.5
		_change_state(State.IDLE)
		return

	var dist_from_start: float = global_position.x - start_position.x
	if patrol_direction > 0 and dist_from_start >= patrol_distance:
		patrol_direction = -1
		idle_timer = 0.5
		_change_state(State.IDLE)
		return
	elif patrol_direction < 0 and dist_from_start <= -patrol_distance:
		patrol_direction = 1
		idle_timer = 0.5
		_change_state(State.IDLE)
		return

	velocity.x = patrol_direction * move_speed
	if animated_sprite:
		animated_sprite.flip_h = patrol_direction < 0


func _process_chase() -> void:
	if not target or not is_instance_valid(target):
		_change_state(State.PATROL)
		return
	if target.get("is_dead") == true:
		target = null
		_change_state(State.PATROL)
		return

	var dist: float = global_position.distance_to(target.global_position)
	var dir_x: float = target.global_position.x - global_position.x

	if animated_sprite:
		animated_sprite.flip_h = dir_x < 0

	if dist <= attack_range and can_attack:
		_change_state(State.ATTACK)
		return

	if dist <= attack_range and not can_attack:
		velocity.x = 0.0
		return

	if dist <= MIN_DISTANCE_TO_PLAYER:
		velocity.x = -sign(dir_x) * move_speed * 0.5
		return

	velocity.x = sign(dir_x) * chase_speed


func _face_target() -> void:
	if target and animated_sprite:
		var dir: float = target.global_position.x - global_position.x
		animated_sprite.flip_h = dir < 0


func _on_detection_entered(body: Node2D) -> void:
	if not is_alive:
		return
	if body.is_in_group("player"):
		if body.get("is_dead") == true:
			return
		target = body
		_change_state(State.CHASE)


func _on_detection_exited(body: Node2D) -> void:
	if not is_alive:
		return
	if body == target:
		target = null
		if current_state == State.CHASE:
			_change_state(State.PATROL)


func _play_anim(anim_name: String) -> void:
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name:
			animated_sprite.play(anim_name)


func _on_frame_changed() -> void:
	if current_state != State.ATTACK or damage_dealt_this_attack:
		return
	if animated_sprite.frame == 3:
		_deal_damage()
		damage_dealt_this_attack = true


func _on_animation_finished() -> void:
	match current_state:
		State.ATTACK:
			if not damage_dealt_this_attack:
				_deal_damage()
				damage_dealt_this_attack = true

			can_attack = false
			attack_cooldown = ATTACK_COOLDOWN_TIME

			if target and is_instance_valid(target) and target.get("is_dead") != true:
				_change_state(State.CHASE)
			else:
				target = null
				_change_state(State.PATROL)
		State.HURT:
			if target and is_instance_valid(target):
				_change_state(State.CHASE)
			else:
				_change_state(State.PATROL)
		State.DEAD:
			_on_death_completed()


func _on_death_completed() -> void:
	is_alive = false
	is_active = false

	var tw: Tween = create_tween()
	tw.tween_property(animated_sprite, "modulate:a", 0.0, 1.0)
	tw.tween_callback(_hide_enemy)


func _hide_enemy() -> void:
	visible = false
	if collision_shape:
		collision_shape.disabled = true
	if detection_area:
		detection_area.monitoring = false
		detection_area.monitorable = false
	set_physics_process(false)

	if persistence:
		persistence.mark_consumed(capture_persistent_state())


func _deal_damage() -> void:
	if not target or not is_instance_valid(target):
		return
	if target.get("is_dead") == true:
		return

	var dist: float = global_position.distance_to(target.global_position)
	if dist <= attack_range + 30.0 and target.has_method("take_damage"):
		target.take_damage(damage, "physical", "РЇС‰РµСЂРёС†Р° СЃ РєРѕРїСЊС‘Рј")


func take_damage(amount: int, _type: String = "physical") -> void:
	if not is_alive or current_state == State.DEAD:
		return

	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)

	if persistence:
		persistence.save_from_owner()

	if Global and Global.has_method("add_damage_dealt"):
		Global.add_damage_dealt(amount)

	_show_damage_flash()

	if current_health <= 0:
		_die()
	else:
		_change_state(State.HURT)


func _show_damage_flash() -> void:
	if not animated_sprite:
		return

	animated_sprite.modulate = Color(2, 0.5, 0.5)
	var tw: Tween = create_tween()
	tw.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)


func _die() -> void:
	if Global and Global.has_method("add_enemy_killed"):
		Global.add_enemy_killed(enemy_type)
	if Global:
		Global.register_killed_enemy(name)

	is_alive = false
	_change_state(State.DEAD)

	if persistence:
		persistence.mark_consumed(capture_persistent_state())

	died.emit()


func activate() -> void:
	if is_alive:
		is_active = true
		set_physics_process(true)
		visible = true


func deactivate() -> void:
	is_active = false
	set_physics_process(false)
	if animated_sprite:
		animated_sprite.stop()
