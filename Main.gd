extends Node2D

# Game state management
enum GameMode {
	PACMAN,
	SHOOTER
}

var current_mode = GameMode.PACMAN
var pacman_scene: PackedScene
var shooter_scene: PackedScene

# References to scene nodes
@onready var pacman_game: Node2D
@onready var shooter_game: Node3D
@onready var ui: Control

# Audio players
var audio_player: AudioStreamPlayer
var beginning_sound: AudioStream

func _ready():
	# Set up audio
	setup_audio()
	
	# Load scenes
	pacman_scene = preload("res://scenes/PacmanGame.tscn")
	shooter_scene = preload("res://scenes/ShooterGame.tscn")
	
	# Start with Pacman mode
	start_pacman_mode()

func start_pacman_mode():
	current_mode = GameMode.PACMAN
	
	# Clean up shooter mode if active
	if shooter_game:
		shooter_game.queue_free()
	
	# Create Pacman game
	pacman_game = pacman_scene.instantiate()
	add_child(pacman_game)
	
	# Connect cherry eaten signal
	pacman_game.cherry_eaten.connect(_on_cherry_eaten)

func start_shooter_mode():
	current_mode = GameMode.SHOOTER
	
	# Clean up Pacman mode
	if pacman_game:
		pacman_game.queue_free()
	
	# Create shooter game
	shooter_game = shooter_scene.instantiate()
	add_child(shooter_game)
	
	# Connect mode switch back signal (when all ghosts defeated or timer runs out)
	shooter_game.return_to_pacman.connect(_on_return_to_pacman)

func _on_cherry_eaten():
	print("Main: Cherry eaten signal received! Switching to shooter mode!")
	start_shooter_mode()

func _on_return_to_pacman():
	print("Returning to Pacman mode!")
	start_pacman_mode()

func setup_audio():
	# Create audio player for game sounds
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	# Load and play beginning sound
	print("Loading Pacman beginning sound...")
	beginning_sound = load("res://assets/audio/sfx/pacman_beginning.mp3")
	if beginning_sound:
		audio_player.stream = beginning_sound
		audio_player.volume_db = 0
		audio_player.play()
		print("Playing Pacman beginning sound!")
	else:
		print("ERROR: Failed to load beginning sound MP3")
