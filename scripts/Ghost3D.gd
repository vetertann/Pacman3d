extends CharacterBody3D

const SPEED = 6.0
const JUMP_VELOCITY = 8.0
const SHOOT_RANGE = 15.0
const SHOOT_COOLDOWN = 2.0
const JUMP_COOLDOWN = 3.0

@onready var ghost_model = $GhostModel/ghost
@onready var navigation_agent = $NavigationAgent3D
@onready var shoot_timer = $ShootTimer
@onready var muzzle = $Muzzle

var bullet_scene = preload("res://scenes/GhostBullet3D.tscn")
var player: CharacterBody3D
var health = 3
var shoot_timer_active = false
var jump_timer_active = false
var last_jump_time = 0.0

# Ghost color assignment (Blue, Orange, Cyan, Red)
var ghost_color: Color = Color(0, 0.5, 1, 1) # Default blue

# Kill sound player
var kill_sound: AudioStreamPlayer3D

# Get the gravity from the project settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# Add to ghost group for collision detection
	add_to_group("ghosts_3d")
	print("Ghost added to ghosts_3d group")
	
	# Assign unique color based on order in scene
	var ghost_colors = [Color(0, 0.5, 1, 1), Color(1, 0.5, 0, 1), Color(0, 1, 1, 1), Color(1, 0, 0, 1)] # Blue, Orange, Cyan, Red
	var ghosts = get_parent().get_children()
	var my_index = ghosts.find(self)
	if my_index >= 0 and my_index < ghost_colors.size():
		ghost_color = ghost_colors[my_index]
	print("Assigned ghost color:", ghost_color)

	# Set ghost color with emission for visibility
	var material = StandardMaterial3D.new()
	material.albedo_color = ghost_color
	material.emission_enabled = true
	material.emission = ghost_color
	material.emission_energy = 0.7
	material.metallic = 0.0
	material.roughness = 0.8
	
	# Apply material to all MeshInstance3D nodes in the ghost model using recursive approach
	if ghost_model:
		apply_material_recursive(ghost_model, material)
		print("Applied emission material to Ghost model")
	
	# Create and setup kill sound player
	kill_sound = AudioStreamPlayer3D.new()
	kill_sound.stream = load("res://assets/audio/sfx/killghost.mp3")
	kill_sound.volume_db = 0.0
	kill_sound.max_distance = 20.0
	add_child(kill_sound)
	print("Kill sound player created and configured")
	
	# Setup collision detection for bullets
	setup_collision_detection()

func setup_collision_detection():
	# Set up collision layers for ghost
	collision_layer = 2  # Ghost layer
	collision_mask = 1   # Can collide with default layer (bullets)
	
	# Ensure the ghost has a collision shape
	var collision_shape = get_node_or_null("CollisionShape3D")
	if not collision_shape:
		# Create CollisionShape3D for the CharacterBody3D
		collision_shape = CollisionShape3D.new()
		var shape = CapsuleShape3D.new()
		shape.radius = 0.8
		shape.height = 2.0
		collision_shape.shape = shape
		add_child(collision_shape)
		print("Created CollisionShape3D for ghost CharacterBody3D")
	
	print("Ghost collision detection setup complete")

