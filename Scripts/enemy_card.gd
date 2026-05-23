extends Node2D
signal card_died

@export var card_info : base_card
@export var poisoned : bool

var in_card_slot : Node2D
var hand_position
var hand_index : int
var instanced : bool = false
@onready var card_name_label = $CardName
@onready var card_health_label = $CardHealth
# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if hand_position and !instanced:
			card_info.current_health = card_info.Max_Health
			instanced = true
	update_card_visuals()


func update_card_visuals():
	if !in_card_slot:
		$CardName.visible = false
		$CardHealth.visible = false
		$Move1.visible = false
		$Move2.visible = false
		$Move3.visible = false
		$Move4.visible = false
		return
	else:
		$CardName.visible = true
		$CardHealth.visible = true
		$Move1.visible = true
		$Move2.visible = true
		$Move3.visible = true
		$Move4.visible = true
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

func remove_card():
	card_died.emit()
	queue_free()
