extends PlayerState
## Subindo no pulo. Ao começar a cair, passa para "fall".


func enter() -> void:
	player.play_anim(&"jump", 1.0, true)


func physics_update(delta: float) -> void:
	if player.is_on_floor() and player.velocity.y >= 0.0:
		land()
		return

	# Bateu a cabeça ou passou do topo → cai
	if player.velocity.y >= 0.0:
		state_machine.change_state(state_machine.fall)
		return

	player.air_move(delta)
	player.update_facing()
