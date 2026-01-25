extends Marker2D
class_name SpawnPoint

# ===========================================
# ТОЧКА СПАВНА
# ===========================================
# Путь: res://scripts/objects/spawn_point.gd
#
# Используется для спавна игрока при переходе между уровнями

@export var spawn_point_id: String = ""   ## ID точки (если пусто - имя узла)
@export var is_default: bool = false      ## Точка по умолчанию


func _ready():
	if spawn_point_id.is_empty():
		spawn_point_id = name
	
	print("📍 Точка спавна: %s (default: %s)" % [spawn_point_id, is_default])
	
	call_deferred("_check_spawn")


func _check_spawn():
	"""Проверяет нужно ли спавнить игрока здесь"""
	if not Global:
		return
	
	var target = Global.spawn_point
	
	# Спавним если это наша точка ИЛИ точка по умолчанию и нет конкретной
	if target == spawn_point_id or (target.is_empty() and is_default):
		_spawn_player_here()


func _spawn_player_here():
	"""Перемещает игрока к этой точке"""
	var player = _find_player()
	
	if player:
		player.global_position = global_position
		print("📍 Игрок спавнен: %s → %s" % [spawn_point_id, global_position])
		
		# Очищаем spawn_point
		if Global:
			Global.spawn_point = ""


func _find_player() -> Node2D:
	if Global and Global.current_player:
		return Global.current_player
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	
	return null
