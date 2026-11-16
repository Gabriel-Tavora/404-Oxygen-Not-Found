extends Control

signal respondido(atividade: StringName, aceitou: bool)

const ATIVIDADES := {
	&"ima": {
		"titulo": "Expedição magnética",
		"descricao": "Use o ímã para abrir caminho e pegar moedas.",
	},
	&"movimento": {
		"titulo": "Lançamento oblíquo",
		"descricao": "Mire a bola e acerte as três caixas.",
	},
	&"borboleta": {
		"titulo": "Do ovo ao voo",
		"descricao": "Monte o ciclo e solte a borboleta.",
	},
	&"botanica": {
		"titulo": "Missão Broto",
		"descricao": "Descubra como nasce um pé de feijão.",
		"beneficio": "Coloque a muda na bandeja e ganhe Conhecimento.",
	},
	&"esteira": {
		"titulo": "Corrida na esteira",
		"descricao": "Pegue 30 moedas e desvie das barreiras.",
		"beneficio": "Complete a missão e ganhe 1 ponto em Resistência.",
		"atributo": "Resistência",
	},
	&"danca": {
		"titulo": "Dança no ritmo",
		"descricao": "Siga as setas e acerte 40 passos.",
		"beneficio": "Complete a missão e ganhe 1 ponto em Resistência.",
		"atributo": "Resistência",
	},
	&"palavras_cruzadas": {
		"titulo": "Palavras cruzadas",
		"descricao": "Leia as pistas e use as letras em comum.",
		"beneficio": "Complete o quadro e ganhe 1 ponto em Mental.",
		"atributo": "Mental",
	},
	&"memoria": {
		"titulo": "Jogo da memória",
		"descricao": "Combine dois rostos com o mesmo sentimento.",
		"beneficio": "Encontre os seis pares e ganhe 1 ponto em Mental.",
		"atributo": "Mental",
	},
}

@onready var _titulo: Label = $Janela/Titulo
@onready var _descricao: Label = $Janela/Descricao
@onready var _beneficio: Panel = $Janela/Beneficio
@onready var _recompensa: Label = $Janela/Recompensa
@onready var _pergunta: Label = $Janela/Pergunta
@onready var _recompensa_inicial := _recompensa.text
@onready var _fundo_inicial := _beneficio.get_theme_stylebox("panel")
@onready var _cor_inicial := _recompensa.get_theme_color("font_color")
@onready var _sim: Button = $Janela/QueroTentar
@onready var _nao: Button = $Janela/AgoraNao
@onready var _icone_ima: TextureRect = $Janela/IconeIma
@onready var _icone_movimento: TextureRect = $Janela/IconeMovimento
@onready var _icone_borboleta: TextureRect = $Janela/IconeBorboleta
@onready var _icone_botanica: TextureRect = $Janela/IconeBotanica
@onready var _icone_esteira: TextureRect = $Janela/IconeEsteira
@onready var _icone_danca: TextureRect = $Janela/IconeDanca
@onready var _icone_palavras_cruzadas: TextureRect = $Janela/IconePalavrasCruzadas
@onready var _icone_memoria: TextureRect = $Janela/IconeMemoria

var _atividade: StringName
var _fundo_aviso: StyleBoxFlat


func _ready() -> void:
	_fundo_aviso = _fundo_inicial.duplicate() as StyleBoxFlat
	_fundo_aviso.bg_color = Color("#d41429")
	_fundo_aviso.border_color = Color("#961124")
	_sim.pressed.connect(_responder.bind(true))
	_nao.pressed.connect(_responder.bind(false))


func abrir(atividade: StringName, concluida: bool = false) -> bool:
	if visible or not ATIVIDADES.has(atividade):
		return false
	_atividade = atividade
	var dados: Dictionary = ATIVIDADES[atividade]
	_titulo.text = dados["titulo"]
	_descricao.text = dados["descricao"]
	var atributo: String = dados.get("atributo", "Conhecimento")
	_recompensa.text = ("Você pode repetir, mas não vai ganhar mais pontos de %s." % atributo
		if concluida else dados.get("beneficio", _recompensa_inicial))
	_beneficio.add_theme_stylebox_override("panel", _fundo_aviso if concluida else _fundo_inicial)
	_recompensa.add_theme_color_override("font_color", Color.WHITE if concluida else _cor_inicial)
	_pergunta.text = "Missão concluída. Quer jogar de novo?" if concluida else "Quer participar?"
	_sim.text = "Jogar de novo" if concluida else "Quero tentar!"
	_icone_ima.visible = atividade == &"ima"
	_icone_movimento.visible = atividade == &"movimento"
	_icone_borboleta.visible = atividade == &"borboleta"
	_icone_botanica.visible = atividade == &"botanica"
	_icone_esteira.visible = atividade == &"esteira"
	_icone_danca.visible = atividade == &"danca"
	_icone_palavras_cruzadas.visible = atividade == &"palavras_cruzadas"
	_icone_memoria.visible = atividade == &"memoria"
	show()
	_sim.grab_focus()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_responder(false)


func _responder(aceitou: bool) -> void:
	if not visible:
		return
	hide()
	respondido.emit(_atividade, aceitou)
