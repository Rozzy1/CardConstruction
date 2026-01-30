extends Resource
class_name base_move

@export var unlocked : bool
@export var move_cost : int
@export var Name : String
@export_multiline var Description : String
@export_range(0,1,0.05) var accuracy : float = 1
@export var damage : int
@export var damaging_move : bool
@export var healing : int 
@export var healing_move : bool
@export var recoil_damage : int
@export var does_poison_damage : bool
@export_range(0,1,0.05) var chance_to_poison : float

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
