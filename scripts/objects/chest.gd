extends Area2D
class_name Chest

# ===========================================
# УНИВЕРСАЛЬНЫЙ СУНДУК v7 - С ДИАГНОСТИКОЙ
# ===========================================

@export var use_inspector_settings: bool = true

enum ContentType { ARTIFACTS, ITEMS, MIXED }
@export var content_type: ContentType = ContentType.ARTIFACTS

@export_group("Артефакты")
@export var artifact_contents: Array[String] = []

@export_group("Предметы")
@export var item_contents: Array[int] = []
@export var item_counts: Array[int] = []

@export_group("Настройки выброса")
@export var eject_spread: float = 45.0
@export var eject_height: float = 70.0
@export var eject_frame: int = 2
@export var max_spread_distance: float = 120.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_zone: Area2D = $InteractionZone
@onready var hint_label: Label = $HintLabel

var is_opened: bool = false
var player_in_range: bool = false
var items_ejected: bool = false

var ARTIFACT_SCENE: PackedScene = null
var ITEM_SCENE: PackedScene = null


func _ready():
	print("")
	print("=== 📦 СУНДУК ИНИЦИАЛИЗАЦИЯ ===")
	print("   Content Type: ", ContentType.keys()[content_type])
	print("   Артефакты: ", artifact_contents)
	print("   Предметы: ", item_contents)
	print("   Количества: ", item_counts)
	
	_load_scenes()
	
	if animated_sprite:
		animated_sprite.play("idle")
	
	if hint_label:
		hint_label.visible = false
	
	if interaction_zone:
		interaction_zone.body_entered.connect(_on_player_entered)
		interaction_zone.body_exited.connect(_on_player_exited)
	
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)
		animated_sprite.frame_changed.connect(_on_frame_changed)
	
	print("=== ✅ СУНДУК ГОТОВ ===")
	print("")


func setup_artifacts(artifacts: Array):
	if use_inspector_settings:
		print("📦 Inspector settings включены - код пропущен")
		return
	
	content_type = ContentType.ARTIFACTS
	artifact_contents.clear()
	for art in artifacts:
		artifact_contents.append(str(art))
	item_contents.clear()
	item_counts.clear()


func setup_items(ids: Array, counts: Array = []):
	if use_inspector_settings:
		print("📦 Inspector settings включены - код пропущен")
		return
	
	content_type = ContentType.ITEMS
	artifact_contents.clear()
	item_contents.clear()
	item_counts.clear()
	
	for id in ids:
		item_contents.append(int(id))
	for c in counts:
		item_counts.append(int(c))
	while item_counts.size() < item_contents.size():
		item_counts.append(1)


func setup_mixed(artifacts: Array, ids: Array, counts: Array = []):
	if use_inspector_settings:
		return
	content_type = ContentType.MIXED
	artifact_contents.clear()
	for art in artifacts:
		artifact_contents.append(str(art))
	item_contents.clear()
	item_counts.clear()
	for id in ids:
		item_contents.append(int(id))
	for c in counts:
		item_counts.append(int(c))
	while item_counts.size() < item_contents.size():
		item_counts.append(1)


func _load_scenes():
	print("🔍 Поиск сцен предметов...")
	
	# Артефакты
	var artifact_paths = [
		"res://scenes/items/artifact_pickup.tscn",
		"res://scenes/objects/artifact_pickup.tscn",
		"res://artifact_pickup.tscn",
	]
	
	for path in artifact_paths:
		if ResourceLoader.exists(path):
			ARTIFACT_SCENE = load(path)
			print("   ✅ Артефакт: ", path)
			break
	
	if not ARTIFACT_SCENE:
		print("   ⚠️ artifact_pickup.tscn НЕ НАЙДЕНА!")
	
	# Предметы
	var item_paths = [
		"res://scenes/items/item_pickup.tscn",
		"res://scenes/objects/item_pickup.tscn",
		"res://item_pickup.tscn",
	]
	
	for path in item_paths:
		print("   🔍 Проверяю: ", path)
		if ResourceLoader.exists(path):
			ITEM_SCENE = load(path)
			print("   ✅ Предмет: ", path)
			break
	
	if not ITEM_SCENE:
		print("   ❌ item_pickup.tscn НЕ НАЙДЕНА! Предметы пойдут в инвентарь напрямую")


func _process(_delta):
	if player_in_range and not is_opened:
		if Input.is_action_just_pressed("interact"):
			_open_chest()


func _on_player_entered(body: Node2D):
	if is_opened:
		return
	if not _is_player(body):
		return
	
	player_in_range = true
	if hint_label:
		hint_label.visible = true


func _on_player_exited(body: Node2D):
	if not _is_player(body):
		return
	
	player_in_range = false
	if hint_label:
		hint_label.visible = false


func _is_player(body: Node2D) -> bool:
	return body.is_in_group("player") or body.has_method("take_damage")


func _open_chest():
	if is_opened:
		return
	
	is_opened = true
	items_ejected = false
	
	print("")
	print("📦 === ОТКРЫТИЕ СУНДУКА ===")
	print("   Content Type: ", ContentType.keys()[content_type])
	
	if hint_label:
		hint_label.visible = false
	
	if animated_sprite:
		animated_sprite.play("opening")


func _on_frame_changed():
	if not animated_sprite:
		return
	
	if animated_sprite.animation == "opening" and animated_sprite.frame == eject_frame:
		if not items_ejected:
			items_ejected = true
			print("   🎬 Кадр %d - выбрасываем содержимое!" % eject_frame)
			_eject_contents()


