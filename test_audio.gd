extends Node

func _ready():
	print("Testing audio file loading...")
	
	# Test loading each audio file
	var files_to_test = [
		"res://assets/audio/sfx/pacman_beginning.wav",
		"res://assets/audio/sfx/pacman_chomp.wav", 
		"res://assets/audio/sfx/pacman_eatfruit.wav",
		"res://assets/audio/music/Pixel Pursuit.mp3"
	]
	
	for file_path in files_to_test:
		print("Testing: ", file_path)
		if FileAccess.file_exists(file_path):
			print("  ✓ File exists")
			var audio_stream = load(file_path)
			if audio_stream:
				print("  ✓ Audio stream loaded successfully")
			else:
				print("  ✗ Failed to load audio stream")
		else:
			print("  ✗ File does not exist")
	
	# Also test if files exist with different extensions
	print("\nTesting alternative paths...")
	var alt_files = [
		"res://assets/audio/sfx/pacman_beginning.ogg",
		"res://assets/audio/sfx/pacman_chomp.ogg"
	]
	
	for file_path in alt_files:
		if FileAccess.file_exists(file_path):
			print("  ✓ Alternative file found: ", file_path)
