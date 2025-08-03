extends Area2D

@onready var sprite = $Sprite2D
var points = 10

func _ready():
	# Sprite is already set up in the scene
	add_to_group("pellets")

func collect():
	# Add to player score and remove pellet
	get_tree().call_group("player", "add_score", points)
	queue_free()
