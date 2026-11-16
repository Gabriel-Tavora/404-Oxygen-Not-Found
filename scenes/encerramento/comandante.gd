extends CanvasLayer

signal apresentacao_concluida

const FALAS := [
	"Parabéns, astronauta! Você terminou todos os treinos.",
	"Você se mostrou capaz de alcançar alturas além do limite do céu.",
	"Você{nome} agora é o melhor dos melhores.",
	"Entre no foguete e mostre ao mundo tudo que você é capaz!",
]
const FALAS_APRESENTACAO := [
	"Olá{nome} sou a comandante Juliana.",
	"Você foi escolhido pois acreditamos que o seu potencial é gigante.",
	"Complete os treino e mostre do que você é capaz!",
]

var apresentacao := false

@onready var _painel: Panel = $Tela/Painel
@onready var _fala: RichTextLabel = $Tela/Painel/Fala
@onready var _pular: Button = $Tela/Painel/Pular
@onready var _som: AudioStreamPlayer = $Som

var _indice := 0
var _falas := FALAS
var _estava_pausado := false


func _ready() -> void:
	_estava_pausado = get_tree().paused
	get_tree().paused = true
	if apresentacao:
		_falas = FALAS_APRESENTACAO
		$Tela/Painel/Nome.text = "Comandante Juliana"
	_painel.modulate.a = 0.0
	create_tween().tween_property(_painel, "modulate:a", 1.0, 0.24)
	_pular.pressed.connect(_avancar)
	_pular.grab_focus()
	_mostrar_fala()


func _mostrar_fala() -> void:
	var nome := PersonagemEscolhido.nome_jogador
	var nome_entre_virgulas := "," if apresentacao else ""
	if not nome.is_empty():
		nome_entre_virgulas = ", %s," % nome
	_fala.text = _falas[_indice].format({"nome": nome_entre_virgulas})
	_som.play()


func _avancar() -> void:
	if _indice < _falas.size() - 1:
		_indice += 1
		_mostrar_fala()
		return
	var arvore := get_tree()
	if apresentacao:
		arvore.paused = _estava_pausado
		queue_free()
		apresentacao_concluida.emit()
		return
	if arvore.change_scene_to_file(OverworldState.MAPA) == OK:
		ProgressoConhecimento.embarque_liberado = true
		arvore.paused = false
		queue_free()
