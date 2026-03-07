extends Area2D
class_name Chest

signal opened
signal item_spawned(pickup_node: Node2D)

const ITEM_PICKUP_SCENE := preload("res://scenes/items/item_pickup.tscn")
const ARTIFACT_PICKUP_SCENE := preload("res://scenes/items/artifact_pickup.tscn")
const PERSISTENCE_COMPONENT := preload("res://scripts/persistence/persistence_component.gd")

enum ChestType { ITEMS, ARTIFACTS, MIXED, RANDOM }

@export var chest_type: ChestType = ChestType.ITEMS
@export var is_initially_open: bool = false

@export var item_ids: Array[int] = []
@export var item_amounts: Array[int] = []
@export var artifact_ids: Array[String] = []

@export var spawn_frame: int = 3

@export_group("Р’РёР·СѓР°Р» РІС‹РїР°РІС€РёС… РїСЂРµРґРјРµС‚РѕРІ")
@export var item_scale: float = 1.5
@export var artifact_scale: float = 1.8
@export var collision_radius: float = 40.0
@export var item_spread: float = 35.0

var animated_sprite: AnimatedSprite2D = null
var interaction_zone: Area2D = null
var hint_label: Label = null
var persistence: PersistenceComponent = null

var is_open: bool = false
var player_in_range: bool = false
var is_opening: bool = false
var items_spawned: bool = false
var pending_restore_after_setup: bool = false
var contents_configured: bool = false


func _ready() -> void:
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	interaction_zone = get_node_or_null("InteractionZone")
	hint_label = get_node_or_null("HintLabel")
	is_open = is_initially_open
	contents_configured = _has_defined_contents()

	_ensure_persistence()
	_configure_persistence()

	var saved_state: Dictionary = _load_persistent_state()
	if bool(saved_state.get("opened", false)) or bool(saved_state.get("consumed", false)):
		_update_visual()
		_setup_hint()
		if contents_configured:
			call_deferred("_restore_items_and_delete")
		else:
			pending_restore_after_setup = true
		return

	_setup_signals()
	_update_visual()
	_setup_hint()


func capture_persistent_state() -> Dictionary:
	return {
		"opened": is_open or is_opening,
		"contents_spawned": items_spawned,
		"consumed": is_open or is_opening,
	}


func apply_persistent_state(state: Dictionary) -> void:
	is_open = bool(state.get("opened", false))
	is_opening = false
	items_spawned = bool(state.get("contents_spawned", false))


func _ensure_persistence() -> void:
	persistence = get_node_or_null("Persistence") as PersistenceComponent
	if persistence != null:
		return

	persistence = PERSISTENCE_COMPONENT.new()
	persistence.name = "Persistence"
	add_child(persistence)


func _configure_persistence() -> void:
	if persistence:
		persistence.configure(name, "chest", true)


func _load_persistent_state() -> Dictionary:
	if Global and not Global.run_started:
		return {}
	if persistence == null:
		return {}

	var saved_state: Dictionary = persistence.get_saved_state()
	if saved_state.is_empty() and Global and Global.is_chest_opened(name):
		saved_state = persistence.mark_consumed({
			"opened": true,
			"contents_spawned": true,
		})

	if not saved_state.is_empty():
		apply_persistent_state(saved_state)

	return saved_state


func _setup_signals() -> void:
	if interaction_zone:
		if not interaction_zone.body_entered.is_connected(_on_body_entered):
			interaction_zone.body_entered.connect(_on_body_entered)
		if not interaction_zone.body_exited.is_connected(_on_body_exited):
			interaction_zone.body_exited.connect(_on_body_exited)
	else:
		if not body_entered.is_connected(_on_body_entered):
			body_entered.connect(_on_body_entered)
		if not body_exited.is_connected(_on_body_exited):
			body_exited.connect(_on_body_exited)

	if animated_sprite:
		if not animated_sprite.frame_changed.is_connected(_on_frame_changed):
			animated_sprite.frame_changed.connect(_on_frame_changed)
		if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
			animated_sprite.animation_finished.connect(_on_animation_finished)


func _setup_hint() -> void:
	if hint_label:
		hint_label.visible = false
		hint_label.text = "[F] РћС‚РєСЂС‹С‚СЊ"


