extends Node2D

signal cherry_eaten

const MAZE_WIDTH = 25
const MAZE_HEIGHT = 25
const CELL_SIZE = 32

@onready var player = $Player
@onready var maze_container = $MazeContainer
@onready var pellets_container = $PelletsContainer
@onready var ghosts_container = $GhostsContainer

# Preload scenes
var wall_scene = preload("res://scenes/Wall.tscn")
var pellet_scene = preload("res://scenes/Pellet.tscn")
var cherry_scene = preload("res://scenes/Cherry.tscn")
var ghost_scene = preload("res://scenes/Ghost.tscn")

# Simple maze layout (1 = wall, 0 = path, 2 = pellet, 3 = cherry)
var maze_layout = [
	[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
	[1,2,2,2,2,2,2,2,2,2,2,2,1,2,2,2,2,2,2,2,2,2,2,2,1],
	[1,2,1,1,1,2,1,1,1,1,1,2,1,2,1,1,1,1,1,2,1,1,1,2,1],
	[1,3,1,0,1,2,1,0,0,0,1,2,1,2,1,0,0,0,1,2,1,0,1,3,1],
	[1,2,1,1,1,2,1,1,1,1,1,2,1,2,1,1,1,1,1,2,1,1,1,2,1],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1],
	[1,2,1,1,1,2,1,2,1,1,1,1,1,1,1,1,1,2,1,2,1,1,1,2,1],
	[1,2,2,2,2,2,1,2,2,2,2,2,1,2,2,2,2,2,1,2,2,2,2,2,1],
	[1,1,1,1,1,2,1,1,1,1,1,0,1,0,1,1,1,1,1,2,1,1,1,1,1],
	[0,0,0,0,1,2,1,0,0,0,0,0,0,0,0,0,0,0,1,2,1,0,0,0,0],
	[0,0,0,0,1,2,1,0,1,1,0,0,0,0,0,1,1,0,1,2,1,0,0,0,0],
	[1,1,1,1,1,2,1,0,1,0,0,0,0,0,0,0,1,0,1,2,1,1,1,1,1],
	[0,0,0,0,0,2,0,0,1,0,0,0,0,0,0,0,1,0,0,2,0,0,0,0,0],
	[1,1,1,1,1,2,1,0,1,0,0,0,0,0,0,0,1,0,1,2,1,1,1,1,1],
	[0,0,0,0,1,2,1,0,1,1,1,1,1,1,1,1,1,0,1,2,1,0,0,0,0],
	[0,0,0,0,1,2,1,0,0,0,0,0,0,0,0,0,0,0,1,2,1,0,0,0,0],
	[1,1,1,1,1,2,1,1,1,1,1,0,1,0,1,1,1,1,1,2,1,1,1,1,1],
	[1,2,2,2,2,2,2,2,2,2,2,2,1,2,2,2,2,2,2,2,2,2,2,2,1],
	[1,2,1,1,1,2,1,1,1,1,1,2,1,2,1,1,1,1,1,2,1,1,1,2,1],
	[1,3,2,2,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,2,2,3,1],
	[1,1,1,2,1,2,1,2,1,1,1,1,1,1,1,1,1,2,1,2,1,2,1,1,1],
	[1,2,2,2,2,2,1,2,2,2,2,2,1,2,2,2,2,2,1,2,2,2,2,2,1],
	[1,2,1,1,1,1,1,1,1,1,1,2,1,2,1,1,1,1,1,1,1,1,1,2,1],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1],
	[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
]

func _ready():
	add_to_group("game")
	generate_maze()
	spawn_ghosts()
	
	# Connect player cherry signal
	player.cherry_eaten.connect(_on_cherry_eaten)

