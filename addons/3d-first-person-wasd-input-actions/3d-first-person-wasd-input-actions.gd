@tool
extends EditorPlugin


func _enable_plugin() -> void:
	# Input actions here
	add_action("move_forward", KEY_W)
	add_action("move_back", KEY_S)
	add_action("move_left", KEY_A)
	add_action("move_right", KEY_D)
	
	# Save to project.godot
	ProjectSettings.save()
	print("Input actions saved to Project Settings.")
	
	# Do not seem to do anything, maybe a bug.
	ProjectSettings.settings_changed.emit()
	emit_signal("project_settings_changed");
	print("  Emitted ProjectSettings.settings_changed signal.")
	
# 	Do not seem to do anything, needs research
	ProjectSettings.set_restart_if_changed("input/move_forward", true)

	


func _disable_plugin() -> void:
# 	Do not seem to do anything, needs research
	ProjectSettings.set_restart_if_changed("input/move_forward", true)
	
	# Removal of actions
	remove_action("move_forward", KEY_W)
	remove_action("move_back", KEY_S)
	remove_action("move_left", KEY_A)
	remove_action("move_right", KEY_D)
	
	# Save to project.godot
	ProjectSettings.save()
	print("Input actions saved to Project Settings.")
	
	# Do not seem to do anything, maybe a bug.
	ProjectSettings.settings_changed.emit()
	emit_signal("project_settings_changed");
	print("  Emitted ProjectSettings.settings_changed signal.")





func add_action(action_name: String, key_scancode: int):
	var event := InputEventKey.new()
	event.physical_keycode = key_scancode
	
	var property := "input/%s" % action_name
	var action: Dictionary = ProjectSettings.get_setting(property, { "deadzone": 0.5, "events": [] })
	
	# Check for existing events to avoid duplicates
	var event_exists := false
	for existing_event in action["events"]:
		if is_same_key_event(existing_event, event):
			event_exists = true
			break
	
	if not event_exists:
		action["events"].append(event)
		ProjectSettings.set_setting(property, action)
		
		# Update InputMap for immediate effect
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		InputMap.action_add_event(action_name, event)
		

	
func is_same_key_event(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		return a.physical_keycode == b.physical_keycode
	return false


func remove_action(action_name: String, key_scancode: int):
	var event := InputEventKey.new()
	event.physical_keycode = key_scancode
	
	var property := "input/%s" % action_name
	var action: Dictionary = ProjectSettings.get_setting(property, { "deadzone": 0.5, "events": [] })
	
	# Check for existing events to avoid duplicates
	var event_exists := false
	for existing_event in action["events"]:
		if is_same_key_event(existing_event, event):
			event_exists = true
			break
	
	if event_exists:
		action["events"].append(event)
		ProjectSettings.set_setting(property, null)
		
		# Update InputMap for immediate effect
		if InputMap.has_action(action_name):
			InputMap.erase_action(action_name)
