extends GameplayLevelBase


func _setup_level_after_player_spawn() -> void:
	_setup_chests()


func _setup_chests() -> void:
	var chest_index: int = 0
	var objects_root: Node = get_objects_root()

	for child in objects_root.get_children():
		if child is Chest:
			chest_index += 1
			_configure_chest(child as Chest, chest_index)

			if Global and Global.is_chest_opened(child.name) and child.has_method("restore_opened_chest"):
				child.restore_opened_chest()


func _configure_chest(chest: Chest, index: int) -> void:
	match index:
		1:
			chest.setup_artifacts(["hermes_wings", "phoenix_feather"])
		2:
			chest.setup_items(
				[1, 2, 3, 4, 101, 102, 103, 104, 105],
				[2, 2, 1, 1, 1, 1, 1, 1, 1]
			)
		_:
			chest.setup_items([1, 2], [2, 2])
