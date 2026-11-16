extends Node2D

@onready var _corpo: AnimatedSprite2D = $Corpo
@onready var _mochila: AnimatedSprite2D = $Mochila


func aplicar_selecao() -> void:
	visible = PersonagemEscolhido.dados != null
	if visible:
		PersonagemEscolhido.aplicar(_corpo, _mochila)
		definir_pose(&"idle_right")


func definir_pose(animacao: StringName, tempo: float = 0.0, espelhado: bool = false) -> void:
	if not visible:
		return
	var frames := _corpo.sprite_frames
	var quadro := floori(tempo * frames.get_animation_speed(animacao)) % frames.get_frame_count(animacao)
	_corpo.animation = animacao
	_mochila.animation = animacao
	_corpo.frame = quadro
	_mochila.frame = quadro
	_corpo.flip_h = espelhado
	_mochila.flip_h = espelhado
