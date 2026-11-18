extends ColorRect

signal fechado

const COR_CABECALHO := Color("#98c5e2")
const COR_LIDER := Color("#ffda86")
const COR_LINHA := Color("#e3f1ff")

@onready var _conteudo: VBoxContainer = $Conteudo
@onready var _rolagem: ScrollContainer = $Conteudo/Rolagem
@onready var _linhas: VBoxContainer = $Conteudo/Rolagem/Linhas
@onready var _vazio: Label = $Conteudo/Vazio
@onready var _voltar: Button = $Conteudo/Voltar


func _ready() -> void:
	var cabecalho := _criar_linha("Pos.", "Jogador", "Melhor tempo", COR_CABECALHO)
	_conteudo.add_child(cabecalho)
	_conteudo.move_child(cabecalho, _rolagem.get_index())
	_voltar.pressed.connect(_fechar)


func abrir() -> void:
	for linha in _linhas.get_children():
		_linhas.remove_child(linha)
		linha.queue_free()
	var registros := Partida.ranking_ordenado()
	for indice in registros.size():
		var registro := registros[indice]
		var cor := COR_LIDER if indice == 0 else COR_LINHA
		var tempo := Partida.formatar_tempo(registro["tempo_ms"])
		_linhas.add_child(_criar_linha("%dº" % (indice + 1), registro["nome"], tempo, cor))
	_vazio.visible = registros.is_empty()
	_rolagem.visible = not registros.is_empty()
	_rolagem.set_deferred("scroll_vertical", 0)
	show()
	_voltar.grab_focus()


func _unhandled_input(evento: InputEvent) -> void:
	if not visible:
		return
	if evento.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_fechar()
	elif _rolagem.visible:
		if evento.is_action_pressed(&"ui_up", true):
			_rolagem.scroll_vertical -= 24
		elif evento.is_action_pressed(&"ui_down", true):
			_rolagem.scroll_vertical += 24


func _fechar() -> void:
	hide()
	fechado.emit()


func _criar_linha(posicao: String, nome: String, tempo: String, cor: Color) -> PanelContainer:
	var linha := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#172b43")
	estilo.content_margin_left = 9
	estilo.content_margin_right = 9
	estilo.content_margin_top = 3
	estilo.content_margin_bottom = 3
	linha.add_theme_stylebox_override(&"panel", estilo)
	var colunas := HBoxContainer.new()
	colunas.add_theme_constant_override(&"separation", 8)
	linha.add_child(colunas)
	colunas.add_child(_criar_coluna(posicao, cor, 36, HORIZONTAL_ALIGNMENT_CENTER))
	var jogador := _criar_coluna(nome, cor, 0, HORIZONTAL_ALIGNMENT_LEFT)
	jogador.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	jogador.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	jogador.mouse_filter = Control.MOUSE_FILTER_PASS
	jogador.tooltip_text = nome
	colunas.add_child(jogador)
	colunas.add_child(_criar_coluna(tempo, cor, 106, HORIZONTAL_ALIGNMENT_RIGHT))
	return linha


func _criar_coluna(valor: String, cor: Color, largura: float, alinhamento: HorizontalAlignment) -> Label:
	var coluna := Label.new()
	coluna.text = valor
	coluna.custom_minimum_size.x = largura
	coluna.horizontal_alignment = alinhamento
	coluna.add_theme_color_override(&"font_color", cor)
	return coluna
