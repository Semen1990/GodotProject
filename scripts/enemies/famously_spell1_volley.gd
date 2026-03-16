extends Node2D

const SPELL1_BOLT_SCENE: PackedScene = preload("res://prefabs/enemies/FamouslySpell1Projectile.tscn")

var target: Node2D = null
var target_body_point: Vector2 = Vector2.ZERO
var target_facing_direction: float = 1.0
var projectile_count: int = 6
var projectile_speed: float = 460.0
var hit_radius: float = 30.0
var projectile_lifetime: float = 1.05
var damage_amount: int = 2
var damage_source: String = "Famously"
var face_side_distance: float = 148.0
var spawn_vertical_offset: float = -258.0
var spawn_horizontal_step: float = 42.0
var spawn_vertical_step: float = 28.0
var impact_horizontal_step: float = 34.0
var target_body_offset: Vector2 = Vector2.ZERO
var active_bolts: Array[Node] = []
var resolved: bool = false


func setup_spell1_volley(
	target_node: Node2D,
	target_snapshot_position: Vector2,
	facing_direction: float,
	count: int,
	speed: float,
	radius: float,
	lifetime: float,
	damage: int,
	source: String,
	side_distance: float,
	vertical_offset: float,
	horizontal_step: float,
	vertical_step: float,
	impact_step: float,
	body_offset: Vector2
) -> void:
	target = target_node
	target_body_point = target_snapshot_position
	target_facing_direction = 1.0 if facing_direction >= 0.0 else -1.0
	projectile_count = maxi(1, count)
	projectile_speed = maxf(1.0, speed)
	hit_radius = maxf(4.0, radius)
	projectile_lifetime = maxf(0.1, lifetime)
	damage_amount = maxi(1, damage)
	damage_source = source
	face_side_distance = side_distance
	spawn_vertical_offset = vertical_offset
	spawn_horizontal_step = horizontal_step
	spawn_vertical_step = vertical_step
	impact_horizontal_step = impact_step
	target_body_offset = body_offset
	_spawn_bolts()


func request_hit(_bolt: Node2D, target_node: Node2D) -> void:
	if resolved:
		return
	resolved = true

	if target_node != null and is_instance_valid(target_node):
		if target_node.has_method("register_incoming_attacker"):
			target_node.register_incoming_attacker(_bolt)
		if target_node.has_method("take_damage"):
			target_node.take_damage(damage_amount, "magical", damage_source)

	if CombatRuntimeLogger:
		CombatRuntimeLogger.log_event("spell", name, "spell1_volley_hit", {
			"target": target_node.name if target_node != null and is_instance_valid(target_node) else "<null>",
			"position": _bolt.global_position if _bolt != null and is_instance_valid(_bolt) else global_position,
			"damage": damage_amount,
		})

	_clear_bolts()
	queue_free()


func notify_bolt_finished(bolt: Node) -> void:
	active_bolts.erase(bolt)
	if active_bolts.is_empty() and not resolved:
		if CombatRuntimeLogger:
			CombatRuntimeLogger.log_event("spell", name, "spell1_volley_miss", {
				"target": target.name if target != null and is_instance_valid(target) else "<null>",
			})
		queue_free()


func _spawn_bolts() -> void:
	if SPELL1_BOLT_SCENE == null:
		queue_free()
		return

	for projectile_index in range(projectile_count):
		var bolt: Node2D = SPELL1_BOLT_SCENE.instantiate() as Node2D
		if bolt == null:
			continue

		var slot_offset: float = _get_projectile_slot_offset(projectile_index)
		var vertical_rank: float = _get_projectile_vertical_rank(projectile_index)
		var spawn_position: Vector2 = target_body_point + Vector2(
			target_facing_direction * slot_offset * spawn_horizontal_step,
			spawn_vertical_offset + vertical_rank * spawn_vertical_step
		)
		var impact_point: Vector2 = target_body_point + Vector2(
			target_facing_direction * slot_offset * impact_horizontal_step,
			0.0
		)
		spawn_position.x += target_facing_direction * face_side_distance

		if bolt.has_method("setup_spell1_bolt"):
			bolt.setup_spell1_bolt(
				self,
				target,
				spawn_position,
				impact_point,
				projectile_speed,
				hit_radius,
				projectile_lifetime,
				target_body_offset
			)
		add_child(bolt)
		active_bolts.append(bolt)

	if active_bolts.is_empty():
		queue_free()


func _get_projectile_slot_offset(projectile_index: int) -> float:
	if projectile_count == 6:
		var slot_offsets: Array[float] = [3.0, 2.0, 1.0, 0.0, -1.0, -2.0]
		return slot_offsets[clampi(projectile_index, 0, slot_offsets.size() - 1)]

	var center_index: float = float(projectile_count - 1) * 0.5
	return center_index - float(projectile_index)


func _get_projectile_vertical_rank(projectile_index: int) -> float:
	if projectile_count == 6:
		var vertical_ranks: Array[float] = [3.0, 2.0, 1.0, 0.0, -1.0, -2.0]
		return vertical_ranks[clampi(projectile_index, 0, vertical_ranks.size() - 1)]

	var center_index: float = float(projectile_count - 1) * 0.5
	return center_index - float(projectile_index)


func _clear_bolts() -> void:
	for bolt in active_bolts:
		if bolt != null and is_instance_valid(bolt):
			bolt.queue_free()
	active_bolts.clear()
