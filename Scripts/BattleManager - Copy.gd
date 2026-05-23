extends Node
const Damage_Move_Degrees : int = 15
const Damage_Move_Movement : int = 100

var current_player_move : base_move
var current_enemy_move : base_move
var number_of_turns_taken : int = 0
@onready var enemy_card_slot = $"../enemyCardSlot"
@onready var player_card_slot = $"../FriendlyCardSlot"
@onready var enemy_hand = $"../enemyHand"
@onready var card_manager = $"../CardManager"
@onready var playerdisplay = $"../FriendlyPlayedCard"
@onready var enemydisplay = $"../enemyPlayedCard"
@onready var playerhand = $"../PlayerHand"
@onready var battletextdisplay = $BattleTextDisplay/RichTextLabel
@onready var enemydecisionmaker = $enemyDecisionMaker
@onready var carddisplaymanager = $CardDisplayManager
var enemy : base_enemy
var card_damage_tween_time : float = 0.2

var battle_event_queue : Array = []
var is_processing_events : bool = false
var enemydiedthisturn : bool = false
var playerdiedthisturn : bool = false
# Called when the node enters the scene tree for the first time.
func _ready():
	$"../FriendlyPlayedCard".end_player_turn.connect(end_player_turn)
	enemy = Globals.current_enemy


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func end_player_turn(player_move):
	current_player_move = player_move
	play_enemy_turn()

func play_enemy_turn():
	if enemy_card_slot.is_card_in_slot == false:
		place_enemy_card_in_slot(enemy_hand.enemy_hand[0])
		enemy_hand.remove_card_from_hand(enemy_hand.enemy_hand[0])
		enemy_hand.update_hand_positions()
		await enemy_card_slot.card_in_play
	var enemy_card_info : base_card = enemy_card_slot.card_in_slot.card_info
	var player_card_info : base_card = player_card_slot.card_in_slot.card_info
	current_enemy_move = enemydecisionmaker.decide_on_move(enemy_card_info,player_card_info,enemy_hand.enemy_hand)
	start_battle_turn(enemy_card_info,player_card_info)

func start_battle_turn(enemy_card_info,player_card_info):
	playerdiedthisturn = false
	enemydiedthisturn = false
	queue_battle_event("", [func(): $BattleTextDisplay.visible = true], 0.0)
	resolve_attack_phase(playerdisplay,enemydisplay,player_card_info,enemy_card_info,current_player_move,true,func():start_enemy_phase(enemy_card_info,player_card_info))

func start_enemy_phase(enemy_card_info,player_card_info):
	resolve_attack_phase(enemydisplay,playerdisplay,enemy_card_info,player_card_info,current_enemy_move,false,func():queue_battle_event("",[func(): $BattleTextDisplay.visible = false,
	func(): start_player_turn()],0.0))
	

func place_enemy_card_in_slot(enemy_card):
	var tween = get_tree().create_tween()
	tween.tween_property(enemy_card,"position",enemy_card_slot.position,0.2)
	await tween.finished
	card_manager.add_card_to_empty_slot(enemy_card,enemy_card_slot)

func resolve_attack_phase(attacker_display : Node2D,defender_display : Node2D,attacking_card : base_card,defending_card : base_card,move : base_move,is_player_attacking : bool,on_phase_complete : Callable):
	queue_battle_event("",[func():$BattleTextDisplay.visible = true],0.0)
	queue_battle_event(str(attacking_card.card_name) + " Used " + str(move.Name),[],1.0)
	if check_move_for_failure(move) == true:
		queue_battle_event("But It Missed!",[],0.5)
		queue_battle_event("", [on_phase_complete], 0.0)
	if move.damaging_move == true:
		#Add multi-hit later
		handle_card_animations("damage_move",defender_display)
		if queue_damage_event(defender_display, defending_card, move.damage, "", 0.0) == false:
			on_phase_complete = func():halt_battle_events()
		queue_battle_event("",[func():defender_display.physical_card.update_card_visuals(),func(): defender_display.update_card_visuals(defender_display.physical_card)],0.0)
	if move.healing_move == true:
		handle_card_animations("healing_move",attacker_display)
		queue_battle_event("",[func():heal_card(attacking_card,move.healing)],0.0)
		queue_battle_event("",[func():attacker_display.physical_card.update_card_visuals(),func(): attacker_display.update_card_visuals(attacker_display.physical_card)],0.0)
	if move.recoil_damage > 0:
		handle_card_animations("damage_move",attacker_display)
		queue_damage_event(attacker_display, attacking_card, move.recoil_damage, "recoil", 1.0)
		queue_battle_event("",[func():attacker_display.physical_card.update_card_visuals(),func(): attacker_display.update_card_visuals(attacker_display.physical_card)],0.0)
	if move.does_poison_damage and status_effect_roll_failure(move.chance_to_poison) == false:
		queue_battle_event(str(defending_card.card_name) + " Was poisoned!",[],1.0)
		defending_card.debuffs.append({name : "poison", time : })
		handle_card_animations("poisoned",defender_display)
	
	on_phase_complete.call()
