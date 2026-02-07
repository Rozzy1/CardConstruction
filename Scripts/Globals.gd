extends Node

var Player_Money : int = 250


var move_folder_path = "res://Moves/"
var enemey_folder_path = "res://Enemys/"
var moves_array = []
var enemey_array = []
var player_hand : Array = []
var test_card
var enemey_hand : Array = []
var current_enemey : base_enemey
# Called when the node enters the scene tree for the first time.
func _ready():
	access_all_moves()
	access_all_enemeys()
	enemey_hand = enemey_array[0].enemey_hand
	current_enemey = enemey_array[0]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func access_all_moves():
	var dir = DirAccess.open(move_folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(".tres"):
				var file_path = move_folder_path + file_name
				var resource = load(file_path)
				if resource:
					moves_array.append(resource)
			file_name = dir.get_next()
		dir.list_dir_end()

func access_all_enemeys():
	var dir = DirAccess.open(enemey_folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(".tres"):
				var file_path = enemey_folder_path + file_name
				var resource = load(file_path)
				if resource:
					enemey_array.append(resource)
			file_name = dir.get_next()
		dir.list_dir_end()
