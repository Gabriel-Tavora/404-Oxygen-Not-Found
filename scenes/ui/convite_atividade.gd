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
	_recompensa.text = "Você pode repetir, mas não vai ganhar mais pontos de Conhecimento." if concluida else _recompensa_inicial
	_beneficio.add_theme_stylebox_override("panel", _fundo_aviso if concluida else _fundo_inicial)
	_recompensa.add_theme_color_override("font_color", Color.WHITE if concluida else _cor_inicial)
	_pergunta.text = "Missão concluída. Quer jogar de novo?" if concluida else "Quer participar?"
	_sim.text = "Jogar de novo" if concluida else "Quero tentar!"
	_icone_ima.visible = atividade == &"ima"
	_icone_movimento.visible = atividade == &"movimento"
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