func _update_visual() -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return

	if is_open:
		if animated_sprite.sprite_frames.has_animation("opened"):
			animated_sprite.play("opened")
		elif animated_sprite.sprite_frames.has_animation("opening"):
			animated_sprite.play("opening")
			animated_sprite.stop()
			animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count("opening") - 1
	else:
		if animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
		elif animated_sprite.sprite_frames.has_animation("closed"):
			animated_sprite.play("closed")


func _on_body_entered(body: Node2D) -> void:
	if is_open or is_opening:
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


func _process(_delta: float) -> void:
	if is_open or is_opening or not player_in_range:
		return

	if Input.is_action_just_pressed("interact"):
		open_chest()


func open_chest() -> void:
	if is_open or is_opening:
		return

	is_opening = true

	if persistence:
		persistence.mark_consumed({
			"opened": true,
			"contents_spawned": false,
		})

	if Global:
		Global.register_opened_chest(name)

	if hint_label:
		hint_label.visible = false

	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("opening"):
		animated_sprite.play("opening")
	else:
		_spawn_contents()
		_finish_opening()


func _on_frame_changed() -> void:
	if not is_opening or items_spawned:
		return

	if animated_sprite and animated_sprite.animation == "opening" and animated_sprite.frame == spawn_frame:
		_spawn_contents()


func _on_animation_finished() -> void:
	if is_opening and animated_sprite and animated_sprite.animation == "opening":
		_finish_opening()


