extends Control

signal concluido
signal fechado

const PASSO_CELULA := 22
const LADO_CELULA := 20
const TINTA := Color("#243e49")
const INSTRUCAO := Color("#c8dedb")
const AVISO := Color("#ffd69c")
const ACERTO := Color("#afe0ad")
const PISTAS := [
	{
		"numero": 1,
		"inicio": Vector2i(0, 0),
		"direcao": Vector2i.RIGHT,
		"palavra": "CORAGEM",
		"dica": "O que ajuda a tentar algo importante, mesmo quando sentimos medo?",
	},
	{
		"numero": 1,
		"inicio": Vector2i(0, 0),
		"direcao": Vector2i.DOWN,
		"palavra": "CALMA",
		"dica": "O que sentimos quando o corpo e a mente estão tranquilos?",
	},
	{
		"numero": 2,
		"inicio": Vector2i(5, 0),
		"direcao": Vector2i.DOWN,
		"palavra": "EMPATIA",
		"dica": "Entender como outra pessoa pode estar se sentindo.",
	},
	{
		"numero": 3,
		"inicio": Vector2i(0, 3),
		"direcao": Vector2i.RIGHT,
		"palavra": "MEDO",
		"dica": "Sentimento que aparece quando achamos que algo pode ser perigoso.",
	},
	{
		"numero": 4,
		"inicio": Vector2i(1, 6),
		"direcao": Vector2i.RIGHT,
		"palavra": "RAIVA",
		"dica": "Sentimento que pode surgir quando algo parece injusto.",
	},
]
const LETRAS_INICIAIS := {
	Vector2i(0, 0): "C",
	Vector2i(5, 0): "E",
	Vector2i(0, 3): "M",
	Vector2i(1, 6): "R",
}

@export var celula_normal: StyleBox
@export var celula_ativa: StyleBox
@export var celula_preenchida: StyleBox

@onready var _grade: Control = $Painel/Tabuleiro/Grade
@onready var _lista: VBoxContainer = $Painel/Pistas
@onready var _dica: Label = $Painel/Dica
@onready var _resposta: LineEdit = $Painel/Resposta
@onready var _conferir: Button = $Painel/Conferir
@onready var _voltar: Button = $Painel/Voltar
@onready var _subtitulo: Label = $Painel/Subtitulo
@onready var _contador: Label = $Painel/Contador
@onready var _feedback: Label = $Painel/Rodape/Feedback

var _celulas: Dictionary[Vector2i, Panel] = {}
var _botoes: Array[Button] = []
var _letras: Dictionary[Vector2i, String] = {}
var _resolvidas: Dictionary[int, bool] = {}
var _rascunhos: Dictionary[int, String] = {}
var _pista_atual := -1


func _ready() -> void:
	_montar_tabuleiro()
	_voltar.pressed.connect(_fechar)
	_conferir.pressed.connect(_conferir_resposta)
	_resposta.text_submitted.connect(func(_texto: String) -> void: _conferir_resposta())


func abrir() -> void:
	_letras.clear()
	_resolvidas.clear()
	_rascunhos.clear()
	_pista_atual = -1
	_subtitulo.text = "Escolha uma pista e complete o quadro."
	_resposta.show()
	_conferir.show()
	show()
	_selecionar_pista(0)


func mostrar_recompensa() -> void:
	_mostrar_feedback("Quadro completo! Você ganhou 1 ponto em Mental.", ACERTO)


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_fechar()


func _montar_tabuleiro() -> void:
	var numeros: Dictionary[Vector2i, int] = {}
	for pista in PISTAS:
		numeros[pista["inicio"]] = pista["numero"]

	for indice in PISTAS.size():
		var pista: Dictionary = PISTAS[indice]
		var botao := Button.new()
		botao.custom_minimum_size.y = 16
		botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
		botao.toggle_mode = true
		botao.pressed.connect(_selecionar_pista.bind(indice))
		_lista.add_child(botao)
		_botoes.append(botao)

		var palavra: String = pista["palavra"]
		for deslocamento in palavra.length():
			var posicao := _posicao_letra(pista, deslocamento)
			if _celulas.has(posicao):
				continue
			_criar_celula(posicao, numeros.get(posicao, 0))


