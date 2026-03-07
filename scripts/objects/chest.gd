extends Area2D
class_name Chest

# ===========================================
# CHEST v7.0 - Р СџР В Р С’Р вЂ™Р ВР вЂєР В¬Р СњР С›Р вЂў Р РЋР С›Р ТђР В Р С’Р СњР вЂўР СњР ВР вЂў Р РЋР С›Р РЋР СћР С›Р Р‡Р СњР ВР Р‡
# ===========================================
# Р вЂєР С•Р С–Р С‘Р С”Р В°:
# - Р вЂ”Р В°Р С”РЎР‚РЎвЂ№РЎвЂљРЎвЂ№Р в„– РЎРѓРЎС“Р Р…Р Т‘РЎС“Р С” РІвЂ вЂ™ Р С—РЎР‚Р С‘ Р Р†Р С•Р В·Р Р†РЎР‚Р В°РЎвЂљР Вµ РЎРѓРЎС“Р Р…Р Т‘РЎС“Р С” Р Р…Р В° Р СР ВµРЎРѓРЎвЂљР Вµ
# - Р С›РЎвЂљР С”РЎР‚РЎвЂ№РЎвЂљРЎвЂ№Р в„– РЎРѓРЎС“Р Р…Р Т‘РЎС“Р С” РІвЂ вЂ™ Р С—РЎР‚Р С‘ Р Р†Р С•Р В·Р Р†РЎР‚Р В°РЎвЂљР Вµ РЎРѓРЎС“Р Р…Р Т‘РЎС“Р С”Р В° Р СњР вЂўР Сћ,
#   Р Р…Р С• Р Р†РЎвЂ№Р С—Р В°Р Р†РЎв‚¬Р С‘Р Вµ Р Р…Р Вµ Р С—Р С•Р Т‘Р С•Р В±РЎР‚Р В°Р Р…Р Р…РЎвЂ№Р Вµ Р С—РЎР‚Р ВµР Т‘Р СР ВµРЎвЂљРЎвЂ№ Р В»Р ВµР В¶Р В°РЎвЂљ

signal opened
signal item_spawned(pickup_node: Node2D)

const ITEM_PICKUP_SCENE := preload("res://scenes/items/item_pickup.tscn")
const ARTIFACT_PICKUP_SCENE := preload("res://scenes/items/artifact_pickup.tscn")

enum ChestType { ITEMS, ARTIFACTS, MIXED, RANDOM }

@export var chest_type: ChestType = ChestType.ITEMS
@export var is_initially_open: bool = false

@export var item_ids: Array[int] = []
@export var item_amounts: Array[int] = []
@export var artifact_ids: Array[String] = []

@export var spawn_frame: int = 3

@export_group("Р В Р В°Р В·Р СР ВµРЎР‚РЎвЂ№ Р Р†РЎвЂ№Р С—Р В°Р Т‘Р В°РЎР‹РЎвЂ°Р С‘РЎвЂ¦ Р С—РЎР‚Р ВµР Т‘Р СР ВµРЎвЂљР С•Р Р†")
@export var item_scale: float = 1.5
@export var artifact_scale: float = 1.8
@export var collision_radius: float = 40.0
@export var item_spread: float = 35.0

var animated_sprite: AnimatedSprite2D = null
var interaction_zone: Area2D = null
var hint_label: Label = null

var is_open: bool = false
var player_in_range: bool = false
var is_opening: bool = false
var items_spawned: bool = false


