extends CanvasLayer

# ===========================================
# PAUSE MENU - ИСПРАВЛЕННАЯ ВЕРСИЯ
# ===========================================

func _ready():
	print("=== 🎮 МЕНЮ ПАУЗЫ ИНИЦИАЛИЗАЦИЯ ===")
	print("Корневой узел: ", name)
	print("Видимость: ", visible)
	
	# Проверяем существование всех узлов
	var panel = $Panel
	if panel:
		print("✅ Панель найдена")
	else:
		print("❌ Панель не найдена!")
		return
	
	var center_container = $Panel/CenterContainer
	var vbox = $Panel/CenterContainer/VBoxContainer
	
	if center_container and vbox:
		print("✅ Контейнеры найдены")
	else:
		print("❌ Контейнеры не найдены!")
		return
	
	# Проверяем кнопки
	var continue_btn = $Panel/CenterContainer/VBoxContainer/ContinueBtn
	var menu_btn = $Panel/CenterContainer/VBoxContainer/MenuBtn
	
	print("Кнопка 'Продолжить' найдена: ", continue_btn != null)
	print("Кнопка 'В главное меню' найдена: ", menu_btn != null)
	
	# Подключаем сигналы
	if continue_btn:
		continue_btn.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		if not continue_btn.pressed.is_connected(_on_continue_pressed):
			continue_btn.pressed.connect(_on_continue_pressed)
		print("✅ Сигнал 'Продолжить' подключен")
	
	if menu_btn:
		menu_btn.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		if not menu_btn.pressed.is_connected(_on_menu_pressed):
			menu_btn.pressed.connect(_on_menu_pressed)
		print("✅ Сигнал 'В главное меню' подключен")
	
	# Скрываем меню при загрузке
	hide()
	print("=== ✅ МЕНЮ ПАУЗЫ ГОТОВО ===")

func _input(event):
	if event.is_action_pressed("ui_cancel"): # Escape
		print("=== 🔄 ОБРАБОТКА ESC ===")
		print("Игра на паузе: ", get_tree().paused)
		print("Меню видимо: ", visible)
		
		if get_tree().paused:
			close_pause_menu()
		else:
			open_pause_menu()

func open_pause_menu():
	print("🔄 ОТКРЫВАЕМ МЕНЮ ПАУЗЫ")
	show()
	get_tree().paused = true
	print("Игра на паузе: ", get_tree().paused)

func close_pause_menu():
	print("🔄 ЗАКРЫВАЕМ МЕНЮ ПАУЗЫ")
	hide()
	get_tree().paused = false
	print("Игра на паузе: ", get_tree().paused)

func _on_continue_pressed():
	print("✅ НАЖАТА 'ПРОДОЛЖИТЬ'")
	close_pause_menu()

func _on_menu_pressed():
	print("✅ НАЖАТА 'В ГЛАВНОЕ МЕНЮ'")
	
	# ВАЖНО: Сначала снимаем паузу
	get_tree().paused = false
	
	# ВАЖНО: Полный сброс данных через Global
	Global.reset_all_for_new_game()
	
	# Безопасная смена сцены
	get_tree().call_deferred("change_scene_to_file", "res://scenes/ui/main_menu.tscn")
