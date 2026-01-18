@tool
class_name InventoryEnums
extends RefCounted
## Все перечисления для системы инвентаря.
## Используются в ItemData, InventoryManager, EquipmentSystem.
##
## Путь: res://scripts/inventory/core/inventory_enums.gd

# ===========================================
# КАТЕГОРИИ ПРЕДМЕТОВ
# ===========================================

## Основная категория предмета
enum ItemCategory {
	EQUIPMENT,      ## Экипировка (броня, оружие)
	CONSUMABLE,     ## Расходники (зелья, еда)
	ARTIFACT,       ## Артефакты (пассивные эффекты)
	MATERIAL,       ## Материалы (для крафта)
	QUEST_ITEM,     ## Квестовые предметы
	MISC,           ## Прочее
}


## Подкатегория экипировки
enum EquipmentType {
	NONE,           ## Не экипировка
	HELMET,         ## Шлем
	ARMOR,          ## Доспех
	PANTS,          ## Штаны
	BOOTS,          ## Сапоги
	GLOVES,         ## Перчатки
	SWORD,          ## Меч
	AXE,            ## Топор
	MACE,           ## Булава
	DAGGER,         ## Кинжал
	STAFF,          ## Посох
	WAND,           ## Жезл
	BOW,            ## Лук
	SHIELD,         ## Щит
	ORB,            ## Орб
	TOME,           ## Том/Книга
	NECKLACE,       ## Ожерелье
	EARRING,        ## Серьга
	RING,           ## Кольцо
}


## Подкатегория расходников
enum ConsumableType {
	NONE,           ## Не расходник
	POTION_HP,      ## Зелье здоровья
	POTION_MANA,    ## Зелье маны
	POTION_BUFF,    ## Зелье с баффом
	FOOD,           ## Еда
	SCROLL,         ## Свиток заклинания
	BOMB,           ## Бомба/Граната
}

# ===========================================
# СЛОТЫ ЭКИПИРОВКИ
# ===========================================

## Слот экипировки на персонаже
enum EquipSlot {
	NONE = 0,           ## Не экипируется
	
	# Броня
	HEAD = 1,           ## Голова
	BODY = 2,           ## Туловище
	LEGS = 3,           ## Штаны
	FEET = 4,           ## Сапоги
	HANDS = 5,          ## Перчатки
	
	# Оружие
	MAIN_HAND = 6,      ## Основная рука
	OFF_HAND = 7,       ## Вторая рука
	
	# Украшения
	NECKLACE = 8,       ## Ожерелье
	EARRING_1 = 9,      ## Серьга левая
	EARRING_2 = 10,     ## Серьга правая
	RING_1 = 11,        ## Кольцо 1
	RING_2 = 12,        ## Кольцо 2
	RING_3 = 13,        ## Кольцо 3
	RING_4 = 14,        ## Кольцо 4
	RING_5 = 15,        ## Кольцо 5
	RING_6 = 16,        ## Кольцо 6
	RING_7 = 17,        ## Кольцо 7
	RING_8 = 18,        ## Кольцо 8
	
	# Артефакты
	ARTIFACT_1 = 19,    ## Слот артефакта 1
	ARTIFACT_2 = 20,    ## Слот артефакта 2
	ARTIFACT_3 = 21,    ## Слот артефакта 3
	ARTIFACT_4 = 22,    ## Слот артефакта 4
	
	# Особые
	RELIC = 23,         ## Реликвия (уникальный слот)
}


## Группы слотов (для UI и логики)
enum SlotGroup {
	ARMOR,          ## Броня (HEAD, BODY, LEGS, FEET, HANDS)
	WEAPONS,        ## Оружие (MAIN_HAND, OFF_HAND)
	JEWELRY,        ## Украшения (NECKLACE, EARRINGS, RINGS)
	ARTIFACTS,      ## Артефакты
	SPECIAL,        ## Особые (RELIC)
}

# ===========================================
# РЕДКОСТЬ
# ===========================================

## Редкость предмета
enum ItemRarity {
	COMMON = 0,         ## Обычный (серый)
	UNCOMMON = 1,       ## Необычный (зелёный)
	RARE = 2,           ## Редкий (синий)
	EPIC = 3,           ## Эпический (фиолетовый)
	LEGENDARY = 4,      ## Легендарный (оранжевый)
	MYTHIC = 5,         ## Мифический (красный/золотой)
}

# ===========================================
# ЭФФЕКТЫ
# ===========================================

## Тип эффекта предмета
enum EffectType {
	NONE = 0,
	
