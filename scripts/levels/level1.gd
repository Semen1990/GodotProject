extends Node2D

# ===========================================
# LEVEL 1 - ФИНАЛЬНАЯ ВЕРСИЯ v5.0
# ===========================================
#
# ИСПРАВЛЕНО:
# 1. Артефакт Перо Феникса работает (возрождение)
# 2. Броня/мана обновляются СРАЗУ при экипировке
# 3. Игра НЕ на паузе при открытии инвентаря
# 4. Иконки артефактов из инвентарной базы данных

@onready var player_spawn = $PlayerSpawn
@onready var game_ui = $GameUI

var current_player = null
var last_armor_value: int = 0

# UI Инвентаря
var inventory_ui: InventoryUI = null
var hotbar_ui: HotbarUI = null

# === БАЗОВЫЕ СТАТЫ ПЕРСОНАЖА ===
var base_player_armor: int = 0
var base_player_max_health: int = 0
var base_player_max_mana: int = 0
var base_player_speed: int = 0
var base_player_damage: int = 0

# === БОНУСЫ ОТ ЭКИПИРОВКИ ===
var equipment_bonus_armor: int = 0
var equipment_bonus_hp: int = 0
var equipment_bonus_mana: int = 0
var equipment_bonus_speed: int = 0
var equipment_bonus_damage: int = 0

# === БОНУСЫ ОТ ЗЕЛИЙ ===
var potion_bonus_armor: int = 0
var potion_bonus_damage: int = 0

func _ready():
	print("🎮 Level 1 loaded!")
	print("Global.selected_character: ", Global.selected_character)
	
	# === Очищаем инвентарь при новом забеге ===
	if Inventory:
		Inventory.clear_all()
		print("🗑️ Инвентарь очищен")
	
	# === Начинаем новый забег ===
	if Global and Global.has_method("start_run"):
		Global.start_run()
	
	_initialize_inventory()
	_create_inventory_ui()
	
	await get_tree().process_frame
	
	spawn_selected_character()
	
	if Global and game_ui:
		Global.register_game_ui(game_ui)
	
	_add_starting_items()
	
	print("")
	print("==================================================")
	print("📋 УПРАВЛЕНИЕ:")
	print("  [B] - Открыть/закрыть инвентарь")
	print("  [1-4] - Использовать быстрый слот")
	print("")
	print("⚠️ Инвентарь НЕ ставит игру на паузу!")
	print("⚠️ Перо Феникса - экипируйте для возрождения!")
	print("==================================================")
	print("")


# ===========================================
# ИНИЦИАЛИЗАЦИЯ ИНВЕНТАРЯ
# ===========================================

func _initialize_inventory():
	print("")
	print("=== 🎒 ИНИЦИАЛИЗАЦИЯ ИНВЕНТАРЯ ===")
	
	if not Inventory:
		push_error("❌ Inventory Autoload не найден!")
		return
	
	var db_path = "res://data/items/demo_database.tres"
	
	if not ResourceLoader.exists(db_path):
		push_warning("⚠️ База данных не найдена: %s" % db_path)
		return
	
	var item_db = load(db_path) as GameItemDatabase
	
	if item_db:
		Inventory.set_database(item_db)
		print("✅ База данных: %d предметов" % item_db.items.size())
		
		var char_class = _get_character_class()
		Inventory.set_character_class(char_class)
		
		# Подключаем сигналы
		if not Inventory.stats_updated.is_connected(_on_equipment_stats_changed):
			Inventory.stats_updated.connect(_on_equipment_stats_changed)
		if not Inventory.equipment_changed.is_connected(_on_equipment_changed):
			Inventory.equipment_changed.connect(_on_equipment_changed)
	
	print("=== ✅ ИНВЕНТАРЬ ГОТОВ ===")
	print("")


func _get_character_class() -> InventoryEnums.CharacterClass:
	match Global.selected_character:
		"warrior":
			return InventoryEnums.CharacterClass.WARRIOR
		"paladin":
			return InventoryEnums.CharacterClass.PALADIN
		"rogue":
			return InventoryEnums.CharacterClass.ROGUE
		"berserk":
			return InventoryEnums.CharacterClass.BERSERK
		_:
			return InventoryEnums.CharacterClass.WARRIOR


