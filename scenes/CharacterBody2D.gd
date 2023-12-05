extends CharacterBody2D
var rng = RandomNumberGenerator.new()
@onready var SPEED = 200.0
@onready var direction = 1
@onready var numofsuccess = 0

var entered_green = false

func _on_green_area_area_entered(area):
	$Label.text = area.name
	entered_green = true


func _on_green_area_area_exited(area):
	$Label.text = ""
	entered_green = false


func _physics_process(delta):
	var greenarea = %GreenArea
	%NumofSuccess.text = "Success Count: "+str(numofsuccess)
	
	if entered_green == true and Input.is_action_just_pressed("ui_accept"):
		var min_range = -149
		var max_range = 208
		var random_number = rng.randf_range(min_range, max_range)
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




