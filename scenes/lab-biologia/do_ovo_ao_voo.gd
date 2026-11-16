extends Control

signal concluido
signal fechado

const TerrarioMetamorfose := preload("res://scenes/lab-biologia/terrario_metamorfose.gd")
const CAMINHO_LAB := "res://scenes/lab-biologia/lab-bio.tscn"
const CORES_ASAS := [Color.TRANSPARENT, Color("#2484bd"), Color("#9551bf")]
const INSTRUCAO := "Toque na carta que vem a seguir."
const DICAS := [
	"Dica: tudo começa com algo pequeno sobre uma folha.",
	"Dica: quem sai do ovo e come folhas?",
	"Dica: em que etapa a lagarta muda de forma?",
	"Dica: quem sai da crisálida e abre as asas?",
]

@onready var _cartas: Control = $Cartas
@onready var _contorno_erro: Panel = $Cartas/ContornoErro
@onready var _instrucao: Label = $Moldura/Instrucao
@onready var _tirar_ultima: Button = $Moldura/Caderno/TirarUltima
@onready var _terrario: TerrarioMetamorfose = $Moldura/Terrario/Metamorfose
@onready var _soltar: Button = $Moldura/Terrario/Soltar
@onready var _escolhas: HBoxContainer = $Moldura/Escolhas
@onready var _dialogo = $Moldura/DialogoAstronauta
@onready var _voltar: Button = $Moldura/Voltar
@onready var _sair: Button = $Moldura/Sair
@onready var _sequencia: Array[Button] = [
	$Cartas/Ovo, $Cartas/Lagarta, $Cartas/Crisalida, $Cartas/Borboleta,
]
@onready var _espacos: Array[Panel] = [
	$Moldura/Caderno/Espaco1, $Moldura/Caderno/Espaco2,
	$Moldura/Caderno/Espaco3, $Moldura/Caderno/Espaco4,
]

var _proxima_etapa := 0
var _cor_escolhida := Color.TRANSPARENT


func _ready() -> void:
	var posicoes: Array[Vector2] = []
	for filho in _cartas.get_children():
		if filho is Button:
			posicoes.append(filho.position)

	var baralho: Array[Button] = _sequencia.duplicate()
	baralho.shuffle()
	if baralho == _sequencia:
		baralho.push_back(baralho.pop_front())

	for i in range(baralho.size()):
		var carta := baralho[i]
		_cartas.move_child(carta, i)
		carta.position = posicoes[i]
		carta.pressed.connect(_tentar_carta.bind(carta))
	_tirar_ultima.pressed.connect(_tirar_ultima_carta)
	_terrario.borboleta_pronta.connect(_mostrar_escolhas)
	_terrario.voo_terminado.connect(_mostrar_final)
	_soltar.pressed.connect(_soltar_borboleta)
	_voltar.pressed.connect(_voltar_ao_laboratorio)
	_sair.pressed.connect(_voltar_ao_laboratorio)
	for i in range(CORES_ASAS.size()):
		var botao: Button = _escolhas.get_child(i)
		botao.pressed.connect(_escolher_cor.bind(CORES_ASAS[i]))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_voltar_ao_laboratorio()


func _tentar_carta(carta: Button) -> void:
	if not carta.visible or _proxima_etapa == _sequencia.size():
		return

	if carta != _sequencia[_proxima_etapa]:
		_contorno_erro.position = carta.position
		_contorno_erro.size = carta.size
		_contorno_erro.show()
		_instrucao.text = "Tente outra carta!\n" + DICAS[_proxima_etapa]
		return

	var proximo_foco := carta.find_next_valid_focus() if carta.has_focus() else null
	_encaixar_carta(carta, _espacos[_proxima_etapa])
	_proxima_etapa += 1
	_terrario.mostrar_etapa(_proxima_etapa, true)
	_tirar_ultima.disabled = false
	if _proxima_etapa == _sequencia.size():
		_mostrar_instrucao("Muito bem! Você montou o ciclo da borboleta.")
		if proximo_foco != null:
			_tirar_ultima.grab_focus()
	else:
		_mostrar_instrucao(INSTRUCAO)
		if proximo_foco != null:
			proximo_foco.grab_focus()


func _tirar_ultima_carta() -> void:
	if _proxima_etapa == 0 or _tirar_ultima.disabled:
		return

	_escolhas.hide()
	_soltar.hide()
	_terrario.colorir_asas(CORES_ASAS[0])
	_proxima_etapa -= 1
	_terrario.mostrar_etapa(_proxima_etapa)
	_espacos[_proxima_etapa].get_child(0).free()
	var carta := _sequencia[_proxima_etapa]
	carta.show()
	if _proxima_etapa == 0:
		if _tirar_ultima.has_focus():
			carta.grab_focus()
		_tirar_ultima.disabled = true
	_mostrar_instrucao("Carta devolvida. Escolha a próxima.")


func _mostrar_escolhas() -> void:
	_mostrar_instrucao("Escolha a cor das asas.")
	_escolhas.show()
	for botao: Button in _escolhas.get_children():
		botao.set_pressed_no_signal(false)
	_escolhas.get_child(0).grab_focus()


func _escolher_cor(cor: Color) -> void:
	_cor_escolhida = cor
	_terrario.colorir_asas(cor)
	_soltar.show()
	_mostrar_instrucao("Toque na borboleta para ela voar!")


func _soltar_borboleta() -> void:
	if not _soltar.visible:
		return

	_soltar.hide()
	_escolhas.hide()
	_tirar_ultima.disabled = true
	_instrucao.hide()
	_dialogo.mostrar("Lá vai a borboleta!")
	_terrario.soltar_borboleta()


func _mostrar_final() -> void:
	BorboletaSolta.soltar(_cor_escolhida)
	_dialogo.mostrar("A lagarta muda de forma dentro da crisálida e sai como borboleta.")
	_sair.hide()
	_voltar.show()
	_voltar.grab_focus()
	concluido.emit()


func _voltar_ao_laboratorio() -> void:
	if get_tree().current_scene == self:
		get_tree().change_scene_to_file(CAMINHO_LAB)
	else:
		fechado.emit()


func _mostrar_instrucao(texto: String) -> void:
	_contorno_erro.hide()
	_instrucao.text = texto


func _encaixar_carta(carta: Button, espaco: Panel) -> void:
	carta.hide()
	var ficha := carta.duplicate(0) as Button
	ficha.disabled = true
	ficha.focus_mode = Control.FOCUS_NONE
	ficha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ficha.position = Vector2.ZERO
	ficha.size = espaco.size
	espaco.add_child(ficha)
	ficha.show()

	var ilustracao: TextureRect = ficha.get_node("Ilustracao")
	ilustracao.position = Vector2(
		floorf((ficha.size.x - ilustracao.size.x) * 0.5),
		4.0 + floorf((42.0 - ilustracao.size.y) * 0.5)
	)

	var rotulo: Label = ficha.get_node("Rotulo")
	if carta == _sequencia.back():
		rotulo.text = "Borboleta\nadulta"
	rotulo.position = Vector2(2, 46)
	rotulo.size = Vector2(ficha.size.x - 4.0, 22)
