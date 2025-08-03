extends CharacterBody3D

signal ghost_defeated

const SPEED = 8.0
const JUMP_VELOCITY = 24.0
const MOUSE_SENSITIVITY = 0.002

@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D
@onready var muzzle = $CameraPivot/Camera3D/Muzzle
@onready var crosshair = $UI/Crosshair

# Bullet scene
var bullet_scene = preload("res://scenes/Bullet3D.tscn")

# Health system
var health = 100
var max_health = 100

# Ammo system
var ammo = 0
var max_ammo = 50

# Charge weapon system
var is_charging = false
var charge_time = 0.0
var max_charge_time = 2.0
var charge_audio: AudioStreamPlayer3D
var shot_audio: AudioStreamPlayer3D

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# Capture mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	add_to_group("player_3d")
	
	# Apply bright emission material to Pacman model for visibility
	var pacman_model = $PacmanModel/pacman
	if pacman_model:
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1, 1, 0.3, 1)
		material.emission_enabled = true
		material.emission = Color(1, 1, 0.5, 1)
		material.emission_energy = 0.7
		material.metallic = 0.0
		material.roughness = 0.5
		
		# Recursively apply material to all MeshInstance3D nodes in GLTF scene
		apply_material_recursive(pacman_model, material)
		print("Applied emission material to Pacman model")
	
	# Set up audio for charge weapon
	setup_weapon_audio()
	
	# Initialize ammo
	ammo = 10  # Start with some ammo
	update_ammo_ui()

func apply_material_recursive(node: Node, material: StandardMaterial3D):
	# Apply material to current node if it's a MeshInstance3D
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		# Override all surface materials
		if mesh_instance.mesh:
			for i in range(mesh_instance.mesh.get_surface_count()):
				mesh_instance.set_surface_override_material(i, material)
		print("Applied material to MeshInstance3D: ", node.name)
	
	# Recursively check all children
	for child in node.get_children():
		apply_material_recursive(child, material)

func setup_weapon_audio():
	# Set up charge audio
	charge_audio = AudioStreamPlayer3D.new()
	add_child(charge_audio)
	var charge_sound = load("res://assets/audio/sfx/powering.mp3")
	if charge_sound:
		charge_audio.stream = charge_sound
		charge_audio.volume_db = 0.0  # Increase volume
		print("Charge audio loaded successfully")
	else:
		print("ERROR: Could not load charge audio from res://assets/audio/sfx/powering.mp3")
	
	# Set up shot audio
	shot_audio = AudioStreamPlayer3D.new()
	add_child(shot_audio)
	var shot_sound = load("res://assets/audio/sfx/shot.mp3")
	if shot_sound:
		shot_audio.stream = shot_sound
		shot_audio.volume_db = 0.0  # Max volume
		print("Shot audio loaded successfully")
	else:
		print("ERROR: Could not load shot audio from res://assets/audio/sfx/shot.mp3")

func update_ammo_ui():
	# Update ammo display in UI
	var ammo_label = $UI/AmmoLabel
	if ammo_label:
		ammo_label.text = "Ammo: " + str(ammo)

func update_charge_ui():
	# Update charge progress bar
	var charge_bar = $UI/ChargeBar
	if charge_bar:
		charge_bar.value = (charge_time / max_charge_time) * 100.0
		charge_bar.visible = is_charging

