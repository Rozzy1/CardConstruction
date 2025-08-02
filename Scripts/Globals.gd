extends Node
var folder_path = "res://Moves/"
var resource_array = []
var player_hand : Array = []
var test_card
var enemey_hand : Array = []
# Called when the node enters the scene tree for the first time.
func _ready():
	access_all_moves()
	for i in 6:
		test_card = base_card.new()
		test_card.Max_Health = 100
		test_card.card_name = str(i)
		test_card.combat_actions.append(resource_array[0])
		player_hand.append(test_card)
	for i in 6:
		test_card = base_card.new()
		test_card.Max_Health = 100
		test_card.card_name = str(i)
		test_card.combat_actions.append(resource_array[0])
		enemey_hand.append(test_card)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func access_all_moves():
	var dir = DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(".tres"):
				var file_path = folder_path + file_name
				var resource = load(file_path)
				if resource:
					resource_array.append(resource)
			file_name = dir.get_next()
		dir.list_dir_end()