func generate_maze():
	# First pass: create collision bodies for walls and spawn items
	for y in range(MAZE_HEIGHT):
		for x in range(MAZE_WIDTH):
			var cell_value = maze_layout[y][x]
			var pos = Vector2(x * CELL_SIZE, y * CELL_SIZE)
			
			match cell_value:
				1: # Wall - create invisible collision body
					var wall_body = StaticBody2D.new()
					var collision_shape = CollisionShape2D.new()
					var shape = RectangleShape2D.new()
					shape.size = Vector2(CELL_SIZE, CELL_SIZE)
					collision_shape.shape = shape
					wall_body.add_child(collision_shape)
					wall_body.position = pos
					wall_body.add_to_group("walls")
					maze_container.add_child(wall_body)
				2: # Pellet
					var pellet = pellet_scene.instantiate()
					pellet.position = pos
					pellets_container.add_child(pellet)
				3: # Cherry
					var cherry = cherry_scene.instantiate()
					cherry.position = pos
					pellets_container.add_child(cherry)
	
	# Second pass: draw wall borders
	draw_wall_borders()
	
	# Position player at start
	player.position = Vector2(12 * CELL_SIZE, 18 * CELL_SIZE)

func draw_wall_borders():
	# Create a single Node2D to hold all wall border graphics
	var wall_graphics = Node2D.new()
	wall_graphics.name = "WallGraphics"
	wall_graphics.z_index = -1  # Render behind sprites
	maze_container.add_child(wall_graphics)
	
	# Draw borders for each wall cell
	for y in range(MAZE_HEIGHT):
		for x in range(MAZE_WIDTH):
			if maze_layout[y][x] == 1: # Wall
				draw_cell_borders(wall_graphics, x, y)

func draw_cell_borders(parent: Node2D, x: int, y: int):
	var pos = Vector2(x * CELL_SIZE, y * CELL_SIZE)
	var border_thickness = 2
	var border_color = Color(0, 0, 0.8, 1) # Blue border
	
	# Check adjacent cells to determine which borders to draw
	var draw_top = (y == 0 or maze_layout[y-1][x] != 1)
	var draw_bottom = (y == MAZE_HEIGHT-1 or maze_layout[y+1][x] != 1)
	var draw_left = (x == 0 or maze_layout[y][x-1] != 1)
	var draw_right = (x == MAZE_WIDTH-1 or maze_layout[y][x+1] != 1)
	
	# Draw borders only where needed
	if draw_top:
		var top_border = ColorRect.new()
		top_border.position = pos + Vector2(-CELL_SIZE/2, -CELL_SIZE/2)
		top_border.size = Vector2(CELL_SIZE, border_thickness)
		top_border.color = border_color
		parent.add_child(top_border)
	
	if draw_bottom:
		var bottom_border = ColorRect.new()
		bottom_border.position = pos + Vector2(-CELL_SIZE/2, CELL_SIZE/2 - border_thickness)
		bottom_border.size = Vector2(CELL_SIZE, border_thickness)
		bottom_border.color = border_color
		parent.add_child(bottom_border)
	
	if draw_left:
		var left_border = ColorRect.new()
		left_border.position = pos + Vector2(-CELL_SIZE/2, -CELL_SIZE/2)
		left_border.size = Vector2(border_thickness, CELL_SIZE)
		left_border.color = border_color
		parent.add_child(left_border)
	
	if draw_right:
		var right_border = ColorRect.new()
		right_border.position = pos + Vector2(CELL_SIZE/2 - border_thickness, -CELL_SIZE/2)
		right_border.size = Vector2(border_thickness, CELL_SIZE)
		right_border.color = border_color
		parent.add_child(right_border)

func spawn_ghosts():
	var ghost_positions = [
		Vector2(12 * CELL_SIZE, 10 * CELL_SIZE),
		Vector2(11 * CELL_SIZE, 12 * CELL_SIZE),
		Vector2(13 * CELL_SIZE, 12 * CELL_SIZE),
		Vector2(12 * CELL_SIZE, 14 * CELL_SIZE)
	]
	
	for pos in ghost_positions:
		var ghost = ghost_scene.instantiate()
		ghost.position = pos
		ghosts_container.add_child(ghost)

func _on_cherry_eaten():
	print("PacmanGame: Cherry eaten signal received! Emitting to Main...")
	cherry_eaten.emit()

func player_caught():
	print("Player caught by ghost! Game Over!")
	# Implement game over logic here
