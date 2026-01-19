extends Node2D

# ===========================================
# LEVEL 1 - ФИНАЛЬНАЯ ВЕРСИЯ (ВСЕ БАГИ ИСПРАВЛЕНЫ)
# ===========================================
#
# ИСПРАВЛЕНО:
# 1. heal() НЕ вызывается - напрямую меняем current_health
# 2. Тестовые артефакты УБРАНЫ из инвентаря
# 3. Артефакты работают ТОЛЬКО когда экипированы
# 4. Экипировка даёт бонусы персонажу
# 5. Hotbar перемещён в левый нижний угол

@onready var player_spawn = $PlayerSpawn
@onready var game_ui = $GameUI

var current_player = null
var last_armor_value: int = 0

# UI Инвентаря
var inventory_ui: InventoryUI = null
var hotbar_ui: HotbarUI = null

# Базовые статы персонажа (до бонусов)
var base_player_armor: int = 0
var base_player_max_health: int = 0
var base_player_speed: int = 0

func _ready():
	print("🎮 Level 1 loaded!")
	print("Global.selected_character: ", Global.selected_character)
	
	# === Начинаем новый забег ===
	if Global and Global.has_method("start_run"):
		Global.start_run()
		print("📊 Новый забег начат!")
	
	# === ИНИЦИАЛИЗАЦИЯ ИНВЕНТАРЯ ===
	_initialize_inventory()
	
	# === СОЗДАЁМ UI ИНВЕНТАРЯ ===
	_create_inventory_ui()
	
	# Ждем полной загрузки
	await get_tree().process_frame
	
	# Спавним персонажа
	spawn_selected_character()
	
	# Регистрируем UI
	if Global and game_ui:
		Global.register_game_ui(game_ui)
		print("✅ Game UI registered")
	
	# === ТЕСТ ИНВЕНТАРЯ (БЕЗ АРТЕФАКТОВ) ===
	_test_inventory()
	
	# Выводим подсказку
	print("")
	print("==================================================")
	print("📋 УПРАВЛЕНИЕ:")
	print("  [B] - Открыть/закрыть инвентарь")
	print("  [ESC] - Закрыть инвентарь")
	print("  [1-4] - Использовать быстрый слот")
	print("  [ЛКМ] - Перетащить предмет")
	print("  [ПКМ] - Использовать / Экипировать")
	print("")
	print("⚠️ Артефакты нужно ЭКИПИРОВАТЬ для активации!")
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
		print("✅ База данных загружена: %d предметов" % item_db.items.size())
		
		var char_class = _get_character_class()
		Inventory.set_character_class(char_class)
		print("✅ Класс персонажа: %s" % InventoryEnums.CharacterClass.keys()[char_class])
		
		# ВАЖНО: Подключаем сигналы для статов и экипировки
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
	print("📦 Создаю UI инвентаря...")
	
	# Главное окно инвентаря
	inventory_ui = InventoryUI.new()
	inventory_ui.name = "InventoryUI"
	add_child(inventory_ui)
	inventory_ui.visible = false
	
	# Подключаем сигналы
	inventory_ui.item_used.connect(_on_inventory_item_used)
	inventory_ui.inventory_opened.connect(_on_inventory_opened)
	inventory_ui.inventory_closed.connect(_on_inventory_closed)
	
	print("✅ InventoryUI создан")
	
	# Панель быстрых слотов
	hotbar_ui = HotbarUI.new()
	hotbar_ui.name = "HotbarUI"
	add_child(hotbar_ui)
	
	# Подключаем использование зелий
	if hotbar_ui.has_signal("hotbar_slot_used"):
		hotbar_ui.hotbar_slot_used.connect(_on_hotbar_slot_used)
	
	print("✅ HotbarUI создан (левый нижний угол)")


func _on_inventory_opened():
	if current_player and "can_move" in current_player:
		current_player.can_move = false
	if current_player and "can_attack" in current_player:
		current_player.can_attack = false


func _on_inventory_closed():
	if current_player and "can_move" in current_player:
		current_player.can_move = true
	if current_player and "can_attack" in current_player:
		current_player.can_attack = true


# ===========================================
# ИСПОЛЬЗОВАНИЕ ПРЕДМЕТОВ - ИСПРАВЛЕНО (БЕЗ heal())
# ===========================================

func _on_inventory_item_used(item: InventoryItem):
	"""Обработчик использования предмета из инвентаря"""
	if not current_player or not item or not item.data:
		return
	
	print("🧪 Используем: %s" % item.get_display_name())
	
	for effect in item.data.effects:
		_apply_effect_to_player(effect)


