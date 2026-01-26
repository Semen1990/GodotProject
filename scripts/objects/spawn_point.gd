extends Marker2D
class_name SpawnPoint

# ===========================================
# ТОЧКА СПАВНА v3 - ПРАВИЛЬНАЯ ЛОГИКА
# ===========================================
# Путь: res://scripts/objects/spawn_point.gd
#
# ЛОГИКА:
# - Работает ТОЛЬКО когда Global.spawn_point == spawn_point_id
# - НЕ трогает игрока при первом запуске уровня
# - PlayerSpawn в level.gd отвечает за начальную позицию

@export var spawn_point_id: String = ""


func _ready():
	if spawn_point_id.is_empty():
		spawn_point_id = name
	
	print("📍 SpawnPoint создан: '%s'" % spawn_point_id)
	
	# Ждём пока игрок создастся
	await get_tree().create_timer(0.15).timeout
	_try_spawn_player()


func _try_spawn_player():
	"""Перемещает игрока ТОЛЬКО если это нужная точка"""
	if not Global:
		return
	
	var target = Global.spawn_point
	
	# ВАЖНО: Работаем ТОЛЬКО если spawn_point совпадает с нашим ID
	# Если spawn_point пустой - НЕ трогаем игрока!
	if target.is_empty():
		print("📍 [%s] spawn_point пустой - пропускаем" % spawn_point_id)
		return
	
	if target != spawn_point_id:
		print("📍 [%s] Не наша точка (нужна '%s')" % [spawn_point_id, target])
		return
	
	# Это наша точка - перемещаем игрока
	var player = _find_player()
	
	if player:
		player.global_position = global_position
		print("📍 ✅ Игрок перемещён → '%s' (%s)" % [spawn_point_id, global_position])
		
		# Очищаем чтобы не сработало повторно
		Global.spawn_point = ""
	else:
		print("📍 ❌ Игрок не найден!")


func _find_player() -> Node2D:
	# Через Global
	if Global and Global.current_player:
		return Global.current_player
	
	# Через группу
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	
	# По имени
	var level = get_parent()
	if level:
		for child in level.get_children():
			if "player" in child.name.to_lower():
				return child
	
	return null
