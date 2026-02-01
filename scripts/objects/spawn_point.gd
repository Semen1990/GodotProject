extends Marker2D
class_name SpawnPoint

# ===========================================
# SPAWN POINT - ТОЧКА СПАВНА (ПРЕФАБ)
# ===========================================
# Путь: res://scripts/objects/SpawnPoint.gd

@export var spawn_point_id: String = ""


func _ready():
	if spawn_point_id.is_empty():
		spawn_point_id = name
	
	# Визуальная метка только в редакторе
	if Engine.is_editor_hint():
		modulate = Color.GREEN
