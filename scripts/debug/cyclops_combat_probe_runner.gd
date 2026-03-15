extends SceneTree


func _initialize() -> void:
	var probe_scene: PackedScene = load("res://scenes/debug/cyclops_combat_probe.tscn") as PackedScene
	if probe_scene == null:
		push_error("CyclopsCombatProbeRunner: failed to load probe scene")
		quit(1)
		return

	var probe: Node = probe_scene.instantiate()
	root.add_child(probe)
