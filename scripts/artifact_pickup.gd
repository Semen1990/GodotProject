extends Area2D

# ===========================================
# ARTIFACT PICKUP - ИНТЕГРАЦИЯ С ИНВЕНТАРЁМ v2
# ===========================================
#
# ИСПРАВЛЕНО:
# - Иконки загружаются из инвентарной базы данных
# - Артефакты добавляются в инвентарь (не в Global)

@export var artifact_id: String = "hermes_wings"
@export var float_height: float = 10.0
@export var float_speed: float = 2.0

# Маппинг artifact_id → ID в инвентарной базе
const ARTIFACT_ID_MAP = {
	"hermes_wings": 201,
	"phoenix_feather": 202,
	"vampire_ring": 203,
	"berserker_amulet": 204,
}

var initial_y: float
var time: float = 0.0
var is_collected: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var label: Label = $Label

func _ready():
	print("🎁 Артефакт создан: ", artifact_id)
	
	initial_y = position.y
	
	# Откладываем проверку на 1 кадр для надёжности
	# (Инвентарь очищается в death_menu ПЕРЕД загрузкой сцены)
	await get_tree().process_frame
	
	# Проверяем, есть ли уже этот артефакт
	if _check_already_collected():
		print("⚠️ Артефакт уже в инвентаре, удаляем...")
		queue_free()
		return
	
	# Настраиваем визуал ИЗ ИНВЕНТАРНОЙ БАЗЫ ДАННЫХ
	_setup_artifact_from_inventory()
	
	body_entered.connect(_on_body_entered)


func _check_already_collected() -> bool:
	"""Проверяет, есть ли артефакт в инвентаре"""
	if not Inventory or not Inventory.item_database:
		return false
	
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


func _setup_artifact_from_inventory():
	"""Настраивает визуал из инвентарной базы данных"""
	if not Inventory or not Inventory.item_database:
		print("⚠️ Инвентарь не доступен, используем запасной визуал")
		_set_fallback_visuals()
		return
	
	var inv_id = ARTIFACT_ID_MAP.get(artifact_id, -1)
	if inv_id < 0:
		print("⚠️ Артефакт '%s' не найден в маппинге" % artifact_id)
		_set_fallback_visuals()
		return
	
	var item_data = Inventory.item_database.get_item_by_id(inv_id)
	if not item_data:
		print("⚠️ Предмет ID %d не найден в базе" % inv_id)
		_set_fallback_visuals()
		return
	
	# === ИКОНКА ИЗ БАЗЫ ДАННЫХ ===
	if item_data.icon:
		sprite.texture = item_data.icon
		print("✅ Иконка загружена из инвентарной базы: ", item_data.display_name)
	else:
		_create_color_sprite_by_rarity(item_data.rarity)
	
	# === НАЗВАНИЕ ИЗ БАЗЫ ДАННЫХ ===
	if label:
		label.text = item_data.display_name
		
		# Цвет по редкости
		label.modulate = InventoryEnums.get_rarity_color(item_data.rarity)


func _create_color_sprite_by_rarity(rarity: InventoryEnums.ItemRarity):
	"""Создаёт цветной спрайт по редкости"""
	var color = InventoryEnums.get_rarity_color(rarity)
	
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture


func _set_fallback_visuals():
	"""Запасные визуальные эффекты"""
	print("🛠️ Используем запасной визуал")
	
	var hash_color = _string_to_color(artifact_id)
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(hash_color)
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	
	if label:
		label.text = artifact_id.capitalize().replace("_", " ")
		label.modulate = Color.WHITE


func _string_to_color(text: String) -> Color:
	var hash = text.hash()
	var r = float((hash >> 16) & 0xFF) / 255.0
	var g = float((hash >> 8) & 0xFF) / 255.0
	var b = float(hash & 0xFF) / 255.0
	return Color(r, g, b)


func _process(delta):
	if not is_collected:
		time += delta * float_speed
		position.y = initial_y + sin(time) * float_height


func _on_body_entered(body):
	"""Обработка столкновения с игроком"""
	if is_collected:
		return
	
	if not (body.is_in_group("player") or body.has_method("take_damage")):
		return
	
	print("🎁 Игрок подбирает артефакт: ", artifact_id)
	
	# Добавляем в ИНВЕНТАРЬ
	var success = _add_to_inventory()
	
	if success:
		print("✅ Артефакт добавлен в инвентарь!")
		_collect_artifact_effect()
	else:
		print("❌ Не удалось добавить артефакт")
		# Fallback - используем старую систему Global
		if Global and Global.has_method("collect_artifact"):
			Global.collect_artifact(artifact_id)
		_collect_artifact_effect()


func _add_to_inventory() -> bool:
	"""Добавляет артефакт в инвентарь"""
	if not Inventory:
		return false
	
	var inv_id = ARTIFACT_ID_MAP.get(artifact_id, -1)
	if inv_id < 0:
		print("⚠️ Артефакт '%s' не найден в маппинге" % artifact_id)
		return false
	
	# Проверяем уникальность
	if _check_already_collected():
		print("⚠️ Артефакт уже есть!")
		return false
	
	# Добавляем в инвентарь
	var remaining = Inventory.add_item_by_id(inv_id, 1)
	
	return remaining == 0


func _collect_artifact_effect():
	"""Визуальный эффект при подборе"""
	is_collected = true
	
	if collision:
		collision.set_deferred("disabled", true)
	
	var tween = create_tween()
	tween.tween_property(sprite, "scale", sprite.scale * 1.5, 0.3)
	tween.parallel().tween_property(sprite, "modulate:a", 0, 0.3)
	if label:
		tween.parallel().tween_property(label, "modulate:a", 0, 0.3)
	tween.tween_callback(queue_free)
	
	print("✨ Артефакт подобран!")