func _on_hotbar_slot_used(index: int):
	"""Обработчик использования быстрого слота"""
	if not current_player or not Inventory:
		return
	
	var item = Inventory.get_hotbar_item(index)
	if item and item.data:
		print("🧪 Быстрый слот %d: %s" % [index + 1, item.get_display_name()])
		for effect in item.data.effects:
			_apply_effect_to_player(effect)


func _apply_effect_to_player(effect: Dictionary):
	"""Применяет эффект к игроку - ИСПРАВЛЕНО БЕЗ ВЫЗОВА heal()"""
	if not current_player:
		return
	
	var effect_type = effect.get("type", InventoryEnums.EffectType.NONE)
	var value = effect.get("value", 0.0)
	var duration = effect.get("duration", 0.0)
	
	match effect_type:
		InventoryEnums.EffectType.INSTANT_HEAL_HP:
			# === ИСПРАВЛЕНО: Напрямую меняем current_health ===
			var heal_amount = int(value)
			var old_hp = current_player.current_health
			var max_hp = current_player.max_health
			
			current_player.current_health = mini(old_hp + heal_amount, max_hp)
			var healed = current_player.current_health - old_hp
			
			print("💚 Восстановлено %d HP (%d → %d/%d)" % [
				healed, old_hp, current_player.current_health, max_hp
			])
			
			# Обновляем UI
			if current_player.has_signal("health_changed"):
				current_player.health_changed.emit(current_player.current_health)
			
			# Визуальный эффект лечения
			_show_heal_effect()
		
		InventoryEnums.EffectType.INSTANT_HEAL_MANA:
			var mana_amount = int(value)
			var old_mana = current_player.current_mana
			var max_mana = current_player.max_mana
			
			current_player.current_mana = mini(old_mana + mana_amount, max_mana)
			var restored = current_player.current_mana - old_mana
			
			print("💙 Восстановлено %d маны (%d → %d/%d)" % [
				restored, old_mana, current_player.current_mana, max_mana
			])
			
			if current_player.has_signal("mana_changed"):
				current_player.mana_changed.emit(current_player.current_mana)
		
		InventoryEnums.EffectType.BUFF_ARMOR:
			print("🛡️ +%d брони на %.1f сек" % [int(value), duration])
			_apply_temp_buff("armor", int(value), duration)
		
		InventoryEnums.EffectType.BUFF_DAMAGE:
			print("⚔️ +%d%% урона на %.1f сек" % [int(value), duration])
			# TODO: Реализовать бафф урона
		
		InventoryEnums.EffectType.BUFF_SPEED:
			print("💨 +%d%% скорости на %.1f сек" % [int(value), duration])
			_apply_temp_buff("speed", int(value), duration)


func _show_heal_effect():
	"""Зелёная вспышка при лечении"""
	if not current_player:
		return
	
	var sprite = current_player.get_node_or_null("AnimatedSprite2D")
	if not sprite:
		return
	
	var original = sprite.modulate
	sprite.modulate = Color(0.5, 2.0, 0.5, 1.0)  # Зелёная вспышка
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", original, 0.3)


func _apply_temp_buff(stat: String, value: int, duration: float):
	"""Применяет временный бафф"""
	if not current_player:
		return
	
	match stat:
		"armor":
			if "armor" in current_player:
				var original = current_player.armor
				current_player.armor += value
				print("  Броня: %d → %d" % [original, current_player.armor])
				
				# Ждём окончания баффа
				await get_tree().create_timer(duration).timeout
				
				if is_instance_valid(current_player) and "armor" in current_player:
					current_player.armor = maxi(current_player.armor - value, 0)
					print("🛡️ Бафф брони закончился (броня: %d)" % current_player.armor)
		
		"speed":
			if "current_speed" in current_player:
				var original = current_player.current_speed
				var bonus = int(original * value / 100.0)
				current_player.current_speed += bonus
				print("  Скорость: %d → %d" % [original, current_player.current_speed])
				
				await get_tree().create_timer(duration).timeout
				
				if is_instance_valid(current_player) and "current_speed" in current_player:
					current_player.current_speed = maxi(current_player.current_speed - bonus, 50)
					print("💨 Бафф скорости закончился")


# ===========================================
# ЭКИПИРОВКА - ПРИМЕНЕНИЕ БОНУСОВ К ПЕРСОНАЖУ
# ===========================================

