extends Area2D
class_name ItemPickup

signal collected(item_id: int)

@export var item_id: int = 1
@export var float_height: float = 3.0
@export var float_speed: float = 2.0

var sprite: Sprite2D = null
var name_label: Label = null
var hint_label: Label = null
var collision: CollisionShape2D = null

var initial_y: float = 0.0
var time: float = 0.0
var player_in_range: bool = false
var is_collected: bool = false
var float_enabled: bool = true
var pending_config: Dictionary = {}

const ITEM_TEXTURES := {
	1: "res://assets/items/potions/Small Health Potion.png",
	2: "res://assets/items/potions/Small Mana Potion.png",
	3: "res://assets/items/potions/Small Stone Skin Potion.png",
	4: "res://assets/items/potions/Potion of Rage.png",
	101: "res://assets/items/weapons/Iron Sword.png",
	102: "res://assets/items/shields/Wooden Shield.png",
	103: "res://assets/items/armor/Steel Helmet.png",
	104: "res://assets/items/armor/Leather Armor.png",
	105: "res://assets/items/armor/Combat Gloves.png",
}

const ITEM_NAMES := {
	1: "Small Health Potion",
	2: "Small Mana Potion",
	3: "Small Stone Skin Potion",
	4: "Potion of Rage",
	101: "Iron Sword",
	102: "Wooden Shield",
	103: "Steel Helmet",
	104: "Leather Armor",
	105: "Combat Gloves",
}


func _ready():
	sprite = get_node_or_null("Sprite2D")
	name_label = get_node_or_null("Label")
	hint_label = get_node_or_null("HintLabel")
	collision = get_node_or_null("CollisionShape2D")
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
	print("ItemPickup '%s': ID=%d" % [name, item_id])


func setup(id: int, config: Dictionary = {}):
	item_id = id
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
	var path = ITEM_TEXTURES.get(item_id, "")
	if sprite and path != "" and ResourceLoader.exists(path):
		sprite.texture = load(path)


func _apply_config(config: Dictionary):
	if config.is_empty():
		return

	if sprite and config.has("display_scale"):
		var display_scale = float(config["display_scale"])
		sprite.scale = Vector2.ONE * display_scale

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
	if Inventory and Inventory.item_database:
		var item_data = Inventory.item_database.get_item_by_id(item_id)
		if item_data and item_data.display_name != "":
			return item_data.display_name
	return ITEM_NAMES.get(item_id, "Item %d" % item_id)


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

	if not Inventory:
		push_warning("ItemPickup: Inventory autoload is missing")
		is_collected = false
		return

	var remaining = Inventory.add_item_by_id(item_id, 1)
	if remaining > 0:
		print("Inventory is full")
		is_collected = false
		return

	if Global:
		Global.register_collected_pickup(name)
		if Global.has_method("remove_dropped_pickup"):
			Global.remove_dropped_pickup(name)
		if Global.has_method("add_item_collected"):
			Global.add_item_collected()

	print("Collected item ID=%d" % item_id)
	collected.emit(item_id)
	_play_collect_effect()


func _play_collect_effect():
	if hint_label:
		hint_label.visible = false

	set_deferred("monitoring", false)

	var tween = create_tween()
	tween.set_parallel(true)
	if sprite:
		tween.tween_property(sprite, "scale", sprite.scale * 1.3, 0.15)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.15)
		tween.tween_property(sprite, "position:y", sprite.position.y - 20, 0.15)
	else:
		tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)
