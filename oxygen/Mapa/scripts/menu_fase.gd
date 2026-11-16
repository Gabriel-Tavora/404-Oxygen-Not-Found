class_name MenuFase
extends Control
## Menu da missão: só o nome e dois botões grandes, "JOGAR" ou "VOLTAR".
## Mesmo estilo da tela de seleção (painel de madeira, moldura azul, seta).
## ← → escolhem, Enter/Espaço confirmam, Esc = sair. Mouse também funciona.

signal escolhido(comecar: bool)

const TAMANHO := Vector2(1536, 1024)

@onready var caixa: Control = $Caixa
@onready var titulo: Label = $Caixa/Painel/Titulo
@onready var descricao: Label = $Caixa/Painel/Descricao
@onready var botoes: Array[Control] = [$Caixa/Painel/Comecar, $Caixa/Painel/Sair]
@onready var selecao: NinePatchRect = $Caixa/Painel/Selecao
@onready var seta: TextureRect = $Caixa/Painel/Seta
@onready var fundo: ColorRect = $Escurecer

var indice := 0
var aberto := false
var _t := 0.0
var _seta_y := 0.0


func _ready() -> void:
	visible = false
	# menos coisa na tela: sem texto de descrição, botões com uma palavra só
	descricao.visible = false
	titulo.position.y += 70.0
	($Caixa/Painel/Comecar/Texto as Label).text = "JOGAR"
	($Caixa/Painel/Sair/Texto as Label).text = "VOLTAR"
	_seta_y = seta.position.y
	resized.connect(_ajustar)
	for i in botoes.size():
		var b := botoes[i] as Button
		b.mouse_entered.connect(func(): _selecionar(i))
		b.pressed.connect(func(): _selecionar(i); _confirmar())
	_ajustar()


func _ajustar() -> void:
	var s := minf(size.x / TAMANHO.x, size.y / TAMANHO.y)
	caixa.scale = Vector2(s, s)
	caixa.position = ((size - TAMANHO * s) / 2.0).round()


func abrir(nome: String, texto: String) -> void:
	titulo.text = nome
	descricao.text = texto
	aberto = true
	visible = true
	_selecionar(0)
	caixa.modulate.a = 0.0
	fundo.modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(caixa, "modulate:a", 1.0, 0.15)
	tw.tween_property(fundo, "modulate:a", 1.0, 0.15)
	var painel: Control = $Caixa/Painel
	painel.scale = Vector2(0.9, 0.9)
	tw.tween_property(painel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func fechar() -> void:
	aberto = false
	var tw := create_tween()
	tw.tween_property(caixa, "modulate:a", 0.0, 0.12)
	tw.parallel().tween_property(fundo, "modulate:a", 0.0, 0.12)
	await tw.finished
	visible = false


func _selecionar(i: int) -> void:
	indice = i
	var b := botoes[i]
	selecao.position = b.position - Vector2(12, 11)
	selecao.size = b.size + Vector2(24, 22)
	seta.position.x = b.position.x + b.size.x / 2.0 - seta.size.x / 2.0


func _process(delta: float) -> void:
	if not aberto:
		return
	_t += delta
	seta.position.y = _seta_y + roundf(sin(_t * 5.0) * 3.0)
	selecao.modulate.a = 0.82 + 0.18 * sin(_t * 4.0)


func _unhandled_input(event: InputEvent) -> void:
	if not aberto:
		return
	if event.is_action_pressed(&"ui_left") or event.is_action_pressed(&"map_left"):
		_selecionar(0)
	elif event.is_action_pressed(&"ui_right") or event.is_action_pressed(&"map_right"):
		_selecionar(1)
	elif event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"map_confirm"):
		_confirmar()
	elif event.is_action_pressed(&"ui_cancel"):
		_selecionar(1)
		_confirmar()
	else:
		return
	get_viewport().set_input_as_handled()


func _confirmar() -> void:
	if not aberto:
		return
	var comecar := indice == 0
	var tw := create_tween()
	for i in 2:
		tw.tween_property(selecao, "modulate", Color(2.2, 2.2, 2.2, 1), 0.06)
		tw.tween_property(selecao, "modulate", Color(1, 1, 1, 1), 0.08)
	await tw.finished
	await fechar()
	escolhido.emit(comecar)
