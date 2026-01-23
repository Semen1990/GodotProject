# ===========================================
# СКРИПТ ОБНОВЛЕНИЯ БАЗЫ ДАННЫХ ПРЕДМЕТОВ
# ===========================================
#
# Путь: res://scripts/tools/update_item_database.gd
#
# Как использовать:
# 1. Откройте этот скрипт в Godot
# 2. Нажмите Script → Run (или Ctrl+Shift+X)

@tool
extends EditorScript

const DATABASE_PATH = "res://data/items/demo_database.tres"

func _run():
	print("\n=== 📦 ОБНОВЛЕНИЕ БАЗЫ ДАННЫХ ПРЕДМЕТОВ ===\n")
	
	var db = load(DATABASE_PATH) as GameItemDatabase
	
	if not db:
		print("❌ База данных не найдена: %s" % DATABASE_PATH)
		print("   Создаём новую...")
		db = DemoItems.create_demo_database()
		_save_database(db)
		return
	
	print("✅ База данных загружена: %d предметов" % db.items.size())
	
	# Обновляем значения зелий
	for item in db.items:
		match item.id:
			1:  # Малое зелье здоровья
				_update_potion_effect(item, InventoryEnums.EffectType.INSTANT_HEAL_HP, 2.0)
				item.display_name = "Малое зелье здоровья"
				item.description = "Восстанавливает 2 единицы здоровья."
				print("✅ [1] Малое зелье здоровья: +2 HP")
			
			2:  # Малое зелье маны
				_update_potion_effect(item, InventoryEnums.EffectType.INSTANT_HEAL_MANA, 2.0)
				item.display_name = "Малое зелье маны"
				item.description = "Восстанавливает 2 единицы маны."
				print("✅ [2] Малое зелье маны: +2 MP")
			
			3:  # Малое зелье каменной кожи
				_update_potion_effect(item, InventoryEnums.EffectType.BUFF_ARMOR, 1.0)
				item.display_name = "Малое зелье каменной кожи"
				item.description = "Увеличивает броню на 1 до конца комнаты."
				print("✅ [3] Малое зелье каменной кожи: +1 броня")
			
			4:  # Зелье ярости
				_update_potion_effect(item, InventoryEnums.EffectType.BUFF_DAMAGE, 1.0)
				item.display_name = "Зелье ярости"
				item.description = "Увеличивает урон на 1 до конца комнаты."
				print("✅ [4] Зелье ярости: +1 урон")
	
	_save_database(db)


func _update_potion_effect(item: GameItemData, effect_type: InventoryEnums.EffectType, value: float):
	"""Обновляет эффект зелья"""
	# Очищаем старые эффекты
	item.effects.clear()
	
	# Добавляем новый эффект
	# Все зелья используют ON_USE (при использовании)
	item.effects.append({
		"type": effect_type,
		"value": value,
		"duration": 0.0,
		"application": InventoryEnums.EffectApplication.ON_USE,
	})


func _save_database(db: GameItemDatabase):
	"""Сохраняет базу данных"""
	var error = ResourceSaver.save(db, DATABASE_PATH)
	
	if error == OK:
		print("\n✅ База данных сохранена: %s" % DATABASE_PATH)
	else:
		print("\n❌ Ошибка сохранения: %d" % error)
	
	print("\n=== 📦 ОБНОВЛЕНИЕ ЗАВЕРШЕНО ===\n")
