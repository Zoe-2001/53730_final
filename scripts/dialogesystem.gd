extends CanvasLayer

var debug = true
@onready var reaction_bar = $TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/Text
@onready var textbox_container = $TextboxContainer
@onready var start_symbol = $TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/Start
@onready var end_symbol = $TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/End
@onready var text_content = $TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/Text

@onready var bar = $ReactionUISet
@onready var bar_indicator = $ReactionUISet/ReactionBarContainer/MarginContainer2/ReactionBarIndicator
@onready var qte_timerbar = $ReactionUISet/MarginContainer/QTETimerBar
@onready var qte_timer = $ReactionUISet/MarginContainer/QTETimer

@onready var mushroom_animation = $Characters/MushroomAnimation
@onready var mushroom_animation_indicator = $Characters/MushroomAnimation/AnimatedSprite2D
@onready var char_animation = $Characters/HuntressAnimation
@onready var char_animation_indicator = $Characters/HuntressAnimation/AnimatedSprite2D2
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
var text_character_queue = []
var text_id_list = ['#d1','#d2','#d3','#d4','#d5']
var reply_id = ''
# Called when the node enters the scene tree for the first time.
func _ready():
	hide_textbox()
	bar.hide()
	mushroom_animation.play("idle")
	char_animation.play("idle")
	mushroom_animation_indicator.play("idle")
	char_animation_indicator.play("idle")
	mushroom_healthbar.value = 100
	char_healthbar.value = 100
	qte_timer.wait_time = 3


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
			qte_timer.start()
			change_state(State.QTE)
			highlight_player(true)
			bar_indicator.start_qte() # switch to ready state of the indicator
		State.QTE:
			qte_timerbar.value = qte_timer.time_left/ qte_timer.wait_time * 100
			if(qte_timer.time_left <= 0.01):
				qte_failed()
				bar.hide()
				change_state(State.READY)
				hide_textbox()
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
	if(char_healthbar.value-qte_attack_HP <= 1):
		char_animation.play("death")
	else:
		char_animation.play("takehit")
	tween = create_tween()
	tween.tween_property(char_healthbar, 'value', char_healthbar.value-qte_attack_HP, 1)	

func qte_succeeded():
	$SoundHit.play()
	debug_print("qte succeed - good option")
	qte_result = QTE_RESULT.GOOD
	if(mushroom_healthbar.value-qte_attack_HP <= 1):
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
	var next_speaking_character = text_character_queue.pop_front()
	if(next_speaking_character == "player"):
		highlight_player(true)
	else:
		highlight_player(false)
			
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


func highlight_player(yes=true):
	if(yes):
		mushroom_animation.modulate = Color(0.5,0.5,0.5)
		char_animation.modulate = Color(1,1,1)
		char_animation_indicator.visible = true
		mushroom_animation_indicator.visible = false
	else:
		char_animation.modulate = Color(0.5,0.5,0.5)
		mushroom_animation.modulate = Color(1,1,1)
		mushroom_animation_indicator.visible = true
		char_animation_indicator.visible = false


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

	elif !text_id_list.is_empty() and text_queue.is_empty():
		var text_id = text_id_list.pop_front()
		add_game_text(text_id)
		
		if text_id[0] == '#': # indicates upcoming text has qte followed
			qte_followed = true
			reply_id = text_id.substr(1)
			debug_print('upcoming text has qte followed')



func queue_text(text):
	text_queue.push_back(text)
	text_character_queue.push_back("player")

func queue_enemy_text(text):
	text_queue.push_back(text)
	text_character_queue.push_back("enemy")

func add_game_text(text_id):
	match text_id:
		'#d1':
			queue_enemy_text("You know, you move through the forest like a lost squirrel. Are you sure you're a real huntress?")
		'^d1':
			queue_text("I prefer the term 'stealthy,' unlike you, Mr. Fungi, announcing your presence with every squishy step.")
			queue_enemy_text("Squishy? How dare you insult the elegance of my spore-infused stride!")
		'xd1':
			queue_enemy_text("Have nothing to say, huh? Your silence speaks volumes, just like your hunting success—nonexistent.")
		'#d2':
			queue_enemy_text("Your bow looks like it's been chewed on by a pack of beavers. Is that the best you can do?")
		'^d2':
			queue_text("It's a customized design, a bit too sophisticated for someone rooted in one place. Maybe I should craft you a walking stick?")
			queue_enemy_text("Craft me a walking stick? I'll have you know my roots are firmly planted in style!")
		'xd2':
			queue_enemy_text("Have nothing to say, huh? Your lack of a comeback is as disappointing as your archery skills.")
		'#d3':
			queue_enemy_text("I've heard your cooking is so bad, even the forest critters wouldn't touch it.")
		'^d3':
			queue_text("They're just jealous they can't appreciate my culinary artistry. Unlike you, they lack taste buds.")
			queue_enemy_text("Artistry? I'd rather feast on my own spores than endure your culinary experiments!")
		'xd3':
			queue_enemy_text("Have nothing to say, huh? Even the critters know when to avoid a taste disaster.")
		'#d4':
			queue_enemy_text("Your footsteps are so heavy; even the rocks in the forest are complaining.")
		'^d4':
			queue_text("I'm just letting the forest know I'm here. Unlike you, who's practically invisible until someone steps on you.")
			queue_enemy_text("Invisible? I'm a master of camouflage. You, on the other hand, couldn't sneak up on a snail.")
		'xd4':
			queue_enemy_text("Have nothing to say, huh? Even the rocks can't bear the weight of your failures.")
		'#d5':
			queue_enemy_text("Are those twigs in your hair, or did you forget to comb it this century?")
		'^d5':
			queue_text("Twigs are the latest trend in woodland fashion. You should try it sometime. It might distract from your lack of branches.")
			queue_enemy_text("Lack of branches? I'll have you know I'm the envy of every sapling in the forest!")
		'xd5':
			queue_enemy_text("Have nothing to say, huh? Your silence is as tangled as your unkempt hair.")	
		_:
			debug_print('No matching reply id for['+ text_id +']. Check your ids in add_game_text.')