## only called when player knocks out enemy
func halt_battle_events():
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
	for callback in event.callbacks:
		if callback != null:
			callback.call_deferred()
	if event.text and !event.text == "":
		await get_tree().create_timer(0.8).timeout
	is_processing_events = false
	process_battle_events()


func start_player_turn():
	current_player_move = null
	current_enemy_move = null
	card_manager.can_drag_cards = true
	number_of_turns_taken = number_of_turns_taken + 1
	playerdisplay.start_player_turn()
	player_card_slot.check_card_status()
	enemy_card_slot.check_card_status()
	check_if_player_lost()
	if enemy_hand.enemy_hand == [] and !enemy_card_slot.card_in_slot:
		playerdisplay.disable_player_moves()
		player_won()

func check_if_player_lost():
	if playerhand.player_hand == [] and !player_card_slot.card_in_slot:
		player_lost()

func player_lost():
	if enemy.enemy_hand == [] and enemy_card_slot.is_card_in_slot == false:
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
	for i in enemy.enemy_hand.size():
		total_money = total_money + enemy.enemy_hand[i].Max_Health
		for move in enemy.enemy_hand[i].combat_actions:
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

func handle_card_animations(animation_needed : String,card_display : Node2D):
	match animation_needed:
		"damage_move":
			queue_battle_event("",[func():carddisplaymanager.handle_card_animation_rotation_and_movement(card_display,Damage_Move_Degrees,Damage_Move_Movement),
			func():carddisplaymanager.apply_card_blinking(card_display,card_damage_tween_time)],0.0)
		"healing_move":
			queue_battle_event("",[func():carddisplaymanager.apply_card_particle_effects(card_display,"healing"),
			func():carddisplaymanager.apply_card_blinking(card_display,card_damage_tween_time)],0.0)
		"poisoned":
			queue_battle_event("",[func():carddisplaymanager.apply_card_particle_effects(card_display,"poison")],0.0)


func create_card_context(attacking_display,caster_display,move):
	var context = card_context.new()
	context.caster_display = caster_display
	context.attacking_display = attacking_display
	context.move = move
	return context

func check_move_for_failure(move : base_move):
	var accuracy_check : float = randf_range(0,1)
	if accuracy_check >= move.accuracy:
		return true
	if enemydiedthisturn == true:
		queue_battle_event("But It Failed!",[],0.5)
		return true
	if playerdiedthisturn == true:
		queue_battle_event("But It Failed!",[],0.5)
		return true
	return false
	#Add conditions later

func status_effect_roll_failure(effect_chance):
	var chance_check : float = randf_range(0,1)
	if chance_check > effect_chance:
		return true
	else:
		return false

func queue_damage_event(target_display : Node2D,target_card_info : base_card,damage_amount: int,damage_type: String,delay: float = 1.0):
	if damage_amount <= 0:
		return
	var damage_text: String = ""
	match damage_type:
		"recoil":
			damage_text = target_display.Card_name + " took recoil damage!"
		"poison":
			damage_text = target_display.Card_name + " is hurt by poison!"
		"burn":
			damage_text = target_display.Card_name + " is scorched by flames!"
		_:
			damage_text = target_display.Card_name + " took damage!"
	
	var predicted_health = target_card_info.current_health - damage_amount
	queue_battle_event(damage_text, [func():target_card_info.current_health -= damage_amount], delay)
	if predicted_health <= 0:
		handle_fainting(target_card_info,target_display.Card_name,target_display.physical_card)
		return false
	
	return true


func handle_fainting(card_info, display_name: String,physical_card : Node2D):
	queue_battle_event(display_name + " Fainted!",[],0.5)
	deal_with_fainted_card(physical_card)

func deal_with_fainted_card(physical_card):
	if physical_card.in_card_slot.friendlyslot == true:
		playerdiedthisturn = true
	if enemy_hand.enemy_hand.size() > 0:
		var next_card_sent_out = enemy_hand.enemy_hand[0]
		queue_battle_event("",[func():enemydisplay.update_card_visuals(next_card_sent_out),
		func():enemy_card_slot.card_in_slot = next_card_sent_out,
		func():enemy_hand.remove_card_from_hand(next_card_sent_out),
		func():enemy_hand.update_hand_positions(),
		func():physical_card.remove_card(),
		func():place_enemy_card_in_slot(next_card_sent_out),],0.0)
		queue_battle_event(enemy.enemy_name + " sent out " + next_card_sent_out.card_info.card_name + "!",[],1.0)
	if physical_card.in_card_slot.friendlyslot == false:
		enemydiedthisturn = true

func heal_card(card_info, heal_amount):
	card_info.current_health += heal_amount
	if card_info.current_health > card_info.Max_Health:
		card_info.current_health = card_info.Max_Health
