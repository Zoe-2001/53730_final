extends CanvasLayer

@onready var textbox_container = $TextboxContainer
@onready var start_symbol = $TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/Start
@onready var end_symbol = $TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/End
@onready var text_content = $TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/Text
var tween : Tween

enum State {
	READY,
	READING,
	FINISHED,
}
var current_state = State.READY

var text_queue = []

# Called when the node enters the scene tree for the first time.
func _ready():
	hide_textbox()
	queue_text("First text. First text. First text. First text. First text. First text. First text. First text. First text. First text. First text. First text. First text. First text. ")
	queue_text("Second text!Second text!Second text!Second text!Second text!Second text!Second text!Second text!")
	queue_text("Third text! Third text! Third text!")


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
				end_symbol.text = ">"
				change_state(State.FINISHED)
		State.FINISHED:
			if Input.is_action_just_pressed("ui_accept"):
				change_state(State.READY)
				hide_textbox()


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
			print("Switching to state READY")
		State.READING:
			print("Switching to state READING")
		State.FINISHED:
			print("Switching to state FINISHED")
			
func queue_text(next_text):
	text_queue.push_back(next_text)
