extends Node3D

signal return_to_pacman

# Node references (will be created programmatically)
var player_3d: CharacterBody3D
var camera_3d: Camera3D
@onready var ghosts_container = $GhostsContainer
@onready var walls_container = $WallsContainer
@onready var timer = $Timer

# Preload 3D scenes
var player_3d_scene = preload("res://scenes/Player3D.tscn")
var wall_3d_scene = preload("res://scenes/Wall3D.tscn")
var ghost_3d_scene = preload("res://scenes/Ghost3D.tscn")

var ghosts_defeated = 0
var total_ghosts = 4
var shooter_duration = 15.0  # 15 seconds in shooter mode (doubled speed)

# Audio
var background_music: AudioStreamPlayer
var music_stream: AudioStream

func _ready():
	add_to_group("shooter_game")
	setup_audio()
	create_tron_environment()
	create_player_3d()
	create_ground()
	# Using imported 3D map instead of programmatic maze generation
	setup_map_collision()
	position_player_safely()
	spawn_3d_ghosts()
	
	# Set up timer for returning to Pacman mode
	timer.wait_time = shooter_duration
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	
	# Connect ghost defeated signals
	player_3d.ghost_defeated.connect(_on_ghost_defeated)

func generate_3d_maze():
	# Convert 2D maze to 3D walls
	var maze_layout = [
		[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,1,1,1,0,1,1,1,1,1,0,1,0,1,1,1,1,1,0,1,1,1,0,1],
		[1,0,1,0,1,0,1,0,0,0,1,0,1,0,1,0,0,0,1,0,1,0,1,0,1],
		[1,0,1,1,1,0,1,1,1,1,1,0,1,0,1,1,1,1,1,0,1,1,1,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,1,1,1,0,1,0,1,1,1,1,1,1,1,1,1,0,1,0,1,1,1,0,1],
		[1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1],
		[1,1,1,1,1,0,1,1,1,1,1,0,1,0,1,1,1,1,1,0,1,1,1,1,1],
		[0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0],
		[0,0,0,0,1,0,1,0,1,1,0,0,0,0,0,1,1,0,1,0,1,0,0,0,0],
		[1,1,1,1,1,0,1,0,1,0,0,0,0,0,0,0,1,0,1,0,1,1,1,1,1],
		[0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0],
		[1,1,1,1,1,0,1,0,1,0,0,0,0,0,0,0,1,0,1,0,1,1,1,1,1],
		[0,0,0,0,1,0,1,0,1,1,1,1,1,1,1,1,1,0,1,0,1,0,0,0,0],
		[0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0],
		[1,1,1,1,1,0,1,1,1,1,1,0,1,0,1,1,1,1,1,0,1,1,1,1,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,0,1,1,1,0,1,1,1,1,1,0,1,0,1,1,1,1,1,0,1,1,1,0,1],
		[1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1],
		[1,1,1,0,1,0,1,0,1,1,1,1,1,1,1,1,1,0,1,0,1,0,1,1,1],
		[1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1],
		[1,0,1,1,1,1,1,1,1,1,1,0,1,0,1,1,1,1,1,1,1,1,1,0,1],
		[1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
		[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
	]
	
	var cell_size = 4.0
	for y in range(len(maze_layout)):
		for x in range(len(maze_layout[y])):
			if maze_layout[y][x] == 1:
				var wall = wall_3d_scene.instantiate()
				# Position walls at ground level (y = 0) instead of floating
				wall.position = Vector3(x * cell_size, 0.0, y * cell_size)
				# Apply Tron-style material with outlines
				apply_tron_wall_material(wall)
				walls_container.add_child(wall)

func position_player_safely():
	# Position player in an open area of the maze
	# Looking at the maze layout, position (1,1) is open (0 in the array)
	var cell_size = 4.0
	var safe_x = 1  # Open position in maze
	var safe_y = 1  # Open position in maze
	player_3d.position = Vector3(safe_x * cell_size, 1.0, safe_y * cell_size)
	print("Player positioned at: ", player_3d.position)

func spawn_3d_ghosts():
	var ghost_positions = [
		Vector3(12 * 4.0, 1.0, 10 * 4.0),
		Vector3(11 * 4.0, 1.0, 12 * 4.0),
		Vector3(13 * 4.0, 1.0, 12 * 4.0),
		Vector3(12 * 4.0, 1.0, 14 * 4.0)
	]
	
	for pos in ghost_positions:
		var ghost = ghost_3d_scene.instantiate()
		ghost.position = pos
		# Apply glow material to Ghost3D
		apply_glow_to_ghost(ghost)
		ghosts_container.add_child(ghost)

func _on_ghost_defeated():
	ghosts_defeated += 1
	if ghosts_defeated >= total_ghosts:
		print("All ghosts defeated! Returning to Pacman mode!")
		# Stop background music when leaving 3D mode
		if background_music:
			background_music.stop()
		return_to_pacman.emit()

func setup_map_collision():
	# Add collision shapes to the imported 3D map
	var map_node = $Map3D/map
	if map_node:
		print("Setting up collision for 3D map...")
		add_collision_recursive(map_node)
		print("Map collision setup complete")

func add_collision_recursive(node: Node):
	# Add collision to MeshInstance3D nodes
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		if mesh_instance.mesh:
			# Create StaticBody3D parent if it doesn't exist
			var static_body = mesh_instance.get_parent()
			if not static_body is StaticBody3D:
				# Create new StaticBody3D and reparent the mesh
				static_body = StaticBody3D.new()
				var original_parent = mesh_instance.get_parent()
				original_parent.remove_child(mesh_instance)
				original_parent.add_child(static_body)
				static_body.add_child(mesh_instance)
				static_body.name = mesh_instance.name + "_Body"
			
			# Create collision shape
			var collision_shape = CollisionShape3D.new()
			var shape = mesh_instance.mesh.create_trimesh_shape()
			collision_shape.shape = shape
			static_body.add_child(collision_shape)
			print("Added collision to: ", mesh_instance.name)
	
	# Recursively process children
	for child in node.get_children():
		add_collision_recursive(child)

func create_ground():
	# Create a large ground plane to prevent falling
	var ground = StaticBody3D.new()
	add_child(ground)
	
	# Create ground mesh
	var ground_mesh = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(200, 0.2, 200)
	ground_mesh.mesh = box_mesh
	ground_mesh.position = Vector3(0, -1, 0)
	ground.add_child(ground_mesh)
	
	# Create ground collision
	var ground_collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(200, 0.2, 200)
	ground_collision.shape = box_shape
	ground_collision.position = Vector3(0, -1, 0)
	ground.add_child(ground_collision)
	
	# Set Tron-style ground material with grid
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.02, 0.02, 0.1, 1.0)  # Very dark blue base
	material.emission_enabled = true
	material.emission = Color(0.1, 0.3, 0.6, 1.0)  # Subtle blue emission
	material.emission_energy = 0.4
	material.metallic = 0.9
	material.roughness = 0.1
	# Create grid pattern
	material.uv1_scale = Vector3(20, 20, 1)  # Grid scale
	material.detail_enabled = true
	material.detail_uv_layer = 1
	if ground_mesh:
		ground_mesh.material_override = material

func apply_tron_wall_material(wall: Node3D):
	# Apply grid-based Tron aesthetic with wireframe glow to walls
	var mesh_instance = wall.get_node_or_null("MeshInstance3D")
	if mesh_instance and mesh_instance is MeshInstance3D:
		var material = StandardMaterial3D.new()
		
		# Visible dark base color with some opacity
		material.albedo_color = Color(0.1, 0.1, 0.3, 0.8)  # Darker blue with transparency
		
		# Enhanced cyan emission for grid lines with glow
		material.emission_enabled = true
		material.emission = Color(0.0, 0.6, 0.9, 1.0)  # Moderate cyan wireframe glow
		material.emission_energy = 0.8  # Balanced glow for wireframe effect
		
		# Create grid pattern using UV scaling
		material.uv1_scale = Vector3(4, 4, 1)  # Grid scale for pattern
		
		# Better visibility properties
		material.metallic = 0.2
		material.roughness = 0.7
		material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL  # Better shading
		
		# Transparency for wireframe effect
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.flags_transparent = true
		material.flags_vertex_lighting = true
		
		mesh_instance.material_override = material
	else:
		print("Warning: Could not find MeshInstance3D in wall: ", wall.name)

func create_boundary_walls():
	# Create invisible walls around the perimeter to prevent falling off
	var cell_size = 4.0
	var maze_width = 25  # Width of the maze in cells
	var maze_height = 25  # Height of the maze in cells
	var wall_height = 10.0  # Height of boundary walls
	var wall_thickness = 1.0
	
	# Create north wall (top)
	var north_wall = StaticBody3D.new()
	add_child(north_wall)
	var north_collision = CollisionShape3D.new()
	var north_shape = BoxShape3D.new()
	north_shape.size = Vector3(maze_width * cell_size + wall_thickness * 2, wall_height, wall_thickness)
	north_collision.shape = north_shape
	north_collision.position = Vector3((maze_width * cell_size) / 2, wall_height / 2, -wall_thickness / 2)
	north_wall.add_child(north_collision)
	
	# Create south wall (bottom)
	var south_wall = StaticBody3D.new()
	add_child(south_wall)
	var south_collision = CollisionShape3D.new()
	var south_shape = BoxShape3D.new()
	south_shape.size = Vector3(maze_width * cell_size + wall_thickness * 2, wall_height, wall_thickness)
	south_collision.shape = south_shape
	south_collision.position = Vector3((maze_width * cell_size) / 2, wall_height / 2, maze_height * cell_size + wall_thickness / 2)
	south_wall.add_child(south_collision)
	
	# Create west wall (left)
	var west_wall = StaticBody3D.new()
	add_child(west_wall)
	var west_collision = CollisionShape3D.new()
	var west_shape = BoxShape3D.new()
	west_shape.size = Vector3(wall_thickness, wall_height, maze_height * cell_size)
	west_collision.shape = west_shape
	west_collision.position = Vector3(-wall_thickness / 2, wall_height / 2, (maze_height * cell_size) / 2)
	west_wall.add_child(west_collision)
	
	# Create east wall (right)
	var east_wall = StaticBody3D.new()
	add_child(east_wall)
	var east_collision = CollisionShape3D.new()
	var east_shape = BoxShape3D.new()
	east_shape.size = Vector3(wall_thickness, wall_height, maze_height * cell_size)
	east_collision.shape = east_shape
	east_collision.position = Vector3(maze_width * cell_size + wall_thickness / 2, wall_height / 2, (maze_height * cell_size) / 2)
	east_wall.add_child(east_collision)
	
	print("Boundary walls created to prevent falling off the level")

func create_tron_environment():
	# Set up environment with subtle glow effects
	var world_env = WorldEnvironment.new()
	add_child(world_env)
	
	# Dark environment with glow support
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.02, 0.02, 0.08, 1.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.2, 0.2, 0.3, 1.0)
	environment.ambient_light_energy = 0.5
	
	# Add subtle glow effects for Tron aesthetic
	environment.glow_enabled = true
	environment.glow_intensity = 0.3  # Much more subtle glow
	environment.glow_strength = 0.8
	environment.glow_bloom = 0.05  # Very minimal bloom
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	
	world_env.environment = environment

