extends Control

const SELECAO_PERSONAGEM := "res://scenes/ui/selecao-personagem/selecao_personagem.tscn"

@onready var _tela: Control = $Tela
@onready var _iniciar: Button = $Tela/Iniciar


func _ready() -> void:
	resized.connect(_ajustar_tela)
	get_viewport().size_changed.connect(_ajustar_tela, CONNECT_DEFERRED)
	_ajustar_tela()
	_iniciar.grab_focus()


func _ajustar_tela() -> void:
	# A configuração global permite que a janela estique cada eixo separadamente.
	var escala_janela := get_viewport().get_final_transform().get_scale()
	var area_disponivel := size * escala_janela
	var escala := minf(area_disponivel.x / _tela.size.x, area_disponivel.y / _tela.size.y)
	_tela.scale = Vector2.ONE * escala / escala_janela
	_tela.position = ((size - _tela.size * _tela.scale) / 2.0).round()


func _abrir_selecao() -> void:
	var erro := get_tree().change_scene_to_file(SELECAO_PERSONAGEM)
	if erro != OK:
		push_error("Falha ao abrir a seleção de personagem: %s" % error_string(erro))
