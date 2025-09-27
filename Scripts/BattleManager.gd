extends Node
var current_player_move : base_move
var current_enemey_move : base_move
var number_of_turns_taken : int = 0
@onready var enemey_card_slot = $"../EnemeyCardSlot"
@onready var player_card_slot = $"../FriendlyCardSlot"
@onready var enemey_hand = $"../EnemeyHand"
@onready var card_manager = $"../CardManager"
@onready var playerdisplay = $"../FriendlyPlayedCard"
@onready var enemeydisplay = $"../EnemeyPlayedCard"
@onready var playerhand = $"../PlayerHand"
@onready var battletextdisplay = $BattleTextDisplay/RichTextLabel
var enemey : base_enemey
var card_damage_tween_time : float = 0.2

var battle_event_queue : Array = []
var is_processing_events : bool = false
var enemeydiedthisturn : bool = false
var playerdiedthisturn : bool = false
# Called when the node enters the scene tree for the first time.
func _ready():
	$"../FriendlyPlayedCard".end_player_turn.connect(end_player_turn)
	enemey = Globals.current_enemey


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func end_player_turn(player_move):
	current_player_move = player_move
	play_enemey_turn()

func play_enemey_turn():
	if enemey_card_slot.is_card_in_slot == false:
		place_enemey_card_in_slot(enemey_hand.enemey_hand[0])
		enemey_hand.remove_card_from_hand(enemey_hand.enemey_hand[0])
		enemey_hand.update_hand_positions()
		await enemey_card_slot.card_in_play
	current_enemey_move = decide_enemey_move()
	start_player_attack_phase(current_player_move,current_enemey_move)

func place_enemey_card_in_slot(enemey_card):
	var tween = get_tree().create_tween()
	tween.tween_property(enemey_card,"position",enemey_card_slot.position,0.2)
	await tween.finished
	card_manager.add_card_to_empty_slot(enemey_card,enemey_card_slot)

func decide_enemey_move():
	var enemey_card_info : base_card = enemey_card_slot.card_in_slot.card_info
	var player_card_info : base_card = player_card_slot.card_in_slot.card_info
	var highest_priority_move : base_move
	var highest_priority_move_number : int = -99999999
	for move in enemey_card_info.combat_actions.size():
		var current_priority : int = 0
		if enemey_card_info.combat_actions[move].damage >= player_card_info.current_health:
			current_priority = current_priority + 100
		if enemey_card_info.combat_actions[move].healing_move == true and enemey_card_info.current_health > enemey_card_info.combat_actions[move].healing:
			current_priority = current_priority - 15
		if enemey_card_info.combat_actions[move].healing_move == true and enemey_card_info.current_health < (float(enemey_card_info.current_health * 30))/100:
			current_priority = current_priority + 50
		if enemey_card_info.combat_actions[move].damaging_move == true and enemey_card_info.current_health > (float(enemey_card_info.current_health * 80))/100:
			current_priority = current_priority + 20
		if enemey_card_info.combat_actions[move].recoil_damage >= enemey_card_info.current_health:
			current_priority = current_priority - 100
		if current_priority >= highest_priority_move_number:
			highest_priority_move_number = current_priority
			highest_priority_move = enemey_card_info.combat_actions[move]
	return highest_priority_move

