extends Node
@onready var healing_particles = $"../../Heal Animation"
@onready var poison_particles = $"../../Poison Animation"

func handle_card_animation_rotation_and_movement(card_display : Node2D,rotate_amount : int,movement_amount : int):
	var rotation_angle : int
	var movement : Vector2
	if card_display.isfriendlyslot == true:
		rotation_angle = -rotate_amount
		movement = Vector2(card_display.global_position.x - movement_amount, card_display.global_position.y)
	else:
		rotation_angle = rotate_amount
		movement = Vector2(card_display.global_position.x + movement_amount, card_display.global_position.y)
	
	var original_position : Vector2 = card_display.global_position
	var original_rotation : float = card_display.rotation
	card_display.animation_player.speed_scale = card_display.cardflippingtime * 5
	card_display.animation_player.play("card_flip")
	card_display.animation_player.play_backwards("card_flip")
	give_rotation_movement_tween_propertys(card_display,rotation_angle,movement,original_rotation,original_position)

func give_rotation_movement_tween_propertys(card_display,rotation_angle,movement,original_rotation,original_position):
	var rotation_tween = get_tree().create_tween()
	var movement_tween = get_tree().create_tween()
	rotation_tween.tween_property(card_display, "rotation_degrees", rotation_angle, card_display.cardflippingtime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rotation_tween.tween_property(card_display, "rotation_degrees", original_rotation, card_display.cardflippingtime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	movement_tween.tween_property(card_display, "position", movement, card_display.cardflippingtime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	movement_tween.tween_property(card_display, "position", original_position, card_display.cardflippingtime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await movement_tween.finished

func regular_attack_rotation_tween(card_display : Node2D,rotate_amount : int):
	if card_display.isfriendlyslot == true:
		rotate_amount = -rotate_amount
	var original_rotation : float = card_display.rotation

func regular_attack_movement_tween(card_display : Node2D, movement_amount : int):
	pass

func apply_card_particle_effects(card_display: Node2D, particle_effect: String) -> void:
	print(card_display.Card_name)
	var emitter: GPUParticles2D = null
	match particle_effect:
		"healing": emitter = healing_particles
		"poison":   emitter = poison_particles

	emitter.global_position = card_display.global_position
	#actually no clue but i need to wait a frame before starting particle effects or itll sprinkle effects on both cards
	await get_tree().create_timer(0).timeout
	emitter.restart()
	emitter.emitting = true
	print(emitter.global_position)


func apply_card_blinking(card_display : Node2D, duration : float):
	var blink_tween = get_tree().create_tween()
	blink_tween.tween_method(func(newvalue): SetBlinkShaderParameters(card_display, newvalue), 1.0, 0.0,duration+0.15)

func SetBlinkShaderParameters(display, newvalue : float):
	display.material.set_shader_parameter("blink_intensity", newvalue)
