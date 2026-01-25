extends Area2D
class_name Chest

# ===========================================
# СУНДУК С АРТЕФАКТАМИ
# ===========================================
# Путь: res://scripts/objects/chest.gd
#
# Игрок подходит к сундуку → появляется подсказка "Нажми F"
# Нажимает F → сундук открывается с анимацией
# На 3-м кадре → артефакты вылетают из сундука
# После анимации → сундук исчезает

# === НАСТРОЙКИ В INSPECTOR ===
@export var chest_contents: Array[String] = ["hermes_wings", "phoenix_feather"]  ## ID артефактов внутри
@export var eject_force: float = 200.0  ## Сила выброса артефактов
@export var eject_spread: float = 60.0  ## Разброс артефактов по горизонтали (пиксели)

# === ССЫЛКИ НА УЗЛЫ ===
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_zone: Area2D = $InteractionZone
@onready var hint_label: Label = $HintLabel

# === СОСТОЯНИЕ ===
var is_opened: bool = false
var player_in_range: bool = false
var player_ref: Node2D = null

# === СЦЕНА АРТЕФАКТА ===
const ARTIFACT_SCENE = preload("res://scenes/items/artifact_pickup.tscn")


func _ready():
	print("📦 Сундук создан с содержимым: ", chest_contents)
	
	# Начальная анимация - закрытый сундук
	if animated_sprite:
		animated_sprite.play("idle")
	
	# Скрываем подсказку
	if hint_label:
		hint_label.visible = false
	
	# Подключаем сигналы зоны взаимодействия
	if interaction_zone:
		interaction_zone.body_entered.connect(_on_player_entered)
		interaction_zone.body_exited.connect(_on_player_exited)
	
	# Подключаем сигнал окончания анимации
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)
		animated_sprite.frame_changed.connect(_on_frame_changed)


func _process(_delta):
	# Проверяем нажатие F когда игрок рядом
	if player_in_range and not is_opened:
		if Input.is_action_just_pressed("interact"):
			_open_chest()


# ===========================================
# ЗОНА ВЗАИМОДЕЙСТВИЯ
# ===========================================

func _on_player_entered(body: Node2D):
	"""Игрок вошёл в зону взаимодействия"""
	if not _is_player(body):
		return
	
	if is_opened:
		return
	
	player_in_range = true
	player_ref = body
	
	# Показываем подсказку
	if hint_label:
		hint_label.visible = true
	
	print("📦 Игрок рядом с сундуком")


func _on_player_exited(body: Node2D):
	"""Игрок вышел из зоны взаимодействия"""
	if not _is_player(body):
		return
	
	player_in_range = false
	player_ref = null
	
	# Скрываем подсказку
	if hint_label:
		hint_label.visible = false


func _is_player(body: Node2D) -> bool:
	"""Проверяет, является ли объект игроком"""
	return body.is_in_group("player") or body.has_method("take_damage")


# ===========================================
# ОТКРЫТИЕ СУНДУКА
# ===========================================

func _open_chest():
	"""Запускает анимацию открытия сундука"""
	if is_opened:
		return
	
	is_opened = true
	print("📦 Открываем сундук!")
	
	# Скрываем подсказку
	if hint_label:
		hint_label.visible = false
	
	# Запускаем анимацию открытия
	if animated_sprite:
		animated_sprite.play("opening")


func _on_frame_changed():
	"""Вызывается при смене кадра анимации"""
	if not animated_sprite:
		return
	
	# На 3-м кадре (индекс 2) выбрасываем артефакты
	if animated_sprite.animation == "opening" and animated_sprite.frame == 2:
		_eject_artifacts()


func _on_animation_finished():
	"""Вызывается когда анимация закончилась"""
	if animated_sprite.animation == "opening":
		print("📦 Сундук открыт, исчезает...")
		_fade_and_remove()


# ===========================================
# ВЫБРОС АРТЕФАКТОВ
# ===========================================

func _eject_artifacts():
	"""Выбрасывает артефакты из сундука"""
	print("✨ Выбрасываем артефакты: ", chest_contents)
	
	var count = chest_contents.size()
	if count == 0:
		return
	
	# Рассчитываем позиции для артефактов (чтобы не перекрывались)
	var start_offset = -eject_spread * (count - 1) / 2.0
	
	for i in range(count):
		var artifact_id = chest_contents[i]
		
		# Проверяем, нет ли уже этого артефакта в инвентаре
		if _artifact_already_collected(artifact_id):
			print("⚠️ Артефакт '%s' уже в инвентаре, пропускаем" % artifact_id)
			continue
		
		# Создаём артефакт
		var artifact = ARTIFACT_SCENE.instantiate()
		artifact.artifact_id = artifact_id
		
		# Позиция с разбросом
		var offset_x = start_offset + i * eject_spread
		artifact.position = global_position + Vector2(offset_x, -20)
		
		# Добавляем на сцену
		get_parent().add_child(artifact)
		
		# Анимация вылета вверх
		_animate_artifact_eject(artifact, offset_x)
		
		print("🎁 Артефакт '%s' вылетел из сундука" % artifact_id)


func _animate_artifact_eject(artifact: Node2D, offset_x: float):
	"""Анимирует вылет артефакта из сундука"""
	var start_pos = global_position + Vector2(0, -10)
	var end_pos = global_position + Vector2(offset_x, -80)  # Вылетает вверх
	var land_pos = global_position + Vector2(offset_x, -30)  # Приземляется чуть ниже
	
	artifact.position = start_pos
	
	# Создаём анимацию: вверх → немного вниз (приземление)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Фаза 1: Вылет вверх
	tween.tween_property(artifact, "position", end_pos, 0.4)
	
	# Фаза 2: Приземление
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(artifact, "position", land_pos, 0.3)


func _artifact_already_collected(artifact_id: String) -> bool:
	"""Проверяет, есть ли артефакт уже в инвентаре"""
	if not Inventory or not Inventory.item_database:
		return false
	
	# Маппинг artifact_id → ID в инвентаре
	const ARTIFACT_ID_MAP = {
		"hermes_wings": 201,
		"phoenix_feather": 202,
		"vampire_ring": 203,
		"berserker_amulet": 204,
	}
	
	var inv_id = ARTIFACT_ID_MAP.get(artifact_id, -1)
	if inv_id < 0:
		return false
	
	# Проверяем в инвентаре
	if Inventory.has_item(inv_id):
		return true
	
	# Проверяем в экипировке
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


# ===========================================
# УДАЛЕНИЕ СУНДУКА
# ===========================================

func _fade_and_remove():
	"""Плавно скрывает и удаляет сундук"""
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