func _ready():
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	interaction_zone = get_node_or_null("InteractionZone")
	hint_label = get_node_or_null("HintLabel")

	is_open = is_initially_open

	# === Р СџР В Р С›Р вЂ™Р вЂўР В Р Р‡Р вЂўР Сљ: Р вЂР В«Р вЂє Р вЂєР В Р РЋР Р€Р СњР вЂќР Р€Р С™ Р Р€Р вЂ“Р вЂў Р С›Р СћР С™Р В Р В«Р Сћ? ===
	if Global and Global.is_chest_opened(name):
		print("СЂСџвЂњВ¦ '%s' Р В±РЎвЂ№Р В» Р С•РЎвЂљР С”РЎР‚РЎвЂ№РЎвЂљ РЎР‚Р В°Р Р…Р ВµР Вµ РІвЂ вЂ™ Р Р†Р С•РЎРѓРЎРѓРЎвЂљР В°Р Р…Р В°Р Р†Р В»Р С‘Р Р†Р В°Р ВµР С Р С—РЎР‚Р ВµР Т‘Р СР ВµРЎвЂљРЎвЂ№, РЎС“Р Т‘Р В°Р В»РЎРЏР ВµР С РЎРѓРЎС“Р Р…Р Т‘РЎС“Р С”" % name)
		# Р РЋРЎС“Р Р…Р Т‘РЎС“Р С” Р В±РЎвЂ№Р В» Р С•РЎвЂљР С”РЎР‚РЎвЂ№РЎвЂљ - Р Р†Р С•РЎРѓРЎРѓРЎвЂљР В°Р Р…Р В°Р Р†Р В»Р С‘Р Р†Р В°Р ВµР С Р Р…Р Вµ Р С—Р С•Р Т‘Р С•Р В±РЎР‚Р В°Р Р…Р Р…РЎвЂ№Р Вµ Р С—РЎР‚Р ВµР Т‘Р СР ВµРЎвЂљРЎвЂ№ Р С‘ РЎС“Р Т‘Р В°Р В»РЎРЏР ВµР С РЎРѓРЎС“Р Р…Р Т‘РЎС“Р С”
		call_deferred("_restore_items_and_delete")
		return

	# Р РЋРЎС“Р Р…Р Т‘РЎС“Р С” Р СњР вЂў Р В±РЎвЂ№Р В» Р С•РЎвЂљР С”РЎР‚РЎвЂ№РЎвЂљ - РЎР‚Р В°Р В±Р С•РЎвЂљР В°Р ВµР С Р С”Р В°Р С” Р С•Р В±РЎвЂ№РЎвЂЎР Р…Р С•
	_setup_signals()
	_update_visual()
	_setup_hint()

	print("СЂСџвЂњВ¦ Р РЋРЎС“Р Р…Р Т‘РЎС“Р С” '%s': Р В·Р В°Р С”РЎР‚РЎвЂ№РЎвЂљ, Р В¶Р Т‘РЎвЂРЎвЂљ Р С•РЎвЂљР С”РЎР‚РЎвЂ№РЎвЂљР С‘РЎРЏ" % name)


func _setup_signals():
	"""Р СњР В°РЎРѓРЎвЂљРЎР‚Р В°Р С‘Р Р†Р В°Р ВµРЎвЂљ РЎРѓР С‘Р С–Р Р…Р В°Р В»РЎвЂ№ Р Т‘Р В»РЎРЏ Р Р†Р В·Р В°Р С‘Р СР С•Р Т‘Р ВµР в„–РЎРѓРЎвЂљР Р†Р С‘РЎРЏ"""
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


func _setup_hint():
	if hint_label:
		hint_label.visible = false
		hint_label.text = "[F] Р С›РЎвЂљР С”РЎР‚РЎвЂ№РЎвЂљРЎРЉ"


func _update_visual():
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


# ===========================================
# Р вЂ™Р вЂ”Р С’Р ВР СљР С›Р вЂќР вЂўР в„ўР РЋР СћР вЂ™Р ВР вЂў Р РЋ Р ВР вЂњР В Р С›Р С™Р С›Р Сљ
# ===========================================

func _on_body_entered(body: Node2D):
	if is_open or is_opening:
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


func _process(_delta):
	if is_open or is_opening or not player_in_range:
		return

	if Input.is_action_just_pressed("interact"):
		open_chest()


