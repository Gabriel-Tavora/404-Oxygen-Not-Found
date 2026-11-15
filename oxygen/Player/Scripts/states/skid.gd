extends PlayerState
## Derrapando ao virar contra o embalo (liga o SkidParticles).

## Duração máxima da derrapada
@export var max_skid_time := 0.4

var _timer := 0.0


func enter() -> void:
	_timer = 0.0
	# A pose de freada do sprite olha para o lado do embalo, inclinada para trás
	player.set_facing(int(signf(player.velocity.x)))
	player.play_anim(&"skid", 1.0, true)
	player.play_sound("SkidSound")
	player.set_skid_particles(true)


func exit() -> void:
	player.stop_sound("SkidSound")
	player.set_skid_particles(false)


func physics_update(delta: float) -> void:
	_timer += delta
	player.brake(delta, player.skid_decel)

	if try_fall():
		return

	# Pulo saindo da derrapada (já sai virado para o lado novo)
	if player.can_jump() and player.wants_jump():
		player.update_facing()
		player.jump()
		return

	var input := player.get_input_x()
	# Voltou para o lado do embalo → continua andando
	if input != 0.0 and signf(input) == signf(player.velocity.x):
		go_move()
		return

	if _timer >= max_skid_time or player.velocity.x == 0.0:
		player.update_facing()
		land()
