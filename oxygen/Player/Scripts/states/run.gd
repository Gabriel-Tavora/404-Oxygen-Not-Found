extends PlayerState
## Correndo (segurando Shift).

@export var skid_min_speed := 60.0


func enter() -> void:
	player.play_anim(&"run")


func physics_update(delta: float) -> void:
	if try_fall() or try_jump() or try_crouch() or try_mine():
		return

	var input := player.get_input_x()

	if input != 0.0 and signf(input) != signf(player.velocity.x) \
			and absf(player.velocity.x) >= skid_min_speed:
		state_machine.change_state(state_machine.skid)
		return

	player.ground_move(delta)
	player.update_facing()

	# Soltou o Shift ou perdeu velocidade → volta a andar
	if not player.is_run_held() or absf(player.velocity.x) <= player.walk_speed:
		if absf(player.velocity.x) > 1.0:
			go_move()
		else:
			state_machine.change_state(state_machine.idle)
		return

	player.play_anim(&"run", clampf(absf(player.velocity.x) / player.run_speed, 0.6, 1.3))