func apply_glow_to_player(player: Node3D):
	# Apply glowing material to Player3D for Tron effect
	var mesh_instance = player.get_node("MeshInstance3D")
	if mesh_instance:
		var material = StandardMaterial3D.new()
		
		# Bright yellow base color for Pacman
		material.albedo_color = Color(1.0, 1.0, 0.0, 1.0)  # Pure bright yellow
		
		# Moderate yellow emission for glow
		material.emission_enabled = true
		material.emission = Color(1.0, 0.9, 0.2, 1.0)  # Warm yellow glow
		material.emission_energy = 0.6  # Balanced glow energy
		
		# Optimized for glow visibility
		material.metallic = 0.1
		material.roughness = 0.4
		material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		
		if mesh_instance and mesh_instance is MeshInstance3D:
			mesh_instance.material_override = material
			print("Applied glow material to player: ", player.name)
		else:
			print("Warning: Could not find MeshInstance3D in player: ", player.name)

func apply_glow_to_ghost(ghost: Node3D):
	# Apply glowing material to Ghost3D for Tron effect
	var mesh_instance = ghost.get_node("MeshInstance3D")
	if mesh_instance:
		var material = StandardMaterial3D.new()
		
		# Bright red base color for ghosts
		material.albedo_color = Color(1.0, 0.2, 0.2, 1.0)  # Brighter red base
		
		# Moderate red emission for glow
		material.emission_enabled = true
		material.emission = Color(0.8, 0.2, 0.2, 1.0)  # Balanced red glow
		material.emission_energy = 0.7  # Balanced glow energy
		
		# Optimized for glow visibility
		material.metallic = 0.1
		material.roughness = 0.4
		material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		
		if mesh_instance and mesh_instance is MeshInstance3D:
			mesh_instance.material_override = material
			print("Applied glow material to ghost: ", ghost.name)
		else:
			print("Warning: Could not find MeshInstance3D in ghost: ", ghost.name)

