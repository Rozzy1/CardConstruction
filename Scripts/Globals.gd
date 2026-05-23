extends Node

var Player_Money : int = 250


var move_folder_path = "res://Moves/"
var enemy_folder_path = "res://Enemys/"
var moves_array = []
var enemy_array = []
var player_hand : Array = []
var test_card
var enemy_hand : Array = []
var current_enemy : base_enemy
# Called when the node enters the scene tree for the first time.
func _ready():
	access_all_moves()
	access_all_enemys()
	enemy_hand = enemy_array[0].enemy_hand
	current_enemy = enemy_array[0]

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

func access_all_enemys():
	var dir = DirAccess.open(enemy_folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(".tres"):
				var file_path = enemy_folder_path + file_name
				var resource = load(file_path)
				if resource:
					enemy_array.append(resource)
			file_name = dir.get_next()
		dir.list_dir_end()
