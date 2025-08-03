extends CharacterBody2D

signal cherry_eaten

const SPEED = 100.0
var score = 0

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

# Pacman sprites for different directions
var pacman_right_sprites = []
var pacman_left_sprites = []
var pacman_up_sprites = []
var pacman_down_sprites = []

var current_direction = Vector2.RIGHT
var animation_frame = 0
var animation_timer = 0.0
var animation_speed = 0.1

# Audio
var chomp_audio: AudioStreamPlayer2D
var chomp_sound: AudioStream
var last_movement_time = 0.0
var chomp_cooldown = 0.3  # Prevent spam

func _ready():
	load_sprites()
	setup_audio()
	update_sprite()

func _physics_process(_delta):
	# Get input direction
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	
	# Normalize diagonal movement
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		velocity = direction * SPEED
		# Update current direction for sprite
		current_direction = direction
		# Play chomp sound when moving
		play_chomp_sound()
		# Animate sprite
		animate_sprite(_delta)
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func _on_area_2d_area_entered(area):
	print("Player detected area: ", area.name)
	print("Area groups: ", area.get_groups())
	if area.has_method("collect"):
		print("Collecting: ", area.name)
		area.collect()
		if area.is_in_group("cherries"):
			print("Cherry eaten! Emitting signal...")
			cherry_eaten.emit()

func add_score(points):
	score += points

func load_sprites():
	# Load all Pacman sprites
	pacman_right_sprites = [
		load("res://assets/pacman-art/pacman-right/1.png"),
		load("res://assets/pacman-art/pacman-right/2.png"),
		load("res://assets/pacman-art/pacman-right/3.png")
	]
	pacman_left_sprites = [
		load("res://assets/pacman-art/pacman-left/1.png"),
		load("res://assets/pacman-art/pacman-left/2.png"),
		load("res://assets/pacman-art/pacman-left/3.png")
	]
	pacman_up_sprites = [
		load("res://assets/pacman-art/pacman-up/1.png"),
		load("res://assets/pacman-art/pacman-up/2.png"),
		load("res://assets/pacman-art/pacman-up/3.png")
	]
	pacman_down_sprites = [
		load("res://assets/pacman-art/pacman-down/1.png"),
		load("res://assets/pacman-art/pacman-down/2.png"),
		load("res://assets/pacman-art/pacman-down/3.png")
	]

func setup_audio():
	# Load and setup chomp sound
	chomp_sound = preload("res://assets/audio/sfx/pacman_chomp.wav")
	chomp_audio = AudioStreamPlayer2D.new()
	chomp_audio.stream = chomp_sound
	chomp_audio.volume_db = -10.0
	add_child(chomp_audio)

func play_chomp_sound():
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if current_time - last_movement_time > chomp_cooldown:
		chomp_audio.play()
		last_movement_time = current_time

func update_sprite():
	var sprites_to_use
	
	# Choose sprite set based on direction
	if abs(current_direction.x) > abs(current_direction.y):
		if current_direction.x > 0:
			sprites_to_use = pacman_right_sprites
		else:
			sprites_to_use = pacman_left_sprites
	else:
		if current_direction.y > 0:
			sprites_to_use = pacman_down_sprites
		else:
			sprites_to_use = pacman_up_sprites
	
	# Set the sprite texture
	sprite.texture = sprites_to_use[animation_frame]

func animate_sprite(delta):
	animation_timer += delta
	if animation_timer >= animation_speed:
		animation_frame = (animation_frame + 1) % 3
		update_sprite()
		animation_timer = 0.0
