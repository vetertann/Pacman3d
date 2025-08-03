extends RigidBody3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var velocity: Vector3
var lifetime = 5.0

func _ready():
	add_to_group("bullets")
	print("Bullet created and added to bullets group at position: ", global_position)
	
	# Set up physics
	gravity_scale = 0
	linear_damp = 0
	contact_monitor = true
	max_contacts_reported = 10
	
	# Set up collision layers
	collision_layer = 1  # Bullet layer (default)
	collision_mask = 2   # Can collide with ghost layer
	
	# Connect collision signal
	body_entered.connect(_on_body_entered)
	
	# Auto-destroy after lifetime
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func _physics_process(delta):
	# Simple forward movement - no orientation needed for sphere
	linear_velocity = velocity
	# Debug: print bullet position every few frames
	if Engine.get_process_frames() % 30 == 0:  # Every 30 frames
		print("Bullet position: ", global_position, " velocity: ", linear_velocity)

func set_emission_intensity(intensity: float):
	# Set emission for glowing beam effect
	var mesh_node = get_node_or_null("MeshInstance3D")
	if mesh_node and mesh_node is MeshInstance3D:
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.0, 1.0, 1.0, 1.0)  # Bright cyan color
		material.emission_enabled = true
		material.emission = Color(0.0, 1.0, 1.0, 1.0)  # Full cyan emission
		material.emission_energy = intensity * 2.0  # Double the intensity
		mesh_node.material_override = material
	
	# Add a point light to make the beam actually glow
	var light = OmniLight3D.new()
	light.light_color = Color(0.0, 1.0, 1.0)  # Cyan light
	light.light_energy = intensity * 5.0  # Very bright
	light.omni_range = 3.0
	add_child(light)

func _on_body_entered(body):
	print("Bullet hit: ", body.name, " Groups: ", body.get_groups())
	if body.is_in_group("ghosts_3d"):
		print("Bullet hit ghost! Dealing damage.")
		body.take_damage()
		queue_free()
	elif body.is_in_group("walls_3d"):
		print("Bullet hit wall! Destroying bullet.")
		queue_free()
	else:
		print("Bullet hit unknown object: ", body.name)
		# Try to destroy bullet on any collision to prevent it from passing through
		queue_free()