# ===========================================
# СОЗДАНИЕ UI ИНВЕНТАРЯ
# ===========================================

func _create_inventory_ui():
	inventory_ui = InventoryUI.new()
	inventory_ui.name = "InventoryUI"
	add_child(inventory_ui)
	inventory_ui.visible = false
	
	inventory_ui.item_used.connect(_on_inventory_item_used)
	
	print("✅ InventoryUI создан")
	
	hotbar_ui = HotbarUI.new()
	hotbar_ui.name = "HotbarUI"
	add_child(hotbar_ui)
	
	if hotbar_ui.has_signal("hotbar_slot_used"):
		hotbar_ui.hotbar_slot_used.connect(_on_hotbar_slot_used)
	
	print("✅ HotbarUI создан")


# ===========================================
# ИСПОЛЬЗОВАНИЕ ЗЕЛИЙ
# ===========================================

func _on_inventory_item_used(item: InventoryItem):
	if not current_player or not item or not item.data:
		return
	
	var item_id = item.get_item_id()
	
	if Inventory.is_potion_used(item_id):
		print("⚠️ Зелье '%s' уже использовано!" % item.get_display_name())
		return
	
	print("🧪 Используем: %s" % item.get_display_name())
	Inventory.mark_potion_used(item_id)
	
	for effect in item.data.effects:
		_apply_potion_effect(effect)


func _on_hotbar_slot_used(index: int):
	if not current_player or not Inventory:
		return
	
	var item = Inventory.get_hotbar_item(index)
	if not item or not item.data:
		return
	
	var item_id = item.get_item_id()
	
	if Inventory.is_potion_used(item_id):
		print("⚠️ Зелье '%s' уже использовано!" % item.get_display_name())
		return
	
	print("🧪 Быстрый слот %d: %s" % [index + 1, item.get_display_name()])
	Inventory.mark_potion_used(item_id)
	
	for effect in item.data.effects:
		_apply_potion_effect(effect)


func _apply_potion_effect(effect: Dictionary):
	if not current_player:
		return
	
	var effect_type = effect.get("type", InventoryEnums.EffectType.NONE)
	var value = effect.get("value", 0.0)
	
	match effect_type:
		InventoryEnums.EffectType.INSTANT_HEAL_HP:
			var heal_amount = int(value)
			var old_hp = current_player.current_health
			current_player.current_health = mini(old_hp + heal_amount, current_player.max_health)
			
			print("💚 +%d HP (%d → %d)" % [current_player.current_health - old_hp, old_hp, current_player.current_health])
			
			if current_player.has_signal("health_changed"):
				current_player.health_changed.emit(current_player.current_health)
			_show_heal_effect()
		
		InventoryEnums.EffectType.INSTANT_HEAL_MANA:
			var mana_amount = int(value)
			var old_mana = current_player.current_mana
			current_player.current_mana = mini(old_mana + mana_amount, current_player.max_mana)
			
			print("💙 +%d маны" % (current_player.current_mana - old_mana))
			
			if current_player.has_signal("mana_changed"):
				current_player.mana_changed.emit(current_player.current_mana)
		
		InventoryEnums.EffectType.BUFF_ARMOR:
			var armor_bonus = int(value)
			potion_bonus_armor += armor_bonus
			
			if current_player.has_method("add_potion_armor"):
				current_player.add_potion_armor(armor_bonus)
			else:
				current_player.armor += armor_bonus
			
			# СРАЗУ обновляем UI
			_update_armor_ui()
			
			print("🛡️ +%d брони" % armor_bonus)
		
		InventoryEnums.EffectType.BUFF_DAMAGE:
			var damage_bonus = int(value)
			potion_bonus_damage += damage_bonus
			print("⚔️ +%d урона" % damage_bonus)


func _show_heal_effect():
	if not current_player:
		return
	
	var sprite = current_player.get_node_or_null("AnimatedSprite2D")
	if not sprite:
		return
	
	var original = sprite.modulate
	sprite.modulate = Color(0.5, 2.0, 0.5, 1.0)
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", original, 0.3)


# ===========================================
# ЭКИПИРОВКА - МГНОВЕННОЕ ОБНОВЛЕНИЕ UI
# ===========================================

