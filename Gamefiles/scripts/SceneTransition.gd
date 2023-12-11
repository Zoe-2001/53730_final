extends CanvasLayer

func change_scene(next_scene):
	$AnimationPlayer.play("dissolve")
	await($AnimationPlayer.animation_finished)
	get_tree().change_scene_to_file(next_scene)
	$AnimationPlayer.play_backwards("dissolve")

func change_scene_slow(next_scene):
	$AnimationPlayer.play("dissolve_slow")
	await($AnimationPlayer.animation_finished)
	get_tree().change_scene_to_file(next_scene)
	$AnimationPlayer.play_backwards("dissolve_slow")

func animation_stopped():
	return $AnimationPlayer.animation_finished
