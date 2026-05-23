extends Node



func decide_on_move(enemy_card_info : base_card,player_card_info : base_card,avaliable_cards : Array):
	var highest_priority_move : base_move
	var highest_priority_move_number : int
	for move in enemy_card_info.combat_actions.size():
		var current_priority : int = 0
		if enemy_card_info.combat_actions[move].damage >= player_card_info.current_health:
			current_priority = current_priority + 100
		if enemy_card_info.combat_actions[move].healing_move == true and enemy_card_info.current_health > enemy_card_info.combat_actions[move].healing:
			current_priority = current_priority - 15
		if enemy_card_info.combat_actions[move].healing_move == true and enemy_card_info.current_health < (float(enemy_card_info.current_health * 30))/100:
			current_priority = current_priority + 50
		if enemy_card_info.combat_actions[move].damaging_move == true and enemy_card_info.current_health > (float(enemy_card_info.current_health * 80))/100:
			current_priority = current_priority + 20
		if enemy_card_info.combat_actions[move].recoil_damage >= enemy_card_info.current_health:
			current_priority = current_priority - 100
		if current_priority >= highest_priority_move_number:
			highest_priority_move_number = current_priority
			highest_priority_move = enemy_card_info.combat_actions[move]
	if !highest_priority_move:
		print("Didnt like my options")
		highest_priority_move = enemy_card_info.combat_actions[randi_range(0,enemy_card_info.combat_actions.size()-1)]
	
	
	
	return highest_priority_move
