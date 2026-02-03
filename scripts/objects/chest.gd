extends Area2D
class_name Chest

# ===========================================
# CHEST v5.0 - ВСТРОЕННАЯ ЛОГИКА ПОДБОРА
# ===========================================
# Предметы создаются со встроенными сигналами и логикой
# Не требует внешних скриптов ItemPickup/ArtifactPickup

signal opened
signal item_spawned(pickup_node: Node2D)

enum ChestType { ITEMS, ARTIFACTS, MIXED, RANDOM }

@export var chest_type: ChestType = ChestType.ITEMS
@export var is_initially_open: bool = false

@export var item_ids: Array[int] = []
@export var item_amounts: Array[int] = []
@export var artifact_ids: Array[String] = []

@export var spawn_frame: int = 3

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
	
	if Global and Global.is_pickup_collected(name):
		is_open = true
	
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
	
	_update_visual()
	_setup_hint()
	
	print("📦 Сундук '%s': открыт=%s" % [name, is_open])


func _setup_hint():
	if hint_label:
		hint_label.visible = false
		hint_label.text = "[F] Открыть" if not is_open else ""


func _update_visual():
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	
	if is_open:
		if animated_sprite.sprite_frames.has_animation("opening"):
			animated_sprite.animation = "opening"
			var count = animated_sprite.sprite_frames.get_frame_count("opening")
			if count > 0:
				animated_sprite.frame = count - 1
			animated_sprite.stop()
	else:
		if animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")


func _process(_delta):
	if player_in_range and not is_open and not is_opening:
		if Input.is_action_just_pressed("interact"):
			open_chest()


func _on_body_entered(body: Node2D):
	if _is_player(body) and not is_open:
		player_in_range = true
		if hint_label:
			hint_label.visible = true
			hint_label.text = "[F] Открыть"


func _on_body_exited(body: Node2D):
	if _is_player(body):
		player_in_range = false
		if hint_label:
			hint_label.visible = false


func _is_player(body: Node2D) -> bool:
	return body.is_in_group("player") or body.has_method("take_damage")


func open_chest():
	if is_open or is_opening:
		return
	
	is_opening = true
	items_spawned = false
	
	if Global:
		Global.register_collected_pickup(name)
	
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
	
	var tween = create_tween()
	tween.tween_interval(0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)


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
# СОЗДАНИЕ PICKUP С ВСТРОЕННОЙ ЛОГИКОЙ
# ===========================================

func _create_item_pickup(item_id: int, index: int):
	"""Создаёт pickup предмета со встроенной логикой подбора"""
	var pickup = Area2D.new()
	pickup.name = "ItemPickup_%d_%d" % [item_id, index]
	
	# Layer 4 = предметы
	pickup.set_collision_layer_value(1, false)
	pickup.set_collision_layer_value(2, false)
	pickup.set_collision_layer_value(3, false)
	pickup.set_collision_layer_value(4, true)   # Layer 4 (items)
	
	# Mask: видим ТОЛЬКО layer 2 (игрок!)
	pickup.set_collision_mask_value(1, false)   # НЕ видим layer 1 (мир)
	pickup.set_collision_mask_value(2, true)    # Видим layer 2 (ИГРОК!)
	pickup.set_collision_mask_value(3, false)   # НЕ видим layer 3 (враги)
	pickup.set_collision_mask_value(4, false)   # НЕ видим layer 4 (предметы)
	
	pickup.monitoring = true
	pickup.monitorable = true
	
	# Sprite
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	_set_item_texture(sprite, item_id)
	pickup.add_child(sprite)
	
	# Collision - большой радиус для удобства
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape = CircleShape2D.new()
	shape.radius = 40  # Увеличен ещё больше
	collision.shape = shape
	pickup.add_child(collision)
	
	print("   🔧 ItemPickup ID=%d: layer=4, mask=2 (видит ИГРОКА)" % item_id)
	
	# Hint Label
	var hint = Label.new()
	hint.name = "HintLabel"
	hint.text = "[F] Подобрать"
	hint.position = Vector2(-45, -40)
	hint.visible = false
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color.WHITE)
	pickup.add_child(hint)
	
	# Позиция с разбросом
	var offset_x = (index % 5 - 2) * 30
	pickup.global_position = global_position + Vector2(offset_x, -10)
	
	# Добавляем на сцену
	get_parent().add_child(pickup)
	
	# Сигналы не нужны - логика в скрипте pickup
	
	# Сохраняем данные в метаданных
	pickup.set_meta("item_id", item_id)
	pickup.set_meta("pickup_type", "item")
	pickup.set_meta("collected", false)
	
	# Анимация появления
	_animate_spawn(pickup)
	
	# Запускаем проверку ввода
	_start_pickup_input_check(pickup, hint)
	
	print("   📦→ Предмет ID=%d (подбор по F)" % item_id)


