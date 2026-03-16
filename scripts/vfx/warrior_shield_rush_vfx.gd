extends Node2D

const TRAIL_COLOR: Color = Color(0.82, 0.93, 1.0, 0.74)
const TRAIL_OUTER_COLOR: Color = Color(0.34, 0.56, 0.92, 0.36)
const IMPACT_COLOR: Color = Color(1.0, 0.95, 0.68, 0.95)
const HEAVY_IMPACT_COLOR: Color = Color(1.0, 0.88, 0.48, 1.0)
const PARTICLE_SPAWN_INTERVAL: float = 0.025
const PARTICLE_LIFETIME_MIN: float = 0.18
const PARTICLE_LIFETIME_MAX: float = 0.28
const PARTICLE_SCALE_MIN: float = 0.62
const PARTICLE_SCALE_MAX: float = 1.08
const PARTICLE_SPEED_MIN: float = 44.0
const PARTICLE_SPEED_MAX: float = 96.0
const PARTICLE_MAX_COUNT: int = 72

const TRAIL_ROWS := [
	{
		"y_offset": 92.0,
		"spawn_back_min": 20.0,
		"spawn_back_max": 38.0,
		"lifetime_scale": 3.1,
		"speed_scale": 0.28,
		"scale": Vector2(1.65, 1.0),
	},
]

var owner_body: Node2D = null
var rush_active: bool = false
var rush_facing: float = 1.0
var particle_spawn_timer: float = 0.0
var particles_root: Node2D = null
var trail_particles: Array[Dictionary] = []


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
	particle_spawn_timer = 0.0


func stop_rush() -> void:
	rush_active = false


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
		particle_spawn_timer -= delta
		while particle_spawn_timer <= 0.0:
			_spawn_trail_rows()
			particle_spawn_timer += PARTICLE_SPAWN_INTERVAL

	_update_particles(delta)


func _build_runtime_nodes() -> void:
	particles_root = Node2D.new()
	particles_root.top_level = true
	add_child(particles_root)


func _spawn_trail_rows() -> void:
	for row_data in TRAIL_ROWS:
		_spawn_trail_particle(row_data)


func _spawn_trail_particle(row_data: Dictionary) -> void:
	if particles_root == null or owner_body == null:
		return

	while trail_particles.size() >= PARTICLE_MAX_COUNT:
		_remove_oldest_particle()

	var particle_node := Polygon2D.new()
	particle_node.polygon = PackedVector2Array([
		Vector2(10.0, 0.0),
		Vector2(2.0, -6.0),
		Vector2(-8.0, 0.0),
		Vector2(2.0, 6.0),
	])
	particle_node.color = TRAIL_COLOR
	var spawn_back_min: float = float(row_data.get("spawn_back_min", 18.0))
	var spawn_back_max: float = float(row_data.get("spawn_back_max", 34.0))
	var y_offset: float = float(row_data.get("y_offset", -18.0))
	particle_node.global_position = owner_body.global_position + Vector2(
		-rush_facing * randf_range(spawn_back_min, spawn_back_max),
		y_offset + randf_range(-3.0, 3.0)
	)
	particle_node.rotation = randf_range(-0.28, 0.28)
	var row_scale: Vector2 = row_data.get("scale", Vector2.ONE)
	particle_node.scale = row_scale * randf_range(PARTICLE_SCALE_MIN, PARTICLE_SCALE_MAX)
	particles_root.add_child(particle_node)

	var speed_scale: float = float(row_data.get("speed_scale", 1.0))
	var drift := Vector2(
		-rush_facing * randf_range(PARTICLE_SPEED_MIN, PARTICLE_SPEED_MAX) * speed_scale,
		randf_range(-10.0, 10.0)
	)
	var lifetime_scale: float = float(row_data.get("lifetime_scale", 1.0))
	trail_particles.append({
		"node": particle_node,
		"velocity": drift,
		"lifetime": randf_range(PARTICLE_LIFETIME_MIN, PARTICLE_LIFETIME_MAX) * lifetime_scale,
		"age": 0.0,
		"base_scale": particle_node.scale,
		"base_color": TRAIL_OUTER_COLOR.lerp(TRAIL_COLOR, randf()),
	})


func _update_particles(delta: float) -> void:
	for index in range(trail_particles.size() - 1, -1, -1):
		var particle: Dictionary = trail_particles[index]
		var node: Polygon2D = particle.get("node") as Polygon2D
		if node == null or not is_instance_valid(node):
			trail_particles.remove_at(index)
			continue

		var age: float = float(particle.get("age", 0.0)) + delta
		var lifetime: float = maxf(float(particle.get("lifetime", PARTICLE_LIFETIME_MAX)), 0.001)
		var normalized: float = clampf(age / lifetime, 0.0, 1.0)
		var velocity: Vector2 = particle.get("velocity", Vector2.ZERO)
		var base_scale: Vector2 = particle.get("base_scale", Vector2.ONE)
		var base_color: Color = particle.get("base_color", TRAIL_COLOR)

		node.global_position += velocity * delta
		node.rotation += delta * 5.4 * signf(velocity.x if velocity.x != 0.0 else rush_facing)
		node.scale = base_scale.lerp(base_scale * 1.48, normalized)
		node.color = Color(base_color.r, base_color.g, base_color.b, lerpf(base_color.a, 0.0, normalized))

		particle["age"] = age
		trail_particles[index] = particle

		if normalized >= 1.0:
			node.queue_free()
			trail_particles.remove_at(index)


func _remove_oldest_particle() -> void:
	if trail_particles.is_empty():
		return
	var particle: Dictionary = trail_particles.pop_back()
	var node: Polygon2D = particle.get("node") as Polygon2D
	if node != null and is_instance_valid(node):
		node.queue_free()


func _make_ring_points(segments: int, radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var segment_count: int = max(segments, 6)
	for index in range(segment_count):
		var angle: float = TAU * float(index) / float(segment_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
