extends Area2D
class_name ItemPickup

# ===========================================
# ITEM PICKUP v1.0 - ПОДБОР ПРЕДМЕТОВ С ЗЕМЛИ
# ===========================================
# Предмет лежит на земле, подбирается по F
# После подбора добавляется в инвентарь

signal collected(item_id: int)

@export var item_id: int = 1
@export var float_height: float = 3.0
@export var float_speed: float = 2.0

var sprite: Sprite2D = null
var hint_label: Label = null
var collision: CollisionShape2D = null

var initial_y: float = 0.0
var time: float = 0.0
var player_in_range: bool = false
var is_collected: bool = false


func _ready():
	sprite = get_node_or_null("Sprite2D")
	hint_label = get_node_or_null("HintLabel")
	collision = get_node_or_null("CollisionShape2D")
	
	initial_y = position.y
	
	# Проверяем: уже подобран?
	if Global and Global.is_pickup_collected(name):
		queue_free()
		return
	
	# Подключаем сигналы
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	
	if hint_label:
		hint_label.visible = false
	
	# Устанавливаем текстуру если не установлена
	if sprite and not sprite.texture:
		_load_texture()
	
	print("📦 ItemPickup '%s': ID=%d" % [name, item_id])


func _load_texture():
	var paths = {
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
	
	var path = paths.get(item_id, "")
	if path != "" and ResourceLoader.exists(path):
		sprite.texture = load(path)


func setup(id: int):
	"""Настраивает pickup"""
	item_id = id
	if sprite:
		_load_texture()


func _process(delta):
	if is_collected:
		return
	
	# Парение
	time += delta * float_speed
	position.y = initial_y + sin(time) * float_height
	
	# Подбор по F
	if player_in_range:
		if Input.is_action_just_pressed("interact"):
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
	
	# Регистрируем
	if Global:
		Global.register_collected_pickup(name)
	
	# Добавляем в инвентарь
	if Inventory:
		var remaining = Inventory.add_item_by_id(item_id, 1)
		if remaining > 0:
			print("⚠️ Инвентарь полон!")
			is_collected = false
			return
	
	print("📦 Подобран предмет ID=%d" % item_id)
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
