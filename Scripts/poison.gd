class_name debuff
extends Resource
var name : String
var time : int
var strength : float
var percent_damage : float :
	get : return strength / 10
func _init(p_name : String,p_time : int, p_strength : int):
	name = p_name
	time = p_time
	strength = p_strength