	# === Мгновенные эффекты ===
	INSTANT_HEAL_HP = 10,       ## Мгновенное лечение HP
	INSTANT_HEAL_MANA = 11,     ## Мгновенное восстановление маны
	INSTANT_DAMAGE = 12,        ## Мгновенный урон (бомбы)
	
	# === Временные баффы ===
	BUFF_ARMOR = 20,            ## +Броня на время
	BUFF_DAMAGE = 21,           ## +Урон на время
	BUFF_SPEED = 22,            ## +Скорость на время
	BUFF_CRIT_CHANCE = 23,      ## +Шанс крита на время
	BUFF_ATTACK_SPEED = 24,     ## +Скорость атаки на время
	BUFF_REGEN_HP = 25,         ## Регенерация HP на время
	BUFF_REGEN_MANA = 26,       ## Регенерация маны на время
	
	# === Пассивные статы (пока экипировано) ===
	STAT_MAX_HP = 50,           ## +Максимальное HP
	STAT_MAX_MANA = 51,         ## +Максимальная мана
	STAT_ARMOR = 52,            ## +Броня
	STAT_DAMAGE = 53,           ## +Урон
	STAT_SPEED = 54,            ## +Скорость передвижения
	STAT_CRIT_CHANCE = 55,      ## +Шанс критического удара
	STAT_CRIT_DAMAGE = 56,      ## +Урон критического удара
	STAT_ATTACK_SPEED = 57,     ## +Скорость атаки
	STAT_BLOCK_CHANCE = 58,     ## +Шанс блока
	STAT_DODGE_CHANCE = 59,     ## +Шанс уклонения
	
	# === Специальные эффекты ===
	SPECIAL_DOUBLE_JUMP = 100,  ## Двойной прыжок
	SPECIAL_LIFESTEAL = 101,    ## Вампиризм (% урона в HP)
	SPECIAL_DAMAGE_REFLECT = 102, ## Отражение урона
	SPECIAL_REVIVAL = 103,      ## Возрождение после смерти
	SPECIAL_THORNS = 104,       ## Шипы (урон атакующему)
	SPECIAL_IMMUNITY = 105,     ## Иммунитет к эффектам
	SPECIAL_EXTRA_SLOTS = 106,  ## Дополнительные слоты инвентаря
}


## Как применяется эффект
enum EffectApplication {
	PASSIVE,        ## Постоянный (пока экипировано)
	ON_USE,         ## При использовании
	ON_HIT,         ## При ударе
	ON_TAKE_DAMAGE, ## При получении урона
	ON_KILL,        ## При убийстве
	ON_LOW_HP,      ## При низком HP (условие)
}

# ===========================================
# КЛАССЫ ПЕРСОНАЖЕЙ
# ===========================================

## Класс персонажа (для ограничений)
enum CharacterClass {
	ANY = 0,        ## Любой класс
	WARRIOR = 1,    ## Воин
	PALADIN = 2,    ## Паладин
	ROGUE = 3,      ## Разбойник
	BERSERK = 4,    ## Берсерк
	MAGE = 5,       ## Маг (будущее)
}

# ===========================================
# ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
# ===========================================

## Цвета редкости
const RARITY_COLORS = {
	ItemRarity.COMMON: Color("#9d9d9d"),      # Серый
	ItemRarity.UNCOMMON: Color("#1eff00"),    # Зелёный
	ItemRarity.RARE: Color("#0070dd"),        # Синий
	ItemRarity.EPIC: Color("#a335ee"),        # Фиолетовый
	ItemRarity.LEGENDARY: Color("#ff8000"),   # Оранжевый
	ItemRarity.MYTHIC: Color("#e6cc80"),      # Золотой
}


## Названия редкости (русские)
const RARITY_NAMES = {
	ItemRarity.COMMON: "Обычный",
	ItemRarity.UNCOMMON: "Необычный",
	ItemRarity.RARE: "Редкий",
	ItemRarity.EPIC: "Эпический",
	ItemRarity.LEGENDARY: "Легендарный",
	ItemRarity.MYTHIC: "Мифический",
}


