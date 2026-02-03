extends Area2D
class_name ArtifactPickup

# ===========================================
# ARTIFACT PICKUP v1.0 - ПОДБОР АРТЕФАКТОВ
# ===========================================
# Артефакт лежит на земле, подбирается по F
# Добавляется В ИНВЕНТАРЬ (не активируется!)
# Работает только когда экипирован в слот артефакта

signal collected(artifact_id: String)

@export var artifact_id: String = "hermes_wings"
@export var float_height: float = 4.0
@export var float_speed: float = 2.5

# ID предметов артефактов в базе данных
const ARTIFACT_ITEM_IDS = {
	"hermes_wings": 201,
	"phoenix_feather": 202,
}

var sprite: Sprite2D = null
var hint_label: Label = null

var initial_y: float = 0.0
var time: float = 0.0
var player_in_range: bool = false
var is_collected: bool = false


func _ready():
	sprite = get_node_or_null("Sprite2D")
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
	
	if sprite and not sprite.texture:
		_load_texture()
	
	print("✨ ArtifactPickup '%s': %s" % [name, artifact_id])


func _load_texture():
	var path = "res://assets/items/artifacts/%s.png" % artifact_id
	if ResourceLoader.exists(path):
		sprite.texture = load(path)


func setup(id: String):
	artifact_id = id
	if sprite:
		_load_texture()


func _process(delta):
	if is_collected:
		return
	
	time += delta * float_speed
	position.y = initial_y + sin(time) * float_height
	
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
	
	if Global:
		Global.register_collected_pickup(name)
	
	# Добавляем артефакт В ИНВЕНТАРЬ как предмет
	var item_id = ARTIFACT_ITEM_IDS.get(artifact_id, 0)
	if item_id > 0 and Inventory:
		var remaining = Inventory.add_item_by_id(item_id, 1)
		if remaining > 0:
			print("⚠️ Инвентарь полон!")
			is_collected = false
			return
		print("✨ Артефакт '%s' добавлен в инвентарь (ID=%d)" % [artifact_id, item_id])
	else:
		# Fallback: регистрируем в Global но НЕ активируем
		print("✨ Артефакт '%s' подобран (нужно экипировать!)" % artifact_id)
	
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
	
	# Эффект звёздочек
	_spawn_particles()
	
	tween.chain().tween_callback(queue_free)


func _spawn_particles():
	for i in range(5):
		var particle = Label.new()
		particle.text = "✨"
		particle.add_theme_font_size_override("font_size", 16)
		particle.position = Vector2(randf_range(-20, 20), randf_range(-20, 0))
		add_child(particle)
		
		var tween = create_tween()
		tween.tween_property(particle, "position:y", particle.position.y - 30, 0.5)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_callback(particle.queue_free)
