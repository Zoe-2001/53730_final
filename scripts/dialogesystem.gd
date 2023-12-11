extends CanvasLayer

var debug = true
@onready var reaction_bar = $TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/Text
@onready var textbox_container = $TextboxContainer
@onready var start_symbol = $TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/Start
@onready var end_symbol = $TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/End
@onready var text_content = $TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/Text
@onready var bar = $ReactionBarContainer
@onready var bar_indicator = $ReactionBarContainer/MarginContainer2/ReactionBarIndicator
@onready var mushroom_animation = $Characters/MushroomAnimation
@onready var char_animation = $Characters/HuntressAnimation
@onready var mushroom_healthbar = $HealthBars/MushroomHealthBar
@onready var char_healthbar = $HealthBars/HuntressHealthBar

var tween : Tween

enum State {
	READY, # display textbox
	READING, # start reading text
	FINISHED, # finish current text
	START_QTE, # start qte
	QTE, # game bar appears (text retained)
}
var current_state = State.READY

enum QTE_RESULT {
	GOOD,
	BAD,
}
var qte_followed = false # if there's a qte after displaying the current text
var qte_result = QTE_RESULT.BAD
var qte_attack_HP = 20

var text_queue = []
var text_id_list = ['i1', '#d1','d2']
var reply_id = ''
# Called when the node enters the scene tree for the first time.
func _ready():
	hide_textbox()
	bar.hide()
	mushroom_animation.play("idle")
	char_animation.play("idle")
	mushroom_healthbar.value = 20
	char_healthbar.value = 20


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# finished other animations like takehit so switch back to idle
	if(!mushroom_animation.is_playing()):
		mushroom_animation.play("idle")
	if(!char_animation.is_playing()): 
		char_animation.play("idle")
			
	match current_state:
		State.READY:
			get_next_queue_text()
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
				$SoundClick.play()
				if(!qte_followed):
					change_state(State.READY)
					hide_textbox()
				else:
					change_state(State.START_QTE)	
					
		State.START_QTE:
			bar.show()
			change_state(State.QTE)
			bar_indicator.start_qte() # switch to ready state of the indicator
		State.QTE:
			if Input.is_action_just_pressed("ui_accept"):
				if bar_indicator.get("entered_green"):
					qte_succeeded()
				else:
					qte_failed()
				bar.hide()
				change_state(State.READY)
				hide_textbox()
			

func qte_failed():
	$SoundTakehit.play()
	debug_print("qte failed - bad option")
	qte_result = QTE_RESULT.BAD
	mushroom_animation.play("attack")
	if(char_healthbar.value-qte_attack_HP <= 0):
		char_animation.play("death")
	else:
		char_animation.play("takehit")
	tween = create_tween()
	tween.tween_property(char_healthbar, 'value', char_healthbar.value-qte_attack_HP, 1)	

func qte_succeeded():
	$SoundHit.play()
	debug_print("qte succeed - good option")
	qte_result = QTE_RESULT.GOOD
	if(mushroom_healthbar.value-qte_attack_HP <= 0):
		mushroom_animation.play("death")
	else:
		mushroom_animation.play("takehit")
	char_animation.play("attack")
	tween = create_tween()
	tween.tween_property(mushroom_healthbar, 'value', mushroom_healthbar.value-qte_attack_HP, 1)				

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

	text_content.visible_ratio = 0.0
	var tween_duration_time = 2.0
	var len_text = next_text.length()
	var max_length = 176.0
	tween = create_tween()
	tween_duration_time = (len_text/max_length)*tween_duration_time
	tween.tween_property(text_content, 'visible_ratio', 1, tween_duration_time)

func change_state(next_state):
	current_state = next_state
	'''match current_state:
		State.READY:
			debug_print("Switching to state READY")
		State.READING:
			debug_print("Switching to state READING")
		State.FINISHED:
			debug_print("Switching to state FINISHED")
		State.START_QTE:
			debug_print("Switching to state START_QTE")
		State.QTE:
			debug_print("Switching to state QTE")'''
			
		
func debug_print(text):
	if(debug):
		print(text)
		

func get_next_queue_text():
	if qte_followed: # means that just finished qte, need add qte reply
			qte_followed = false
			var text_id = reply_id
			match qte_result:
				QTE_RESULT.GOOD:
					text_id = '^'+text_id
				QTE_RESULT.BAD:
					text_id = 'x'+text_id
			debug_print('qte reply id is: '+ text_id)
			add_game_text(text_id)

	elif !text_id_list.is_empty():
		var text_id = text_id_list.pop_front()
		add_game_text(text_id)
		
		if text_id[0] == '#': # indicates upcoming text has qte followed
			qte_followed = true
			reply_id = text_id.substr(1)
			debug_print('upcoming text has qte followed')



func queue_text(text):
	text_queue.push_back(text)


func add_game_text(text_id):
	match text_id:
		'i1':
			queue_text('[Alex enters the tavern, the air thick with tension. Donovan, a hooded figure, beckons Alex over.]')
		'#d1':
			queue_text("Donovan: Ah, you made it. Took your sweet time, didn't you?")
		'^d1':
			queue_text("Alex: Apologies for the delay. What's this all about?")
			queue_text("Donovan: Straight to the point, good.")
		'xd1':
			queue_text("Alex: Watch your tone. I'm here, aren't I?")
			queue_text("Donovan: Wow, that's a bit rude.")
		'd2':
			queue_text("Donovan: Anyway, I've got a job for you, and I don't like to waste time.")
		_:
			debug_print('No matching reply id for['+ text_id +']. Check your ids in add_game_text.')
