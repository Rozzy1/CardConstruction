extends Node2D
signal hovered
signal hovered_off
signal card_died
@onready var card_name_label = $CardName
@onready var card_health_label = $CardHealth
@export var card_info : base_card

var in_card_slot : Node2D
var hand_position
var hand_index : int
var instanced : bool = false
# Called when the node enters the scene tree for the first time.
func _ready():
	get_parent().connect_card_signals(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$DebugNumber.text = card_info.card_name
	if hand_position and !instanced:
		card_info.current_health = card_info.Max_Health
		update_card_visuals()
		instanced = true


func _on_area_2d_mouse_entered():
	emit_signal("hovered",self)


func _on_area_2d_mouse_exited():
	emit_signal("hovered_off",self)

func take_damage(damage_amt):
	card_info.current_health = card_info.current_health - damage_amt
	if card_info.current_health <= 0:
		card_died.emit()
		queue_free()
	update_card_visuals()

func heal(heal_amt):
	card_info.current_health = card_info.current_health + heal_amt
	if card_info.current_health > card_info.Max_Health:
		card_info.current_health = card_info.Max_Health
	update_card_visuals()

func update_card_visuals():
	card_health_label.text = str(card_info.current_health) + "/" + str(card_info.Max_Health)
	card_name_label.text = card_info.card_name
	for i in 4:
		var move = get_node("Move"+str(i+1))
		move.disabled = true
		move.add_theme_stylebox_override("focus", StyleBoxEmpty.new()) #gets rid of the button outline when you click on a button
		if i < card_info.combat_actions.size():
			move.text = card_info.combat_actions[i-1].Name
		else:
			move.text = ""