func start_player_attack_phase(player_move,enemey_move):
	playerdiedthisturn = false
	enemeydiedthisturn = false
	queue_battle_event("",[func():$BattleTextDisplay.visible = true],0.0)
	queue_battle_event(playerdisplay.Card_name + " Used " + player_move.Name,[],0.5)
	var did_move_fail = check_move_for_failure(player_move)
	if did_move_fail == false:
		if player_move.damage > 0:
			queue_damage_event_with_animation(enemeydisplay.Card_name,enemey_card_slot.card_in_slot.card_info,player_move.damage,"damage",func():handle_card_animations(player_move,enemey_move,create_card_context(enemeydisplay,playerdisplay,player_move)),1.0)
			queue_battle_event("",[func():enemey_card_slot.card_in_slot.update_card_visuals(),func():enemeydisplay.update_card_visuals(enemey_card_slot.card_in_slot)],0.0)
		if player_move.healing > 0:
			queue_battle_event("",[func():handle_card_animations(player_move,enemey_move,create_card_context(enemeydisplay,playerdisplay,player_move)),func():heal_card(player_card_slot.card_in_slot.card_info,player_move.healing)],0.0)
			queue_battle_event("",[func():playerdisplay.update_card_visuals(player_card_slot.card_in_slot)],0.0)
		if player_move.does_poison_damage == true:
			did_move_fail = check_move_for_failure(player_move,player_move.chance_to_poison)
			if did_move_fail == false:
				enemey_card_slot.card_in_slot.poisoned = true
				queue_battle_event(enemey_card_slot.card_in_slot.card_info.card_name + "is hurt by poison!",[func():handle_card_animations(player_move,enemey_move,create_card_context(enemeydisplay,playerdisplay,player_move))],0.5)
	if player_move.recoil_damage > 0:
		queue_damage_event_with_animation(playerdisplay.Card_name,player_card_slot.card_in_slot.card_info,player_move.recoil_damage,"recoil",func():,1.0)
		queue_battle_event("",[func():player_card_slot.card_in_slot.update_card_visuals(),func():playerdisplay.update_card_visuals(player_card_slot.card_in_slot)],0.0)


	queue_battle_event("",[func():check_fainting(enemey_card_slot.card_in_slot.card_info,enemeydisplay.Card_name,enemey_card_slot.card_in_slot)],0.0)
	queue_battle_event("",[func():check_fainting(player_card_slot.card_in_slot.card_info,playerdisplay.Card_name,player_card_slot.card_in_slot)],0.0)
	queue_battle_event("", [func(): start_enemey_attack_phase(player_move,enemey_move)], 0.0)
	process_battle_events()

func start_enemey_attack_phase(player_move,enemey_move):
	queue_battle_event(enemeydisplay.Card_name + " Used " + enemey_move.Name,[],0.5)
	var did_move_fail = check_move_for_failure(enemey_move)
	if did_move_fail == false:
		if enemey_move.damage > 0:
			queue_damage_event_with_animation(playerdisplay.Card_name,player_card_slot.card_in_slot.card_info,enemey_move.damage,"damage",func():handle_card_animations(player_move,enemey_move,create_card_context(playerdisplay,enemeydisplay,enemey_move)),1.0)
			queue_battle_event("",[func():player_card_slot.card_in_slot.update_card_visuals(),func():playerdisplay.update_card_visuals(player_card_slot.card_in_slot)],0.0)
		if enemey_move.healing > 0:
			queue_battle_event("",[func():handle_card_animations(player_move,enemey_move,create_card_context(playerdisplay,enemeydisplay,enemey_move)),func():heal_card(enemey_card_slot.card_in_slot.card_info,enemey_move.healing)],0.0)
			queue_battle_event("",[func():enemeydisplay.update_card_visuals(enemey_card_slot.card_in_slot)],0.0)
	else:
		queue_battle_event("But it failed!",[],0.5)
	if enemey_move.recoil_damage > 0 and enemey_card_slot.card_in_slot:
		queue_damage_event_with_animation(enemeydisplay.Card_name,enemey_card_slot.card_in_slot.card_info,enemey_move.recoil_damage,"recoil",func():,1.0)
		queue_battle_event("",[func():enemey_card_slot.card_in_slot.update_card_visuals(),func():enemeydisplay.update_card_visuals(enemey_card_slot.card_in_slot)],0.0)
	
	if !enemeydiedthisturn:
		queue_battle_event("",[func():check_fainting(enemey_card_slot.card_in_slot.card_info,enemeydisplay.Card_name,enemey_card_slot.card_in_slot)],0.0)
	if !playerdiedthisturn:
		queue_battle_event("",[func():check_fainting(player_card_slot.card_in_slot.card_info,playerdisplay.Card_name,player_card_slot.card_in_slot)],0.0)
	queue_battle_event("",[func():$BattleTextDisplay.visible = false,func():start_player_turn()],0.0)
	process_battle_events()


