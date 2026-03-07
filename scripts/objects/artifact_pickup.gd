extends Area2D
class_name ArtifactPickup

signal collected(artifact_id: String)

@export var artifact_id: String = "hermes_wings"
@export var float_height: float = 4.0
@export var float_speed: float = 2.5

const PERSISTENCE_COMPONENT := preload("res://scripts/persistence/persistence_component.gd")
const ARTIFACT_ITEM_IDS := {
	"hermes_wings": 201,
	"phoenix_feather": 202,
	"vampire_ring": 203,
	"berserker_amulet": 204,
}

const ARTIFACT_FALLBACK_NAMES := {
	"hermes_wings": "Крылья Гермеса",
	"phoenix_feather": "Перо Феникса",
	"vampire_ring": "Кольцо Вампира",
	"berserker_amulet": "Амулет Берсерка",
}

var sprite: Sprite2D = null
var name_label: Label = null
var hint_label: Label = null
var persistence: PersistenceComponent = null

var initial_y: float = 0.0
var time: float = 0.0
var player_in_range: bool = false
var is_collected: bool = false
var float_enabled: bool = true
var pending_config: Dictionary = {}
var pending_persistent_id: String = ""


func _ready() -> void:
	sprite = get_node_or_null("Sprite2D")
	name_label = get_node_or_null("Label")
	hint_label = get_node_or_null("HintLabel")
	initial_y = position.y

	_ensure_persistence()
	_configure_persistence()

	var saved_state: Dictionary = _load_persistent_state()
	if bool(saved_state.get("collected", false)) or bool(saved_state.get("consumed", false)):
		queue_free()
		return

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

	_configure_labels()

	if hint_label:
		hint_label.visible = false
		if hint_label.text.is_empty():
			hint_label.text = "[F] Подобрать"

	_apply_config(pending_config)
	_refresh_visuals()


func setup(id: String, config: Dictionary = {}) -> void:
	artifact_id = id
	pending_config = config.duplicate(true)
	if is_node_ready():
		_apply_config(pending_config)
		_refresh_visuals()


func set_persistent_id(id: String) -> void:
	pending_persistent_id = id
	if is_node_ready():
		_configure_persistence()


func start_floating_after(delay: float) -> void:
	float_enabled = false
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if not is_inside_tree() or is_collected:
		return
	initial_y = position.y
	time = 0.0
	float_enabled = true


func capture_persistent_state() -> Dictionary:
	return {
		"artifact_id": artifact_id,
		"collected": is_collected,
		"consumed": is_collected,
	}


func apply_persistent_state(state: Dictionary) -> void:
	if state.has("artifact_id"):
		artifact_id = str(state["artifact_id"])
	is_collected = bool(state.get("collected", false)) or bool(state.get("consumed", false))


func _ensure_persistence() -> void:
	persistence = get_node_or_null("Persistence") as PersistenceComponent
	if persistence != null:
		return

	persistence = PERSISTENCE_COMPONENT.new()
	persistence.name = "Persistence"
	add_child(persistence)


func _configure_persistence() -> void:
	if persistence == null:
		return

	var resolved_id: String = pending_persistent_id
	if resolved_id.is_empty():
		resolved_id = name
	persistence.configure(resolved_id, "pickup", true)


func _load_persistent_state() -> Dictionary:
	if Global and not Global.run_started:
		return {}
	if persistence == null:
		return {}

	var saved_state: Dictionary = persistence.get_saved_state()
	if saved_state.is_empty() and Global and Global.is_pickup_collected(name):
		saved_state = persistence.mark_consumed({
			"artifact_id": artifact_id,
			"collected": true,
		})

	if not saved_state.is_empty():
		apply_persistent_state(saved_state)

	return saved_state


