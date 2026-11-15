extends PlayerState
## Parado no chão.


func enter() -> void:
	player.play_anim(&"idle")


func physics_update(delta: float) -> void:
	if try_fall() or try_jump() or try_crouch() or try_mine():
		return

	player.ground_move(delta)
	player.update_facing()

	if player.get_input_x() != 0.0 or absf(player.velocity.x) > 5.0:
		go_move()
