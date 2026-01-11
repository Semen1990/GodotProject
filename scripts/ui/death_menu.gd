extends CanvasLayer

class_name DeathMenu

# ===========================================
# МЕНЮ СМЕРТИ (ПОЛНАЯ ВЕРСИЯ)
# ===========================================

# Сигналы
signal main_menu_requested
signal restart_requested
signal revive_requested(data: Dictionary)

# Режимы меню
enum MenuMode { NORMAL, REVIVAL }
var current_mode: MenuMode = MenuMode.NORMAL

# Данные
var has_revival_artifact: bool = false
var current_revival_artifact_id: String = ""
var death_statistics: Dictionary = {}
var player_last_room: String = ""
var player_last_position: Vector2 = Vector2.ZERO

# Состояние подтверждения
var is_confirmation_active: bool = false
var pending_action: String = ""
var countdown_time: float = 6.0
var current_countdown: float = 6.0

# Константы
const STATS_DISPLAY_TIME: float = 6.0

# Ноды (будут созданы программно)
var background: ColorRect
var main_container: CenterContainer
var main_content: VBoxContainer
var death_title: Label
var stats_panel: PanelContainer
var stats_container: VBoxContainer
var buttons_container: HBoxContainer
var main_menu_button: Button
var restart_button: Button
var revive_button: Button
var revival_panel: PanelContainer
var confirmation_dialog: PanelContainer
var confirmation_text: Label
var countdown_bar: ProgressBar
var confirm_yes_button: Button
var confirm_no_button: Button
var countdown_timer: Timer

func _ready():
	print("=== 💀 МЕНЮ СМЕРТИ ИНИЦИАЛИЗАЦИЯ ===")
	
	# Создаём UI программно
	_create_ui()
	
	# Скрываем по умолчанию
	hide()
	
	# Не ставим на паузу это меню
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	print("=== ✅ МЕНЮ СМЕРТИ ГОТОВО ===")

func _create_ui():
	"""Создаёт весь UI программно"""
	
	# === ФОНОВЫЙ ЗАТЕМНИТЕЛЬ ===
	background = ColorRect.new()
	background.name = "Background"
	background.color = Color(0, 0, 0, 0.85)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	
	# === ГЛАВНЫЙ КОНТЕЙНЕР ===
	main_container = CenterContainer.new()
	main_container.name = "MainContainer"
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.add_child(main_container)
	
	# === ОСНОВНОЙ КОНТЕНТ ===
	main_content = VBoxContainer.new()
	main_content.name = "MainContent"
	main_content.custom_minimum_size = Vector2(500, 400)
	main_content.add_theme_constant_override("separation", 20)
	main_container.add_child(main_content)
	
	# === ЗАГОЛОВОК ===
	death_title = Label.new()
	death_title.name = "DeathTitle"
	death_title.text = "ВЫ ПОГИБЛИ"
	death_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_title.add_theme_font_size_override("font_size", 48)
	death_title.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1))
	main_content.add_child(death_title)
	
	# === ПАНЕЛЬ СТАТИСТИКИ ===
	_create_stats_panel()
	
	# === ПАНЕЛЬ ВОЗРОЖДЕНИЯ ===
	_create_revival_panel()
	
	# === КНОПКИ ===
	_create_buttons()
	
	# === ДИАЛОГ ПОДТВЕРЖДЕНИЯ ===
	_create_confirmation_dialog()
	
	# === ТАЙМЕР ===
	countdown_timer = Timer.new()
	countdown_timer.name = "CountdownTimer"
	countdown_timer.one_shot = false
	countdown_timer.timeout.connect(_on_countdown_tick)
	add_child(countdown_timer)

func _create_stats_panel():
	"""Создаёт панель статистики"""
	stats_panel = PanelContainer.new()
	stats_panel.name = "StatsPanel"
	stats_panel.custom_minimum_size = Vector2(450, 200)
	
	# Стиль панели
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_color = Color(0.5, 0.1, 0.1)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(15)
	stats_panel.add_theme_stylebox_override("panel", style)
	
	main_content.add_child(stats_panel)
	
	# Контейнер статистики
	stats_container = VBoxContainer.new()
	stats_container.name = "StatsContainer"
	stats_container.add_theme_constant_override("separation", 10)
	stats_panel.add_child(stats_container)

