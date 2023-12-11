extends CanvasLayer

var debug = true
@onready var reaction_bar = $TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/Text
@onready var textbox_container = $TextboxContainer
@onready var start_symbol = $TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/Start
@onready var end_symbol = $TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/End
@onready var text_content = $TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/Text

var tween : Tween

enum State {
	READY, # display textbox
	READING, # start reading text
	FINISHED, # finish current text
}
var current_state = State.READY
var text_queue = []
var num_of_intro_text = 5
# Called when the node enters the scene tree for the first time.
func _ready():
	hide_textbox()
	$BGM.play()
	$Cheering.play()
	queue_text("Ladies, gentlemen, and enchanted forest creatures, welcome to the most anticipated event in woodland entertainment – the War of Words, fondly known as WoW!")
	queue_text("Today, we bring you a competition where insults are slung with the precision of arrows, and banter reigns supreme in the heart of the enchanted forest.")
	queue_text("In this age-old tradition, we will witness a clash of wit and banter between a skilled huntress and a mischievous mushroom monster.")
	queue_text("Now, let me break down the rules of this verbal skirmish. Our contestants will engage in a lighthearted exchange of insults, showcasing their creativity and quick thinking. Each comeback will be met with an equally witty reply, turning the forest into a playground of clever taunts.")
	queue_text("Now, get ready for WoW – where arrows may miss, but insults hit the bullseye of amusement! The War of Words has begun!")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	match current_state:
		State.READY:
			if !text_queue.is_empty():
				display_text()
		State.READING:
			if !tween.is_running():
				change_state(State.FINISHED)
			elif Input.is_action_just_pressed("ui_accept"):
				text_content.visible_ratio = 1
				tween.stop()
				change_state(State.FINISHED)
		State.FINISHED:
			end_symbol.text = ">"
			if Input.is_action_just_pressed("ui_accept"):
				change_state(State.READY)
				hide_textbox()
				$SoundClick.play()
				num_of_intro_text = num_of_intro_text -1
				if(num_of_intro_text <= 0):
					SceneTransition.change_scene_slow("res://scenes/gameloop.tscn")


func hide_textbox():
	start_symbol.text = ""
	end_symbol.text = ""
	text_content.text = ""
	textbox_container.hide()

func show_textbox():
	start_symbol.text = "*"
	textbox_container.show()
	
func display_text():
	var next_text = text_queue.pop_front()
		
	text_content.text = next_text
	change_state(State.READING)
	show_textbox()
	tween = create_tween()
	text_content.visible_ratio = 0.0
	var tween_duration_time = 2.0
	var len_text = next_text.length()
	var max_length = 176.0
	tween_duration_time = (len_text/max_length)*tween_duration_time
	tween.tween_property(text_content, 'visible_ratio', 1, tween_duration_time)

func change_state(next_state):
	current_state = next_state
	match current_state:
		State.READY:
			debug_print("Switching to state READY")
		State.READING:
			debug_print("Switching to state READING")
		State.FINISHED:
			debug_print("Switching to state FINISHED")
			
		
func debug_print(text):
	if(debug):
		print(text)
		

func queue_text(next_text, type="text"):
	if type == "text":
		text_queue.push_back(next_text)
	elif type == "qte":
		text_queue.push_back('#')
		text_queue.push_back(next_text)
	else:
		debug_print("error in your queue text second argument.")
		