func open_chest():
	if is_open or is_opening:
		return

	is_opening = true

	# Р В Р ВµР С–Р С‘РЎРѓРЎвЂљРЎР‚Р С‘РЎР‚РЎС“Р ВµР С РЎвЂЎРЎвЂљР С• РЎРѓРЎС“Р Р…Р Т‘РЎС“Р С” Р С›Р СћР С™Р В Р В«Р Сћ
	if Global:
		Global.register_opened_chest(name)

	if hint_label:
		hint_label.visible = false

	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation("opening"):
			print("СЂСџвЂњВ¦ '%s' - Р В°Р Р…Р С‘Р СР В°РЎвЂ Р С‘РЎРЏ opening" % name)
			animated_sprite.play("opening")
		else:
			_spawn_contents()
			_finish_opening()
	else:
		_spawn_contents()
		_finish_opening()


func _on_frame_changed():
	if not is_opening or items_spawned:
		return

	if animated_sprite.animation == "opening":
		var current_frame = animated_sprite.frame

		if current_frame == spawn_frame:
			print("СЂСџвЂњВ¦ '%s' - Р РЋР СџР С’Р вЂ™Р Сњ Р Р…Р В° Р С”Р В°Р Т‘РЎР‚Р Вµ %d!" % [name, spawn_frame])
			_spawn_contents()
			items_spawned = true


func _on_animation_finished():
	if is_opening and animated_sprite.animation == "opening":
		_finish_opening()