func _create_revival_panel():
	"""Создаёт панель возрождения"""
	revival_panel = PanelContainer.new()
	revival_panel.name = "RevivalPanel"
	revival_panel.custom_minimum_size = Vector2(400, 100)
	revival_panel.visible = false
	
	# Стиль
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.1, 0.95)
	style.border_color = Color(0.2, 0.8, 0.2)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(15)
	revival_panel.add_theme_stylebox_override("panel", style)
	
	main_content.add_child(revival_panel)
	
	# Содержимое
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	revival_panel.add_child(hbox)
	
	var icon = Label.new()
	icon.name = "ArtifactIcon"
	icon.text = "🔮"
	icon.add_theme_font_size_override("font_size", 40)
	hbox.add_child(icon)
	
	var vbox = VBoxContainer.new()
	hbox.add_child(vbox)
	
	var title = Label.new()
	title.text = "У ВАС ЕСТЬ ШАНС!"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	vbox.add_child(title)
	
	var artifact_name = Label.new()
	artifact_name.name = "ArtifactName"
	artifact_name.text = "Перо Феникса"
	artifact_name.add_theme_font_size_override("font_size", 18)
	artifact_name.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	vbox.add_child(artifact_name)

func _create_buttons():
	"""Создаёт кнопки"""
	buttons_container = HBoxContainer.new()
	buttons_container.name = "ButtonsContainer"
	buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_container.add_theme_constant_override("separation", 20)
	main_content.add_child(buttons_container)
	
	# Кнопка возрождения (скрыта по умолчанию)
	revive_button = Button.new()
	revive_button.name = "ReviveButton"
	revive_button.text = "🔮 ВОЗРОДИТЬСЯ"
	revive_button.custom_minimum_size = Vector2(180, 50)
	revive_button.visible = false
	revive_button.pressed.connect(_on_revive_pressed)
	_style_button(revive_button, Color(0.2, 0.7, 0.2))
	buttons_container.add_child(revive_button)
	
	# Кнопка главного меню
	main_menu_button = Button.new()
	main_menu_button.name = "MainMenuButton"
	main_menu_button.text = "🏠 В МЕНЮ"
	main_menu_button.custom_minimum_size = Vector2(150, 50)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	_style_button(main_menu_button, Color(0.5, 0.5, 0.5))
	buttons_container.add_child(main_menu_button)
	
	# Кнопка рестарта
	restart_button = Button.new()
	restart_button.name = "RestartButton"
	restart_button.text = "🔄 ЗАНОВО"
	restart_button.custom_minimum_size = Vector2(150, 50)
	restart_button.pressed.connect(_on_restart_pressed)
	_style_button(restart_button, Color(0.6, 0.4, 0.2))
	buttons_container.add_child(restart_button)

func _style_button(button: Button, base_color: Color):
	"""Стилизует кнопку"""
	var normal = StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.set_corner_radius_all(5)
	normal.set_content_margin_all(10)
	button.add_theme_stylebox_override("normal", normal)
	
	var hover = StyleBoxFlat.new()
	hover.bg_color = base_color.lightened(0.2)
	hover.set_corner_radius_all(5)
	hover.set_content_margin_all(10)
	button.add_theme_stylebox_override("hover", hover)
	
	var pressed = StyleBoxFlat.new()
	pressed.bg_color = base_color.darkened(0.2)
	pressed.set_corner_radius_all(5)
	pressed.set_content_margin_all(10)
	button.add_theme_stylebox_override("pressed", pressed)
	
	button.add_theme_font_size_override("font_size", 18)

func _create_confirmation_dialog():
	"""Создаёт диалог подтверждения"""
	confirmation_dialog = PanelContainer.new()
	confirmation_dialog.name = "ConfirmationDialog"
	confirmation_dialog.custom_minimum_size = Vector2(400, 180)
	confirmation_dialog.visible = false
	
	# Центрируем
	confirmation_dialog.set_anchors_preset(Control.PRESET_CENTER)
	confirmation_dialog.position = Vector2(-200, -90)
	
	# Стиль
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.98)
	style.border_color = Color(0.9, 0.7, 0.1)
	style.set_border_width_all(4)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(20)
	confirmation_dialog.add_theme_stylebox_override("panel", style)
	
	background.add_child(confirmation_dialog)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	confirmation_dialog.add_child(vbox)
	
	# Текст предупреждения
	confirmation_text = Label.new()
	confirmation_text.name = "ConfirmationText"
	confirmation_text.text = "Вы потеряете артефакт возрождения!\nВы уверены?"
	confirmation_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirmation_text.add_theme_font_size_override("font_size", 18)
	confirmation_text.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	vbox.add_child(confirmation_text)
	
	# Прогресс-бар обратного отсчёта
	countdown_bar = ProgressBar.new()
	countdown_bar.name = "CountdownBar"
	countdown_bar.custom_minimum_size = Vector2(350, 20)
	countdown_bar.max_value = countdown_time
	countdown_bar.value = countdown_time
	countdown_bar.show_percentage = false
	vbox.add_child(countdown_bar)
	
	# Кнопки подтверждения
	var buttons = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 30)
	vbox.add_child(buttons)
	
	confirm_yes_button = Button.new()
	confirm_yes_button.text = "ДА, ВЫЙТИ"
	confirm_yes_button.custom_minimum_size = Vector2(120, 40)
	confirm_yes_button.pressed.connect(_on_confirm_yes)
	_style_button(confirm_yes_button, Color(0.7, 0.2, 0.2))
	buttons.add_child(confirm_yes_button)
	
	confirm_no_button = Button.new()
	confirm_no_button.text = "НЕТ"
	confirm_no_button.custom_minimum_size = Vector2(120, 40)
	confirm_no_button.pressed.connect(_on_confirm_no)
	_style_button(confirm_no_button, Color(0.2, 0.5, 0.2))
	buttons.add_child(confirm_no_button)