func _on_equipment_stats_changed(stats: Dictionary):
	"""Применяем бонусы от экипировки - СРАЗУ обновляем UI"""
	if not current_player:
		return
	
	print("")
	print("📊 === БОНУСЫ ОТ ЭКИПИРОВКИ ===")
	
	equipment_bonus_hp = stats.get("max_hp", 0)
	equipment_bonus_mana = stats.get("max_mana", 0)
	equipment_bonus_armor = stats.get("armor", 0)
	equipment_bonus_speed = stats.get("speed_percent", 0)
	equipment_bonus_damage = stats.get("damage", 0)
	
	print("  +HP: %d" % equipment_bonus_hp)
	print("  +MP: %d" % equipment_bonus_mana)
	print("  +Armor: %d" % equipment_bonus_armor)
	print("  +Speed: %d%%" % equipment_bonus_speed)
	print("  +Damage: %d" % equipment_bonus_damage)
	
	# === ПРИМЕНЯЕМ БОНУС БРОНИ ===
	if current_player.has_method("set_equipment_armor"):
		current_player.set_equipment_armor(equipment_bonus_armor)
	elif "armor" in current_player:
		current_player.armor = base_player_armor + equipment_bonus_armor + potion_bonus_armor
		if "base_armor" in current_player:
			current_player.base_armor = base_player_armor + equipment_bonus_armor
	
	# === СРАЗУ ОБНОВЛЯЕМ UI БРОНИ ===
	_update_armor_ui()
	
	# === ПРИМЕНЯЕМ БОНУС HP ===
	if equipment_bonus_hp != 0 and "max_health" in current_player:
		var old_max = current_player.max_health
		current_player.max_health = base_player_max_health + equipment_bonus_hp
		
		# Если увеличили макс HP - добавляем текущее
		if current_player.max_health > old_max:
			current_player.current_health += (current_player.max_health - old_max)
			current_player.current_health = mini(current_player.current_health, current_player.max_health)
		
		# СРАЗУ обновляем UI
		if game_ui:
			if game_ui.has_method("update_max_health"):
				game_ui.update_max_health(current_player.max_health)
			game_ui.update_health(current_player.current_health)
		
		print("  Итого макс HP: %d" % current_player.max_health)
	
	# === ПРИМЕНЯЕМ БОНУС МАНЫ ===
	if equipment_bonus_mana != 0 and "max_mana" in current_player:
		var old_max = current_player.max_mana
		current_player.max_mana = base_player_max_mana + equipment_bonus_mana
		
		if current_player.max_mana > old_max:
			current_player.current_mana += (current_player.max_mana - old_max)
			current_player.current_mana = mini(current_player.current_mana, current_player.max_mana)
		
		# СРАЗУ обновляем UI
		if game_ui:
			if game_ui.has_method("update_max_mana"):
				game_ui.update_max_mana(current_player.max_mana)
			game_ui.update_mana(current_player.current_mana)
		
		print("  Итого макс MP: %d" % current_player.max_mana)
	
	# === ПРИМЕНЯЕМ БОНУС СКОРОСТИ ===
	if equipment_bonus_speed != 0 and "current_speed" in current_player:
		var speed_bonus = int(base_player_speed * equipment_bonus_speed / 100.0)
		current_player.current_speed = base_player_speed + speed_bonus
		print("  Итого скорость: %d" % current_player.current_speed)
	
	print("📊 === БОНУСЫ ПРИМЕНЕНЫ ===")
	print("")


func _update_armor_ui():
	"""Обновляет UI брони немедленно"""
	if game_ui and current_player:
		game_ui.update_armor(current_player.armor)


func _on_equipment_changed():
	"""Обработчик изменения экипировки"""
	_check_artifact_abilities()
	
	# Обновляем UI сразу
	if game_ui and current_player:
		game_ui.update_armor(current_player.armor)


func _check_artifact_abilities():
	"""Проверяет артефакты"""
	if not current_player or not Inventory:
		return
	
	# Двойной прыжок
	var has_double_jump = Inventory.has_special_effect(InventoryEnums.EffectType.SPECIAL_DOUBLE_JUMP)
	
	if "enable_double_jump" in current_player:
		var old_value = current_player.enable_double_jump
		current_player.enable_double_jump = has_double_jump
		
		if old_value != has_double_jump:
			print("🦅 Двойной прыжок: %s" % ("ВКЛ" if has_double_jump else "ВЫКЛ"))
	
	# Обновляем глобальный флаг возрождения для базового класса
	_update_revival_artifact_status()


