extends CharacterBody2D
var rng = RandomNumberGenerator.new()
var debug = false
@onready var SPEED = 400.0
@onready var direction = 1
@onready var numofsuccess = 0
@onready var greenarea = %GreenArea

enum IndicatorState {
	PAUSE,
	READY,
	GAMING,
	FINISHED
}
var current_state = IndicatorState.PAUSE

var entered_green = false
func _on_green_area_area_entered(area):
	entered_green = true

func _on_green_area_area_exited(area):
	entered_green = false

var min_range = -220
var max_range = 220

func _physics_process(delta):
	match current_state:
		IndicatorState.PAUSE:
			pass
				
		IndicatorState.READY:
			var random_number = rng.randf_range(min_range, max_range)
			greenarea.position.x = random_number
			change_state(IndicatorState.GAMING)
		IndicatorState.GAMING:
			pass
				
			
		IndicatorState.FINISHED:
			pass
					
		
			

	
		
	var velocity = Vector2(SPEED * direction, 0)
	move_and_slide()
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		direction *= -1
		
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)


func change_state(next_state):
	current_state = next_state
	match current_state:
		IndicatorState.PAUSE:
			debug_print("Bar: Switching to state PAUSE")
		IndicatorState.READY:
			debug_print("Bar: Switching to state READY")
		IndicatorState.GAMING:
			debug_print("Bar: Switching to state GAMING")
		IndicatorState.FINISHED:
			debug_print("Bar: Switching to state FINISHED")


func start_qte():
	current_state = IndicatorState.READY
	
func debug_print(text):
	if(debug):
		print(text)
