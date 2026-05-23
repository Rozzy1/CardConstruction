extends Resource
class_name base_card

@export var card_name : String
@export var Max_Health : int
@export var combat_actions : Array[base_move]
@export var debuffs : Array[debuff]
var current_health : int
var card_total_cost : int

func add_to_list(new_effect : debuff):
	var hasfounddebuff : bool = false
	for db in debuffs:
		if db.name == new_effect.name:
			db.strength += new_effect.strength
			db.time = max(db.time,new_effect.time)
			hasfounddebuff = true
	if hasfounddebuff == false:
		debuffs.append(new_effect)