func _update_revival_artifact_status():
	"""Обновляет статус артефакта возрождения в Global"""
	if not Global or not Inventory:
		return
	
	# Проверяем Перо Феникса (ID 202) в экипировке
	var has_phoenix = Inventory.has_special_effect(InventoryEnums.EffectType.SPECIAL_REVIVAL)
	
	# Устанавливаем в Global для работы с base_game_character
	if has_phoenix:
		if Global.has_method("set_revival_artifact"):
			Global.set_revival_artifact("phoenix_feather")
		elif "revival_artifact_id" in Global:
			Global.revival_artifact_id = "phoenix_feather"
		print("🔥 Перо Феникса АКТИВНО")
	else:
		# Убираем артефакт возрождения
		if Global.has_method("use_revival_artifact"):
			Global.use_revival_artifact()  # Это очищает revival_artifact_id
		elif "revival_artifact_id" in Global:
			Global.revival_artifact_id = ""


# ===========================================
# ПЕРЕХОД / СМЕРТЬ
# ===========================================

func on_room_changed():
	print("🚪 Новая комната - сброс зелий")
	
	potion_bonus_armor = 0
	potion_bonus_damage = 0
	
	if current_player and current_player.has_method("reset_potion_bonuses"):
		current_player.reset_potion_bonuses()
	
	if Inventory:
		Inventory.reset_for_new_room()


func _on_player_died():
	print("💀 Игрок погиб - сброс зелий")
	
	potion_bonus_armor = 0
	potion_bonus_damage = 0
	
	if current_player and current_player.has_method("reset_potion_bonuses"):
		current_player.reset_potion_bonuses()
	
	if Inventory:
		Inventory.reset_on_death()


func _on_player_revived():
	print("✨ Игрок возродился")
	
	# Перо Феникса использовано - убираем из экипировки
	_consume_revival_artifact()


func _consume_revival_artifact():
	"""Удаляет использованный артефакт возрождения"""
	if not Inventory:
		return
	
	# Ищем Перо Феникса в экипировке
	for slot in [
		InventoryEnums.EquipSlot.ARTIFACT_1,
		InventoryEnums.EquipSlot.ARTIFACT_2,
		InventoryEnums.EquipSlot.ARTIFACT_3,
		InventoryEnums.EquipSlot.ARTIFACT_4,
	]:
		var item = Inventory.get_equipped_item(slot)
		if item and item.get_item_id() == 202:  # ID Пера Феникса
			# Снимаем и удаляем
			Inventory.unequip_item(slot)
			Inventory.remove_item_by_id(202, 1)
			print("🔥 Перо Феникса использовано и удалено!")
			
			# Обновляем статус
			_update_revival_artifact_status()
			break


# ===========================================
# СТАРТОВЫЕ ПРЕДМЕТЫ
# ===========================================

func _add_starting_items():
	if not Inventory or not Inventory.item_database:
		return
	
	print("")
	print("=== 🧪 СТАРТОВЫЕ ПРЕДМЕТЫ ===")
	
	# Зелья (игрок сам решает какие класть в быстрые слоты)
	Inventory.add_item_by_id(1, 5)    # 5 малых зелий здоровья
	Inventory.add_item_by_id(2, 5)    # 5 малых зелий маны
	Inventory.add_item_by_id(3, 3)    # 3 малых зелья каменной кожи
	Inventory.add_item_by_id(4, 2)    # 2 зелья ярости
	
	# Экипировка
	Inventory.add_item_by_id(101)     # Железный меч
	Inventory.add_item_by_id(102)     # Стальной шлем
	Inventory.add_item_by_id(103)     # Кожаный доспех
	Inventory.add_item_by_id(104)     # Деревянный щит
	Inventory.add_item_by_id(105)     # Боевые перчатки
	
	# НЕ заполняем хотбар автоматически!
	# Игрок сам перетаскивает зелья в быстрые слоты
	
	print("✅ Добавлено 9 предметов")
	print("💡 Перетащите зелья в быстрые слоты [1-4]")


