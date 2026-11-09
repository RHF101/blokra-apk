extends SceneTree


func _initialize() -> void:
	var packed: PackedScene = load("res://main.tscn") as PackedScene
	assert(packed != null, "main.tscn gagal dimuat")
	var root_node: Node = packed.instantiate()
	get_root().add_child(root_node)
	assert(root_node.get_node_or_null("Player") != null, "Node Player tidak ada")
	print("VALIDATOR OK")
	quit(0)
