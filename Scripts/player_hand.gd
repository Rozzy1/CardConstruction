extends Node2D

const CARD_SCENE_PATH = "res://Scenes/card.tscn"
const CARD_WIDTH = 200
const HAND_Y_POSITION = 1000
const HAND_ANIMATION_SPEED = 0.1

var player_hand = []
var centre_screen_x


func _ready()->void:
	centre_screen_x = $"../Camera2D".position.x
	var card_scene = preload(CARD_SCENE_PATH)
	for i in Globals.player_hand.size():
		var newcard = card_scene.instantiate()
		$"../CardManager".add_child(newcard)
		newcard.card_info = Globals.player_hand[i]
		add_card_to_hand(newcard)


func add_card_to_hand(card):
	if card not in player_hand:
		player_hand.insert(0,card)
		update_hand_positions()
	else:
		animate_card_to_position(card, card.hand_position)

func update_hand_positions():
	for i in range(player_hand.size()):
			var new_position = Vector2(calculate_card_positions(i), HAND_Y_POSITION)
			var card = player_hand[i]
			card.hand_position = new_position
			card.hand_index = i+1
			animate_card_to_position(card, new_position)

func calculate_card_positions(index):
	var total_width = (player_hand.size() -1) * CARD_WIDTH
	var x_offset = centre_screen_x + index * CARD_WIDTH - float(total_width) / 2
	return x_offset

func animate_card_to_position(card, Position):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", Position, HAND_ANIMATION_SPEED)

func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		update_hand_positions()