func _on_equipment_stats_changed(stats: Dictionary):
	"""Применяем бонусы от экипировки к персонажу"""
	if not current_player:
		return
	
	print("")
	print("📊 === ОБНОВЛЕНИЕ СТАТОВ ОТ ЭКИПИРОВКИ ===")
	
	var bonus_hp = stats.get("max_hp", 0)
	var bonus_armor = stats.get("armor", 0)
	var bonus_damage = stats.get("damage", 0)
	var bonus_speed = stats.get("speed_percent", 0)
	
	print("  +HP: %d" % bonus_hp)
	print("  +Armor: %d" % bonus_armor)
	print("  +Damage: %d" % bonus_damage)
	print("  +Speed: %d%%" % bonus_speed)
	
	# Применяем бонус брони
	if "armor" in current_player and "base_armor" in current_player:
		current_player.armor = current_player.base_armor + bonus_armor
		print("  Итого броня: %d (база %d + бонус %d)" % [
			current_player.armor, current_player.base_armor, bonus_armor
		])
	elif "armor" in current_player:
		# Если нет base_armor, сохраняем текущую броню как базу
		if base_player_armor == 0:
			base_player_armor = current_player.armor
		current_player.armor = base_player_armor + bonus_armor
	
	# Применяем бонус HP
	if bonus_hp > 0 and "max_health" in current_player:
		if base_player_max_health == 0:
			base_player_max_health = current_player.max_health
		current_player.max_health = base_player_max_health + bonus_hp
		print("  Итого макс HP: %d" % current_player.max_health)
	
	# Применяем бонус скорости
	if bonus_speed > 0 and "current_speed" in current_player:
		if base_player_speed == 0:
			base_player_speed = current_player.current_speed
		var speed_bonus = int(base_player_speed * bonus_speed / 100.0)
		current_player.current_speed = base_player_speed + speed_bonus
		print("  Итого скорость: %d" % current_player.current_speed)
	
	print("📊 === СТАТЫ ПРИМЕНЕНЫ ===")
	print("")


func _on_equipment_changed():
	"""Обработчик изменения экипировки - проверяем артефакты"""
	_check_artifact_abilities()


func _check_artifact_abilities():
	"""Проверяет ЭКИПИРОВАННЫЕ артефакты и включает/выключает способности"""
	if not current_player or not Inventory:
		return
	
	# === ДВОЙНОЙ ПРЫЖОК ===
	# Работает ТОЛЬКО если артефакт экипирован в слот артефакта
	var has_double_jump = Inventory.has_special_effect(InventoryEnums.EffectType.SPECIAL_DOUBLE_JUMP)
	
	if "enable_double_jump" in current_player:
		var old_value = current_player.enable_double_jump
		current_player.enable_double_jump = has_double_jump
		
		if old_value != has_double_jump:
			if has_double_jump:
				print("🦅 Двойной прыжок ВКЛЮЧЕН (артефакт экипирован)")
			else:
				print("🦅 Двойной прыжок ВЫКЛЮЧЕН")
	
	# === ВОЗРОЖДЕНИЕ ===
	var has_revival = Inventory.has_special_effect(InventoryEnums.EffectType.SPECIAL_REVIVAL)
	if has_revival:
		print("🔥 Возрождение доступно (Перо Феникса экипировано)")


# ===========================================
# ТЕСТ ИНВЕНТАРЯ - БЕЗ АРТЕФАКТОВ!
# ===========================================

func _test_inventory():
	"""Добавляет тестовые предметы БЕЗ АРТЕФАКТОВ"""
	if not Inventory or not Inventory.item_database:
		print("⚠️ Инвентарь не инициализирован")
		return
	
	print("")
	print("=== 🧪 ДОБАВЛЯЕМ ТЕСТОВЫЕ ПРЕДМЕТЫ ===")
	
	# === ТОЛЬКО ЗЕЛЬЯ И ЭКИПИРОВКА ===
	Inventory.add_item_by_id(1, 10)   # 10 зелий здоровья
	Inventory.add_item_by_id(2, 8)    # 8 зелий маны
	Inventory.add_item_by_id(3, 5)    # 5 зелий каменной кожи
	Inventory.add_item_by_id(4, 3)    # 3 зелья ярости
	Inventory.add_item_by_id(101)     # Железный меч
	Inventory.add_item_by_id(102)     # Стальной шлем
	Inventory.add_item_by_id(103)     # Кожаный доспех
	Inventory.add_item_by_id(104)     # Деревянный щит
	Inventory.add_item_by_id(105)     # Боевые перчатки
	
	# === АРТЕФАКТЫ УБРАНЫ! ===
	# Они подбираются на уровне и должны быть ЭКИПИРОВАНЫ
	# Inventory.add_item_by_id(201)   # Крылья Гермеса - УБРАНО
	# Inventory.add_item_by_id(202)   # Перо Феникса - УБРАНО
	
	# Зелья в быстрые слоты
	Inventory.set_hotbar_item(0, 0)  # Зелье здоровья → слот 1
	Inventory.set_hotbar_item(1, 1)  # Зелье маны → слот 2
	Inventory.set_hotbar_item(2, 2)  # Зелье каменной кожи → слот 3
	Inventory.set_hotbar_item(3, 3)  # Зелье ярости → слот 4
	
	print("✅ Добавлено 9 предметов (зелья + экипировка)")
	print("⚠️ Артефакты нужно подобрать на уровне!")
	print("⚠️ Для активации артефактов - экипируйте их в слот!")
	
	Inventory.debug_print()


