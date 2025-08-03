extends RigidBody3D

var velocity: Vector3
var lifetime = 3.0

@onready var ghost_scene = preload("res://assets/3d/Ghost blue1/scene.gltf")
var ghost_instance: Node3D = null
var ghost_color: Color = Color(0, 0.5, 1, 1) # Default blue

func _ready():
	add_to_group("ghost_bullets")
	print("Ghost bullet created")

	# Remove default mesh if present
	if has_node("MeshInstance3D"):
		$MeshInstance3D.queue_free()

	# Instance ghost model as visual
	ghost_instance = ghost_scene.instantiate()
	ghost_instance.scale = Vector3(0.25, 0.25, 0.25)
	add_child(ghost_instance)
	ghost_instance.global_transform = global_transform
	_apply_ghost_color()

	# Set up physics
	gravity_scale = 0
	linear_damp = 0
	contact_monitor = true
	max_contacts_reported = 10

	# Connect collision signal
	body_entered.connect(_on_body_entered)

	# Auto-destroy after lifetime
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func _physics_process(_delta):
	linear_velocity = velocity

func set_ghost_color(color: Color):
	ghost_color = color
	_apply_ghost_color()

func _apply_ghost_color():
	if ghost_instance == null:
		return
	# Recursively set emission color on all MeshInstance3D nodes
	for child in ghost_instance.get_children():
		if child is MeshInstance3D:
			var mat = child.get_active_material(0)
			if mat == null:
				mat = StandardMaterial3D.new()
				child.set_surface_override_material(0, mat)
			mat.albedo_color = ghost_color
			mat.emission_enabled = true
			mat.emission = ghost_color
			mat.emission_energy = 2.5

func _on_body_entered(body):
	print("Ghost bullet hit: ", body.name, " Groups: ", body.get_groups())
	if body.is_in_group("player"):
		print("Ghost bullet hit player! Dealing damage.")
		# Damage player
		body.take_damage()
		queue_free()
	elif body.is_in_group("walls_3d"):
		print("Ghost bullet hit wall! Destroying bullet.")
		queue_free()
	else:
		print("Ghost bullet hit unknown object: ", body.name)