# ===========================================
# ПОКАЗ МЕНЮ
# ===========================================

func show_death_menu(statistics: Dictionary = {}, revival_artifact_id: String = ""):
	"""Показывает меню смерти"""
	print("\n💀 ПОКАЗ МЕНЮ СМЕРТИ")
	
	death_statistics = statistics
	current_revival_artifact_id = revival_artifact_id
	has_revival_artifact = revival_artifact_id != ""
	
	# Определяем режим
	if has_revival_artifact:
		current_mode = MenuMode.REVIVAL
		_setup_revival_mode()
	else:
		current_mode = MenuMode.NORMAL
		_setup_normal_mode()
	
	# Показываем меню
	show()
	
	# Ставим игру на паузу
	get_tree().paused = true
	
	# Фокус на кнопку
	if has_revival_artifact:
		revive_button.grab_focus()
	else:
		restart_button.grab_focus()

func _setup_normal_mode():
	"""Настройка обычного режима (без артефакта)"""
	death_title.text = "ВЫ ПОГИБЛИ"
	death_title.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1))
	
	# Показываем статистику
	stats_panel.visible = true
	_update_statistics()
	
	# Скрываем панель возрождения
	revival_panel.visible = false
	
	# Кнопки
	revive_button.visible = false
	main_menu_button.disabled = false
	restart_button.disabled = false

func _setup_revival_mode():
	"""Настройка режима с артефактом возрождения"""
	death_title.text = "ЕСТЬ ВТОРОЙ ШАНС!"
	death_title.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	
	# Скрываем статистику
	stats_panel.visible = false
	
	# Показываем панель возрождения
	revival_panel.visible = true
	_update_revival_info()
	
	# Кнопки
	revive_button.visible = true
	main_menu_button.disabled = false
	restart_button.disabled = false

func _update_statistics():
	"""Обновляет отображение статистики"""
	# Очищаем старую статистику
	for child in stats_container.get_children():
		child.queue_free()
	
	# Причина смерти
	var reason = death_statistics.get("death_reason", "Неизвестно")
	_add_stat_row("💀 Причина смерти:", reason, Color(0.9, 0.3, 0.3))
	
	# Разделитель
	_add_separator()
	
	# Собранные предметы
	var keys = death_statistics.get("keys_collected", 0)
	_add_stat_row("🔑 Ключей собрано:", str(keys), Color(1.0, 0.9, 0.2))
	
	var items = death_statistics.get("items_collected", 0)
	_add_stat_row("📦 Предметов найдено:", str(items), Color(0.5, 0.8, 1.0))
	
	var coins = death_statistics.get("coins_collected", 0)
	_add_stat_row("💰 Монет собрано:", str(coins), Color(1.0, 0.85, 0.0))
	
	# Разделитель
	_add_separator()
	
	# Убитые враги
	var simple_enemies = death_statistics.get("enemies_simple", 0)
	_add_stat_row("👹 Обычных врагов:", str(simple_enemies), Color(0.7, 0.7, 0.7))
	
	var elite_enemies = death_statistics.get("enemies_elite", 0)
	_add_stat_row("⚔️ Элитных врагов:", str(elite_enemies), Color(1.0, 0.6, 0.2))
	
	var bosses = death_statistics.get("enemies_boss", 0)
	_add_stat_row("👑 Боссов повержено:", str(bosses), Color(0.8, 0.2, 0.8))
	
	# Разделитель
	_add_separator()
	
	# Дополнительная статистика
	var time_played = death_statistics.get("time_played", 0.0)
	var minutes = int(time_played) / 60
	var seconds = int(time_played) % 60
	_add_stat_row("⏱️ Время игры:", "%d:%02d" % [minutes, seconds], Color(0.6, 0.8, 0.6))
	
	var rooms_visited = death_statistics.get("rooms_visited", 0)
	_add_stat_row("🚪 Комнат пройдено:", str(rooms_visited), Color(0.6, 0.6, 0.9))
	
	var damage_dealt = death_statistics.get("damage_dealt", 0)
	_add_stat_row("⚔️ Урона нанесено:", str(damage_dealt), Color(0.9, 0.5, 0.3))
	
	var damage_taken = death_statistics.get("damage_taken", 0)
	_add_stat_row("💔 Урона получено:", str(damage_taken), Color(0.9, 0.3, 0.3))