func apply_material_recursive(node: Node, material: StandardMaterial3D):
	# Apply material to current node if it's a MeshInstance3D
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		# Override all surface materials
		if mesh_instance.mesh:
			for i in range(mesh_instance.mesh.get_surface_count()):
				mesh_instance.set_surface_override_material(i, material)
		print("Applied material to Ghost MeshInstance3D: ", node.name)
	
	# Recursively check all children
	for child in node.get_children():
		apply_material_recursive(child, material)
	
	# Find 3D player specifically
	player = get_tree().get_first_node_in_group("player_3d")
	
	# Set up shoot timer
	shoot_timer.wait_time = SHOOT_COOLDOWN
	shoot_timer.one_shot = true
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	
	add_to_group("ghosts_3d")

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0  # Stop falling when on ground
	
	if player:
		var distance_to_player = global_position.distance_to(player.global_position)
		var current_time = Time.get_ticks_msec() / 1000.0
		
		# Simple direct movement towards player (no navigation for now)
		var direction_to_player = (player.global_position - global_position).normalized()
		
		# Only move on X and Z axes, keep Y for gravity
		velocity.x = direction_to_player.x * SPEED
		velocity.z = direction_to_player.z * SPEED
		
		# Jump if player is above or to reach player better
		var height_diff = player.global_position.y - global_position.y
		if is_on_floor() and height_diff > 1.0 and current_time - last_jump_time > JUMP_COOLDOWN:
			velocity.y = JUMP_VELOCITY
			last_jump_time = current_time
			print("Ghost jumping to reach player!")
		
		# Random jump for dynamic movement
		if is_on_floor() and distance_to_player > 5.0 and randf() < 0.02 and current_time - last_jump_time > JUMP_COOLDOWN:
			velocity.y = JUMP_VELOCITY * 0.8  # Slightly lower jump for variety
			last_jump_time = current_time
		
		# Look at player
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
		
	
	# Move the ghost
	move_and_slide()
	
	# Check for bullet collisions after movement
	if Engine.get_process_frames() % 60 == 0:  # Every 60 frames
		print("Ghost physics process running at position: ", global_position)
	check_bullet_collisions()
	
	# Handle shooting - DISABLED per user request
	# if player and global_position.distance_to(player.global_position) <= SHOOT_RANGE:
	#	if not shoot_timer_active:
	#		shoot_at_player()

func check_bullet_collisions():
	# Get all bullets in the scene
	var bullets = get_tree().get_nodes_in_group("bullets")
	print("Ghost checking for bullets. Found: ", bullets.size(), " bullets")
	
	for bullet in bullets:
		if bullet and is_instance_valid(bullet):
			# Check distance between ghost and bullet
			var distance = global_position.distance_to(bullet.global_position)
			print("Distance to bullet: ", distance, " at position: ", bullet.global_position)
			if distance < 2.0:  # Increased collision threshold for easier testing
				print("*** GHOST HIT BY BULLET! Distance: ", distance, " ***")
				take_damage()
				bullet.queue_free()
				break  # Only handle one collision per frame

func shoot_at_player():
	if not player:
		return
	
	print("Ghost shooting at player!")
	var bullet = bullet_scene.instantiate()
	# Add bullet to the shooter game scene
	get_parent().get_parent().add_child(bullet)
	bullet.global_position = muzzle.global_position
	
	# Set bullet color to this ghost's color
	if bullet.has_method("set_ghost_color"):
		bullet.set_ghost_color(ghost_color)
	
	var direction = (player.global_position - muzzle.global_position).normalized()
	bullet.look_at(muzzle.global_position + direction, Vector3.UP)
	bullet.velocity = direction * 40.0
	
	print("Ghost bullet created at: ", bullet.global_position, " targeting: ", player.global_position, " color: ", ghost_color)
	
	# Start cooldown
	shoot_timer_active = true
	shoot_timer.start()

func _on_shoot_timer_timeout():
	shoot_timer_active = false

func take_damage():
	health -= 1
	print("Ghost took damage! Health now: ", health)
	if health <= 0:
		print("Ghost health reached 0, dying...")
		die()

func die():
	print("*** GHOST DIE FUNCTION CALLED! ***")
	
	# Play kill sound
	if kill_sound and kill_sound.stream:
		print("Playing kill sound...")
		kill_sound.play()
		# Create a timer instead of await to avoid potential issues
		var timer = Timer.new()
		timer.wait_time = 1.0  # Wait 1 second for sound
		timer.one_shot = true
		add_child(timer)
		timer.timeout.connect(_finish_death)
		timer.start()
	else:
		print("No kill sound available, destroying immediately")
		_finish_death()

func _finish_death():
	print("*** GHOST BEING DESTROYED ***")
	# Notify game that ghost was defeated
	get_tree().call_group("player", "_on_ghost_hit")
	queue_free()

func _on_area_3d_body_entered(body):
	print("Ghost collision detected with: ", body.name, " Groups: ", body.get_groups())
	if body.is_in_group("bullets"):
		print("Ghost taking damage from bullet!")
		take_damage()
		body.queue_free()
	else:
		print("Body is not in bullets group")
