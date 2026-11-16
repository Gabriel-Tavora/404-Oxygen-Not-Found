extends Control

signal concluido
signal fechado

const CARTA := preload("res://scenes/sala-emocoes/carta-memoria.tscn")
const FOLHA_RETRATOS := preload("res://assets/sala-emocoes/rostos-memoria.png")
const VERSO := preload("res://assets/sala-emocoes/verso-carta-memoria.png")
const TAMANHO_RETRATO := Vector2i(36, 36)
const EMOCOES := ["Alegria", "Tristeza", "Raiva", "Medo", "Surpresa", "Nojo"]
const INSTRUCAO := Color("#c8dedb")
const ACERTO := Color("#afe0ad")
const AVISO := Color("#ffd69c")

@onready var _grade: GridContainer = $Painel/Tabuleiro/Grade
@onready var _voltar: Button = $Painel/Voltar
@onready var _contador: Label = $Painel/Contador
@onready var _feedback: Label = $Painel/Rodape/Feedback
@onready var _tempo_de_revelacao: Timer = $TempoDeRevelacao

var _cartas: Array[Button] = []
var _retratos: Dictionary[Vector2i, Texture2D] = {}
var _baralho: Array[Vector2i] = []
var _pareadas: Array[bool] = []
var _primeira := -1
var _segunda := -1
var _pares := 0


func _ready() -> void:
	for emocao in EMOCOES.size():
		for variacao in 2:
			var posicao := Vector2i(emocao, variacao)
			var retrato := AtlasTexture.new()
			retrato.atlas = FOLHA_RETRATOS
			retrato.region = Rect2i(posicao * TAMANHO_RETRATO, TAMANHO_RETRATO)
			retrato.filter_clip = true
			_retratos[posicao] = retrato
			_baralho.append(posicao)

	for indice in _baralho.size():
		var carta := CARTA.instantiate() as Button
		carta.name = "Carta%02d" % (indice + 1)
		carta.pressed.connect(_virar_carta.bind(indice))
		_grade.add_child(carta)
		_cartas.append(carta)

	_pareadas.resize(_cartas.size())
	_voltar.pressed.connect(_fechar)
	_tempo_de_revelacao.timeout.connect(_recolher_cartas)


func abrir() -> void:
	_tempo_de_revelacao.stop()
	_primeira = -1
	_segunda = -1
	_pares = 0
	_pareadas.fill(false)
	_baralho.shuffle()
	for indice in _cartas.size():
		_atualizar_carta(indice)
	_atualizar_contador()
	_mostrar_feedback("Vire duas cartas para comparar os rostos.", INSTRUCAO)
	show()
	_cartas[0].grab_focus()


func mostrar_recompensa() -> void:
	_mostrar_feedback("Todos os pares! Você ganhou 1 ponto em Mental.", ACERTO)


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_fechar()


func _virar_carta(indice: int) -> void:
	if not visible or _pareadas[indice]:
		return
	if _segunda >= 0 or indice == _primeira:
		_atualizar_carta(indice)
		return

	if _primeira < 0:
		_primeira = indice
		_atualizar_carta(indice)
		_mostrar_feedback("Escolha mais uma carta.", INSTRUCAO)
		return

	_segunda = indice
	if _baralho[_primeira].x == _baralho[_segunda].x:
		_registrar_par()
	else:
		_atualizar_carta(indice)
		_mostrar_feedback("Os sentimentos são diferentes. Tente outro par.", AVISO)
		_tempo_de_revelacao.start()


func _registrar_par() -> void:
	var primeira := _primeira
	var segunda := _segunda
	_pareadas[primeira] = true
	_pareadas[segunda] = true
	_primeira = -1
	_segunda = -1
	_pares += 1
	_atualizar_carta(primeira)
	_atualizar_carta(segunda)
	_atualizar_contador()
	if _pares == EMOCOES.size():
		_mostrar_feedback("Você encontrou todos os pares. Parabéns!", ACERTO)
		_voltar.grab_focus()
		concluido.emit()
		return

	var emocao: String = EMOCOES[_baralho[segunda].x]
	_mostrar_feedback("Par de %s encontrado!" % emocao.to_lower(), ACERTO)
	var proxima := (_pareadas.find(false, segunda + 1) if segunda + 1 < _pareadas.size() else -1)
	if proxima < 0:
		proxima = _pareadas.find(false)
	_cartas[proxima].grab_focus()


func _recolher_cartas() -> void:
	var primeira := _primeira
	var segunda := _segunda
	_primeira = -1
	_segunda = -1
	_atualizar_carta(primeira)
	_atualizar_carta(segunda)
	_mostrar_feedback("Escolha duas cartas.", INSTRUCAO)


func _atualizar_carta(indice: int) -> void:
	var carta := _cartas[indice]
	var retrato: TextureRect = carta.get_node("Retrato")
	var nome: Label = carta.get_node("Nome")
	var selo: Label = carta.get_node("Selo")
	var pareada := _pareadas[indice]
	var virada := pareada or indice == _primeira or indice == _segunda
	var posicao := _baralho[indice]
	carta.disabled = pareada
	carta.set_pressed_no_signal(virada)
	retrato.texture = _retratos[posicao] if virada else VERSO
	retrato.position.y = 3 if virada else 8
	nome.text = EMOCOES[posicao.x] if virada else ""
	selo.visible = pareada
	carta.accessibility_name = nome.text if virada else "Carta %d" % (indice + 1)


func _atualizar_contador() -> void:
	_contador.text = "%d de %d pares" % [_pares, EMOCOES.size()]


func _mostrar_feedback(texto: String, cor: Color) -> void:
	_feedback.text = texto
	_feedback.add_theme_color_override("font_color", cor)


func _fechar() -> void:
	_tempo_de_revelacao.stop()
	hide()
	fechado.emit()