func _finish_opening() -> void:
	is_open = true
	is_opening = false
	if persistence:
		persistence.save_from_owner()
	opened.emit()

	var tween: Tween = create_tween()
	tween.tween_interval(0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


func _spawn_contents() -> void:
	if items_spawned:
		return

	items_spawned = true

	match chest_type:
		ChestType.ITEMS:
			_spawn_items()
		ChestType.ARTIFACTS:
			_spawn_artifacts()
		ChestType.MIXED:
			_spawn_items()
			_spawn_artifacts()
		ChestType.RANDOM:
			_spawn_random()

	if persistence:
		persistence.save_from_owner()


func _spawn_items() -> void:
	var layout_index: int = 0

	for i in range(item_ids.size()):
		var item_id: int = item_ids[i]
		var amount: int = item_amounts[i] if i < item_amounts.size() else 1

		for j in range(amount):
			_create_item_pickup(item_id, i * 10 + j, layout_index)
			layout_index += 1


func _spawn_artifacts() -> void:
	for i in range(artifact_ids.size()):
		_create_artifact_pickup(artifact_ids[i], i, i)


func _spawn_random() -> void:
	_create_item_pickup(1, 0, 0)
	_create_item_pickup(2, 1, 1)


func _restore_items_and_delete() -> void:
	await get_tree().process_frame

	match chest_type:
		ChestType.ITEMS:
			_restore_items()
		ChestType.ARTIFACTS:
			_restore_artifacts()
		ChestType.MIXED:
			_restore_items()
			_restore_artifacts()
		ChestType.RANDOM:
			_restore_items()

	queue_free()


func restore_opened_chest() -> void:
	if not pending_restore_after_setup or not contents_configured:
		return

	pending_restore_after_setup = false
	call_deferred("_restore_items_and_delete")


func _restore_items() -> void:
	var layout_index: int = 0

	for i in range(item_ids.size()):
		var item_id: int = item_ids[i]
		var amount: int = item_amounts[i] if i < item_amounts.size() else 1

		for j in range(amount):
			var pickup_index: int = i * 10 + j
			if _is_item_pickup_collected(item_id, pickup_index):
				layout_index += 1
				continue
			_create_restored_item_pickup(item_id, pickup_index, layout_index)
			layout_index += 1


func _restore_artifacts() -> void:
	for i in range(artifact_ids.size()):
		var artifact_id: String = artifact_ids[i]
		if _is_artifact_pickup_collected(artifact_id, i):
			continue
		_create_restored_artifact_pickup(artifact_id, i, i)


func _create_item_pickup(item_id: int, persistent_index: int, layout_index: int) -> void:
	var pickup: ItemPickup = ITEM_PICKUP_SCENE.instantiate() as ItemPickup
	if pickup == null:
		push_error("Chest: failed to instantiate ItemPickup scene")
		return

	pickup.name = _build_item_pickup_name(item_id, persistent_index)
	pickup.item_id = item_id
	pickup.global_position = _get_item_pickup_position(layout_index)
	pickup.setup(item_id, _build_item_pickup_config())
	pickup.set_persistent_id(pickup.name)
	_add_spawned_pickup(pickup)


func _create_restored_item_pickup(item_id: int, persistent_index: int, layout_index: int) -> void:
	var pickup: ItemPickup = ITEM_PICKUP_SCENE.instantiate() as ItemPickup
	if pickup == null:
		push_error("Chest: failed to instantiate restored ItemPickup scene")
		return

	pickup.name = _build_item_pickup_name(item_id, persistent_index)
	pickup.item_id = item_id
	pickup.global_position = _get_item_pickup_position(layout_index)
	pickup.setup(item_id, _build_item_pickup_config())
	pickup.set_persistent_id(pickup.name)
	_add_restored_pickup(pickup)


func _create_artifact_pickup(artifact_id: String, persistent_index: int, layout_index: int) -> void:
	var pickup: ArtifactPickup = ARTIFACT_PICKUP_SCENE.instantiate() as ArtifactPickup
	if pickup == null:
		push_error("Chest: failed to instantiate ArtifactPickup scene")
		return

	pickup.name = _build_artifact_pickup_name(artifact_id, persistent_index)
	pickup.artifact_id = artifact_id
	pickup.global_position = _get_artifact_pickup_position(layout_index)
	pickup.setup(artifact_id, _build_artifact_pickup_config())
	pickup.set_persistent_id(pickup.name)
	_add_spawned_pickup(pickup)


func _create_restored_artifact_pickup(artifact_id: String, persistent_index: int, layout_index: int) -> void:
	var pickup: ArtifactPickup = ARTIFACT_PICKUP_SCENE.instantiate() as ArtifactPickup
	if pickup == null:
		push_error("Chest: failed to instantiate restored ArtifactPickup scene")
		return

	pickup.name = _build_artifact_pickup_name(artifact_id, persistent_index)
	pickup.artifact_id = artifact_id
	pickup.global_position = _get_artifact_pickup_position(layout_index)
	pickup.setup(artifact_id, _build_artifact_pickup_config())
	pickup.set_persistent_id(pickup.name)
	_add_restored_pickup(pickup)


func _get_item_pickup_position(index: int) -> Vector2:
	var columns: int = 4
	var column: int = index % columns
	var row: int = index / columns
	var center_offset: float = (columns - 1) * 0.5
	var offset_x: float = (column - center_offset) * item_spread
	var offset_y: float = -12.0 + row * 24.0
	return global_position + Vector2(offset_x, offset_y)


func _get_artifact_pickup_position(index: int) -> Vector2:
	var columns: int = 3
	var column: int = index % columns
	var row: int = index / columns
	var center_offset: float = (columns - 1) * 0.5
	var offset_x: float = (column - center_offset) * item_spread * 1.25
	var offset_y: float = -18.0 + row * 28.0
	return global_position + Vector2(offset_x, offset_y)


func _build_item_pickup_config() -> Dictionary:
	return {
		"display_scale": item_scale,
		"collision_radius": collision_radius,
		"hint_text": "[F] РџРѕРґРѕР±СЂР°С‚СЊ",
		"hint_offset": Vector2(-60, -30 * item_scale),
		"label_offset": Vector2(-90, -62 * item_scale),
		"label_visible": true,
	}


func _build_artifact_pickup_config() -> Dictionary:
	return {
		"display_scale": artifact_scale,
		"collision_radius": collision_radius,
		"hint_text": "[F] РџРѕРґРѕР±СЂР°С‚СЊ",
		"hint_offset": Vector2(-60, -35 * artifact_scale),
		"label_offset": Vector2(-90, -68 * artifact_scale),
		"label_visible": true,
	}


func _add_spawned_pickup(pickup: Node2D) -> void:
	if get_parent() == null:
		push_error("Chest: missing parent node for spawned pickup")
		pickup.queue_free()
		return

	get_parent().add_child(pickup)
	if pickup.has_method("start_floating_after"):
		pickup.start_floating_after(0.6)
	_animate_spawn(pickup)
	item_spawned.emit(pickup)


func _add_restored_pickup(pickup: Node2D) -> void:
	if get_parent() == null:
		push_error("Chest: missing parent node for restored pickup")
		pickup.queue_free()
		return

	get_parent().add_child(pickup)
	pickup.scale = Vector2.ONE
	pickup.modulate = Color.WHITE
	if pickup is CanvasItem:
		(pickup as CanvasItem).self_modulate = Color.WHITE

	var sprite_node: CanvasItem = pickup.get_node_or_null("Sprite2D") as CanvasItem
	if sprite_node:
		sprite_node.modulate = Color.WHITE
		sprite_node.self_modulate = Color.WHITE

	if pickup.has_method("start_floating_after"):
		pickup.start_floating_after(0.0)
	item_spawned.emit(pickup)


func _animate_spawn(pickup: Node2D) -> void:
	var start_y: float = pickup.global_position.y

	pickup.global_position.y -= 50.0
	pickup.scale = Vector2.ONE * 0.2
	pickup.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(pickup, "global_position:y", start_y, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(pickup, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(pickup, "modulate:a", 1.0, 0.2)


func _get_level_id() -> String:
	var current_scene: Node = get_tree().current_scene
	return current_scene.name if current_scene else "unknown_level"


func _build_item_pickup_name(item_id: int, index: int) -> String:
	return "%s_%s_ItemPickup_%d_%d" % [_get_level_id(), name, item_id, index]


func _build_legacy_item_pickup_name(item_id: int, index: int) -> String:
	return "ItemPickup_%d_%d" % [item_id, index]


func _build_artifact_pickup_name(artifact_id: String, index: int) -> String:
	return "%s_%s_ArtifactPickup_%s_%d" % [_get_level_id(), name, artifact_id, index]


func _build_legacy_artifact_pickup_name(artifact_id: String) -> String:
	return "ArtifactPickup_%s" % artifact_id


func _is_item_pickup_collected(item_id: int, index: int) -> bool:
	if not Global:
		return false

	return (
		Global.is_pickup_collected(_build_item_pickup_name(item_id, index))
		or Global.is_pickup_collected(_build_legacy_item_pickup_name(item_id, index))
	)


func _is_artifact_pickup_collected(artifact_id: String, index: int) -> bool:
	if not Global:
		return false

	return (
		Global.is_pickup_collected(_build_artifact_pickup_name(artifact_id, index))
		or Global.is_pickup_collected(_build_legacy_artifact_pickup_name(artifact_id))
	)


func _has_defined_contents() -> bool:
	match chest_type:
		ChestType.ITEMS:
			return not item_ids.is_empty() or not item_amounts.is_empty()
		ChestType.ARTIFACTS:
			return not artifact_ids.is_empty()
		ChestType.MIXED:
			return not item_ids.is_empty() or not artifact_ids.is_empty()
		ChestType.RANDOM:
			return true
		_:
			return false


func _mark_contents_configured() -> void:
	contents_configured = true
	restore_opened_chest()


func setup_items(ids: Array, amounts: Array = []) -> void:
	chest_type = ChestType.ITEMS
	item_ids.clear()
	item_amounts.clear()
	for i in range(ids.size()):
		item_ids.append(ids[i])
		item_amounts.append(amounts[i] if i < amounts.size() else 1)
	_mark_contents_configured()


func setup_artifacts(ids: Array) -> void:
	chest_type = ChestType.ARTIFACTS
	artifact_ids.clear()
	for id in ids:
		artifact_ids.append(id)
	_mark_contents_configured()


func setup_mixed(items: Array, items_amounts: Array, artifacts: Array) -> void:
	chest_type = ChestType.MIXED
	item_ids.clear()
	item_amounts.clear()
	for i in range(items.size()):
		item_ids.append(items[i])
		item_amounts.append(items_amounts[i] if i < items_amounts.size() else 1)
	artifact_ids.clear()
	for id in artifacts:
		artifact_ids.append(id)
	_mark_contents_configured()