func _on_animation_finished():
	if animated_sprite.animation == "opening":
		_fade_and_remove()


func _eject_contents():
	print("")
	print("✨ === ВЫБРОС СОДЕРЖИМОГО ===")
	print("   Content Type: ", ContentType.keys()[content_type])
	
	var spawn_list: Array = []
	
	# Артефакты (только для ARTIFACTS и MIXED)
	if content_type == ContentType.ARTIFACTS or content_type == ContentType.MIXED:
		print("   📋 Обрабатываем артефакты: ", artifact_contents)
		for artifact_id in artifact_contents:
			if not _artifact_already_collected(artifact_id):
				spawn_list.append({"type": "artifact", "id": artifact_id})
				print("      + Артефакт: ", artifact_id)
			else:
				print("      - Артефакт уже есть: ", artifact_id)
	
	# Предметы (только для ITEMS и MIXED)
	if content_type == ContentType.ITEMS or content_type == ContentType.MIXED:
		print("   📋 Обрабатываем предметы: ", item_contents)
		for i in range(item_contents.size()):
			var item_id = item_contents[i]
			var count = item_counts[i] if i < item_counts.size() else 1
			spawn_list.append({"type": "item", "id": item_id, "count": count})
			print("      + Предмет ID=%d x%d" % [item_id, count])
	
	var total = spawn_list.size()
	print("   📊 Всего к выбросу: %d объектов" % total)
	
	if total == 0:
		print("   ⚠️ Сундук пуст или Content Type не соответствует содержимому!")
		print("   💡 Проверь: если есть item_contents, Content Type должен быть ITEMS!")
		return
	
	# Разброс
	var actual_spread = eject_spread
	if total > 1:
		actual_spread = min(eject_spread, max_spread_distance / (total - 1))
	var start_x = -actual_spread * (total - 1) / 2.0
	
	# Спавн
	for i in range(total):
		var data = spawn_list[i]
		var offset_x = start_x + i * actual_spread
		offset_x = clamp(offset_x, -max_spread_distance, max_spread_distance)
		
		if i > 0:
			await get_tree().create_timer(0.06).timeout
		
		if data.type == "artifact":
			_spawn_artifact(data.id, offset_x)
		else:
			_spawn_item(data.id, data.count, offset_x)
	
	print("✨ === ВЫБРОС ЗАВЕРШЁН ===")
	print("")


func _spawn_artifact(artifact_id: String, offset_x: float):
	print("   🎁 Спавн артефакта: ", artifact_id)
	
	if not ARTIFACT_SCENE:
		print("      ❌ Нет сцены - добавляем напрямую")
		_add_artifact_directly(artifact_id)
		return
	
	var artifact = ARTIFACT_SCENE.instantiate()
	
	if not "artifact_id" in artifact:
		print("      ❌ Сцена не имеет artifact_id!")
		artifact.queue_free()
		_add_artifact_directly(artifact_id)
		return
	
	artifact.artifact_id = artifact_id
	artifact.position = global_position
	
	get_parent().add_child(artifact)
	_animate_eject(artifact, offset_x)
	
	print("      ✅ Артефакт вылетел!")


func _spawn_item(item_id: int, count: int, offset_x: float):
	print("   📦 Спавн предмета: ID=%d x%d" % [item_id, count])
	
	if not ITEM_SCENE:
		print("      ❌ Нет сцены item_pickup.tscn - добавляем напрямую в инвентарь")
		if Inventory:
			Inventory.add_item_by_id(item_id, count)
		return
	
	var item = ITEM_SCENE.instantiate()
	print("      🔧 Сцена создана: ", item)
	
	if not "item_id" in item:
		print("      ❌ Сцена не имеет свойства item_id!")
		print("      💡 Проверь что item_pickup.tscn использует скрипт item_pickup.gd")
		item.queue_free()
		if Inventory:
			Inventory.add_item_by_id(item_id, count)
		return
	
	item.item_id = item_id
	item.item_count = count
	item.position = global_position
	
	get_parent().add_child(item)
	_animate_eject(item, offset_x)
	
	print("      ✅ Предмет вылетел!")


func _add_artifact_directly(artifact_id: String):
	const ARTIFACT_MAP = {
		"hermes_wings": 201,
		"phoenix_feather": 202,
		"vampire_ring": 203,
		"berserker_amulet": 204,
	}
	
	var inv_id = ARTIFACT_MAP.get(artifact_id, -1)
	if inv_id > 0 and Inventory:
		Inventory.add_item_by_id(inv_id, 1)


func _animate_eject(node: Node2D, offset_x: float):
	var start_pos = global_position + Vector2(0, -10)
	var peak_pos = global_position + Vector2(offset_x, -eject_height)
	var land_pos = global_position + Vector2(offset_x, -25)
	
	node.position = start_pos
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "position", peak_pos, 0.35)
	
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(node, "position", land_pos, 0.25)


func _artifact_already_collected(artifact_id: String) -> bool:
	if not Inventory:
		return false
	
	const ARTIFACT_MAP = {
		"hermes_wings": 201,
		"phoenix_feather": 202,
		"vampire_ring": 203,
		"berserker_amulet": 204,
	}
	
	var inv_id = ARTIFACT_MAP.get(artifact_id, -1)
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


func _fade_and_remove():
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
