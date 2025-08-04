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
var enemey : base_enemey
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
		await enemey_card_slot.enemey_card_in_play
	current_enemey_move = decide_enemey_move()
	start_attack_phase(current_player_move,current_enemey_move)

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
	for i in enemey_card_info.combat_actions.size():
		var current_priority : int = 0
		if enemey_card_info.combat_actions[i].damage >= player_card_info.current_health:
			current_priority = current_priority + 100
		if enemey_card_info.combat_actions[i].healing_move == true and enemey_card_info.current_health > enemey_card_info.combat_actions[i].healing:
			current_priority = current_priority - 15
		if enemey_card_info.combat_actions[i].healing_move == true and enemey_card_info.current_health < (float(enemey_card_info.current_health * 30))/100:
			current_priority = current_priority + 50
		if enemey_card_info.combat_actions[i].damaging_move == true and enemey_card_info.current_health > (float(enemey_card_info.current_health * 80))/100:
			current_priority = current_priority + 20
		if enemey_card_info.combat_actions[i].recoil_damage >= enemey_card_info.current_health:
			current_priority = current_priority - 100
		if current_priority >= highest_priority_move_number:
			highest_priority_move_number = current_priority
			highest_priority_move = enemey_card_info.combat_actions[i]
	return highest_priority_move

func start_attack_phase(player_move,enemey_move):
	if player_move.damage > 0:
		enemey_card_slot.card_in_slot.take_damage(player_move.damage)
		player_card_slot.card_in_slot.take_damage(player_move.recoil_damage)
	if player_move.healing > 0:
		player_card_slot.card_in_slot.heal(player_move.healing)
	if enemey_move.damage > 0:
		player_card_slot.card_in_slot.take_damage(enemey_move.damage)
		enemey_card_slot.card_in_slot.take_damage(enemey_move.recoil_damage)
	if enemey_move.healing > 0:
		enemey_card_slot.card_in_slot.heal(enemey_move.healing)
	playerdisplay.change_to_players_card(player_card_slot.card_in_slot)
	enemeydisplay.change_to_enemey_card(enemey_card_slot.card_in_slot)
	start_player_turn()

func start_player_turn():
	current_player_move = null
	current_enemey_move = null
	card_manager.can_drag_cards = true
	number_of_turns_taken = number_of_turns_taken + 1
	playerdisplay.start_player_turn()
	player_card_slot.check_card_status()
	enemey_card_slot.check_card_status()
	if playerhand.player_hand == [] and player_card_slot.is_card_in_slot == false:
		player_lost()
	if enemey_hand.enemey_hand == [] and enemey_card_slot.is_card_in_slot == false:
		player_won()

func player_lost():
	if enemey.enemey_hand == [] and enemey_card_slot.is_card_in_slot == false:
		player_won()
		return
	get_tree().quit()

func player_won():
	print(calculate_money_earnings())


func calculate_money_earnings():
	var total_money : int
	for i in enemey.enemey_hand.size():
		for move in enemey.enemey_hand[i].combat_actions:
			total_money = total_money + move.move_cost
	return total_money
