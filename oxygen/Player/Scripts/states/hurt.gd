extends PlayerState
## Tomou dano: empurrão para trás e sem controle por um instante.
## Use player.take_damage(1, posicao_do_inimigo) para entrar aqui.

## Tempo sem controle
@export var hurt_time := 0.4

var _timer := 0.0


func enter() -> void:
	_timer = 0.0
	player.play_anim(&"hurt", 1.0, true)
	player.play_sound("HurtSound")


func physics_update(delta: float) -> void:
	_timer += delta
	if player.is_on_floor():
		player.brake(delta)

	if _timer < hurt_time:
		return

	if player.is_on_floor():
		land()
	else:
		state_machine.change_state(state_machine.fall)
