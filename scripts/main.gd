extends Node3D

const SPEED: float = 6.0
const JUMP_VELOCITY: float = 6.5
const STICK_RADIUS_PX: float = 120.0
const CAM_OFFSET: Vector3 = Vector3(0.0, 6.0, 10.0)
const FLOOR_SIZE: Vector3 = Vector3(60.0, 0.4, 60.0)
const BLOCK_COUNT: int = 12
const WORLD_SEED: int = 42
const CAPSULE_RADIUS: float = 0.35
const CAPSULE_HEIGHT: float = 1.8

var player: CharacterBody3D
var camera: Camera3D
var _gravity: float = 9.8
var _stick: Vector2 = Vector2.ZERO
var _stick_origin: Vector2 = Vector2.ZERO
var _stick_index: int = -1
var _jump_requested: bool = false


func _ready() -> void:
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	_build_world()
	_build_player()
	_build_camera()


func _build_world() -> void:
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.name = "Floor"
	floor_body.position = Vector3(0.0, -FLOOR_SIZE.y * 0.5, 0.0)
	add_child(floor_body)
	_add_box_to(floor_body, Vector3.ZERO, FLOOR_SIZE, Color(0.35, 0.6, 0.35))

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = WORLD_SEED
	for _i: int in range(BLOCK_COUNT):
		var size: Vector3 = Vector3(
			rng.randf_range(2.0, 5.0),
			rng.randf_range(1.0, 4.0),
			rng.randf_range(2.0, 5.0))
		var pos: Vector3 = Vector3(
			rng.randf_range(-20.0, 20.0),
			size.y * 0.5,
			rng.randf_range(-20.0, 20.0))
		var color: Color = Color.from_hsv(rng.randf(), 0.5, 0.9)
		var block: StaticBody3D = StaticBody3D.new()
		block.name = "Block_%d" % _i
		block.position = pos
		add_child(block)
		_add_box_to(block, Vector3.ZERO, size, color)

	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.rotation = Vector3(deg_to_rad(-55.0), deg_to_rad(30.0), 0.0)
	add_child(light)


func _add_box_to(parent: Node3D, local_pos: Vector3, size: Vector3, color: Color) -> void:
	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = size
	shape_node.shape = box_shape
	shape_node.position = local_pos
	parent.add_child(shape_node)

	var mesh_node: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = size
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	box_mesh.material = mat
	mesh_node.mesh = box_mesh
	mesh_node.position = local_pos
	parent.add_child(mesh_node)


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	add_child(player)

	var half_h: float = CAPSULE_HEIGHT * 0.5
	var pivot_offset: Vector3 = Vector3(0.0, half_h, 0.0)

	var shape_node: CollisionShape3D = CollisionShape3D.new()
	var capsule_shape: CapsuleShape3D = CapsuleShape3D.new()
	capsule_shape.radius = CAPSULE_RADIUS
	capsule_shape.height = CAPSULE_HEIGHT
	shape_node.shape = capsule_shape
	shape_node.position = pivot_offset
	player.add_child(shape_node)

	var mesh_node: MeshInstance3D = MeshInstance3D.new()
	var capsule_mesh: CapsuleMesh = CapsuleMesh.new()
	capsule_mesh.radius = CAPSULE_RADIUS
	capsule_mesh.height = CAPSULE_HEIGHT
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.3, 0.3)
	capsule_mesh.material = mat
	mesh_node.mesh = capsule_mesh
	mesh_node.position = pivot_offset
	player.add_child(mesh_node)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "Camera"
	add_child(camera)
	camera.current = true
	camera.position = player.position + CAM_OFFSET


func _process(_delta: float) -> void:
	camera.position = player.position + CAM_OFFSET
	camera.look_at(player.position + Vector3(0.0, 1.0, 0.0), Vector3.UP)


func _input(event: InputEvent) -> void:
	var half_width: float = get_viewport().get_visible_rect().size.x * 0.5
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			if touch.position.x < half_width and _stick_index == -1:
				_stick_index = touch.index
				_stick_origin = touch.position
				_stick = Vector2.ZERO
			elif touch.position.x >= half_width:
				_jump_requested = true
		elif touch.index == _stick_index:
			_stick_index = -1
			_stick = Vector2.ZERO
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		if drag.index == _stick_index:
			var offset: Vector2 = drag.position - _stick_origin
			_stick = (offset / STICK_RADIUS_PX).limit_length(1.0)


func _physics_process(delta: float) -> void:
	var keys: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var move: Vector2 = _stick if _stick.length() > 0.05 else keys

	var vel: Vector3 = player.velocity
	vel.x = move.x * SPEED
	vel.z = move.y * SPEED
	if not player.is_on_floor():
		vel.y -= _gravity * delta
	elif _jump_requested or Input.is_action_just_pressed("ui_accept"):
		vel.y = JUMP_VELOCITY
	_jump_requested = false

	player.velocity = vel
	player.move_and_slide()
