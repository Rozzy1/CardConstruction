extends Node2D
signal card_updated
@export var Max_Name_Size : int = 25
@export var Max_Allowed_Health : int = 300
@onready var descriptionpanel = $DescriptionPanel
@onready var descriptiontext = $DescriptionPanel/DescriptionText
@onready var textedit = $TextEdit
@onready var cardhealthlabel = $CardHealth
var moves_array : Array[base_move] = []
var card_name : String
var card_health : int = 1
var previoustext : String

var cost_of_health : int = 0
var cost_of_moves : int = 0

var Card_Total_Cost : int
# Called when the node enters the scene tree for the first time.
func _ready():
	$"..".selected_moves_updated.connect(selected_moves_updated)
	$HSlider.max_value = Max_Allowed_Health
	$HSlider.value = 1
	cardhealthlabel.text = "1/1"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	Card_Total_Cost = cost_of_health + cost_of_moves

func selected_moves_updated(selected_moves):
	for i in 4:
		moves_array = selected_moves
		var move = get_node("Move"+str(i+1))
		if selected_moves.size() > i:
			move.text = selected_moves[i].Name
			move.disabled = false
		else:
			move.disabled = true
			move.text = ""
	cost_of_moves = calculate_move_costs()
	card_updated.emit(Card_Total_Cost,selected_moves)

func _on_move_1_mouse_entered():
	display_description_panel(0)
func _on_move_1_mouse_exited():
	hide_description_panel()
func _on_move_2_mouse_entered():
	display_description_panel(1)
func _on_move_2_mouse_exited():
	hide_description_panel()
func _on_move_3_mouse_entered():
	display_description_panel(2)
func _on_move_3_mouse_exited():
	hide_description_panel()
func _on_move_4_mouse_entered():
	display_description_panel(3)
func _on_move_4_mouse_exited():
	hide_description_panel()

func _on_move_1_pressed():
	remove_move_from_array(0)
func _on_move_2_pressed():
	remove_move_from_array(1)
func _on_move_3_pressed():
	remove_move_from_array(2)
func _on_move_4_pressed():
	remove_move_from_array(3)

func display_description_panel(move_hovered):
	if moves_array.size() > move_hovered:
		descriptionpanel.visible = true
		descriptiontext.text = moves_array[move_hovered].Description + " (" + str(moves_array[move_hovered].move_cost) + "$)"
		var descriptiontext_tween = get_tree().create_tween()
		descriptiontext.visible_ratio = 0
		descriptiontext_tween.tween_property(descriptiontext,"visible_ratio",1,0.5)

func hide_description_panel():
	descriptionpanel.visible = false
	descriptiontext.visible_ratio = 0


func _on_text_edit_text_changed(_new_text):
	if textedit.text.length() > Max_Name_Size:
		textedit.text = previoustext
	else:
		previoustext = textedit.text
		card_name = textedit.text
		card_updated.emit(Card_Total_Cost,moves_array)


func _on_h_slider_value_changed(value):
	card_health = value
	cardhealthlabel.text = str(value) + "/" + str(value)
	cost_of_health = calculate_cost_of_health(value)
	card_updated.emit(Card_Total_Cost,moves_array)

func remove_move_from_array(movepressed):
	if moves_array.size() > movepressed:
		moves_array.erase(moves_array[movepressed])
		selected_moves_updated(moves_array)

func calculate_cost_of_health(health):
	var threshold1 : int = 100
	var threshold2 : int = 150
	var threshold3 : int = 200
	var threshold4 : int = 250
	if health <= threshold1:
		return health-1
	if health <= threshold2:
		return roundi(threshold1 + (health - threshold1)*1.5)
	if health <= threshold3:
		return roundi(threshold2 + (health-threshold2)*2)
	if health <= threshold4:
		return roundi(threshold3 + (health-threshold3)*2.5)
	if health >= threshold4:
		return roundi(threshold4 + (health-threshold4)*3)

func calculate_move_costs():
	var total_cost : int = 0
	for i in moves_array.size():
		total_cost = moves_array[i].move_cost + total_cost
	return total_cost
