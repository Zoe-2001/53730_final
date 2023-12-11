extends CanvasLayer

var debug = false
@onready var reaction_bar = $TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/Text
@onready var textbox_container = $TextboxContainer
@onready var start_symbol = $TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/Start
@onready var end_symbol = $TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/End
@onready var text_content = $TextboxContainer/MarginContainer/MarginContainer/HBoxContainer/Text

@onready var bar = $ReactionUISet
@onready var bar_indicator = $ReactionUISet/ReactionBarContainer/MarginContainer2/ReactionBarIndicator
@onready var qte_timerbar = $ReactionUISet/MarginContainer/QTETimerBar
@onready var qte_timer = $ReactionUISet/MarginContainer/QTETimer
@onready var combo_label = $BackgroundAndTexts/ComboCount

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
	GAMEOVER,
}
var current_state = State.READY
var game_over = false
enum QTE_RESULT {
	GOOD,
	BAD,
}
var qte_followed = false # if there's a qte after displaying the current text
var qte_result = QTE_RESULT.BAD
var qte_attack_HP = 10
var qte_combo = 0

var text_queue = []
var text_character_queue = []
var text_id_list = ['#d1','#d2','#d3','#d4','#d5','#d6','#d7','#d8','#d9','#d10','#d11','#d12','#d13']
var reply_id = ''
# Called when the node enters the scene tree for the first time.
func _ready():
	hide_textbox()
	bar.hide()
	combo_label.hide()
	mushroom_animation.play("idle")
	char_animation.play("idle")
	mushroom_animation_indicator.play("idle")
	char_animation_indicator.play("idle")
	mushroom_healthbar.value = 100
	char_healthbar.value = 100
	qte_timer.wait_time = 2.5


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(SceneTransition.animation_stopped()):
		# finished other animations like takehit so switch back to idle
		if(!mushroom_animation.is_playing()):
			if(current_state != State.GAMEOVER):
				mushroom_animation.play("idle")
			else:
				if(qte_result == QTE_RESULT.BAD):
					mushroom_animation.play("idle")
			
		if(!char_animation.is_playing()):
			if(current_state != State.GAMEOVER):
				char_animation.play("idle")
			else:
				if(qte_result == QTE_RESULT.GOOD):
					char_animation.play("idle")
					
		match current_state:
			State.READY:
				get_next_queue_text()
				if !text_queue.is_empty():
					display_text()
				if game_over:
					change_state(State.GAMEOVER)
			State.READING:
				if !tween.is_running():
					change_state(State.FINISHED)
				#elif Input.is_action_just_pressed("ui_accept"):
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
					hide_textbox()
					change_state(State.READY)
				if Input.is_action_just_pressed("ui_accept"):
					if bar_indicator.get("entered_green"):
						qte_succeeded()
					else:
						qte_failed()
					bar.hide()
					hide_textbox()
					change_state(State.READY)
			State.GAMEOVER:
				if((!char_animation.is_playing() or !mushroom_animation.is_playing()) and Input.is_action_just_pressed("ui_accept")):
					if(qte_result == QTE_RESULT.BAD): 
						SceneTransition.change_scene("res://scenes/you_lost.tscn")
					else:
						SceneTransition.change_scene("res://scenes/you_won.tscn")
				

func qte_failed():
	$SoundTakehit.play()
	combo_label.hide()
	qte_combo = 0
	debug_print("qte failed - bad option")
	qte_result = QTE_RESULT.BAD
	mushroom_animation.play("attack")
	if(char_healthbar.value-qte_attack_HP <= 1):
		char_animation.play("death")
		game_over = true
	else:
		char_animation.play("takehit")
	tween = create_tween()
	tween.tween_property(char_healthbar, 'value', char_healthbar.value-qte_attack_HP, 1)	

