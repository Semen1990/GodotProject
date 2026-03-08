extends CanvasLayer

func _ready() -> void:
	var panel = $Panel
	if not panel:
		return

	var center_container = $Panel/CenterContainer
	var vbox = $Panel/CenterContainer/VBoxContainer
	if not (center_container and vbox):
		return

	var continue_btn = $Panel/CenterContainer/VBoxContainer/ContinueBtn
	var menu_btn = $Panel/CenterContainer/VBoxContainer/MenuBtn

	if continue_btn:
		continue_btn.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		if not continue_btn.pressed.is_connected(_on_continue_pressed):
			continue_btn.pressed.connect(_on_continue_pressed)

	if menu_btn:
		menu_btn.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		if not menu_btn.pressed.is_connected(_on_menu_pressed):
			menu_btn.pressed.connect(_on_menu_pressed)

	hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			close_pause_menu()
		else:
			open_pause_menu()

func open_pause_menu() -> void:
	show()
	get_tree().paused = true

func close_pause_menu() -> void:
	hide()
	get_tree().paused = false

func _on_continue_pressed() -> void:
	close_pause_menu()

func _on_menu_pressed() -> void:
	get_tree().paused = false

	if Inventory:
		Inventory.clear_all()

	Global.reset_all_for_new_game()
	get_tree().call_deferred("change_scene_to_file", "res://scenes/ui/main_menu.tscn")
