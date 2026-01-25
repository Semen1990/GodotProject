extends Area2D

# ===========================================
# ARTIFACT PICKUP v7
# ===========================================
# Путь: res://scripts/objects/artifact_pickup.gd

@export var artifact_id: String = "hermes_wings"
@export var float_height: float = 10.0
@export var float_speed: float = 2.0

const ARTIFACT_ID_MAP = {
	"hermes_wings": 201,
	"phoenix_feather": 202,
	"vampire_ring": 203,
	"berserker_amulet": 204,
}

var initial_y: float
var time: float = 0.0
var is_collected: bool = false
var player_in_range: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var label: Label = $Label
var hint_label: Label = null


func _ready():
	print("🎁 ArtifactPickup создан: %s pos=%s" % [artifact_id, position])
	
	initial_y = position.y
	
	await get_tree().process_frame
	
	if _check_already_collected():
		print("   ⚠️ Артефакт уже в инвентаре!")
		queue_free()
		return
	
	_setup_artifact_from_inventory()
	_create_hint_label()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _create_hint_label():
	hint_label = get_node_or_null("HintLabel")
	
	if not hint_label:
		hint_label = Label.new()
		hint_label.name = "HintLabel"
		hint_label.text = "Нажми F"
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_label.position = Vector2(-35, -70)
		hint_label.add_theme_font_size_override("font_size", 14)
		hint_label.add_theme_color_override("font_color", Color(1, 1, 0.7))
		add_child(hint_label)
	
	hint_label.visible = false


func _check_already_collected() -> bool:
	if not Inventory or not Inventory.item_database:
		return false
	
	var inv_id = ARTIFACT_ID_MAP.get(artifact_id, -1)
	if inv_id < 0:
		return false
	
	if Inventory.has_item(inv_id):
		return true
	
	for slot in [
		InventoryEnums.EquipSlot.ARTIFACT_1,
		InventoryEnums.EquipSlot.ARTIFACT_2,
		InventoryEnums.EquipSlot.ARTIFACT_3,
		InventoryEnums.EquipSlot.ARTIFACT_4,
	]:
		var equipped = Inventory.get_equipped_item(slot)
		if equipped and equipped.get_item_id() == inv_id:
			return true
	
	return false


func _setup_artifact_from_inventory():
	if not Inventory or not Inventory.item_database:
		_set_fallback_visuals()
		return
	
	var inv_id = ARTIFACT_ID_MAP.get(artifact_id, -1)
	if inv_id < 0:
		_set_fallback_visuals()
		return
	
	var item_data = Inventory.item_database.get_item_by_id(inv_id)
	if not item_data:
		_set_fallback_visuals()
		return
	
	if item_data.icon and sprite:
		sprite.texture = item_data.icon
	else:
		_create_color_sprite(item_data.rarity)
	
	if label:
		label.text = item_data.display_name
		label.modulate = InventoryEnums.get_rarity_color(item_data.rarity)
	
	print("   ✅ Загружен: %s" % item_data.display_name)


func _create_color_sprite(rarity):
	if not sprite:
		return
	var color = InventoryEnums.get_rarity_color(rarity)
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(color)
	sprite.texture = ImageTexture.create_from_image(image)


func _set_fallback_visuals():
	if sprite:
		var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		image.fill(Color.PURPLE)
		sprite.texture = ImageTexture.create_from_image(image)
	if label:
		label.text = artifact_id.replace("_", " ").capitalize()


func _process(delta):
	if not is_collected:
		time += delta * float_speed
		position.y = initial_y + sin(time) * float_height
	
	if player_in_range and not is_collected:
		if Input.is_action_just_pressed("interact"):
			_collect_artifact()


func _on_body_entered(body):
	if is_collected:
		return
	if not (body.is_in_group("player") or body.has_method("take_damage")):
		return
	
	player_in_range = true
	if hint_label:
		hint_label.visible = true
	print("🎁 Игрок рядом с артефактом: %s" % artifact_id)


func _on_body_exited(body):
	if not (body.is_in_group("player") or body.has_method("take_damage")):
		return
	
	player_in_range = false
	if hint_label:
		hint_label.visible = false


func _collect_artifact():
	if is_collected:
		return
	
	var success = _add_to_inventory()
	
	if success:
		print("✅ Артефакт в инвентаре: %s" % artifact_id)
	else:
		if Global and Global.has_method("collect_artifact"):
			Global.collect_artifact(artifact_id)
	
	_play_collect_effect()


func _add_to_inventory() -> bool:
	if not Inventory:
		return false
	
	var inv_id = ARTIFACT_ID_MAP.get(artifact_id, -1)
	if inv_id < 0:
		return false
	
	if _check_already_collected():
		return false
	
	var remaining = Inventory.add_item_by_id(inv_id, 1)
	return remaining == 0


func _play_collect_effect():
	is_collected = true
	
	if hint_label:
		hint_label.visible = false
	
	if collision:
		collision.set_deferred("disabled", true)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	if sprite:
		tween.tween_property(sprite, "scale", sprite.scale * 1.5, 0.3)
		tween.tween_property(sprite, "modulate:a", 0, 0.3)
	
	if label:
		tween.tween_property(label, "modulate:a", 0, 0.3)
	
	tween.chain().tween_callback(queue_free)