func qte_succeeded():
	$SoundHit.play()
	qte_combo = qte_combo + 1
	if qte_combo > 1:
		combo_label.show()
		combo_label.text = "Combo x" + str(qte_combo)
	debug_print("qte succeed - good option")
	qte_result = QTE_RESULT.GOOD
	if(mushroom_healthbar.value-qte_attack_HP <= 1):
		mushroom_animation.play("death")
		game_over = true
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
	match current_state:
		State.READY:
			debug_print("Switching to state READY")
		State.READING:
			debug_print("Switching to state READING")
		State.FINISHED:
			debug_print("Switching to state FINISHED")
		State.START_QTE:
			debug_print("Switching to state START_QTE")
		State.QTE:
			debug_print("Switching to state QTE")
		State.GAMEOVER:
			debug_print("Switching to state GAMEOVER")
			
		
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
			queue_text("(Lost squirrel? Well, that stings a bit...)")
		'#d2':
			queue_enemy_text("Your bow looks like it's been chewed on by a pack of beavers. Is that the best you can do?")
		'^d2':
			queue_text("It's a customized design, a bit too sophisticated for someone rooted in one place. Maybe I should craft you a walking stick?")
			queue_enemy_text("Craft me a walking stick? I'll have you know my roots are firmly planted in style!")
		'xd2':
			queue_enemy_text("Have nothing to say, huh? Your lack of a comeback is as disappointing as your archery skills.")
			queue_text("(I guess my crafting skills could use some improvement.)")
		'#d3':
			queue_enemy_text("I've heard your cooking is so bad, even the forest critters wouldn't touch it.")
		'^d3':
			queue_text("They're just jealous they can't appreciate my culinary artistry. Unlike you, they lack taste buds.")
			queue_enemy_text("Artistry? I'd rather feast on my own spores than endure your culinary experiments!")
		'xd3':
			queue_enemy_text("Have nothing to say, huh? Even the critters know when to avoid a taste disaster.")
			queue_text("(Ouch, maybe I should stick to hunting and leave the cooking to someone else.)")
		'#d4':
			queue_enemy_text("Your footsteps are so heavy; even the rocks in the forest are complaining.")
		'^d4':
			queue_text("I'm just letting the forest know I'm here. Unlike you, who's practically invisible until someone steps on you.")
			queue_enemy_text("Invisible? I'm a master of camouflage. You, on the other hand, couldn't sneak up on a snail.")
		'xd4':
			queue_enemy_text("Have nothing to say, huh? Even the rocks can't bear the weight of your failures.")
			queue_text("(Great, even the rocks are against me. I need to learn to tread more lightly.)")
		'#d5':
			queue_enemy_text("Are those twigs in your hair, or did you forget to comb it this century?")
		'^d5':
			queue_text("Twigs are the latest trend in woodland fashion. You should try it sometime. It might distract from your lack of branches.")
			queue_enemy_text("Lack of branches? I'll have you know I'm the envy of every sapling in the forest!")
		'xd5':
			queue_enemy_text("Have nothing to say, huh? Your silence is as tangled as your unkempt hair.")	
			queue_text("(Twigs? It's called embracing the natural look. Not everyone needs a perfectly coiffed 'do in the middle of a forest, you know.)")
		'#d6':
			queue_enemy_text("Your aim is so off, the trees are considering dodging your arrows.")
		'^d6':
			queue_text("I'm just giving the trees a chance to exercise. Unlike you, stuck in one spot, not even lifting a cap.")
			queue_enemy_text("Exercise for the trees? I provide shade and oxygen. What do your arrows provide, other than disappointment?")
		'xd6':
			queue_enemy_text("Have nothing to say, huh? Even the trees are shaking their leaves in disappointment at your lack of skill.")
			queue_text("(Well, I guess my marksmanship needs work. Even the trees are getting in on the critique now, huh?)")
		'#d7':
			queue_enemy_text("Your idea of tracking is like following a breadcrumb trail in a hurricane.")
		'^d7':
			queue_text("I like to keep things interesting. If it were too easy, even you might stand a chance of being a decent challenge.")
			queue_enemy_text("Decent challenge? I'm the king of hide and seek in the fungal kingdom. Your tracking skills are laughable.")
		'xd7':
			queue_enemy_text("Have nothing to say, huh? Your silence is a testament to your inability to find anything, even your own wit.")
			queue_text("(Alright, maybe I'm not the forest detective I thought I was. Tracking in a hurricane? That's a new low, even for me.)")
		'#d8':
			queue_enemy_text("Your campfire stories are so boring; even the fire tries to put itself out.")
		'^d8':
			queue_text("My stories are an acquired taste, much like your spores. Not everyone can appreciate the finer things in life.")
			queue_enemy_text("Acquired taste? I've had more excitement watching moss grow. Your stories are a cure for insomnia.")
		'xd8':
			queue_enemy_text("Have nothing to say, huh? Even the flames can't bear the agony of your storytelling.")
			queue_text(" (Well, that hit close to home. Maybe I should work on my storytelling skills. Even the flames want to escape my tales, apparently.)")
		'#d9':
			queue_enemy_text("Your fashion sense is so outdated; even the ancient oaks are cringing.")
		'^d9':
			queue_text("Outdated? I'll have you know, retro is in. The oaks just can't keep up with the latest trends.")
			queue_enemy_text("Retro? More like a relic from the compost heap. The oaks deserve better.")
		'xd9':
			queue_enemy_text("Have nothing to say, huh? Your silence is as out of style as your wardrobe.")
			queue_text("(Maybe I should reconsider my fashion choices. Even the trees are giving me a hard time about it.)")

		'#d10':
			queue_enemy_text("Your choice of companionship is as lonesome as a single mushroom in an open field.")
		'^d10':
			queue_text("Quality over quantity, my fungal friend. I'd rather have a few loyal allies than a crowd of fair-weather fungi.")
			queue_enemy_text("Fair-weather fungi? Your allies are probably too embarrassed to show their faces.")
		'xd10':
			queue_enemy_text("Have nothing to say, huh? Your silence speaks volumes about your lack of allies.")
			queue_text("(Maybe I should work on expanding my social circle. Even the mushrooms are questioning my choices.)")

		'#d11':
			queue_enemy_text("Your laughter echoes through the forest like a wounded animal. Have you considered a mute spell?")
		'^d11':
			queue_text("Laughter is the best medicine, even if it sounds a bit wild. You should try it sometime.")
			queue_enemy_text("Best medicine? More like a forest-wide annoyance. The animals probably wear earplugs when you're around.")
		'xd11':
			queue_enemy_text("Have nothing to say, huh? Your silence is a relief for the ears of the entire woodland.")
			queue_text("(Well, maybe I should work on toning down my laughter. Even the creatures of the forest are complaining.)")

		'#d12':
			queue_enemy_text("Your night vision is so poor; even the nocturnal creatures use lanterns when you're around.")
		'^d12':
			queue_text("Night vision is overrated. I prefer to enjoy the moonlit scenery without seeing every twig and leaf.")
			queue_enemy_text("Moonlit scenery? More like stumbling through the dark. The creatures are probably guiding you out of pity.")
		'xd12':
			queue_enemy_text("Have nothing to say, huh? Your silence is as dark as your vision.")
			queue_text("(Maybe I should invest in some night vision goggles. Even the creatures are questioning my ability to navigate in the dark.)")
		'#d13':
			queue_enemy_text("Your wilderness survival skills are so lacking; even a houseplant would outlast you.")
		'^d13':
			queue_text("Survival skills are overrated. I'm more of a 'blend in with nature' kind of person.")
			queue_enemy_text("'Blend in with nature'? More like a master of the lost-and-confused technique. Even the ferns are mocking you.")
		'xd13':
			queue_enemy_text("Have nothing to say, huh? Your silence is as lost as you are in the woods.")
			queue_text("(Maybe I should take a survival course. Even the plants are questioning my ability to navigate the great outdoors.)")
		'#d14':
			queue_enemy_text("Your tree-climbing skills are abysmal; even the sloths are laughing at your attempts.")
		'^d14':
			queue_text("I prefer to keep my feet on solid ground, thank you very much. Tree climbing is so last century.")
			queue_enemy_text("Last century? Your lack of altitude is showing. Even the acorns can out-climb you.")
		'xd14':
			queue_enemy_text("Have nothing to say, huh? Your silence is as grounded as your tree-climbing aspirations.")
			queue_text("(Maybe I should work on my tree-climbing game. Even the slowest creatures are having a good laugh at my attempts.)")

		'#d15':
			queue_enemy_text("Your stealth is on par with a clumsy elephant; even the butterflies can out-sneak you.")
		'^d15':
			queue_text("Stealth is overrated. I like to announce my presence. Keeps the forest on its toes.")
			queue_enemy_text("On its toes? More like on its back, snoring from boredom. Even the snails move more gracefully.")
		'xd15':
			queue_enemy_text("Have nothing to say, huh? Your silence is as loud as your 'stealthy' approach.")
			queue_text("(Maybe I should practice a more subtle entrance. Even the butterflies are giving me pointers on sneaking around.)")

		'#d16':
			queue_enemy_text("Your sense of direction is as reliable as a broken compass; even the migratory birds won't take your advice.")
		'^d16':
			queue_text("I prefer to take the scenic route. Compasses are for those in a hurry.")
			queue_enemy_text("Scenic route? More like the 'getting lost' route. Even the ants have better navigation skills.")
		'xd16':
			queue_enemy_text("Have nothing to say, huh? Your silence is as directionless as your wanderings.")
			queue_text("(Maybe I should reconsider my navigation methods. Even the migratory birds are questioning my route choices.)")

		'#d17':
			queue_enemy_text("Your campfire building skills are atrocious; even the damp logs refuse to ignite.")
		'^d17':
			queue_text("I like my fires to have a bit of a challenge. Keeps things interesting.")
			queue_enemy_text("Challenge? Your fires are more like a damp squib. Even the rain can't extinguish your mediocrity.")
		'xd17':
			queue_enemy_text("Have nothing to say, huh? Your silence is as cold as your feeble attempts at campfire mastery.")
			queue_text("(Maybe I should invest in some fire-starting skills. Even the damp logs are mocking my attempts to light a decent campfire.)")

		'#d18':
			queue_enemy_text("Your plant identification skills are laughable; even the mushrooms roll their caps at your guesses.")
		'^d18':
			queue_text("Plants like their mysteries. Who am I to spoil the fun with accurate identifications?")
			queue_enemy_text("Mysteries? More like confusion. Even the weeds are more discerning than you.")
		'xd18':
			queue_enemy_text("Have nothing to say, huh? Your silence is as unidentified as the flora in your presence.")
			queue_text("(Maybe I should brush up on my plant knowledge. Even the mushrooms are questioning my ability to tell a fern from a daisy.)")

		'#d19':
			queue_enemy_text("Your singing voice is so grating; even the rocks cover their ears when you hum a tune.")
		'^d19':
			queue_text("I prefer to call it a unique woodland melody. The rocks just haven't refined their taste yet.")
			queue_enemy_text("Unique melody? More like a forest-wide cacophony. Even the wind cringes at your attempts.")
		'xd19':
			queue_enemy_text("Have nothing to say, huh? Your silence is as tone-deaf as your attempts at serenading the forest.")
			queue_text("(Maybe I should stick to humming in the shower. Even the rocks are protesting my attempts at a woodland serenade.)")

		'#d20':
			queue_enemy_text("Your treehouse-building skills are subpar; even the squirrels wouldn't trust your architectural prowess.")
		'^d20':
			queue_text("Squirrels can be quite demanding clients. I like to keep my constructions unique.")
			queue_enemy_text("Unique? Your treehouses are more like bird nests on stilts. Even the beavers build more reliable shelters.")
		'xd20':
			queue_enemy_text("Have nothing to say, huh? Your silence is as shaky as the foundation of your treehouse endeavors.")
			queue_text("(Maybe I should take a course in treehouse architecture. Even the squirrels are side-eyeing my attempts at providing woodland housing.)")

		_:
			debug_print('No matching reply id for['+ text_id +']. Check your ids in add_game_text.')
