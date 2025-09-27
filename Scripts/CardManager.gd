extends Node2D

const CheckCollisionMask : int = 1
const CheckCollisionMaskSlot : int = 2

var can_drag_cards : bool = true
var drag_offset : Vector2
var card_being_dragged
var screen_size
var is_hovering_on_card : bool 
var player_hand_reference

func _ready():
	$"../FriendlyPlayedCard".end_player_turn.connect(end_player_turn)
	screen_size = get_viewport().size
	print(screen_size)
	player_hand_reference = $"../PlayerHand"

func _process(_delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		var desired_position = mouse_pos + drag_offset
		var current_position = card_being_dragged.position
		#var distance = current_position.distance_to(desired_position)
		 # Adaptive smoothing: Adjust 't' based on distance var t = distance * 0.01  
		# Adjust 0.01 as needed t = clamp(t, 0.1, 0.5)    
		# Clamp 't' to a reasonable range
		card_being_dragged.position = current_position.lerp(desired_position, 0.25)
		card_being_dragged.position = Vector2(clamp(card_being_dragged.position.x,0,screen_size.x),clamp(card_being_dragged.position.y,0,screen_size.y))

#Checks if we have clicked
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and can_drag_cards == true:
		if event.pressed:
			var cardclicked = check_for_card()
			if cardclicked:
				start_drag(cardclicked)
				card_being_dragged = cardclicked
		else:
			if card_being_dragged:
				finish_drag()
	

func check_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = CheckCollisionMaskSlot
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		#Gives back the card we clicked
		return result[0].collider.get_parent()
		 
	return null

#Checks to see if we have clicked a card
func check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = CheckCollisionMask
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		#Gives back the card we clicked
		return get_card_with_highest_z_index(result)
		
	return null

func get_card_with_highest_z_index(cards):
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	for i in range (1, cards.size()):
		var currentcard = cards[i].collider.get_parent()
		if currentcard.z_index > highest_z_index:
			highest_z_card = currentcard
			highest_z_index = currentcard.z_index
	return highest_z_card


func highlight_card(card, hovered):
	if hovered:
		card.scale = Vector2(1.05,1.05)
		card.z_index = 2
	else:
		card.scale = Vector2(1.,1)
		card.z_index = 1

#CARDS MUST BE FIRST CREATED AS A CARD OF CARD MANAGER
func connect_card_signals(card):
	card.connect("hovered",on_hovered_over_card)
	card.connect("hovered_off",on_hovered_off_card)

func on_hovered_over_card(card):
	if !is_hovering_on_card:
		is_hovering_on_card = true
		highlight_card(card, true)

func on_hovered_off_card(card):
	if !card_being_dragged:
		highlight_card(card, false)
		var new_card_covered = check_for_card()
		if new_card_covered:
			highlight_card(new_card_covered,true)
		else:
			is_hovering_on_card = false

func start_drag(card):
	card.scale = Vector2(1,1)
	card_being_dragged = card

func finish_drag():
	card_being_dragged.scale = Vector2(1.05,1.05)
	var card_slot_found = check_for_card_slot()
	#puts card in empty slot
	if (card_slot_found and not card_slot_found.is_card_in_slot) and card_slot_found.friendlyslot == true:
		add_card_to_empty_slot(card_being_dragged,card_slot_found)
	else:
		#Stops dumb bug by checking if the card_slots card being held is not the card we are trying to put in.
		if card_slot_found and card_slot_found.card_in_slot == card_being_dragged:
			add_card_to_empty_slot(card_being_dragged,card_slot_found)
			card_being_dragged = null
			return
		player_hand_reference.add_card_to_hand(card_being_dragged)
	#resets cardslot and card if taken out of slot
	if !card_slot_found and card_being_dragged.in_card_slot:
		card_being_dragged.in_card_slot.is_card_in_slot = false
		card_being_dragged.in_card_slot = null
	card_being_dragged = null

func add_card_to_empty_slot(Card_being_dragged, Card_slot_found):
	player_hand_reference.remove_card_from_hand(Card_being_dragged)
	Card_being_dragged.position = Card_slot_found.position
	Card_being_dragged.in_card_slot = Card_slot_found
	Card_slot_found.is_card_in_slot = true
	Card_slot_found.card_in_slot = Card_being_dragged

func end_player_turn(_move_info):
	can_drag_cards = false