func queue_battle_event(text: String,callbacks: Array,delay: float) -> void:
	battle_event_queue.append({"text": text,"callbacks": callbacks,"delay": delay})

func process_battle_events() -> void:
	if battle_event_queue.is_empty():
		return
	is_processing_events = true
	var event = battle_event_queue.pop_front()
	# Show text first
	await show_battle_text_message(event.text, event.delay)
	# Run all callbacks in parallel
	var parallel_tasks: Array = []
	for callback in event.callbacks:
		if callback != null:
			parallel_tasks.append(callback.call_deferred())
	if event.text and !event.text == "":
		await get_tree().create_timer(1.0).timeout
	is_processing_events = false
	process_battle_events()


func start_player_turn():
	current_player_move = null
	current_enemey_move = null
	card_manager.can_drag_cards = true
	number_of_turns_taken = number_of_turns_taken + 1
	playerdisplay.start_player_turn()
	player_card_slot.check_card_status()
	enemey_card_slot.check_card_status()
	check_if_player_lost()
	if enemey_hand.enemey_hand == [] and !enemey_card_slot.card_in_slot:
		playerdisplay.disable_player_moves()
		player_won()

func check_if_player_lost():
	if playerhand.player_hand == [] and !player_card_slot.card_in_slot:
		player_lost()

func player_lost():
	if enemey.enemey_hand == [] and enemey_card_slot.is_card_in_slot == false:
		player_won()
		return
	
	get_tree().quit()

func player_won():
	queue_battle_event("",[func():$BattleTextDisplay.visible = true],0.0)
	queue_battle_event("You won!" + " You earned " + str(calculate_money_earnings()) + "$!",[],0.5)
	queue_battle_event("",[func():$BattleTextDisplay.visible = false],0.0)
	process_battle_events()


func calculate_money_earnings():
	var total_money : int
	for i in enemey.enemey_hand.size():
		total_money = total_money + enemey.enemey_hand[i].Max_Health
		for move in enemey.enemey_hand[i].combat_actions:
			total_money = total_money + move.move_cost
	return total_money

func show_battle_text_message(text : String, duration : float):
	battletextdisplay.text = text
	var text_scroll_tween = get_tree().create_tween()
	battletextdisplay.visible_ratio = 0
	battletextdisplay.visible = true
	text_scroll_tween.tween_property(battletextdisplay,"visible_ratio",1,duration)
	await text_scroll_tween.finished
	return


func wait_for_key_press(action_name: String) -> void:
	while not Input.is_action_just_pressed(action_name):
		await get_tree().process_frame
	await get_tree().process_frame

func handle_card_animations(_player_move, _enemey_move, card_to_animate_context):
	var blink_tween = get_tree().create_tween()
	if card_to_animate_context.move.damage > 0:
		handle_card_animation_rotation_and_movement(card_to_animate_context)
		blink_tween.tween_method(func(newvalue): SetBlinkShaderParameters(card_to_animate_context.attacking_display, newvalue), 1, 0.0,card_damage_tween_time+0.05)
	if card_to_animate_context.move.healing > 0:
		card_to_animate_context.caster_display.healing_particles.emitting = true
		blink_tween.tween_method(func(newvalue): SetBlinkShaderParameters(card_to_animate_context.caster_display, newvalue), 1, 0.0,card_damage_tween_time+0.05)
	if card_to_animate_context.move.does_poison_damage == true:
		pass


func SetBlinkShaderParameters(display, newvalue : float):
	display.material.set_shader_parameter("blink_intensity", newvalue)


