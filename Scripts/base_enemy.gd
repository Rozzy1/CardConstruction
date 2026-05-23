extends Resource
class_name base_enemy

@export var enemy_name : String
@export var enemy_hand : Array[base_card] = []
@export var unlock_moves : Array[base_move] = []
@export var money_earned : int
@export var max_turns : int
@export var boss_enemy : bool
