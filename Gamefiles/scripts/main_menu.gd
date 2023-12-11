extends Node2D



func _on_quit_button_pressed():
	get_tree().quit()


func _on_play_button_pressed():
	SceneTransition.change_scene("res://scenes/textbox.tscn")
	$SoundClick.play()


