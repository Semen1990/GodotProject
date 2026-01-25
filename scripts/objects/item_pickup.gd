extends Area2D
class_name ItemPickup

# ===========================================
# ПОДБИРАЕМЫЙ ПРЕДМЕТ v7
# ===========================================
# Путь: res://scripts/objects/item_pickup.gd

@export var item_id: int = 1
@export var item_count: int = 1
@export var float_height: float = 8.0
@export var float_speed: float = 2.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var label: Label = $Label

var hint_label: Label = null
var initial_y: float
var time: float = 0.0
var is_collected: bool = false
var player_in_range: bool = false


func _ready():
	print("📦 ItemPickup создан: ID=%d x%d pos=%s" % [item_id, item_count, position])
	
	initial_y = position.y
	
	call_deferred("_load_item_data")
	_ensure_hint_label()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _ensure_hint_label():
	hint_label = get_node_or_null("HintLabel")
	
	if not hint_label:
		hint_label = Label.new()
		hint_label.name = "HintLabel"
		hint_label.text = "Нажми F"
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_label.position = Vector2(-35, -65)
		hint_label.add_theme_font_size_override("font_size", 14)
		hint_label.add_theme_color_override("font_color", Color(1, 1, 0.7))
		add_child(hint_label)
	
	hint_label.visible = false


func _load_item_data():
	if not Inventory or not Inventory.item_database:
		print("   ⚠️ База данных недоступна")
		_set_fallback_visuals()
		return
	
	var item_data = Inventory.item_database.get_item_by_id(item_id)
	
	if not item_data:
		print("   ⚠️ Предмет ID=%d не найден в базе" % item_id)
		_set_fallback_visuals()
		return
	
	if sprite and item_data.icon:
		sprite.texture = item_data.icon
	else:
		_create_colored_sprite(item_data)
	
	if label:
		var text = item_data.display_name
		if item_count > 1:
			text += " x%d" % item_count
		label.text = text
		label.modulate = InventoryEnums.get_rarity_color(item_data.rarity)
	
	print("   ✅ Загружен: %s" % item_data.display_name)


func _create_colored_sprite(item_data):
	if not sprite:
		return
	var color = Color.GRAY
	if item_data:
		color = InventoryEnums.get_rarity_color(item_data.rarity)
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(color)
	sprite.texture = ImageTexture.create_from_image(image)


func _set_fallback_visuals():
	if sprite:
		var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		image.fill(Color.GRAY)
		sprite.texture = ImageTexture.create_from_image(image)
	if label:
		label.text = "ID: %d" % item_id


func _process(delta):
	# Парение
	if not is_collected:
		time += delta * float_speed
		position.y = initial_y + sin(time) * float_height
	
	# Подбор по F
	if player_in_range and not is_collected:
		if Input.is_action_just_pressed("interact"):
			_collect_item()


func _on_body_entered(body: Node2D):
	if is_collected:
		return
	if not _is_player(body):
		return
	
	player_in_range = true
	if hint_label:
		hint_label.visible = true
	print("📦 Игрок рядом с предметом ID=%d" % item_id)


func _on_body_exited(body: Node2D):
	if not _is_player(body):
		return
	
	player_in_range = false
	if hint_label:
		hint_label.visible = false


func _is_player(body: Node2D) -> bool:
	return body.is_in_group("player") or body.has_method("take_damage")


func _collect_item():
	if is_collected:
		return
	
	if not Inventory:
		print("❌ Инвентарь недоступен!")
		return
	
	var remaining = Inventory.add_item_by_id(item_id, item_count)
	
	if remaining > 0:
		print("⚠️ Инвентарь полон!")
		return
	
	print("✅ Подобран: ID=%d x%d" % [item_id, item_count])
	_play_collect_effect()


func _play_collect_effect():
	is_collected = true
	
	if hint_label:
		hint_label.visible = false
	
	if collision:
		collision.set_deferred("disabled", true)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	if sprite:
		tween.tween_property(sprite, "scale", sprite.scale * 1.5, 0.25)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
	
	if label:
		tween.tween_property(label, "modulate:a", 0.0, 0.25)
	
	tween.chain().tween_callback(queue_free)
