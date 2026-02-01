extends Area2D
class_name Chest

# ===========================================
# CHEST - СУНДУК (ПРЕФАБ)
# ===========================================
# Путь: res://scripts/objects/Chest.gd

signal opened
signal item_given(item_id: int, amount: int)
signal artifact_given(artifact_id: String)

enum ChestType { ITEMS, ARTIFACTS, MIXED, RANDOM }

@export var chest_type: ChestType = ChestType.ITEMS
@export var is_initially_open: bool = false

# Содержимое (настраивается в инспекторе или через код)
@export var item_ids: Array[int] = []
@export var item_amounts: Array[int] = []
@export var artifact_ids: Array[String] = []

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var is_open: bool = false
var player_in_range: bool = false
var hint_label: Label = null


func _ready():
	is_open = is_initially_open
	
	# Проверяем: был ли уже открыт?
	if GameState and GameState.is_chest_opened(name):
		is_open = true
		_set_opened_visual()
		return
	
	_setup_hint()
	_update_visual()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	print("📦 Сундук '%s': тип=%d, открыт=%s" % [name, chest_type, is_open])


func _setup_hint():
	hint_label = get_node_or_null("HintLabel")
	if not hint_label:
		hint_label = Label.new()
		hint_label.name = "HintLabel"
		hint_label.text = "[F] Открыть"
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_label.position = Vector2(-50, -60)
		hint_label.add_theme_font_size_override("font_size", 14)
		hint_label.add_theme_color_override("font_color", Color.YELLOW)
		add_child(hint_label)
	hint_label.visible = false


func _update_visual():
	if animated_sprite and animated_sprite.sprite_frames:
		var anim = "open" if is_open else "idle"
		if animated_sprite.sprite_frames.has_animation(anim):
			animated_sprite.play(anim)


func _set_opened_visual():
	"""Устанавливает визуал открытого сундука (без анимации)"""
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation("open"):
			animated_sprite.play("open")
			# Переходим на последний кадр
			animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count("open") - 1


func _process(_delta):
	if player_in_range and not is_open:
		if Input.is_action_just_pressed("interact"):
			open_chest()


func _on_body_entered(body: Node2D):
	if _is_player(body) and not is_open:
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


# ===========================================
# ОТКРЫТИЕ СУНДУКА
# ===========================================

func open_chest():
	if is_open:
		return
	
	is_open = true
	
	# Регистрируем в GameState
	if GameState:
		GameState.register_chest_opened(name)
	
	# Обновляем визуал
	_update_visual()
	if hint_label:
		hint_label.visible = false
	
	# Выдаём содержимое
	_give_contents()
	
	opened.emit()
	print("📦 Сундук '%s' открыт!" % name)


func _give_contents():
	match chest_type:
		ChestType.ITEMS:
			_give_items()
		ChestType.ARTIFACTS:
			_give_artifacts()
		ChestType.MIXED:
			_give_items()
			_give_artifacts()
		ChestType.RANDOM:
			_give_random()


func _give_items():
	if not Inventory:
		return
	
	for i in range(item_ids.size()):
		var item_id = item_ids[i]
		var amount = item_amounts[i] if i < item_amounts.size() else 1
		
		Inventory.add_item_by_id(item_id, amount)
		item_given.emit(item_id, amount)
		
		if GameState:
			GameState.add_item_collected()
		
		print("   +%d x предмет #%d" % [amount, item_id])


func _give_artifacts():
	for artifact_id in artifact_ids:
		if GameState:
			GameState.collect_artifact(artifact_id)
		
		# Добавляем в инвентарь (если есть маппинг)
		if Inventory:
			var inv_id = _get_artifact_inventory_id(artifact_id)
			if inv_id > 0:
				Inventory.add_item_by_id(inv_id, 1)
		
		artifact_given.emit(artifact_id)
		print("   +артефакт: %s" % artifact_id)


func _get_artifact_inventory_id(artifact_id: String) -> int:
	# Маппинг artifact_id → inventory_id
	var mapping = {
		"hermes_wings": 201,
		"phoenix_feather": 202,
		"vampire_ring": 203,
	}
	return mapping.get(artifact_id, -1)


func _give_random():
	# Случайный лут
	if randf() < 0.5:
		# 50% шанс - зелья
		if Inventory:
			Inventory.add_item_by_id(1, randi_range(1, 3))  # Зелье HP
			Inventory.add_item_by_id(2, randi_range(1, 2))  # Зелье маны
	else:
		# 50% шанс - экипировка
		if Inventory:
			var equip_ids = [101, 102, 103, 104, 105]
			Inventory.add_item_by_id(equip_ids.pick_random(), 1)


# ===========================================
# НАСТРОЙКА СОДЕРЖИМОГО (ИЗ КОДА)
# ===========================================

func setup_items(ids: Array, amounts: Array = []):
	"""Настраивает предметы в сундуке"""
	chest_type = ChestType.ITEMS
	item_ids.clear()
	item_amounts.clear()
	
	for i in range(ids.size()):
		item_ids.append(ids[i])
		item_amounts.append(amounts[i] if i < amounts.size() else 1)


func setup_artifacts(ids: Array):
	"""Настраивает артефакты в сундуке"""
	chest_type = ChestType.ARTIFACTS
	artifact_ids.clear()
	
	for id in ids:
		artifact_ids.append(id)


func setup_mixed(items: Array, items_amounts: Array, artifacts: Array):
	"""Настраивает смешанное содержимое"""
	chest_type = ChestType.MIXED
	setup_items(items, items_amounts)
	artifact_ids.clear()
	for id in artifacts:
		artifact_ids.append(id)


func set_opened(value: bool):
	"""Устанавливает состояние (для восстановления)"""
	is_open = value
	if is_open:
		_set_opened_visual()
