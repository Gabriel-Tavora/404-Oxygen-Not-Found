extends PlayerState
## Morte: toca a animação e reinicia a fase depois de um tempo.

## Tempo até reiniciar
@export var restart_delay := 2.0
## Recarrega a cena atual ao morrer (desligue se o seu GameManager cuidar disso)
@export var reload_scene := true


func enter() -> void:
	player.velocity.x = 0.0
	player.animated_sprite.modulate.a = 1.0
	player.play_anim(&"death", 1.0, true)
	player.play_sound("DeathSound")
	player.died.emit()

	if reload_scene:
		await get_tree().create_timer(restart_delay).timeout
		player.get_tree().reload_current_scene()


func physics_update(delta: float) -> void:
	player.brake(delta)