func _create_artifact_pickup(artifact_id: String, index: int):
	"""Создаёт pickup артефакта со встроенной логикой подбора"""
	var pickup = Area2D.new()
	pickup.name = "ArtifactPickup_%s" % artifact_id
	
	# Layer 4 = предметы/артефакты
	pickup.set_collision_layer_value(1, false)
	pickup.set_collision_layer_value(2, false)
	pickup.set_collision_layer_value(3, false)
	pickup.set_collision_layer_value(4, true)   # Layer 4 (items)
	
	# Mask: видим ТОЛЬКО layer 2 (игрок!)
	pickup.set_collision_mask_value(1, false)   # НЕ видим layer 1 (мир)
	pickup.set_collision_mask_value(2, true)    # Видим layer 2 (ИГРОК!)
	pickup.set_collision_mask_value(3, false)   # НЕ видим layer 3 (враги)
	pickup.set_collision_mask_value(4, false)   # НЕ видим layer 4 (предметы)
	
	pickup.monitoring = true
	pickup.monitorable = true
	
	# Sprite
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	var tex_path = "res://assets/items/artifacts/%s.png" % artifact_id
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
	pickup.add_child(sprite)
	
	# Collision - большой радиус
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape = CircleShape2D.new()
	shape.radius = 40  # Увеличен
	collision.shape = shape
	pickup.add_child(collision)
	
	print("   🔧 ArtifactPickup %s: layer=4, mask=2 (видит ИГРОКА)" % artifact_id)
	
	# Hint Label
	var hint = Label.new()
	hint.name = "HintLabel"
	hint.text = "[F] Подобрать"
	hint.position = Vector2(-45, -40)
	hint.visible = false
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))  # Золотистый
	pickup.add_child(hint)
	
	# Позиция
	var offset_x = (index - artifact_ids.size() / 2.0) * 40
	pickup.global_position = global_position + Vector2(offset_x, -10)
	
	# Добавляем на сцену
	get_parent().add_child(pickup)
	
	# Сигналы не нужны - логика в скрипте pickup
	
	# Метаданные
	pickup.set_meta("artifact_id", artifact_id)
	pickup.set_meta("pickup_type", "artifact")
	pickup.set_meta("collected", false)
	
	# Анимация
	_animate_spawn(pickup)
	
	# Запускаем проверку ввода
	_start_pickup_input_check(pickup, hint)
	
	print("   📦→ Артефакт: %s (подбор по F)" % artifact_id)


# ===========================================
# ЛОГИКА ПОДБОРА (ВСТРОЕННАЯ)
# ===========================================

# Функции обработки сигналов удалены - логика теперь в скрипте pickup


func _start_pickup_input_check(pickup: Area2D, hint: Label):
	"""Добавляет скрипт к pickup для обработки нажатия F"""
	# Создаём встроенный скрипт для обработки ввода
	var script = GDScript.new()
	script.source_code = """
extends Area2D

var hint_label: Label = null
var is_collected: bool = false
var chest_ref = null

func setup(hint: Label, chest):
	hint_label = hint
	is_collected = false
	chest_ref = chest
	set_process(true)

func _process(_delta):
	if is_collected:
		set_process(false)
		return
	
	# Проверяем overlapping bodies каждый кадр
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
	pickup.call("setup", hint, self)


# Функция _check_pickup_input удалена - логика теперь в скрипте pickup


# Функция _collect_pickup удалена - логика теперь в скрипте pickup


# Функция _add_item_to_inventory удалена - логика теперь в скрипте pickup


# Функция _add_artifact_to_inventory удалена - логика теперь в скрипте pickup


# Функция _play_collect_effect удалена - логика теперь в скрипте pickup


# ===========================================
# ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
# ===========================================

func _set_item_texture(sprite: Sprite2D, item_id: int):
	"""Устанавливает текстуру предмета по ID"""
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
	"""Анимация появления предмета из сундука"""
	var start_y = pickup.global_position.y
	pickup.global_position.y -= 40
	pickup.scale = Vector2(0.3, 0.3)
	pickup.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(pickup, "global_position:y", start_y + 15, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(pickup, "scale", Vector2(1, 1), 0.3)
	tween.tween_property(pickup, "modulate:a", 1.0, 0.2)


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
