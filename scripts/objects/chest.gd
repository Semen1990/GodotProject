extends Area2D
class_name Chest

# ===========================================
# CHEST v7.0 - ПРАВИЛЬНОЕ СОХРАНЕНИЕ СОСТОЯНИЯ
# ===========================================
# Логика:
# - Закрытый сундук → при возврате сундук на месте
# - Открытый сундук → при возврате сундука НЕТ, 
#   но выпавшие не подобранные предметы лежат

signal opened
signal item_spawned(pickup_node: Node2D)

enum ChestType { ITEMS, ARTIFACTS, MIXED, RANDOM }

@export var chest_type: ChestType = ChestType.ITEMS
@export var is_initially_open: bool = false

@export var item_ids: Array[int] = []
@export var item_amounts: Array[int] = []
@export var artifact_ids: Array[String] = []

@export var spawn_frame: int = 3

@export_group("Размеры выпадающих предметов")
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
	
	# === ПРОВЕРЯЕМ: БЫЛ ЛИ СУНДУК УЖЕ ОТКРЫТ? ===
	if Global and Global.is_chest_opened(name):
		print("📦 '%s' был открыт ранее → восстанавливаем предметы, удаляем сундук" % name)
		# Сундук был открыт - восстанавливаем не подобранные предметы и удаляем сундук
		call_deferred("_restore_items_and_delete")
		return
	
	# Сундук НЕ был открыт - работаем как обычно
	_setup_signals()
	_update_visual()
	_setup_hint()
	
	print("📦 Сундук '%s': закрыт, ждёт открытия" % name)


func _setup_signals():
	"""Настраивает сигналы для взаимодействия"""
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
		hint_label.text = "[F] Открыть"


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
# ВЗАИМОДЕЙСТВИЕ С ИГРОКОМ
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
	
	# Регистрируем что сундук ОТКРЫТ
	if Global:
		Global.register_opened_chest(name)
	
	if hint_label:
		hint_label.visible = false
	
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation("opening"):
			print("📦 '%s' - анимация opening" % name)
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
			print("📦 '%s' - СПАВН на кадре %d!" % [name, spawn_frame])
			_spawn_contents()
			items_spawned = true


func _on_animation_finished():
	if is_opening and animated_sprite.animation == "opening":
		_finish_opening()


func _finish_opening():
	is_open = true
	is_opening = false
	opened.emit()
	print("📦 '%s' открыт!" % name)
	
	# Плавно удаляем сундук
	var tween = create_tween()
	tween.tween_interval(0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


# ===========================================
# СПАВН СОДЕРЖИМОГО
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
# ВОССТАНОВЛЕНИЕ ПРИ ВОЗВРАТЕ НА УРОВЕНЬ
# ===========================================

func _restore_items_and_delete():
	"""Восстанавливает НЕ подобранные предметы и удаляет сундук"""
	await get_tree().process_frame
	
	# Спавним только НЕ подобранные предметы
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
	
	# Сразу удаляем сундук
	queue_free()


func _restore_items():
	"""Спавнит только НЕ подобранные предметы"""
	var restored_count = 0
	
	for i in range(item_ids.size()):
		var item_id = item_ids[i]
		var amount = item_amounts[i] if i < item_amounts.size() else 1
		
		for j in range(amount):
			var pickup_name = "ItemPickup_%d_%d" % [item_id, i * 10 + j]
			
			# Проверяем - был ли подобран
			if Global and Global.is_pickup_collected(pickup_name):
				continue  # Пропускаем
			
			_create_item_pickup(item_id, i * 10 + j)
			restored_count += 1
	
	if restored_count > 0:
		print("   📦 Восстановлено предметов: %d" % restored_count)


func _restore_artifacts():
	"""Спавнит только НЕ подобранные артефакты"""
	var restored_count = 0
	
	for i in range(artifact_ids.size()):
		var artifact_id = artifact_ids[i]
		var pickup_name = "ArtifactPickup_%s" % artifact_id
		
		# Проверяем - был ли подобран
		if Global and Global.is_pickup_collected(pickup_name):
			continue  # Пропускаем
		
		_create_artifact_pickup(artifact_id, i)
		restored_count += 1
	
	if restored_count > 0:
		print("   📦 Восстановлено артефактов: %d" % restored_count)


# ===========================================
# СОЗДАНИЕ PICKUP
# ===========================================

func _create_item_pickup(item_id: int, index: int):
	"""Создаёт pickup предмета"""
	var pickup = Area2D.new()
	pickup.name = "ItemPickup_%d_%d" % [item_id, index]
	
	# Collision layers
	pickup.set_collision_layer_value(1, false)
	pickup.set_collision_layer_value(2, false)
	pickup.set_collision_layer_value(3, false)
	pickup.set_collision_layer_value(4, true)
	pickup.set_collision_mask_value(1, false)
	pickup.set_collision_mask_value(2, true)  # Видит игрока
	pickup.set_collision_mask_value(3, false)
	pickup.set_collision_mask_value(4, false)
	pickup.monitoring = true
	pickup.monitorable = true
	
	# Sprite
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	_set_item_texture(sprite, item_id)
	sprite.scale = Vector2(item_scale, item_scale)
	pickup.add_child(sprite)
	
	# Collision
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape = CircleShape2D.new()
	shape.radius = collision_radius
	collision.shape = shape
	pickup.add_child(collision)
	
	# Hint
	var hint = Label.new()
	hint.name = "HintLabel"
	hint.text = "[F] Подобрать"
	hint.position = Vector2(-50, -30 * item_scale)
	hint.visible = false
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color.WHITE)
	pickup.add_child(hint)
	
	# Позиция
	var offset_x = (index % 5 - 2) * item_spread
	pickup.global_position = global_position + Vector2(offset_x, -10)
	
	# Добавляем на сцену
	get_parent().add_child(pickup)
	
	# Metadata
	pickup.set_meta("item_id", item_id)
	pickup.set_meta("pickup_type", "item")
	pickup.set_meta("collected", false)
	
	# Анимация
	_animate_spawn(pickup)
	
	# Логика подбора
	_attach_pickup_script(pickup, hint)
	
	print("   📦→ Предмет ID=%d" % item_id)