func _add_stat_row(label_text: String, value_text: String, color: Color):
	"""Добавляет строку статистики"""
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	stats_container.add_child(hbox)
	
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)
	
	var value = Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 16)
	value.add_theme_color_override("font_color", color)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(value)

func _add_separator():
	"""Добавляет разделительную линию"""
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 5)
	stats_container.add_child(sep)

func _update_revival_info():
	"""Обновляет информацию об артефакте возрождения"""
	var artifact_data = null
	if Global and Global.has_method("get_artifact_data"):
		artifact_data = Global.get_artifact_data(current_revival_artifact_id)
	
	var artifact_name_label = revival_panel.get_node("HBoxContainer/VBoxContainer/ArtifactName")
	if artifact_name_label and artifact_data:
		artifact_name_label.text = artifact_data.get("name", "Артефакт возрождения")

# ===========================================
# ОБРАБОТЧИКИ КНОПОК
# ===========================================

func _on_revive_pressed():
	"""Нажата кнопка возрождения"""
	print("🔮 Игрок выбрал возрождение!")
	
	# Снимаем паузу
	get_tree().paused = false
	
	# Скрываем меню
	hide()
	
	# Отправляем сигнал
	revive_requested.emit({
		"artifact_id": current_revival_artifact_id,
		"last_room": player_last_room,
		"last_position": player_last_position
	})

func _on_main_menu_pressed():
	"""Нажата кнопка главного меню"""
	if has_revival_artifact:
		_show_confirmation("main_menu")
	else:
		_go_to_main_menu()

func _on_restart_pressed():
	"""Нажата кнопка рестарта"""
	if has_revival_artifact:
		_show_confirmation("restart")
	else:
		_restart_game()

func _show_confirmation(action: String):
	"""Показывает диалог подтверждения"""
	pending_action = action
	is_confirmation_active = true
	
	# Обновляем текст
	var artifact_name = "артефакт возрождения"
	if Global and Global.has_method("get_artifact_data"):
		var data = Global.get_artifact_data(current_revival_artifact_id)
		if data:
			artifact_name = data.get("name", artifact_name)
	
	confirmation_text.text = "Вы потеряете " + artifact_name + "!\nВы уверены?"
	
	# Сбрасываем таймер
	current_countdown = countdown_time
	countdown_bar.value = countdown_time
	
	# Показываем диалог
	confirmation_dialog.visible = true
	confirm_no_button.grab_focus()
	
	# Запускаем таймер (автоотмена через 6 секунд)
	countdown_timer.start(0.1)

func _on_confirm_yes():
	"""Подтверждение выхода"""
	print("✅ Подтверждён выход")
	countdown_timer.stop()
	confirmation_dialog.visible = false
	
	# Показываем статистику перед выходом
	stats_panel.visible = true
	_update_statistics()
	revival_panel.visible = false
	revive_button.visible = false
	
	death_title.text = "ВЫ ПОГИБЛИ"
	death_title.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1))
	
	# Ждём и выполняем действие
	await get_tree().create_timer(STATS_DISPLAY_TIME).timeout
	
	if pending_action == "main_menu":
		_go_to_main_menu()
	elif pending_action == "restart":
		_restart_game()

func _on_confirm_no():
	"""Отмена выхода"""
	print("❌ Отмена выхода")
	countdown_timer.stop()
	confirmation_dialog.visible = false
	is_confirmation_active = false
	revive_button.grab_focus()

func _on_countdown_tick():
	"""Тик таймера обратного отсчёта"""
	current_countdown -= 0.1
	countdown_bar.value = current_countdown
	
	if current_countdown <= 0:
		# Автоматическая отмена
		_on_confirm_no()

func _go_to_main_menu():
	"""Переход в главное меню"""
	print("🏠 Переход в главное меню")
	get_tree().paused = false
	hide()
	
	# Сбрасываем статистику в Global
	if Global:
		Global.reset_artifacts()
	
	main_menu_requested.emit()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _restart_game():
	"""Перезапуск игры"""
	print("🔄 Перезапуск игры")
	get_tree().paused = false
	hide()
	
	# Сбрасываем статистику в Global
	if Global:
		Global.reset_artifacts()
	
	restart_requested.emit()
	get_tree().change_scene_to_file("res://scenes/levels/level1.tscn")

# ===========================================
# ВВОД
# ===========================================

func _input(event):
	if not visible:
		return
	
	# ESC - отмена подтверждения или выход в меню
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		if is_confirmation_active:
			_on_confirm_no()
		get_viewport().set_input_as_handled()
