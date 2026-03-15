extends Control

func _ready():
	# Эта функция запускается при загрузке сцены
	print("Главное меню загружено!")
	
	# Устанавливаем состояние для меню паузы
	#var pause_ui = get_node_or_null("/root/PauseUI")
	#if pause_ui:
		#pause_ui.set_main_menu_state(true)
		#print("PauseUI настроен для главного меню")
	#else:
		#print("PauseUI не найден")
	
	# Находим кнопки и подключаем сигналы
	var start_button = find_child("Start")  # Первая кнопка
	var exit_button = find_child("Exit") # Вторая кнопка
	
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
	if exit_button:
		exit_button.pressed.connect(_on_exit_button_pressed)


func _on_start_button_pressed():
	print("Начинаем игру!")
	# Убедимся, что пауза снята перед переходом
	get_tree().paused = false
	
	# Переход к выбору персонажа
	get_tree().change_scene_to_file("res://scenes/levels/character_selection.tscn")

func _on_exit_button_pressed():
	print("Выходим из игры")
	get_tree().quit()  # Закрываем игру
