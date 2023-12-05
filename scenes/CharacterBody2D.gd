extends CharacterBody2D
var rng = RandomNumberGenerator.new()
@onready var SPEED = 200.0
@onready var direction = 1
@onready var numofsuccess = 0

var entered_green = false
func _on_green_area_area_entered(area):
	$Label.text = "Click!"
	entered_green = true

func _on_green_area_area_exited(area):
	$Label.text = ""
	entered_green = false


var entered_blue = false
func _on_blue_area_area_entered(area):
	$Label.text = "Click!"
	entered_blue = true

func _on_blue_area_area_exited(area):
	$Label.text = ""
	entered_blue = false
	
func _physics_process(delta):
	var greenarea = %GreenArea
	var bluearea = %BlueArea
	%NumofSuccess.text = "Success Count: "+str(numofsuccess)
	
	if (entered_blue or entered_green) and Input.is_action_just_pressed("ui_accept"):
		var min_range = -246
		var max_range = 117
		var random_number = rng.randf_range(min_range, max_range)
		bluearea.position.x = random_number
		min_range = -70
		max_range = 288
		random_number = rng.randf_range(min_range, max_range)
		greenarea.position.x = random_number
		numofsuccess += 1
		
	var velocity = Vector2(SPEED * direction, 0)
	move_and_slide()
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		direction *= -1
		
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)








