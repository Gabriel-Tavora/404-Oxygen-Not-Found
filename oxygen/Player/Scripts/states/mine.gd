extends PlayerState
## Golpe de picareta. Segurando o botão, continua minerando.
## O acerto acontece no frame das faíscas (impact_frame).

## Frame da animação "mine" em que a picareta acerta (0 a 3)
@export var impact_frame := 3

var _hit_done := false
var _last_frame := 0


func enter() -> void:
	_hit_done = false
	_last_frame = 0
	player.play_anim(&"mine", 1.0, true)


func physics_update(delta: float) -> void:
	if try_fall() or try_jump():
		return

	player.brake(delta)

	var frame := player.animated_sprite.frame

	# Acerto (uma vez por golpe)
	if frame == impact_frame and not _hit_done:
		_hit_done = true
		player.mine_hit()
		player.play_sound("MineSound")

	# Terminou um golpe (voltou ao frame 0)
	if frame < _last_frame:
		_hit_done = false
		if not Input.is_action_pressed(Player.ACTION_MINE):
			land()
			return
		player.update_facing()  # pode virar entre um golpe e outro

	_last_frame = frame
