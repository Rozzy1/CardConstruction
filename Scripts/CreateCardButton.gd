extends Button
@onready var error_text = $ValidText
@onready var cardbeingcreated = $"../CardBeingCreated"
# Called when the node enters the scene tree for the first time.
func _ready():
	disabled = true
	$"../CardBeingCreated".card_updated.connect(check_if_valid)
	error_text.text = "Input information into card"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func check_if_valid(card_cost,card_moves):
	if card_cost > Globals.Player_Money:
		error_text.text = "[color=red]Insufficent Funds"
		disabled = true
		return
	if card_moves == []:
		error_text.text = "[color=red]Card must have at least ONE move"
		disabled = true
		return
	error_text.text = "[color=green]Valid Card!"
	disabled = false
	if cardbeingcreated.card_name == "":
		error_text.text = "[color=red]Give your card a name!"


func _on_pressed():
	if Globals.player_hand.size() >= 6:
		error_text.text = "[color=red]You have the maximum amount of cards for a deck!"
	else:
		Globals.Player_Money = Globals.Player_Money - cardbeingcreated.Card_Total_Cost
		var newcard = base_card.new()
		newcard.card_name = cardbeingcreated.card_name
		newcard.Max_Health = cardbeingcreated.card_health
		newcard.combat_actions = cardbeingcreated.moves_array
		Globals.player_hand.append(newcard)
		get_tree().change_scene_to_file("res://Scenes/main.tscn")
