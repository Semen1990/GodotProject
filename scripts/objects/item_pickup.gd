extends Area2D
class_name ItemPickup

signal collected(item_id: int)

@export var item_id: int = 1
@export var float_height: float = 3.0
@export var float_speed: float = 2.0

const PERSISTENCE_COMPONENT := preload("res://scripts/persistence/persistence_component.gd")
const ITEM_FALLBACK_DATA := {
	1: {
		"name": "Малое зелье здоровья",
		"texture": "res://assets/items/potions/Small Health Potion.png",
	},
	2: {
		"name": "Малое зелье маны",
		"texture": "res://assets/items/potions/Small Mana Potion.png",
	},
	3: {
		"name": "Малое зелье каменной кожи",
		"texture": "res://assets/items/potions/Small Stone Skin Potion.png",
	},
	4: {
		"name": "Зелье ярости",
		"texture": "res://assets/items/potions/Potion of Rage.png",
	},
	101: {
		"name": "Железный меч",
		"texture": "res://assets/items/weapons/Iron Sword.png",
	},
	102: {
		"name": "Стальной шлем",
		"texture": "res://assets/items/armor/Steel Helmet.png",
	},
	103: {
		"name": "Кожаный доспех",
		"texture": "res://assets/items/armor/Leather Armor.png",
	},
	104: {
		"name": "Деревянный щит",
		"texture": "res://assets/items/shields/Wooden Shield.png",
	},
	105: {
		"name": "Боевые перчатки",
		"texture": "res://assets/items/armor/Combat Gloves.png",
	},
}

var sprite: Sprite2D = null
var name_label: Label = null
var hint_label: Label = null
var collision: CollisionShape2D = null
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
	collision = get_node_or_null("CollisionShape2D")
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


func setup(id: int, config: Dictionary = {}) -> void:
	item_id = id
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
		"collected": is_collected,
		"item_id": item_id,
		"consumed": is_collected,
	}


func apply_persistent_state(state: Dictionary) -> void:
	if state.has("item_id"):
		item_id = int(state["item_id"])
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
			"collected": true,
			"item_id": item_id,
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


func _get_item_data() -> GameItemData:
	if Inventory and Inventory.item_database:
		return Inventory.item_database.get_item_by_id(item_id)
	return null


func _load_texture() -> void:
	if not sprite:
		return

	var item_data: GameItemData = _get_item_data()
	if item_data and item_data.icon:
		sprite.texture = item_data.icon
		return

	var fallback: Dictionary = ITEM_FALLBACK_DATA.get(item_id, {})
	var path: String = String(fallback.get("texture", ""))
	if not path.is_empty() and ResourceLoader.exists(path):
		sprite.texture = load(path)


func _apply_config(config: Dictionary) -> void:
	if config.is_empty():
		return

	if sprite and config.has("display_scale"):
		var display_scale: float = float(config["display_scale"])
		sprite.scale = Vector2.ONE * display_scale

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


func _get_display_name() -> String:
	var item_data: GameItemData = _get_item_data()
	if item_data and not item_data.display_name.is_empty():
		return item_data.display_name

	var fallback: Dictionary = ITEM_FALLBACK_DATA.get(item_id, {})
	if fallback.has("name"):
		return str(fallback["name"])

	return "Предмет %d" % item_id


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

	if not Inventory:
		push_warning("ItemPickup: не найден автозагрузочный Inventory")
		is_collected = false
		return

	var remaining: int = Inventory.add_item_by_id(item_id, 1)
	if remaining > 0:
		is_collected = false
		return

	if persistence:
		persistence.mark_consumed({
			"collected": true,
			"item_id": item_id,
		})

	if Global:
		Global.register_collected_pickup(name)
		if Global.has_method("remove_dropped_pickup"):
			Global.remove_dropped_pickup(name)
		if Global.has_method("add_item_collected"):
			Global.add_item_collected()

	collected.emit(item_id)
	_play_collect_effect()


func _play_collect_effect() -> void:
	if hint_label:
		hint_label.visible = false

	set_deferred("monitoring", false)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	if sprite:
		tween.tween_property(sprite, "scale", sprite.scale * 1.3, 0.15)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.15)
		tween.tween_property(sprite, "position:y", sprite.position.y - 20.0, 0.15)
	else:
		tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)
