class_name PlayerState
extends Node
## Base de todos os estados do astronauta.

var player: Player
var state_machine: PlayerStateMachine


func enter() -> void:
	pass


func exit() -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


## Se o Player deve aplicar gravidade neste estado
func can_apply_gravity() -> bool:
	return true


# --- Transições comuns ---

## Pulo (respeita coyote time e buffer)
func try_jump() -> bool:
	if player.can_jump() and player.wants_jump():
		player.jump()
		return true
	return false


func try_crouch() -> bool:
	if Input.is_action_pressed(Player.ACTION_DUCK) and player.is_on_floor():
		state_machine.change_state(state_machine.crouch)
		return true
	return false


func try_mine() -> bool:
	if Input.is_action_just_pressed(Player.ACTION_MINE) and player.is_on_floor():
		state_machine.change_state(state_machine.mine)
		return true
	return false


## Saiu do chão sem pular → cai
func try_fall() -> bool:
	if not player.is_on_floor():
		state_machine.change_state(state_machine.fall)
		return true
	return false


## Andar ou correr, conforme o Shift e a velocidade
func go_move() -> void:
	if player.is_run_held() and absf(player.velocity.x) > player.walk_speed:
		state_machine.change_state(state_machine.run)
	else:
		state_machine.change_state(state_machine.walk)


## Para onde ir ao tocar o chão / terminar uma ação
func land() -> void:
	if try_jump() or try_crouch() or try_mine():
		return
	if player.get_input_x() != 0.0 or absf(player.velocity.x) > 1.0:
		go_move()
	else:
		state_machine.change_state(state_machine.idle)
