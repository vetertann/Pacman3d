extends Area3D

signal pellet_collected

func _ready():
	# Set up pellet appearance with bright emission
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance and mesh_instance is MeshInstance3D:
		# Create glowing yellow material
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1, 1, 0.8, 1)
		material.emission_enabled = true
		material.emission = Color(1, 1, 0.9, 1)
		material.emission_energy = 2.0
		material.metallic = 0.0
		material.roughness = 0.3
		mesh_instance.material_override = material
		print("3D pellet created with glowing material")
	else:
		print("Warning: Could not find MeshInstance3D in pellet")
	
	# Add to pellets group
	add_to_group("pellets_3d")
	
	# Rotate pellet for visual appeal
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "rotation:y", rotation.y + TAU, 2.0)

func _on_body_entered(body):
	if body.is_in_group("player_3d"):
		# Emit signal for ammo collection
		pellet_collected.emit()
		print("Pellet collected! +1 ammo")
		queue_free()
