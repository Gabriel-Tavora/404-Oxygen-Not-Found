class_name MenuFase
extends Control
## Menu que aparece quando o personagem chega a uma área.
## Mesmo estilo da tela de seleção (painel de madeira, moldura azul, seta).
## ← → escolhem, Enter/Espaço confirmam, Esc = sair. Mouse também funciona.

signal escolhido(comecar: bool)
signal treino_escolhido(laboratorio: StringName)

const TAMANHO := Vector2(1536, 1024)
const TAMANHO_AVISO := Vector2(1100, 912)
const FOTO_LABORATORIO := preload("res://scenes/hub-missoes/foto-laboratorio.tscn")
const FOTOS_TREINOS := {
	&"fisica": ["Física (via Biblioteca)", preload("res://assets/hub-missoes/laboratorios/fisica.png")],
	&"biologia": ["Biologia", preload("res://assets/hub-missoes/laboratorios/biologia.png")],
	&"resistencia": ["Resistência", preload("res://assets/hub-missoes/laboratorios/resistencia.png")],
	&"emocoes": ["Sala das Emoções", preload("res://assets/hub-missoes/laboratorios/emocoes.png")],
}

@onready var caixa: Control = $Caixa
@onready var painel: Control = $Caixa/Painel
@onready var titulo: Label = $Caixa/Painel/Titulo
@onready var descricao: Label = $Caixa/Painel/Descricao
@onready var galeria_treinos: Control = $Caixa/Painel/GaleriaTreinos
@onready var mensagem_treinos: Label = $Caixa/Painel/GaleriaTreinos/Mensagem
@onready var fotos_treinos: GridContainer = $Caixa/Painel/GaleriaTreinos/Fotos
@onready var botoes: Array[Button] = [$Caixa/Painel/Comecar, $Caixa/Painel/Sair]
@onready var acao_principal: Label = $Caixa/Painel/Comecar/Texto
@onready var selecao: NinePatchRect = $Caixa/Painel/Selecao
@onready var seta: TextureRect = $Caixa/Painel/Seta
@onready var fundo: ColorRect = $Escurecer

var indice := 0
var aberto := false
var _confirmando := false
var _somente_aviso := false
var _painel_original: Rect2
var _voltar_x := 0.0
var _legendas_treinos: Dictionary[StringName, Label] = {}
var _t := 0.0
var _seta_y := 0.0


func _ready() -> void:
	visible = false
	_painel_original = painel.get_rect()
	_voltar_x = botoes[1].position.x
	resized.connect(_ajustar)
	for i in botoes.size():
		var b := botoes[i]
		b.mouse_entered.connect(func(): _selecionar(i))
		b.pressed.connect(func(): _selecionar(i); _confirmar())
	for laboratorio: StringName in FOTOS_TREINOS:
		var foto := FOTO_LABORATORIO.instantiate() as Button
		foto.get_node("Moldura/Conteudo/Imagem").texture = FOTOS_TREINOS[laboratorio][1]
		foto.accessibility_name = "Ir para %s" % FOTOS_TREINOS[laboratorio][0]
		foto.pressed.connect(_escolher_treino.bind(laboratorio))
		_legendas_treinos[laboratorio] = foto.get_node("Moldura/Conteudo/Legenda")
		fotos_treinos.add_child(foto)
	botoes[1].add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	botoes[1].focus_entered.connect(_atualizar_indicadores)
	botoes[1].focus_exited.connect(_atualizar_indicadores)
	_ajustar()


func _ajustar() -> void:
	var s := minf(size.x / TAMANHO.x, size.y / TAMANHO.y)
	caixa.scale = Vector2(s, s)
	caixa.position = ((size - TAMANHO * s) / 2.0).round()


