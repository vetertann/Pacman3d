extends CharacterBody2D

const SPEED = 150.0
var target_position: Vector2
var direction_change_timer = 0.0
var direction_change_interval = 2.0

@onready var sprite = $Sprite2D

# Ghost textures
var ghost_textures = []

enum GhostColor {
	RED,
	PINK,
	CYAN,
	ORANGE
}

var ghost_color: GhostColor

func _ready():
	# Load ghost textures
	ghost_textures = [
		load("res://assets/pacman-art/ghosts/blinky.png"),
		load("res://assets/pacman-art/ghosts/pinky.png"),
		load("res://assets/pacman-art/ghosts/inky.png"),
		load("res://assets/pacman-art/ghosts/clyde.png")
	]
	
	# Set random ghost texture
	ghost_color = GhostColor.values()[randi() % GhostColor.size()]
	sprite.texture = ghost_textures[ghost_color]
	
	# Start with random direction
	choose_random_direction()

func _physics_process(_delta):
	direction_change_timer += _delta
	
	# Change direction periodically or when hitting walls
	if direction_change_timer >= direction_change_interval:
		choose_random_direction()
		direction_change_timer = 0.0
	
	# Move towards target
	var direction = (target_position - global_position).normalized()
	velocity = direction * SPEED
	
	# Check for wall collision
	if move_and_slide():
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_collider().is_in_group("walls"):
				choose_random_direction()
				break

func choose_random_direction():
	# Choose a random direction to move
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var random_dir = directions[randi() % directions.size()]
	target_position = global_position + random_dir * 100

func _on_area_2d_area_entered(area):
	if area.is_in_group("player"):
		# Handle collision with player (game over in normal mode)
		get_tree().call_group("game", "player_caught")