func _input(event):
	if event is InputEventMouseMotion:
		# Rotate camera horizontally
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		# Rotate camera vertically
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI/2, PI/2)

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump (high jump for going over walls)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle charge weapon system
	if Input.is_action_pressed("shoot") and ammo > 0 and not is_charging:
		# Start charging
		print("Starting to charge weapon...")
		start_charging()
	elif Input.is_action_just_released("shoot") and is_charging:
		# Fire if fully charged
		if charge_time >= max_charge_time:
			print("Weapon fully charged! Firing shot!")
			fire_charged_shot()
		else:
			print("Weapon not fully charged (charge_time: ", charge_time, "/", max_charge_time, "). Canceling.")
			# Cancel charge if not fully charged
			cancel_charge()
	
	# Update charging
	if is_charging:
		charge_time += delta
		update_charge_ui()
		
		# Auto-fire when fully charged
		if charge_time >= max_charge_time:
			fire_charged_shot()

	# Get input direction
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1
		print("Forward pressed")
	if Input.is_action_pressed("move_backward"):
		input_dir.y += 1
		print("Backward pressed")
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
		print("Left pressed")
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
		print("Right pressed")

	# Calculate movement direction relative to player rotation
	var direction = Vector3.ZERO
	if input_dir != Vector2.ZERO:
		print("Input detected: ", input_dir)
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		print("Moving with velocity: ", Vector2(velocity.x, velocity.z))
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func start_charging():
	if ammo <= 0:
		print("Cannot charge: no ammo")
		return
	
	is_charging = true
	charge_time = 0.0
	update_charge_ui()
	
	# Play charge audio
	print("Starting charge - Playing powering sound")
	if charge_audio and charge_audio.stream:
		charge_audio.play()
		print("Charge audio started playing")
	else:
		print("Warning: charge audio not available")

func cancel_charge():
	is_charging = false
	charge_time = 0.0
	update_charge_ui()
	
	# Stop charge audio
	if charge_audio and charge_audio.is_playing():
		charge_audio.stop()

func fire_charged_shot():
	if ammo <= 0:
		cancel_charge()
		return
	
	ammo -= 1
	update_ammo_ui()
	
	# Stop charge audio and play shot audio
	print("Firing shot - Playing shot sound")
	if charge_audio and charge_audio.is_playing():
		charge_audio.stop()
	if shot_audio and shot_audio.stream:
		shot_audio.play()
		print("Shot audio started playing")
	else:
		print("Warning: shot audio not available")
	
	# Get current camera for 3D aiming
	var camera = get_viewport().get_camera_3d()
	var direction: Vector3
	var spawn_position: Vector3

	# Use the Muzzle node's global position for bullet spawning
	spawn_position = muzzle.global_transform.origin
	print("[DEBUG] Player global_position:", global_position)
	print("[DEBUG] Muzzle global_position:", muzzle.global_transform.origin)
	print("[DEBUG] Intended bullet spawn_position:", spawn_position)

	if camera:
		# Use camera's direction for aiming
		direction = -camera.global_transform.basis.z
	else:
		# Fallback to player's forward direction
		direction = -global_transform.basis.z
	
	var beam_instance = bullet_scene.instantiate()
	print("*** PLAYER BULLET CREATED! ***")
	
	# Position beam at spawn point
	get_parent().add_child(beam_instance)
	beam_instance.global_position = spawn_position
	
	# Ensure bullet is in the bullets group (force add if not already)
	if not beam_instance.is_in_group("bullets"):
		beam_instance.add_to_group("bullets")
		print("[DEBUG] Manually added bullet to bullets group")
	
	print("[DEBUG] Bullet actual global_position after parenting:", beam_instance.global_position)
	print("[DEBUG] Bullet groups after group assignment:", beam_instance.get_groups())
	
	# Orient beam to face player's front direction
	if camera:
		# Use camera's forward direction for precise alignment
		beam_instance.global_basis = camera.global_basis
	else:
		# Fallback: use player's forward direction
		beam_instance.look_at(spawn_position + direction)
	
	# Scale the beam appropriately
	beam_instance.scale = Vector3(0.3, 0.3, 3)
	
	# Set beam properties
	beam_instance.velocity = direction * 50.0  # Fast beam
	beam_instance.set_emission_intensity(5.0)  # Glowing beam
	
	# Note: bullet already added to parent above, don't add twice!
	
	cancel_charge()
	
	print("Fired charged shot! Ammo: ", ammo)

func _on_ghost_hit():
	ghost_defeated.emit()

func take_damage(damage_amount = 25):
	health -= damage_amount
	if health <= 0:
		health = 0
		die()

func die():
	print("Player died! Returning to Pacman mode!")
	get_tree().call_group("shooter_game", "_on_timer_timeout")