func create_player_3d():
	# Create Player3D programmatically to avoid scene reference issues
	player_3d = player_3d_scene.instantiate()
	# Use original size in 3D mode
	add_child(player_3d)
	
	# Apply glow material to Player3D
	apply_glow_to_player(player_3d)
	
	# Get camera reference
	camera_3d = player_3d.get_node("CameraPivot/Camera3D")
	
	# Connect ghost defeated signals
	player_3d.ghost_defeated.connect(_on_ghost_defeated)
	
	print("Player3D created programmatically!")

func setup_audio():
	# Create audio player for background music
	background_music = AudioStreamPlayer.new()
	add_child(background_music)
	
	# Load background music for 3D mode
	music_stream = load("res://assets/audio/music/Pixel Pursuit.mp3")
	if music_stream:
		background_music.stream = music_stream
		background_music.volume_db = -10  # Lower volume for background
		background_music.autoplay = false
		# Set up looping by connecting to finished signal
		background_music.finished.connect(_on_background_music_finished)
		background_music.play()
		print("3D background music started!")

func _on_background_music_finished():
	# Restart background music to create looping effect
	if background_music and music_stream:
		background_music.play()

func _on_timer_timeout():
	print("Shooter mode time up! Returning to Pacman mode!")
	# Stop background music when leaving 3D mode
	if background_music:
		background_music.stop()
	return_to_pacman.emit()