## Названия слотов (русские)
const SLOT_NAMES = {
	EquipSlot.NONE: "Нет",
	EquipSlot.HEAD: "Голова",
	EquipSlot.BODY: "Туловище",
	EquipSlot.LEGS: "Штаны",
	EquipSlot.FEET: "Сапоги",
	EquipSlot.HANDS: "Перчатки",
	EquipSlot.MAIN_HAND: "Основная рука",
	EquipSlot.OFF_HAND: "Вторая рука",
	EquipSlot.NECKLACE: "Ожерелье",
	EquipSlot.EARRING_1: "Серьга (Л)",
	EquipSlot.EARRING_2: "Серьга (П)",
	EquipSlot.RING_1: "Кольцо 1",
	EquipSlot.RING_2: "Кольцо 2",
	EquipSlot.RING_3: "Кольцо 3",
	EquipSlot.RING_4: "Кольцо 4",
	EquipSlot.RING_5: "Кольцо 5",
	EquipSlot.RING_6: "Кольцо 6",
	EquipSlot.RING_7: "Кольцо 7",
	EquipSlot.RING_8: "Кольцо 8",
	EquipSlot.ARTIFACT_1: "Артефакт 1",
	EquipSlot.ARTIFACT_2: "Артефакт 2",
	EquipSlot.ARTIFACT_3: "Артефакт 3",
	EquipSlot.ARTIFACT_4: "Артефакт 4",
	EquipSlot.RELIC: "Реликвия",
}


## Возвращает цвет редкости
static func get_rarity_color(rarity: ItemRarity) -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)


## Возвращает название редкости
static func get_rarity_name(rarity: ItemRarity) -> String:
	return RARITY_NAMES.get(rarity, "Неизвестно")


## Возвращает название слота
static func get_slot_name(slot: EquipSlot) -> String:
	return SLOT_NAMES.get(slot, "Неизвестно")


## Проверяет, является ли слот слотом для колец
static func is_ring_slot(slot: EquipSlot) -> bool:
	return slot >= EquipSlot.RING_1 and slot <= EquipSlot.RING_8


## Проверяет, является ли слот слотом для артефактов
static func is_artifact_slot(slot: EquipSlot) -> bool:
	return slot >= EquipSlot.ARTIFACT_1 and slot <= EquipSlot.ARTIFACT_4


## Проверяет, является ли слот слотом для серёг
static func is_earring_slot(slot: EquipSlot) -> bool:
	return slot == EquipSlot.EARRING_1 or slot == EquipSlot.EARRING_2


## Возвращает все слоты указанной группы
static func get_slots_in_group(group: SlotGroup) -> Array[EquipSlot]:
	var slots: Array[EquipSlot] = []
	
	match group:
		SlotGroup.ARMOR:
			slots = [EquipSlot.HEAD, EquipSlot.BODY, EquipSlot.LEGS, 
					 EquipSlot.FEET, EquipSlot.HANDS]
		SlotGroup.WEAPONS:
			slots = [EquipSlot.MAIN_HAND, EquipSlot.OFF_HAND]
		SlotGroup.JEWELRY:
			slots = [EquipSlot.NECKLACE, EquipSlot.EARRING_1, EquipSlot.EARRING_2]
			for i in range(8):
				slots.append(EquipSlot.RING_1 + i)
		SlotGroup.ARTIFACTS:
			slots = [EquipSlot.ARTIFACT_1, EquipSlot.ARTIFACT_2, 
					 EquipSlot.ARTIFACT_3, EquipSlot.ARTIFACT_4]
		SlotGroup.SPECIAL:
			slots = [EquipSlot.RELIC]
	
	return slots


## Возвращает допустимые слоты для типа экипировки
static func get_valid_slots_for_equipment(equip_type: EquipmentType) -> Array[EquipSlot]:
	match equip_type:
		EquipmentType.HELMET:
			return [EquipSlot.HEAD]
		EquipmentType.ARMOR:
			return [EquipSlot.BODY]
		EquipmentType.PANTS:
			return [EquipSlot.LEGS]
		EquipmentType.BOOTS:
			return [EquipSlot.FEET]
		EquipmentType.GLOVES:
			return [EquipSlot.HANDS]
		EquipmentType.SWORD, EquipmentType.AXE, EquipmentType.MACE, \
		EquipmentType.DAGGER, EquipmentType.STAFF, EquipmentType.WAND, \
		EquipmentType.BOW:
			return [EquipSlot.MAIN_HAND]
		EquipmentType.SHIELD, EquipmentType.ORB, EquipmentType.TOME:
			return [EquipSlot.OFF_HAND]
		EquipmentType.NECKLACE:
			return [EquipSlot.NECKLACE]
		EquipmentType.EARRING:
			return [EquipSlot.EARRING_1, EquipSlot.EARRING_2]
		EquipmentType.RING:
			var rings: Array[EquipSlot] = []
			for i in range(8):
				rings.append(EquipSlot.RING_1 + i)
			return rings
		_:
			return []
