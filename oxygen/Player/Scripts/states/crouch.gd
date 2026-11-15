extends PlayerState
## Agachado (troca para a DuckShape, se existir).


func enter() -> void:
	player.set_ducking(true)
	player.play_anim(&"crouch", 1.0, true)


func exit() -> void:
	player.set_ducking(false)


func physics_update(delta: float) -> void:
	if try_fall():
		return

	# Agachado vai freando e não anda
	player.brake(delta)
	player.update_facing()

	if not player.can_stand_up():
		return

	if player.can_jump() and player.wants_jump():
		player.jump()
		return

	if not Input.is_action_pressed(Player.ACTION_DUCK):
		land()