# ===========================================
# СПАВН ПЕРСОНАЖА
# ===========================================

func spawn_selected_character():
	if not Global.selected_character:
		Global.selected_character = "warrior"
	
	print("🔄 Spawning: ", Global.selected_character)
	
	var character_scene_path = Global.character_player_scenes.get(Global.selected_character)
	
	if character_scene_path and ResourceLoader.exists(character_scene_path):
		var character_scene = load(character_scene_path)
		current_player = character_scene.instantiate()
		
		if player_spawn:
			current_player.global_position = player_spawn.global_position
		else:
			current_player.global_position = Vector2(100, 100)
		
		add_child(current_player)
		print("✅ Player spawned")
		
		Global.register_player(current_player)
		
		_save_base_stats()
		setup_player_ui()
		setup_player_camera()
		
		# Подключаем сигналы
		if current_player.has_signal("died"):
			current_player.died.connect(_on_player_died)
		if current_player.has_signal("revived"):
			current_player.revived.connect(_on_player_revived)
		
		_disable_old_artifact_system()
	else:
		print("❌ Character scene not found")
		create_fallback_player()


func _save_base_stats():
	if not current_player:
		return
	
	if "armor" in current_player:
		base_player_armor = current_player.armor
	if "max_health" in current_player:
		base_player_max_health = current_player.max_health
	if "max_mana" in current_player:
		base_player_max_mana = current_player.max_mana
	if "current_speed" in current_player:
		base_player_speed = current_player.current_speed
	
	print("📊 Базовые статы сохранены")


func _disable_old_artifact_system():
	if current_player and "enable_double_jump" in current_player:
		current_player.enable_double_jump = false


# ===========================================
# НАСТРОЙКА UI
# ===========================================

func setup_player_ui():
	if not current_player or not game_ui:
		return
	
	var stats = {
		"health": current_player.current_health,
		"max_health": current_player.max_health,
		"mana": current_player.current_mana,
		"max_mana": current_player.max_mana,
		"armor": current_player.armor
	}
	
	game_ui.setup_character_ui(stats)
	
	if current_player.has_signal("health_changed"):
		if not current_player.health_changed.is_connected(_on_player_health_changed):
			current_player.health_changed.connect(_on_player_health_changed)
	
	if current_player.has_signal("mana_changed"):
		if not current_player.mana_changed.is_connected(_on_player_mana_changed):
			current_player.mana_changed.connect(_on_player_mana_changed)
	
	var armor_timer = Timer.new()
	armor_timer.wait_time = 0.1
	armor_timer.timeout.connect(_check_armor_changed)
	add_child(armor_timer)
	armor_timer.start()


func _check_armor_changed():
	if not current_player:
		return
	
	if current_player.armor != last_armor_value:
		last_armor_value = current_player.armor
		_on_player_armor_changed(current_player.armor)


func _on_player_health_changed(new_health):
	if game_ui:
		game_ui.update_health(new_health)


func _on_player_mana_changed(new_mana):
	if game_ui:
		game_ui.update_mana(new_mana)


func _on_player_armor_changed(new_armor):
	if game_ui:
		game_ui.update_armor(new_armor)


# ===========================================
# КАМЕРА
# ===========================================

func setup_player_camera():
	if not current_player:
		return
	
	var camera = current_player.get_node_or_null("Camera2D")
	if not camera:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		camera.zoom = Vector2(1.5, 1.5)
		current_player.add_child(camera)
	
	camera.limit_left = 0
	camera.limit_right = 2000
	camera.limit_top = 0
	camera.limit_bottom = 1200
	camera.make_current()


func create_fallback_player():
	var player = CharacterBody2D.new()
	player.name = "FallbackPlayer"
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(30, 50)
	collision.shape = shape
	player.add_child(collision)
	
	var sprite = Sprite2D.new()
	sprite.texture = preload("res://icon.svg")
	sprite.modulate = Color.RED
	player.add_child(sprite)
	
	if player_spawn:
		player.global_position = player_spawn.global_position
	else:
		player.global_position = Vector2(100, 100)
	
	add_child(player)
	current_player = player
