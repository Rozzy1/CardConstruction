extends Button


func _on_pressed() -> void:
	if Globals.player_hand:
		get_tree().change_scene_to_file("res://Scenes/main.tscn")
	else:
		text = "Please create atleast one card!"
		await get_tree().create_timer(1.0).timeout
		text = "Fight!"
