# ===========================================
# СКРИПТ ПРИВЯЗКИ ИКОНОК К БАЗЕ ДАННЫХ
# ===========================================
#
# Путь: res://scripts/tools/bind_item_icons.gd
#
# Как использовать:
# 1. Разместите иконки в папке res://assets/items/
# 2. Откройте этот скрипт в Godot
# 3. Нажмите Script → Run (или Ctrl+Shift+X)

@tool
extends EditorScript

# Путь к базе данных предметов
const DATABASE_PATH = "res://data/items/demo_database.tres"

# Базовый путь к иконкам
const ICONS_BASE_PATH = "res://assets/items/"

# Маппинг internal_name → путь к иконке
# Измените пути в соответствии с вашей структурой папок
const ICON_PATHS = {
	# Зелья
	"health_potion": "potions/health_potion.png",
	"mana_potion": "potions/mana_potion.png",
	"stoneskin_potion": "potions/armor_potion.png",
	"rage_potion": "potions/rage_potion.png",
	
	# Оружие
	"iron_sword": "weapons/iron_sword.png",
	
	# Броня
	"steel_helmet": "armor/steel_helmet.png",
	"leather_armor": "armor/leather_armor.png",
	"wooden_shield": "shields/wooden_shield.png",
	"combat_gloves": "accessories/combat_gloves.png",
	
	# Артефакты
	"hermes_wings": "artifacts/hermes_wings.png",
	"phoenix_feather": "artifacts/phoenix_feather.png",
	"vampire_ring": "artifacts/vampire_ring.png",
	"berserker_amulet": "artifacts/berserker_amulet.png",
}


func _run():
	print("\n=== 🎨 ПРИВЯЗКА ИКОНОК К ПРЕДМЕТАМ ===\n")
	
	# Загружаем базу данных
	var db = load(DATABASE_PATH) as GameItemDatabase
	
	if not db:
		print("❌ Ошибка: База данных не найдена по пути: %s" % DATABASE_PATH)
		return
	
	print("✅ База данных загружена: %d предметов\n" % db.items.size())
	
	var success_count = 0
	var fail_count = 0
	
	# Проходим по всем предметам
	for item in db.items:
		var internal_name = item.internal_name
		
		# Ищем путь к иконке
		var icon_relative_path = ICON_PATHS.get(internal_name, "")
		
		if icon_relative_path == "":
			# Пробуем найти по имени файла
			icon_relative_path = internal_name + ".png"
		
		var full_path = ICONS_BASE_PATH + icon_relative_path
		
		if ResourceLoader.exists(full_path):
			var texture = load(full_path)
			if texture is Texture2D:
				item.icon = texture
				print("✅ [%d] %s → %s" % [item.id, item.display_name, full_path])
				success_count += 1
			else:
				print("⚠️ [%d] %s - файл не является текстурой: %s" % [item.id, item.display_name, full_path])
				fail_count += 1
		else:
			# Пробуем альтернативные пути
			var found = _try_alternative_paths(item)
			if found:
				success_count += 1
			else:
				print("❌ [%d] %s - иконка не найдена" % [item.id, item.display_name])
				print("   Пробовали: %s" % full_path)
				fail_count += 1
	
	# Сохраняем базу данных
	var error = ResourceSaver.save(db, DATABASE_PATH)
	
	if error == OK:
		print("\n✅ База данных сохранена!")
	else:
		print("\n❌ Ошибка при сохранении базы данных: %d" % error)
	
	print("\n=== 📊 РЕЗУЛЬТАТ ===")
	print("   Привязано иконок: %d" % success_count)
	print("   Не найдено: %d" % fail_count)
	print("========================\n")


func _try_alternative_paths(item: GameItemData) -> bool:
	"""Пробует найти иконку по альтернативным путям"""
	var alternatives = [
		ICONS_BASE_PATH + item.internal_name + ".png",
		ICONS_BASE_PATH + item.internal_name.to_lower() + ".png",
		ICONS_BASE_PATH + "all/" + item.internal_name + ".png",
		"res://assets/icons/" + item.internal_name + ".png",
		"res://assets/ui/items/" + item.internal_name + ".png",
	]
	
	for path in alternatives:
		if ResourceLoader.exists(path):
			var texture = load(path)
			if texture is Texture2D:
				item.icon = texture
				print("✅ [%d] %s → %s (альтернативный путь)" % [item.id, item.display_name, path])
				return true
	
	return false