# ===========================================
# СПАВН ПЕРСОНАЖА
# ===========================================

func spawn_selected_character():
	print("🔄 Attempting to spawn character...")
	
	if not Global.selected_character:
		print("❌ No character selected! Using default warrior.")
		Global.selected_character = "warrior"
	
	print("🔄 Spawning character: ", Global.selected_character)
	
	var character_scene_path = Global.character_player_scenes.get(Global.selected_character)
	
	if character_scene_path and ResourceLoader.exists(character_scene_path):
		var character_scene = load(character_scene_path)
		current_player = character_scene.instantiate()
		
		if player_spawn:
			current_player.global_position = player_spawn.global_position
			add_child(current_player)
			print("✅ Player spawned: ", Global.selected_character)
			
			Global.register_player(current_player)
			
			# Сохраняем базовые статы
			_save_base_stats()
			
			setup_player_ui()
			setup_player_camera()
			
			# ВАЖНО: Отключаем старую систему артефактов!
			_disable_old_artifact_system()
		else:
			current_player.global_position = Vector2(100, 100)
			add_child(current_player)
	else:
		print("❌ Character scene not found")
		create_fallback_player()


func _save_base_stats():
	"""Сохраняет базовые статы персонажа"""
	if not current_player:
		return
	
	if "armor" in current_player:
		base_player_armor = current_player.armor
	if "max_health" in current_player:
		base_player_max_health = current_player.max_health
	if "current_speed" in current_player:
		base_player_speed = current_player.current_speed


func _disable_old_artifact_system():
	"""Отключает старую систему артефактов (из Global)"""
	if current_player and "enable_double_jump" in current_player:
		current_player.enable_double_jump = false
		print("🔧 Старая система артефактов отключена")
		print("   Используйте инвентарь для экипировки артефактов!")


# ===========================================
# НАСТРОЙКА UI
# ===========================================

func setup_player_ui():
	if not current_player or not game_ui:
		return
	
	print("")
	print("=== 🔗 ПОДКЛЮЧЕНИЕ UI К ПЕРСОНАЖУ ===")
	
	var stats = {
		"health": current_player.current_health,
		"max_health": current_player.max_health,
		"mana": current_player.current_mana,
		"max_mana": current_player.max_mana,
		"armor": current_player.armor
	}
	
	print("📊 Статы персонажа:")
	print("  HP: %d/%d" % [stats["health"], stats["max_health"]])
	print("  MP: %d/%d" % [stats["mana"], stats["max_mana"]])
	print("  ARM: %d" % stats["armor"])
	
	game_ui.setup_character_ui(stats)
	
	if current_player.has_signal("health_changed"):
		if not current_player.health_changed.is_connected(_on_player_health_changed):
			current_player.health_changed.connect(_on_player_health_changed)
	
	if current_player.has_signal("mana_changed"):
		if not current_player.mana_changed.is_connected(_on_player_mana_changed):
			current_player.mana_changed.connect(_on_player_mana_changed)
	
	# Таймер для отслеживания брони
	var armor_timer = Timer.new()
	armor_timer.wait_time = 0.1
	armor_timer.timeout.connect(_check_armor_changed)
	add_child(armor_timer)
	armor_timer.start()
	
	print("=== ✅ UI ПОДКЛЮЧЕН ===")
	print("")


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


# ===========================================
# РЕЗЕРВНЫЙ ИГРОК
# ===========================================

func create_fallback_player():
	print("🔄 Creating fallback player...")
	
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
	
	var player_script = load("res://scripts/game_characters/base_game_character.gd")
	if player_script:
		player.set_script(player_script)
	
	if player_spawn:
		player.global_position = player_spawn.global_position
	else:
		player.global_position = Vector2(100, 100)
	
	add_child(player)
	current_player = player
	print("✅ Fallback player created")