func abrir(nome: String, texto: String, somente_aviso := false, acao := "ENTRAR") -> void:
	_somente_aviso = somente_aviso
	painel.size = TAMANHO_AVISO if somente_aviso else _painel_original.size
	painel.position = _painel_original.get_center() - painel.size / 2.0
	painel.pivot_offset = painel.size / 2.0
	titulo.text = nome
	descricao.visible = not somente_aviso
	galeria_treinos.visible = somente_aviso
	if somente_aviso:
		_atualizar_galeria(texto)
	else:
		descricao.text = texto
	botoes[0].visible = not somente_aviso
	acao_principal.text = acao
	var voltar := botoes[1]
	voltar.focus_mode = Control.FOCUS_ALL if somente_aviso else Control.FOCUS_NONE
	voltar.position.x = (painel.size.x - voltar.size.x) / 2.0 if somente_aviso else _voltar_x
	_seta_y = voltar.position.y - seta.size.y - 11.0
	seta.position.y = _seta_y
	aberto = true
	visible = true
	_selecionar(0)
	if somente_aviso:
		voltar.grab_focus()
	_atualizar_indicadores()
	caixa.modulate.a = 0.0
	fundo.modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(caixa, "modulate:a", 1.0, 0.15)
	tw.tween_property(fundo, "modulate:a", 1.0, 0.15)
	painel.scale = Vector2(0.9, 0.9)
	tw.tween_property(painel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _atualizar_galeria(mensagem: String) -> void:
	mensagem_treinos.text = mensagem
	for laboratorio: StringName in _legendas_treinos:
		_legendas_treinos[laboratorio].text = "%s  ·  %d/%d" % [
			FOTOS_TREINOS[laboratorio][0],
			ProgressoConhecimento.total_concluido_no_laboratorio(laboratorio),
			ProgressoConhecimento.total_tarefas(laboratorio),
		]


func fechar() -> void:
	var tw := create_tween()
	tw.tween_property(caixa, "modulate:a", 0.0, 0.12)
	tw.parallel().tween_property(fundo, "modulate:a", 0.0, 0.12)
	await tw.finished
	visible = false
	aberto = false


func _selecionar(i: int) -> void:
	indice = 1 if _somente_aviso else i
	var b := botoes[indice]
	selecao.position = b.position - Vector2(12, 11)
	selecao.size = b.size + Vector2(24, 22)
	seta.position.x = b.position.x + b.size.x / 2.0 - seta.size.x / 2.0


func _atualizar_indicadores() -> void:
	var destacar_voltar := not _somente_aviso or botoes[1].has_focus()
	selecao.visible = destacar_voltar
	seta.visible = destacar_voltar


func _process(delta: float) -> void:
	if not aberto or _confirmando:
		return
	_t += delta
	seta.position.y = _seta_y + roundf(sin(_t * 5.0) * 3.0)
	selecao.modulate.a = 0.82 + 0.18 * sin(_t * 4.0)


func _unhandled_input(event: InputEvent) -> void:
	if not aberto or _confirmando:
		return
	if event.is_action_pressed(&"ui_left") or event.is_action_pressed(&"map_left"):
		_selecionar(0)
	elif event.is_action_pressed(&"ui_right") or event.is_action_pressed(&"map_right"):
		_selecionar(1)
	elif event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"map_confirm"):
		var foco := get_viewport().gui_get_focus_owner() as Button
		if _somente_aviso and foco and foco.get_parent() == fotos_treinos:
			foco.pressed.emit()
		else:
			botoes[indice].pressed.emit()
	elif event.is_action_pressed(&"ui_cancel"):
		botoes[1].pressed.emit()
	else:
		return
	get_viewport().set_input_as_handled()


func _escolher_treino(laboratorio: StringName) -> void:
	if not aberto or not _somente_aviso or _confirmando:
		return
	_confirmando = true
	await fechar()
	_confirmando = false
	treino_escolhido.emit(laboratorio)


func _confirmar() -> void:
	if not aberto or _confirmando:
		return
	_confirmando = true
	var comecar := indice == 0
	var tw := create_tween()
	for i in 2:
		tw.tween_property(selecao, "modulate", Color(2.2, 2.2, 2.2, 1), 0.06)
		tw.tween_property(selecao, "modulate", Color(1, 1, 1, 1), 0.08)
	await tw.finished
	await fechar()
	_confirmando = false
	escolhido.emit(comecar)
