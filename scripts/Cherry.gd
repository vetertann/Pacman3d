extends Area2D

@onready var sprite = $Sprite2D
var points = 100

# Audio
var eat_fruit_audio: AudioStreamPlayer2D
var eat_fruit_sound: AudioStream

func _ready():
	# Sprite is already set up in the scene
	add_to_group("cherries")
	setup_audio()

func collect():
	# Play eating fruit sound
	play_eat_fruit_sound()
	# Add to player score and trigger mode switch
	get_tree().call_group("player", "add_score", points)
	# Delay queue_free to let sound play
	get_tree().create_timer(0.5).timeout.connect(queue_free)

func setup_audio():
	# Create audio player for eating fruit sound
	eat_fruit_audio = AudioStreamPlayer2D.new()
	add_child(eat_fruit_audio)
	
	# Load eating fruit sound
	eat_fruit_sound = load("res://assets/audio/sfx/pacman_eatfruit.mp3")
	if eat_fruit_sound:
		eat_fruit_audio.stream = eat_fruit_sound
		print("Eating fruit sound loaded!")

func play_eat_fruit_sound():
	if eat_fruit_audio and eat_fruit_sound:
		eat_fruit_audio.play()
		print("Playing eating fruit sound!")