func _finish_opening():
	is_open = true
	is_opening = false
	opened.emit()
	print("СЂСџвЂњВ¦ '%s' Р С•РЎвЂљР С”РЎР‚РЎвЂ№РЎвЂљ!" % name)

	# Р СџР В»Р В°Р Р†Р Р…Р С• РЎС“Р Т‘Р В°Р В»РЎРЏР ВµР С РЎРѓРЎС“Р Р…Р Т‘РЎС“Р С”
	var tween = create_tween()
	tween.tween_interval(0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


# ===========================================
# Р РЋР СџР С’Р вЂ™Р Сњ Р РЋР С›Р вЂќР вЂўР В Р вЂ“Р ВР СљР С›Р вЂњР С›
# ===========================================

func _spawn_contents():
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


func _spawn_items():
	for i in range(item_ids.size()):
		var item_id = item_ids[i]
		var amount = item_amounts[i] if i < item_amounts.size() else 1

		for j in range(amount):
			_create_item_pickup(item_id, i * 10 + j)


func _spawn_artifacts():
	for i in range(artifact_ids.size()):
		_create_artifact_pickup(artifact_ids[i], i)


func _spawn_random():
	_create_item_pickup(1, 0)
	_create_item_pickup(2, 1)


# ===========================================
# Р вЂ™Р С›Р РЋР РЋР СћР С’Р СњР С›Р вЂ™Р вЂєР вЂўР СњР ВР вЂў Р СџР В Р В Р вЂ™Р С›Р вЂ”Р вЂ™Р В Р С’Р СћР вЂў Р СњР С’ Р Р€Р В Р С›Р вЂ™Р вЂўР СњР В¬
# ===========================================

func _restore_items_and_delete():
	"""Р вЂ™Р С•РЎРѓРЎРѓРЎвЂљР В°Р Р…Р В°Р Р†Р В»Р С‘Р Р†Р В°Р ВµРЎвЂљ Р СњР вЂў Р С—Р С•Р Т‘Р С•Р В±РЎР‚Р В°Р Р…Р Р…РЎвЂ№Р Вµ Р С—РЎР‚Р ВµР Т‘Р СР ВµРЎвЂљРЎвЂ№ Р С‘ РЎС“Р Т‘Р В°Р В»РЎРЏР ВµРЎвЂљ РЎРѓРЎС“Р Р…Р Т‘РЎС“Р С”"""
	await get_tree().process_frame

	# Р РЋР С—Р В°Р Р†Р Р…Р С‘Р С РЎвЂљР С•Р В»РЎРЉР С”Р С• Р СњР вЂў Р С—Р С•Р Т‘Р С•Р В±РЎР‚Р В°Р Р…Р Р…РЎвЂ№Р Вµ Р С—РЎР‚Р ВµР Т‘Р СР ВµРЎвЂљРЎвЂ№
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

	# Р РЋРЎР‚Р В°Р В·РЎС“ РЎС“Р Т‘Р В°Р В»РЎРЏР ВµР С РЎРѓРЎС“Р Р…Р Т‘РЎС“Р С”
	queue_free()


func _restore_items():
	"""Р РЋР С—Р В°Р Р†Р Р…Р С‘РЎвЂљ РЎвЂљР С•Р В»РЎРЉР С”Р С• Р СњР вЂў Р С—Р С•Р Т‘Р С•Р В±РЎР‚Р В°Р Р…Р Р…РЎвЂ№Р Вµ Р С—РЎР‚Р ВµР Т‘Р СР ВµРЎвЂљРЎвЂ№"""
	var restored_count = 0

	for i in range(item_ids.size()):
		var item_id = item_ids[i]
		var amount = item_amounts[i] if i < item_amounts.size() else 1

		for j in range(amount):
			var pickup_name = "ItemPickup_%d_%d" % [item_id, i * 10 + j]

			# Р СџРЎР‚Р С•Р Р†Р ВµРЎР‚РЎРЏР ВµР С - Р В±РЎвЂ№Р В» Р В»Р С‘ Р С—Р С•Р Т‘Р С•Р В±РЎР‚Р В°Р Р…
			if Global and Global.is_pickup_collected(pickup_name):
				continue  # Р СџРЎР‚Р С•Р С—РЎС“РЎРѓР С”Р В°Р ВµР С

			_create_item_pickup(item_id, i * 10 + j)
			restored_count += 1

	if restored_count > 0:
		print("   СЂСџвЂњВ¦ Р вЂ™Р С•РЎРѓРЎРѓРЎвЂљР В°Р Р…Р С•Р Р†Р В»Р ВµР Р…Р С• Р С—РЎР‚Р ВµР Т‘Р СР ВµРЎвЂљР С•Р Р†: %d" % restored_count)


func _restore_artifacts():
	"""Р РЋР С—Р В°Р Р†Р Р…Р С‘РЎвЂљ РЎвЂљР С•Р В»РЎРЉР С”Р С• Р СњР вЂў Р С—Р С•Р Т‘Р С•Р В±РЎР‚Р В°Р Р…Р Р…РЎвЂ№Р Вµ Р В°РЎР‚РЎвЂљР ВµРЎвЂћР В°Р С”РЎвЂљРЎвЂ№"""
	var restored_count = 0

	for i in range(artifact_ids.size()):
		var artifact_id = artifact_ids[i]
		var pickup_name = "ArtifactPickup_%s" % artifact_id

		# Р СџРЎР‚Р С•Р Р†Р ВµРЎР‚РЎРЏР ВµР С - Р В±РЎвЂ№Р В» Р В»Р С‘ Р С—Р С•Р Т‘Р С•Р В±РЎР‚Р В°Р Р…
		if Global and Global.is_pickup_collected(pickup_name):
			continue  # Р СџРЎР‚Р С•Р С—РЎС“РЎРѓР С”Р В°Р ВµР С

		_create_artifact_pickup(artifact_id, i)
		restored_count += 1

	if restored_count > 0:
		print("   СЂСџвЂњВ¦ Р вЂ™Р С•РЎРѓРЎРѓРЎвЂљР В°Р Р…Р С•Р Р†Р В»Р ВµР Р…Р С• Р В°РЎР‚РЎвЂљР ВµРЎвЂћР В°Р С”РЎвЂљР С•Р Р†: %d" % restored_count)


# ===========================================
# Р РЋР С›Р вЂ”Р вЂќР С’Р СњР ВР вЂў PICKUP
# ===========================================

func _create_item_pickup(item_id: int, index: int):
	"""Create an item pickup from the reusable scene."""
	var pickup = ITEM_PICKUP_SCENE.instantiate() as ItemPickup
	if pickup == null:
		push_error("Chest: failed to instantiate item pickup scene")
		return

	pickup.name = "ItemPickup_%d_%d" % [item_id, index]
	pickup.item_id = item_id
	pickup.global_position = _get_item_pickup_position(index)
	pickup.setup(item_id, _build_item_pickup_config())
	_add_spawned_pickup(pickup)

	print("   spawned item ID=%d" % item_id)


func _create_artifact_pickup(artifact_id: String, index: int):
	"""Create an artifact pickup from the reusable scene."""
	var pickup = ARTIFACT_PICKUP_SCENE.instantiate() as ArtifactPickup
	if pickup == null:
		push_error("Chest: failed to instantiate artifact pickup scene")
		return

	pickup.name = "ArtifactPickup_%s" % artifact_id
	pickup.artifact_id = artifact_id
	pickup.global_position = _get_artifact_pickup_position(index)
	pickup.setup(artifact_id, _build_artifact_pickup_config())
	_add_spawned_pickup(pickup)

	print("   spawned artifact %s" % artifact_id)


func _get_item_pickup_position(index: int) -> Vector2:
	var offset_x = (index % 5 - 2) * item_spread
	return global_position + Vector2(offset_x, -10)


func _get_artifact_pickup_position(index: int) -> Vector2:
	var offset_x = (index - artifact_ids.size() / 2.0) * item_spread * 1.2
	return global_position + Vector2(offset_x, -10)


func _build_item_pickup_config() -> Dictionary:
	return {
		"display_scale": item_scale,
		"collision_radius": collision_radius,
		"hint_offset": Vector2(-50, -30 * item_scale),
	}


func _build_artifact_pickup_config() -> Dictionary:
	return {
		"display_scale": artifact_scale,
		"collision_radius": collision_radius,
		"hint_offset": Vector2(-50, -35 * artifact_scale),
	}


func _add_spawned_pickup(pickup: Node2D):
	if get_parent() == null:
		push_error("Chest: parent is missing, cannot spawn pickup")
		pickup.queue_free()
		return

	get_parent().add_child(pickup)
	if pickup.has_method("start_floating_after"):
		pickup.start_floating_after(0.6)
	_animate_spawn(pickup)
	item_spawned.emit(pickup)


func _animate_spawn(pickup: Node2D):
	"""Spawn animation."""
	var start_y = pickup.global_position.y
	var random_offset_x = randf_range(-20, 20)

	pickup.global_position.y -= 50
	pickup.global_position.x += random_offset_x
	pickup.scale = Vector2(0.2, 0.2)
	pickup.modulate.a = 0.0

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(pickup, "global_position:y", start_y + 5, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(pickup, "scale", Vector2(1, 1), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(pickup, "modulate:a", 1.0, 0.25)


func setup_items(ids: Array, amounts: Array = []):
	chest_type = ChestType.ITEMS
	item_ids.clear()
	item_amounts.clear()
	for i in range(ids.size()):
		item_ids.append(ids[i])
		item_amounts.append(amounts[i] if i < amounts.size() else 1)


func setup_artifacts(ids: Array):
	chest_type = ChestType.ARTIFACTS
	artifact_ids.clear()
	for id in ids:
		artifact_ids.append(id)


func setup_mixed(items: Array, items_amounts: Array, artifacts: Array):
	chest_type = ChestType.MIXED
	setup_items(items, items_amounts)
	artifact_ids.clear()
	for id in artifacts:
		artifact_ids.append(id)
