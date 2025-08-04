extends Control
signal selected_moves_updated

@onready var avaliable_container = $MoveSelectionContainer
@export var button_scene: PackedScene = preload("res://Scenes/move_select_button.tscn")
@onready var money_display = $MoneyDisplay
@onready var cardbeingcreated = $CardBeingCreated

var selected_moves: Array[base_move] = []

func _ready():
	set_selection_menu_buttons()
	money_display.text = str(Globals.Player_Money) + "$"

func _process(_delta):
	update_money_label()

func _on_button_pressed(btn):
	if btn.button_move in selected_moves:
		return # Already added
	selected_moves.append(btn.button_move)
	selected_moves_updated.emit(selected_moves)

func set_selection_menu_buttons():
	var button_moves = Globals.moves_array
	for move in button_moves:
		var btn = button_scene.instantiate()
		if move.unlocked == true:
			btn.text = move.Name + " (" + str(move.move_cost) + "$" + ")"
		else:
			btn.text = "???"
			btn.disabled = true
		btn.button_move = move
		btn.pressed.connect(_on_button_pressed.bind(btn))
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		avaliable_container.add_child(btn)

func update_money_label():
	money_display.text = str(Globals.Player_Money-cardbeingcreated.Card_Total_Cost) + "$"
