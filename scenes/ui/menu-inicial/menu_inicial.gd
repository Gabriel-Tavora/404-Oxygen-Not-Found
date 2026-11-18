extends Control

const Creditos = preload("res://scenes/encerramento/creditos.gd")
const SELECAO_PERSONAGEM := "res://scenes/ui/selecao-personagem/selecao_personagem.tscn"

@onready var _tela: Control = $Tela
@onready var _iniciar: Button = $Tela/Iniciar
@onready var _botao_creditos: Button = $Tela/Creditos
@onready var _painel_creditos: Control = $PainelCreditos
@onready var _voltar: Button = $PainelCreditos/Conteudo/Voltar
@onready var _botao_ranking: Button = $Tela/Ranking
@onready var _ranking = $Ranking


func _ready() -> void:
	resized.connect(_ajustar_tela)
	get_viewport().size_changed.connect(_ajustar_tela, CONNECT_DEFERRED)
	_ajustar_tela()
	Creditos.preencher_lista($PainelCreditos/Conteudo/Lista)
	_botao_ranking.pressed.connect(_abrir_ranking)
	_ranking.fechado.connect(_fechar_ranking)
	_iniciar.grab_focus()


func _unhandled_input(evento: InputEvent) -> void:
	if _painel_creditos.visible and evento.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_fechar_creditos()


func _abrir_creditos() -> void:
	_tela.hide()
	_painel_creditos.show()
	_voltar.grab_focus()


func _fechar_creditos() -> void:
	_painel_creditos.hide()
	_tela.show()
	_botao_creditos.grab_focus()


func _abrir_ranking() -> void:
	_tela.hide()
	_ranking.abrir()


func _fechar_ranking() -> void:
	_tela.show()
	_botao_ranking.grab_focus()


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


func _sair_do_jogo() -> void:
	get_tree().quit()
