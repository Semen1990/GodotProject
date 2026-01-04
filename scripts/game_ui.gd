extends CanvasLayer

# Ссылки на узлы
@onready var health_bar = $MainContainer/MainVertical/StatsContainer/HealthSection/HealthContainer/HealthBar
@onready var health_label = $MainContainer/MainVertical/StatsContainer/HealthSection/HealthLabel
@onready var mana_bar = $MainContainer/MainVertical/StatsContainer/ManaSection/ManaContainer/ManaBar
@onready var mana_label = $MainContainer/MainVertical/StatsContainer/ManaSection/ManaLabel
@onready var armor_value = $MainContainer/MainVertical/StatsContainer/ArmorSection/ArmorContainer/ArmorValue
@onready var armor_label = $MainContainer/MainVertical/StatsContainer/ArmorSection/ArmorLabel

@onready var health_section = $MainContainer/MainVertical/StatsContainer/HealthSection
@onready var mana_section = $MainContainer/MainVertical/StatsContainer/ManaSection
@onready var armor_section = $MainContainer/MainVertical/StatsContainer/ArmorSection
@onready var keys_container = $MainContainer/MainVertical/KeysContainer

# Массив для ключей
var key_icons = []

# Характеристики
var current_stats = {
	"health": 100,
	"max_health": 100,
	"mana": 50,
	"max_mana": 50,
	"armor": 0
}

func _ready():
	print("🎮 Game UI загружен")
	
	# Проверяем что все узлы найдены
	print("Проверка узлов:")
	print("  HealthBar: ", health_bar != null)
	print("  ManaBar: ", mana_bar != null)
	print("  ArmorValue: ", armor_value != null)
	
	# Настраиваем временные текстуры
	setup_temporary_textures()
	
	# Инициализируем UI с тестовыми значениями
	update_ui_display()
	
	# Инициализируем ключи
	call_deferred("initialize_keys")

func setup_temporary_textures():
	print("🎨 Настройка временных текстур")
	
	# HealthBar - красный
	if health_bar:
		var health_style = StyleBoxFlat.new()
		health_style.bg_color = Color.RED
		health_bar.add_theme_stylebox_override("fill", health_style)
		
		var health_bg_style = StyleBoxFlat.new()
		health_bg_style.bg_color = Color.DARK_RED
		health_bar.add_theme_stylebox_override("background", health_bg_style)
	
	# ManaBar - синий
	if mana_bar:
		var mana_style = StyleBoxFlat.new()
		mana_style.bg_color = Color.BLUE
		mana_bar.add_theme_stylebox_override("fill", mana_style)
		
		var mana_bg_style = StyleBoxFlat.new()
		mana_bg_style.bg_color = Color.DARK_BLUE
		mana_bar.add_theme_stylebox_override("background", mana_bg_style)

func initialize_keys():
	# Создаем 6 ключей
	for i in range(6):
		var key_container = VBoxContainer.new()
		key_container.custom_minimum_size = Vector2(40, 50)
		
		var key_icon = TextureRect.new()
		key_icon.custom_minimum_size = Vector2(32, 32)
		key_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		
		var key_label = Label.new()
		key_label.text = "0"
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		key_container.add_child(key_icon)
		key_container.add_child(key_label)
		keys_container.add_child(key_container)
		
		key_icons.append({
			"icon": key_icon,
			"label": key_label
		})
	
	print("🔑 Инициализировано ключей: ", key_icons.size())

func update_ui_display():
	# Обновляем полосы
	if health_bar:
		health_bar.max_value = current_stats["max_health"]
		health_bar.value = current_stats["health"]
	
	if mana_bar:
		mana_bar.max_value = current_stats["max_mana"]
		mana_bar.value = current_stats["mana"]
	
	# Обновляем текстовые значения
	if health_label:
		health_label.text = "ЗДОРОВЬЕ\n%d/%d" % [current_stats["health"], current_stats["max_health"]]
	if mana_label:
		mana_label.text = "МАНА\n%d/%d" % [current_stats["mana"], current_stats["max_mana"]]
	if armor_value:
		armor_value.text = str(current_stats["armor"])
	if armor_label:
		armor_label.text = "БРОНЯ\n%d" % current_stats["armor"]

# Функции для обновления значений
func update_health(new_health: int):
	current_stats["health"] = clamp(new_health, 0, current_stats["max_health"])
	update_ui_display()
	print("❤️ Здоровье обновлено: ", current_stats["health"])

func update_mana(new_mana: int):
	current_stats["mana"] = clamp(new_mana, 0, current_stats["max_mana"])
	update_ui_display()
	print("🔵 Мана обновлена: ", current_stats["mana"])

func update_armor(new_armor: int):
	current_stats["armor"] = max(0, new_armor)
	update_ui_display()
	print("🛡️ Броня обновлена: ", current_stats["armor"])

# Функция для установки характеристик персонажа
func setup_character_ui(character_stats: Dictionary):
	current_stats = character_stats.duplicate()
	update_ui_display()
	print("🔄 UI настроен для персонажа")

# Функции для работы с ключами
func update_keys(key_counts: Array):
	for i in range(min(6, key_counts.size())):
		var key_data = key_icons[i]
		key_data["label"].text = str(key_counts[i])
	
	print("🔑 Ключи обновлены: ", key_counts)
