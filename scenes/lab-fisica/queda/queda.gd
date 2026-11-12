extends Control

signal fechado
signal concluido

enum Etapa { PALPITE, QUEDA, RESULTADO }

const CAMARA_SCRIPT := preload("res://scenes/lab-fisica/queda/camara.gd")
const DIALOGO_SCRIPT := preload("res://scenes/ui/dialogo_astronauta.gd")

@onready var _camara: CAMARA_SCRIPT = $Painel/Camara
@onready var _rodada: Label = $Painel/Rodada
@onready var _pergunta: Label = $Painel/Pergunta
@onready var _palpites: Array[Button] = [
	$Painel/Palpites/Bola,
	$Painel/Palpites/Folha,
	$Painel/Palpites/Juntas,
]
@onready var _acao: Button = $Painel/Acao
@onready var _voltar: Button = $Painel/Voltar
@onready var _dialogo: DIALOGO_SCRIPT = $DialogoAstronauta

var _etapa := Etapa.PALPITE
var _com_ar := true
var _tempo := 0.0


func _ready() -> void:
	set_process(false)
	for palpite in _palpites:
		palpite.pressed.connect(_selecionar_palpite)
	_acao.pressed.connect(_avancar)
	_voltar.pressed.connect(_fechar)


func abrir() -> void:
	show()
	_iniciar_rodada(true)


func _iniciar_rodada(com_ar: bool) -> void:
	_com_ar = com_ar
	_etapa = Etapa.PALPITE
	_tempo = 0.0
	set_process(false)
	_camara.atualizar(0.0, _com_ar)
	for palpite in _palpites:
		palpite.disabled = false
		palpite.set_pressed_no_signal(false)
	_acao.disabled = true
	_acao.text = "Soltar"
	_rodada.text = "Com ar" if _com_ar else "Sem ar"
	_pergunta.text = "Qual chega primeiro ao chão?"
	if _com_ar:
		_dialogo.mostrar("A bola e a folha estão na mesma altura. Dê seu palpite e solte as duas!")
	else:
		_dialogo.mostrar("Agora tiramos o ar da câmara. O que vai acontecer? Você pode mudar seu palpite.")
	_palpites[0].grab_focus()


func _selecionar_palpite() -> void:
	_acao.disabled = false
	_acao.grab_focus()


func _avancar() -> void:
	match _etapa:
		Etapa.PALPITE:
			_soltar_objetos()
		Etapa.RESULTADO:
			_iniciar_rodada(not _com_ar)


func _soltar_objetos() -> void:
	_etapa = Etapa.QUEDA
	_acao.disabled = true
	for palpite in _palpites:
		palpite.disabled = true
	_pergunta.text = "Observe a queda!"
	_dialogo.mostrar("As duas foram soltas ao mesmo tempo.")
	set_process(true)


func _process(delta: float) -> void:
	_tempo += delta
	if _camara.atualizar(_tempo, _com_ar):
		_mostrar_resultado()


func _mostrar_resultado() -> void:
	_etapa = Etapa.RESULTADO
	set_process(false)
	var acertou := _palpites[0 if _com_ar else 2].button_pressed
	if _com_ar:
		_pergunta.text = ("Acertou! " if acertou else "") + "A bola chegou primeiro!"
		_dialogo.mostrar("O ar freia mais a folha. Por isso, ela demorou mais para chegar ao chão.")
		_acao.text = "Testar sem ar"
	else:
		_pergunta.text = ("Acertou! " if acertou else "") + "As duas chegaram juntas!"
		_dialogo.mostrar("A gravidade puxa as duas. Foi o ar que atrasou a folha!")
		_acao.text = "Jogar de novo"
		concluido.emit()
	_acao.disabled = false
	_acao.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_fechar()


func _fechar() -> void:
	set_process(false)
	hide()
	fechado.emit()
