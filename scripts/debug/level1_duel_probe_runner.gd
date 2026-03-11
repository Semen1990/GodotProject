extends SceneTree


func _initialize() -> void:
	var probe_scene: PackedScene = load("res://scenes/debug/level1_duel_probe.tscn") as PackedScene
	if probe_scene == null:
		push_error("Level1DuelProbeRunner: failed to load probe scene")
		quit(1)
		return

	var probe: Node = probe_scene.instantiate()
	root.add_child(probe)
