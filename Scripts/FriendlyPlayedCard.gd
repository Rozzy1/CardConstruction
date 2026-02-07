extends Node2D
signal end_player_turn

@export var isfriendlyslot : bool
@export var cardflippingtime : float = 0.2
@onready var descriptiontext = %DescriptionText
@onready var descriptionpanel = %DescriptionPanel
@onready var card_name = %CardName
@onready var card_health = %CardHealth
@onready var animation_player = $AnimationPlayer
@onready var card_flip_timer = $CardFlipTimer
@onready var friendlycardslot = $"../FriendlyCardSlot"
var current_player_moves : Array = []
var physical_card
var Card_name : String
# Called when the node enters the scene tree for the first time.
func _ready():
	card_flip_timer.wait_time = cardflippingtime
	animation_player.play("card_flip")
	if isfriendlyslot == true:
		friendlycardslot.card_in_play.connect(change_to_new_card)
		friendlycardslot.card_not_in_play.connect(remove_card_data)
	for child in self.get_children():
		var parent_material = material.duplicate()
		parent_material.set_shader_parameter("blink_intensity", 1)
		if child.has_method("material"):
			child.material = parent_material

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func change_to_new_card(card):
	flip_card_animation("forward")
	update_card_visuals(card)

func update_card_visuals(card):
	physical_card = card
	Card_name = card.card_info.card_name
	card_name.text = card.card_info.card_name
	card_health.text = str(card.card_info.current_health) + "/" + str(card.card_info.Max_Health)
	#Loops through the cards combatactions and then sets the internal moveset along with the card names
	if !current_player_moves:
		for i in card.card_info.combat_actions.size():
			current_player_moves.append(card.card_info.combat_actions[i])
			var move = get_node("Move"+str(i+1))
			move.text = current_player_moves[i].Name

func flip_card_animation(direction):
	if direction == "forward":
		animation_player.play_backwards("card_flip")
	else:
		animation_player.play("card_flip")


func _on_move_1_mouse_entered():
	display_description_panel(0)
func _on_move_2_mouse_entered():
	display_description_panel(1)
func _on_move_3_mouse_entered():
	display_description_panel(2)
func _on_move_4_mouse_entered():
	display_description_panel(3)

func _on_move_1_mouse_exited():
	remove_description_panel()
func _on_move_2_mouse_exited():
	remove_description_panel()
func _on_move_3_mouse_exited():
	remove_description_panel()
func _on_move_4_mouse_exited():
	remove_description_panel()

func remove_description_panel():
	%DescriptionPanel.visible = false

func display_description_panel(movehovered):
	if current_player_moves.size() > movehovered:
		descriptionpanel.visible = true
		descriptiontext.text = current_player_moves[movehovered].Description
		var descriptiontext_tween = get_tree().create_tween()
		descriptiontext.visible_ratio = 0
		descriptiontext_tween.tween_property(descriptiontext,"visible_ratio",1,0.5)


func _on_move_1_pressed():
	if current_player_moves.size() >= 1:
		end_players_turn(1)
func _on_move_2_pressed():
	if current_player_moves.size() >= 2:
		end_players_turn(2)
func _on_move_3_pressed():
	if current_player_moves.size() >= 3:
		end_players_turn(3)
func _on_move_4_pressed():
	if current_player_moves.size() >= 4:
		end_players_turn(4)

func end_players_turn(move_pressed):
	remove_description_panel()
	disable_player_moves()
	end_player_turn.emit(current_player_moves[move_pressed-1])

func remove_card_data():
	flip_card_animation("backwards")
	card_flip_timer.start()
	await card_flip_timer.timeout
	current_player_moves.clear()
	card_name.text = ""
	card_health.text = ""
	for i in 4:
		var move = get_node("Move"+str(i+1))
		move.text = ""

func start_player_turn():
	for i in 4:
		var move = get_node("Move"+str(i+1))
		move.disabled = false

func disable_player_moves():
	for i in 4:
		var move = get_node("Move"+str(i+1))
		move.disabled = true
