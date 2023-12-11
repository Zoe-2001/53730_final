extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready():
	var tween = create_tween()
	$Label.visible_ratio = 0.0
	tween.tween_property($Label, 'visible_ratio', 1, 3)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		SceneTransition.change_scene_slow("res://scenes/main_menu.tscn")
		$SoundClick.play()