func _create_artifact_pickup(artifact_id: String, index: int):
	"""Создаёт pickup артефакта"""
	var pickup = Area2D.new()
	pickup.name = "ArtifactPickup_%s" % artifact_id
	
	# Collision layers
	pickup.set_collision_layer_value(1, false)
	pickup.set_collision_layer_value(2, false)
	pickup.set_collision_layer_value(3, false)
	pickup.set_collision_layer_value(4, true)
	pickup.set_collision_mask_value(1, false)
	pickup.set_collision_mask_value(2, true)  # Видит игрока
	pickup.set_collision_mask_value(3, false)
	pickup.set_collision_mask_value(4, false)
	pickup.monitoring = true
	pickup.monitorable = true
	
	# Sprite
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	var tex_path = "res://assets/items/artifacts/%s.png" % artifact_id
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
	sprite.scale = Vector2(artifact_scale, artifact_scale)
	pickup.add_child(sprite)
	
	# Collision
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape = CircleShape2D.new()
	shape.radius = collision_radius
	collision.shape = shape
	pickup.add_child(collision)
	
	# Hint
	var hint = Label.new()
	hint.name = "HintLabel"
	hint.text = "[F] Подобрать"
	hint.position = Vector2(-50, -35 * artifact_scale)
	hint.visible = false
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	pickup.add_child(hint)
	
	# Позиция
	var offset_x = (index - artifact_ids.size() / 2.0) * item_spread * 1.2
	pickup.global_position = global_position + Vector2(offset_x, -10)
	
	# Добавляем на сцену
	get_parent().add_child(pickup)
	
	# Metadata
	pickup.set_meta("artifact_id", artifact_id)
	pickup.set_meta("pickup_type", "artifact")
	pickup.set_meta("collected", false)
	
	# Анимация
	_animate_spawn(pickup)
	
	# Логика подбора
	_attach_pickup_script(pickup, hint)
	
	print("   📦→ Артефакт: %s" % artifact_id)


func _attach_pickup_script(pickup: Area2D, hint: Label):
	"""Прикрепляет скрипт обработки подбора к pickup"""
	var script = GDScript.new()
	script.source_code = """
extends Area2D

var hint_label: Label = null
var is_collected: bool = false

func _ready():
	set_process(true)

func setup(hint: Label):
	hint_label = hint

func _process(_delta):
	if is_collected:
		return
	
	var player_near = false
	for body in get_overlapping_bodies():
		if body.is_in_group(\"player\") or body.has_method(\"take_damage\"):
			player_near = true
			break
	
	if hint_label:
		hint_label.visible = player_near
	
	if player_near and Input.is_action_just_pressed(\"interact\"):
		_collect()

func _collect():
	if is_collected:
		return
	is_collected = true
	
	if hint_label:
		hint_label.visible = false
	
	var pickup_type = get_meta(\"pickup_type\", \"\")
	
	if pickup_type == \"item\":
		var item_id = get_meta(\"item_id\", 0)
		if Inventory:
			var remaining = Inventory.add_item_by_id(item_id, 1)
			if remaining > 0:
				print(\"⚠️ Инвентарь полон!\")
				is_collected = false
				return
		if Global:
			Global.register_collected_pickup(name)
			Global.add_item_collected()
		print(\"✅ Подобран предмет ID=%d\" % item_id)
	
	elif pickup_type == \"artifact\":
		var artifact_id = get_meta(\"artifact_id\", \"\")
		var artifact_item_ids = {
			\"hermes_wings\": 201,
			\"phoenix_feather\": 202,
			\"vampire_ring\": 203,
			\"berserker_amulet\": 204,
		}
		var item_id = artifact_item_ids.get(artifact_id, 0)
		if item_id > 0 and Inventory:
			var remaining = Inventory.add_item_by_id(item_id, 1)
			if remaining > 0:
				print(\"⚠️ Инвентарь полон!\")
				is_collected = false
				return
			print(\"✅ Артефакт '%s' добавлен в инвентарь\" % artifact_id)
		else:
			if Global:
				Global.collect_artifact(artifact_id)
			print(\"✅ Артефакт '%s' подобран\" % artifact_id)
		if Global:
			Global.register_collected_pickup(name)
	
	# Эффект исчезновения
	var sprite = get_node_or_null(\"Sprite2D\")
	monitoring = false
	
	var tween = create_tween()
	tween.set_parallel(true)
	if sprite:
		tween.tween_property(sprite, \"scale\", sprite.scale * 1.5, 0.15)
		tween.tween_property(sprite, \"modulate:a\", 0.0, 0.15)
		tween.tween_property(sprite, \"position:y\", sprite.position.y - 25, 0.15)
	tween.chain().tween_callback(queue_free)
"""
	script.reload()
	pickup.set_script(script)
	pickup.call("setup", hint)


func _set_item_texture(sprite: Sprite2D, item_id: int):
	"""Устанавливает текстуру предмета"""
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


func _animate_spawn(pickup: Node2D):
	"""Анимация появления"""
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


# ===========================================
# НАСТРОЙКА СОДЕРЖИМОГО
# ===========================================

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