func _configure_labels() -> void:
	if name_label:
		name_label.custom_minimum_size = Vector2(180.0, 20.0)
		name_label.size = Vector2(180.0, 40.0)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.clip_text = false

	if hint_label:
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _load_texture() -> void:
	if not sprite:
		return

	var item_id: int = _resolve_item_id()
	if item_id > 0 and Inventory and Inventory.item_database:
		var item_data: GameItemData = Inventory.item_database.get_item_by_id(item_id)
		if item_data and item_data.icon:
			sprite.texture = item_data.icon
			return

	var artifact_data: Dictionary = _get_artifact_data()
	var explicit_icon_path: String = String(artifact_data.get("icon", ""))
	if not explicit_icon_path.is_empty() and ResourceLoader.exists(explicit_icon_path):
		sprite.texture = load(explicit_icon_path)
		return

	var path: String = "res://assets/items/artifacts/%s.png" % artifact_id
	if ResourceLoader.exists(path):
		sprite.texture = load(path)


func _apply_config(config: Dictionary) -> void:
	if config.is_empty():
		return

	if sprite and config.has("display_scale"):
		var display_scale: float = float(config["display_scale"])
		sprite.scale = Vector2.ONE * display_scale

	var collision: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision and collision.shape is CircleShape2D and config.has("collision_radius"):
		var circle_shape: CircleShape2D = collision.shape as CircleShape2D
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


func _refresh_visuals() -> void:
	_load_texture()
	if name_label:
		name_label.text = _get_display_name()


func _get_artifact_data() -> Dictionary:
	if Global and Global.artifacts_database is Dictionary:
		var artifact_data: Dictionary = Global.artifacts_database.get(artifact_id, {})
		return artifact_data
	return {}


func _get_display_name() -> String:
	var item_id: int = _resolve_item_id()
	if item_id > 0 and Inventory and Inventory.item_database:
		var item_data: GameItemData = Inventory.item_database.get_item_by_id(item_id)
		if item_data and not item_data.display_name.is_empty():
			return item_data.display_name

	var artifact_data: Dictionary = _get_artifact_data()
	if artifact_data.has("name") and not String(artifact_data["name"]).is_empty():
		return String(artifact_data["name"])

	return ARTIFACT_FALLBACK_NAMES.get(artifact_id, artifact_id.capitalize())


func _resolve_item_id() -> int:
	var artifact_data: Dictionary = _get_artifact_data()
	if artifact_data.has("item_id"):
		return int(artifact_data["item_id"])
	return ARTIFACT_ITEM_IDS.get(artifact_id, 0)


func _process(delta: float) -> void:
	if is_collected:
		return

	if float_enabled:
		time += delta * float_speed
		position.y = initial_y + sin(time) * float_height

	if player_in_range and Input.is_action_just_pressed("interact"):
		_collect()


func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return

	if _is_player(body):
		player_in_range = true
		if hint_label:
			hint_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if _is_player(body):
		player_in_range = false
		if hint_label:
			hint_label.visible = false


func _is_player(body: Node2D) -> bool:
	return body.is_in_group("player") or body.has_method("take_damage")


func _collect() -> void:
	if is_collected:
		return

	is_collected = true

	var item_id: int = _resolve_item_id()
	if item_id > 0:
		if not Inventory:
			push_warning("ArtifactPickup: не найден автозагрузочный Inventory")
			is_collected = false
			return

		var remaining: int = Inventory.add_item_by_id(item_id, 1)
		if remaining > 0:
			is_collected = false
			return
	elif not (Global and Global.has_method("collect_artifact")):
		push_warning("ArtifactPickup: для '%s' не настроен item_id" % artifact_id)
		is_collected = false
		return

	if persistence:
		persistence.mark_consumed({
			"artifact_id": artifact_id,
			"collected": true,
		})

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


func _play_collect_effect() -> void:
	if hint_label:
		hint_label.visible = false

	set_deferred("monitoring", false)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	if sprite:
		tween.tween_property(sprite, "scale", sprite.scale * 1.5, 0.2)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
		tween.tween_property(sprite, "position:y", sprite.position.y - 25.0, 0.2)
	else:
		tween.tween_property(self, "modulate:a", 0.0, 0.2)

	_spawn_particles()
	tween.chain().tween_callback(queue_free)


func _spawn_particles() -> void:
	for i in range(5):
		var particle: Label = Label.new()
		particle.text = "*"
		particle.add_theme_font_size_override("font_size", 16)
		particle.position = Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 0.0))
		add_child(particle)

		var tween: Tween = create_tween()
		tween.tween_property(particle, "position:y", particle.position.y - 30.0, 0.5)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_callback(particle.queue_free)