func _criar_celula(posicao: Vector2i, numero: int) -> void:
	var celula := Panel.new()
	celula.position = Vector2(posicao * PASSO_CELULA)
	celula.size = Vector2(LADO_CELULA, LADO_CELULA)
	celula.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grade.add_child(celula)
	_celulas[posicao] = celula

	var letra := Label.new()
	letra.name = "Letra"
	letra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if numero > 0:
		letra.offset_left = 4
		letra.offset_top = 5
	letra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letra.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	letra.add_theme_font_size_override("font_size", 12)
	letra.add_theme_color_override("font_color", TINTA)
	celula.add_child(letra)

	if numero > 0:
		var ordem := Label.new()
		ordem.name = "Numero"
		ordem.position = Vector2(2, 0)
		ordem.text = str(numero)
		ordem.add_theme_color_override("font_color", TINTA)
		celula.add_child(ordem)


func _posicao_letra(pista: Dictionary, deslocamento: int) -> Vector2i:
	return pista["inicio"] + pista["direcao"] * deslocamento


func _selecionar_pista(indice: int) -> void:
	if _pista_atual >= 0 and not _resolvidas.has(_pista_atual):
		_rascunhos[_pista_atual] = _resposta.text
	_pista_atual = indice
	_dica.text = PISTAS[indice]["dica"]
	_resposta.text = _rascunhos.get(indice, "")
	_resposta.caret_column = _resposta.text.length()
	_atualizar_tabuleiro()
	_mostrar_feedback("Digite a palavra e pressione Enter.", INSTRUCAO)
	_resposta.grab_focus()


func _atualizar_tabuleiro() -> void:
	var ativas: Array[Vector2i] = []
	if _pista_atual >= 0:
		var selecionada: Dictionary = PISTAS[_pista_atual]
		var palavra: String = selecionada["palavra"]
		for indice in palavra.length():
			ativas.append(_posicao_letra(selecionada, indice))

	for posicao in _celulas:
		var celula := _celulas[posicao]
		var letra: Label = celula.get_node("Letra")
		letra.text = _letras.get(posicao, LETRAS_INICIAIS.get(posicao, ""))
		var estilo := celula_preenchida if _letras.has(posicao) else celula_normal
		celula.add_theme_stylebox_override("panel", celula_ativa if posicao in ativas else estilo)

	for indice in _botoes.size():
		var pista: Dictionary = PISTAS[indice]
		var direcao := "Horizontal" if pista["direcao"] == Vector2i.RIGHT else "Vertical"
		var resolvida := _resolvidas.has(indice)
		var estado := "Resolvida" if resolvida else "%d letras" % pista["palavra"].length()
		var botao := _botoes[indice]
		botao.text = "%d   %s     %s" % [pista["numero"], direcao, estado]
		botao.disabled = resolvida
		botao.set_pressed_no_signal(indice == _pista_atual)
	_contador.text = "%d de %d" % [_resolvidas.size(), PISTAS.size()]


func _conferir_resposta() -> void:
	if _pista_atual < 0:
		return

	var pista: Dictionary = PISTAS[_pista_atual]
	var palavra: String = pista["palavra"]
	var tentativa := _resposta.text.strip_edges().to_upper()
	if tentativa != palavra:
		if tentativa.length() != palavra.length():
			_mostrar_feedback("Esta palavra tem %d letras." % palavra.length(), AVISO)
		else:
			_mostrar_feedback("Ainda não. Leia a pista e tente outra palavra.", AVISO)
		_resposta.grab_focus()
		_resposta.select_all()
		return

	for indice in palavra.length():
		_letras[_posicao_letra(pista, indice)] = palavra[indice]
	_resolvidas[_pista_atual] = true
	if _resolvidas.size() == PISTAS.size():
		_concluir()
		return

	for passo in range(1, PISTAS.size()):
		var proxima := (_pista_atual + passo) % PISTAS.size()
		if not _resolvidas.has(proxima):
			_selecionar_pista(proxima)
			_mostrar_feedback("Certo! As letras em comum ajudam nas outras pistas.", ACERTO)
			return


func _concluir() -> void:
	_pista_atual = -1
	_subtitulo.text = "Quadro completo"
	_resposta.hide()
	_conferir.hide()
	_dica.text = "Dar nome ao que sentimos ajuda a falar sobre isso."
	_atualizar_tabuleiro()
	_mostrar_feedback("Você encontrou todas as palavras. Parabéns!", ACERTO)
	_voltar.grab_focus()
	concluido.emit()


func _mostrar_feedback(texto: String, cor: Color) -> void:
	_feedback.text = texto
	_feedback.add_theme_color_override("font_color", cor)


func _fechar() -> void:
	hide()
	fechado.emit()
