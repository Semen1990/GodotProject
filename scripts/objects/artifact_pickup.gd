extends Area2D
class_name ArtifactPickup

signal collected(artifact_id: String)

@export var artifact_id: String = "hermes_wings"
@export var float_height: float = 4.0
@export var float_speed: float = 2.5

const ARTIFACT_ITEM_IDS := {
	"hermes_wings": 201,
	"phoenix_feather": 202,
	"vampire_ring": 203,
	"berserker_amulet": 204,
}

var sprite: Sprite2D = null
var name_label: Label = null
var hint_label: Label = null

var initial_y: float = 0.0
var time: float = 0.0
var player_in_range: bool = false
var is_collected: bool = false
var float_enabled: bool = true
var pending_config: Dictionary = {}


func _ready():
	sprite = get_node_or_null("Sprite2D")
	name_label = get_node_or_null("Label")
	hint_label = get_node_or_null("HintLabel")
	initial_y = position.y

	if Global and Global.is_pickup_collected(name):
		queue_free()
		return

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

	if hint_label:
		hint_label.visible = false

	_apply_config(pending_config)
	_refresh_visuals()
	print("ArtifactPickup '%s': %s" % [name, artifact_id])


func setup(id: String, config: Dictionary = {}):
	artifact_id = id
	pending_config = config.duplicate(true)
	if is_node_ready():
		_apply_config(pending_config)
		_refresh_visuals()


func start_floating_after(delay: float):
	float_enabled = false
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if not is_inside_tree() or is_collected:
		return
	initial_y = position.y
	time = 0.0
	float_enabled = true


func _load_texture():
	var path = "res://assets/items/artifacts/%s.png" % artifact_id
	if sprite and ResourceLoader.exists(path):
		sprite.texture = load(path)


func _apply_config(config: Dictionary):
	if config.is_empty():
		return

	if sprite and config.has("display_scale"):
		var display_scale = float(config["display_scale"])
		sprite.scale = Vector2.ONE * display_scale

	var collision = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision and collision.shape is CircleShape2D and config.has("collision_radius"):
		var circle_shape := collision.shape as CircleShape2D
		collision.shape = circle_shape.duplicate()
		(collision.shape as CircleShape2D).radius = float(config["collision_radius"])

	if hint_label:
		if config.has("hint_text"):
			hint_label.text = str(config["hint_text"])
		if config.has("hint_offset"):
			hint_label.position = config["hint_offset"]

	if name_label:
		if config.has("label_offset"):
			name_label.position = config["label_offset"]
		if config.has("label_visible"):
			name_label.visible = bool(config["label_visible"])


func _refresh_visuals():
	_load_texture()
	if name_label:
		name_label.text = _get_display_name()


func _get_display_name() -> String:
	if Global and Global.artifacts_database is Dictionary:
		var artifact_data = Global.artifacts_database.get(artifact_id, {})
		if artifact_data is Dictionary and artifact_data.get("name", "") != "":
			return artifact_data["name"]
	return artifact_id.capitalize()


func _resolve_item_id() -> int:
	if Global and Global.artifacts_database is Dictionary:
		var artifact_data = Global.artifacts_database.get(artifact_id, {})
		if artifact_data is Dictionary and artifact_data.has("item_id"):
			return int(artifact_data["item_id"])
	return ARTIFACT_ITEM_IDS.get(artifact_id, 0)


func _process(delta):
	if is_collected:
		return

	if float_enabled:
		time += delta * float_speed
		position.y = initial_y + sin(time) * float_height

	if player_in_range and Input.is_action_just_pressed("interact"):
		_collect()


func _on_body_entered(body: Node2D):
	if is_collected:
		return

	if _is_player(body):
		player_in_range = true
		if hint_label:
			hint_label.visible = true


func _on_body_exited(body: Node2D):
	if _is_player(body):
		player_in_range = false
		if hint_label:
			hint_label.visible = false


func _is_player(body: Node2D) -> bool:
	return body.is_in_group("player") or body.has_method("take_damage")


func _collect():
	if is_collected:
		return

	is_collected = true

	var item_id = _resolve_item_id()
	if item_id > 0:
		if not Inventory:
			push_warning("ArtifactPickup: Inventory autoload is missing")
			is_collected = false
			return

		var remaining = Inventory.add_item_by_id(item_id, 1)
		if remaining > 0:
			print("Inventory is full")
			is_collected = false
			return

		print("Collected artifact '%s' as inventory item %d" % [artifact_id, item_id])
	elif not (Global and Global.has_method("collect_artifact")):
		push_warning("ArtifactPickup: item id is not configured for '%s'" % artifact_id)
		is_collected = false
		return

	if Global:
		Global.register_collected_pickup(name)
		if Global.has_method("collect_artifact"):
			Global.collect_artifact(artifact_id)
		if Global.has_method("remove_dropped_pickup"):
			Global.remove_dropped_pickup(name)
		if Global.has_method("add_artifact_collected"):
			Global.add_artifact_collected()

	collected.emit(artifact_id)
	_play_collect_effect()


func _play_collect_effect():
	if hint_label:
		hint_label.visible = false

	set_deferred("monitoring", false)

	var tween = create_tween()
	tween.set_parallel(true)
	if sprite:
		tween.tween_property(sprite, "scale", sprite.scale * 1.5, 0.2)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
		tween.tween_property(sprite, "position:y", sprite.position.y - 25, 0.2)

	_spawn_particles()
	tween.chain().tween_callback(queue_free)


func _spawn_particles():
	for i in range(5):
		var particle = Label.new()
		particle.text = "*"
		particle.add_theme_font_size_override("font_size", 16)
		particle.position = Vector2(randf_range(-20, 20), randf_range(-20, 0))
		add_child(particle)

		var tween = create_tween()
		tween.tween_property(particle, "position:y", particle.position.y - 30, 0.5)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_callback(particle.queue_free)