func handle_card_animation_rotation_and_movement(card_to_move_context):
	var rotation_angle
	var movement
	if enemeydisplay.name == card_to_move_context.attacking_display.name:
		rotation_angle = (card_to_move_context.move.damage/2) * get_process_delta_time()
		movement = Vector2(card_to_move_context.attacking_display.position.x + card_to_move_context.move.damage ,card_to_move_context.attacking_display.position.y)
	else:
		rotation_angle= -(card_to_move_context.move.damage/2) * get_process_delta_time()
		movement  = Vector2(card_to_move_context.attacking_display.position.x - card_to_move_context.move.damage ,card_to_move_context.attacking_display.position.y)
	var original_position = card_to_move_context.attacking_display.position
	var original_rotation = card_to_move_context.attacking_display.rotation_degrees
	card_to_move_context.attacking_display.animation_player.speed_scale = card_damage_tween_time * 5
	card_to_move_context.attacking_display.animation_player.play("card_flip")
	card_to_move_context.attacking_display.animation_player.play_backwards("card_flip")
	give_rotation_movement_tween_propertys(card_to_move_context.attacking_display,rotation_angle,movement,original_rotation,original_position)

func give_rotation_movement_tween_propertys(carddisplay,rotation_angle,movement,original_rotation,original_position):
	var rotation_tween = get_tree().create_tween()
	var movement_tween = get_tree().create_tween()
	rotation_tween.tween_property(carddisplay, "rotation", rotation_angle, card_damage_tween_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rotation_tween.tween_property(carddisplay, "rotation", original_rotation, card_damage_tween_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	movement_tween.tween_property(carddisplay, "position", movement, card_damage_tween_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	movement_tween.tween_property(carddisplay, "position", original_position, card_damage_tween_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await movement_tween.finished


func create_card_context(attacking_display,caster_display,move):
	var context = card_context.new()
	context.caster_display = caster_display
	context.attacking_display = attacking_display
	context.move = move
	return context

func check_move_for_failure(move, move_accuracy : float = 1):
	var accuracy_check : float = randf_range(0,1)
	if accuracy_check >= move_accuracy:
		queue_battle_event("But It Missed!",[],0.5)
		return true
	if enemeydiedthisturn == true:
		queue_battle_event("But It Failed!",[],0.5)
		return true
	if playerdiedthisturn == true:
		queue_battle_event("But It Failed!",[],0.5)
		return true
	return false
	#Add conditions later


func queue_damage_event_with_animation(target_name: String,target_card_info,damage_amount: int,damage_type: String,animation_callback: Callable,delay: float = 1.0):
	if damage_amount <= 0:
		return
	var damage_text: String = ""
	match damage_type:
		"recoil":
			damage_text = target_name + " took recoil damage!"
		"poison":
			damage_text = target_name + " is hurt by poison!"
		"burn":
			damage_text = target_name + " is scorched by flames!"
		_:
			damage_text = target_name + " took damage!"
	
	var callbacks: Array = []
	var predicted_health = target_card_info.current_health - damage_amount
	if predicted_health <= 0:
		pass
	callbacks.append(func():target_card_info.current_health -= damage_amount)
	if animation_callback:
		callbacks.append(animation_callback)
	queue_battle_event(damage_text, callbacks, delay)


func check_fainting(card_info, display_name: String,card):
	if card_info.current_health <= 0:
		queue_battle_event(display_name + " Fainted!",[],0.5)
		queue_battle_event("",[deal_with_fainted_card(card)],0.5)

func deal_with_fainted_card(card):
	if card.in_card_slot.friendlyslot == true:
		playerdiedthisturn = true
	card.remove_card()
	if enemey_hand.enemey_hand.size() > 0:
		var next_card_sent_out = enemey_hand.enemey_hand[0]
		queue_battle_event(enemey.enemey_name + " sent out " + next_card_sent_out.card_info.card_name + "!",[func():enemeydisplay.change_to_new_card(enemey_card_slot.card_in_slot)],1.0)
		enemey_card_slot.card_in_slot = next_card_sent_out
		place_enemey_card_in_slot(next_card_sent_out)
		enemey_hand.remove_card_from_hand(next_card_sent_out)
		enemey_hand.update_hand_positions()
		card.in_card_slot.card_in_play.emit(card)
	if card.in_card_slot.friendlyslot == false:
		enemeydiedthisturn = true

func heal_card(card_info, heal_amount):
	card_info.current_health += heal_amount
	if card_info.current_health > card_info.Max_Health:
		card_info.current_health = card_info.Max_Health
