extends PlayerState
## Caindo (depois do pulo ou ao sair de uma beirada).


func enter() -> void:
	player.play_anim(&"fall")


func physics_update(delta: float) -> void:
	if player.is_on_floor():
		player.play_sound("LandSound")
		land()
		return

	# Coyote time: acabou de sair da beirada e ainda pode pular
	if try_jump():
		return

	player.air_move(delta)
	player.update_facing()
