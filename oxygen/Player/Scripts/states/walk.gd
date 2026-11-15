extends PlayerState
## Andando.

## Velocidade mínima para derrapar ao virar
@export var skid_min_speed := 60.0


func enter() -> void:
	player.play_anim(&"walk")


func physics_update(delta: float) -> void:
	if try_fall() or try_jump() or try_crouch() or try_mine():
		return

	var input := player.get_input_x()

	# Virou contra o embalo → derrapa
	if input != 0.0 and signf(input) != signf(player.velocity.x) \
			and absf(player.velocity.x) >= skid_min_speed:
		state_machine.change_state(state_machine.skid)
		return

	player.ground_move(delta)
	player.update_facing()

	if input == 0.0 and absf(player.velocity.x) < 1.0:
		player.velocity.x = 0.0
		state_machine.change_state(state_machine.idle)
		return

	# Segurou Shift e passou da velocidade de andar → corre
	if player.is_run_held() and absf(player.velocity.x) > player.walk_speed:
		state_machine.change_state(state_machine.run)
		return

	# Ritmo dos passos acompanha a velocidade
	player.play_anim(&"walk", clampf(absf(player.velocity.x) / player.walk_speed, 0.5, 1.3))
