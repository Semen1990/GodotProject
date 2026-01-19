extends Area2D

# ===========================================
# ARTIFACT PICKUP - ДОБАВЛЯЕТ В ИНВЕНТАРЬ
# ===========================================
#
# ВАЖНО: Артефакты теперь НЕ активируются сразу!
# Они добавляются в инвентарь и работают ТОЛЬКО
# когда экипированы в слот артефакта.

@export var artifact_id: String = "hermes_wings"
@export var float_height: float = 10.0
@export var float_speed: float = 2.0

var initial_y: float
var time: float = 0.0
var is_collected: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var label: Label = $Label

# === МАППИНГ ID ДЛЯ ИНВЕНТАРЯ ===
const ARTIFACT_ID_MAP = {
	"hermes_wings": 201,      # Крылья Гермеса (двойной прыжок)
	"phoenix_feather": 202,   # Перо Феникса (возрождение)
	"vampire_ring": 203,      # Кольцо вампира (вампиризм)
	"berserker_amulet": 204,  # Амулет берсерка (бонус при низком HP)
}

func _ready():
	print("🎁 Артефакт создан: ", artifact_id)
	
	initial_y = position.y
	_setup_artifact()
	body_entered.connect(_on_body_entered)


func _setup_artifact():
	"""Настраивает внешний вид артефакта"""
	var inventory_id = ARTIFACT_ID_MAP.get(artifact_id, -1)
	
	# Пробуем получить данные из инвентаря
	if inventory_id > 0 and Inventory and Inventory.item_database:
		var item_data = Inventory.item_database.get_item_by_id(inventory_id)
		if item_data:
			_setup_from_inventory_data(item_data)
			return
	
	# Запасной вариант - из Global
	if Global and Global.has_method("get_artifact_data"):
		var artifact_data = Global.get_artifact_data(artifact_id)
		if artifact_data:
			_setup_from_global_data(artifact_data)
			return
	
	_set_fallback_visuals()


func _setup_from_inventory_data(item_data: GameItemData):
	"""Настраивает визуал из данных инвентаря"""
	if item_data.icon:
		sprite.texture = item_data.icon
	else:
		_create_colored_sprite(item_data.get_rarity_color())
	
	label.text = item_data.display_name
	label.modulate = item_data.get_rarity_color()
	
	print("✅ Артефакт настроен из инвентаря: ", item_data.display_name)


func _setup_from_global_data(artifact_data: Dictionary):
	"""Настраивает визуал из Global"""
	if artifact_data.has("icon") and artifact_data["icon"] != "":
		var texture = load(artifact_data["icon"])
		if texture:
			sprite.texture = texture
		else:
			_create_color_sprite_by_rarity(artifact_data.get("rarity", "common"))
	else:
		_create_color_sprite_by_rarity(artifact_data.get("rarity", "common"))
	
	label.text = artifact_data.get("name", artifact_id.capitalize().replace("_", " "))
	_set_label_color_by_rarity(artifact_data.get("rarity", "common"))


func _create_colored_sprite(color: Color):
	"""Создаёт цветной спрайт"""
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(color)
	sprite.texture = ImageTexture.create_from_image(image)


func _create_color_sprite_by_rarity(rarity: String):
	var color: Color
	match rarity:
		"common": color = Color(0.7, 0.7, 0.7)
		"rare": color = Color(0.2, 0.5, 1.0)
		"epic": color = Color(0.8, 0.2, 0.8)
		"legendary": color = Color(1.0, 0.8, 0.0)
		_: color = Color(1.0, 0.5, 0.0)
	_create_colored_sprite(color)


func _set_label_color_by_rarity(rarity: String):
	match rarity:
		"common": label.modulate = Color(0.7, 0.7, 0.7)
		"rare": label.modulate = Color(0.2, 0.5, 1.0)
		"epic": label.modulate = Color(0.8, 0.2, 0.8)
		"legendary": label.modulate = Color(1.0, 0.8, 0.0)
		_: label.modulate = Color.WHITE


func _set_fallback_visuals():
	var hash_color = _string_to_color(artifact_id)
	_create_colored_sprite(hash_color)
	label.text = artifact_id.capitalize().replace("_", " ")
	label.modulate = Color.WHITE


func _string_to_color(text: String) -> Color:
	var hash = text.hash()
	return Color(
		float((hash >> 16) & 0xFF) / 255.0,
		float((hash >> 8) & 0xFF) / 255.0,
		float(hash & 0xFF) / 255.0
	)


func _process(delta):
	if not is_collected:
		time += delta * float_speed
		position.y = initial_y + sin(time) * float_height


func _on_body_entered(body):
	"""Обработка столкновения с игроком"""
	if is_collected:
		return
	
	# Проверяем что это игрок
	if not (body.is_in_group("player") or body.has_method("take_damage")):
		return
	
	print("🎁 Игрок подбирает артефакт: ", artifact_id)
	
	# === ДОБАВЛЯЕМ В ИНВЕНТАРЬ (НЕ АКТИВИРУЕМ!) ===
	var added = _add_to_inventory()
	
	if added:
		print("✅ Артефакт добавлен в ИНВЕНТАРЬ!")
		print("⚠️ Для активации экипируйте его в слот артефакта [B]")
		_collect_artifact_effect()
	else:
		print("❌ Не удалось добавить в инвентарь")
		# НЕ используем старую систему Global - она активирует сразу!
		_collect_artifact_effect()


func _add_to_inventory() -> bool:
	"""Добавляет артефакт в инвентарь БЕЗ АКТИВАЦИИ"""
	if not Inventory or not Inventory.item_database:
		print("⚠️ Инвентарь недоступен")
		return false
	
	var inventory_id = ARTIFACT_ID_MAP.get(artifact_id, -1)
	
	if inventory_id < 0:
		print("⚠️ Артефакт '%s' не найден в маппинге" % artifact_id)
		return false
	
	var item_data = Inventory.item_database.get_item_by_id(inventory_id)
	if not item_data:
		print("⚠️ Предмет ID %d не найден в базе" % inventory_id)
		return false
	
	# Проверяем уникальность
	if item_data.is_unique and Inventory.has_item(inventory_id):
		print("⚠️ Уникальный артефакт '%s' уже есть!" % item_data.display_name)
		return false
	
	# Добавляем в инвентарь
	var overflow = Inventory.add_item_by_id(inventory_id, 1)
	
	if overflow > 0:
		print("⚠️ Инвентарь полон!")
		return false
	
	print("✅ Добавлен: %s (ID: %d)" % [item_data.display_name, inventory_id])
	
	# === ВАЖНО: НЕ вызываем Global.collect_artifact() ===
	# Артефакт будет активирован ТОЛЬКО когда игрок
	# экипирует его в слот артефакта через инвентарь
	
	return true


func _collect_artifact_effect():
	"""Визуальный эффект при подборе"""
	is_collected = true
	
	if collision:
		collision.set_deferred("disabled", true)
	
	# Эффект увеличения и исчезновения
	var tween = create_tween()
	tween.tween_property(sprite, "scale", sprite.scale * 1.5, 0.3)
	tween.parallel().tween_property(sprite, "modulate:a", 0, 0.3)
	tween.parallel().tween_property(label, "modulate:a", 0, 0.3)
	tween.tween_callback(queue_free)
	
	print("✨ Артефакт подобран: ", label.text)
