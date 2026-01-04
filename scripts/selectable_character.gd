extends CharacterBody2D

# Сигнал, который будет отправляться при клике на персонажа
signal character_clicked(character_name)

func _ready():
	# Проверяем, что у персонажа есть Area2D для обработки кликов
	if not has_node("Area2D"):
		push_warning("Персонаж " + name + " не имеет Area2D для обработки кликов!")

# Эта функция будет вызываться когда кликают на Area2D персонажа
func _on_area_2d_input_event(viewport, event, shape_idx):
	# Проверяем, что это нажатие левой кнопки мыши
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Кликнут персонаж: ", name)  # Для отладки
		emit_signal("character_clicked", name)  # Отправляем сигнал с именем этого персонажа
