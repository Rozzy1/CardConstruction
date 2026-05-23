extends Node2D
signal card_in_play
signal card_not_in_play

var is_card_in_slot : bool = false
var emitted_signal : bool = false

var card_in_slot : Node2D

@export var friendlyslot : bool

func _process(_delta):
	if is_card_in_slot == true and friendlyslot == false and emitted_signal == false:
		card_in_play.emit(card_in_slot)
		card_in_slot.card_died.connect(card_died)
		emitted_signal = true
	elif is_card_in_slot == false and emitted_signal == true:
		emitted_signal = false
		card_not_in_play.emit()

func check_card_status():
	if is_card_in_slot == true:
		pass
	else:
		card_not_in_play.emit()

func card_died():
	is_card_in_slot = false
