extends CanvasLayer

const MENU_INICIAL := "res://scenes/ui/menu-inicial/menu-inicial.tscn"
const HUB := "res://scenes/hub-missoes/mapa.tscn"

const CENAS_DE_JOGO := [
	"res://scenes/hub-missoes/mapa.tscn",
	"res://scenes/lab-biologia/lab-bio.tscn",
	"res://scenes/lab-fisica/lab-fisica.tscn",
	"res://scenes/lab-resistencia/lab-resistencia.tscn",
	"res://scenes/sala-emocoes/sala-emocoes.tscn",
]

@onready var _continuar: Button = $Fundo/Janela/Botoes/Continuar
@onready var _menu_inicial: Button = $Fundo/Janela/Botoes/MenuInicial
@onready var _fechar: Button = $Fundo/Janela/Botoes/Fechar

var _foco_anterior: Control
var _retomar_edicao := false


func _ready() -> void:
	_continuar.pressed.connect(_retomar)
	_menu_inicial.pressed.connect(_voltar_ao_menu)
	_fechar.pressed.connect(func() -> void: get_tree().quit())


func _input(evento: InputEvent) -> void:
	if not evento is InputEventKey or not evento.is_action_pressed(&"ui_cancel", true):
		return
	if not visible and not _pode_pausar():
		return
	get_viewport().set_input_as_handled()
	if evento.is_echo():
		return
	if visible:
		_retomar()
	else:
		abrir()


func _pode_pausar() -> bool:
	var cena := get_tree().current_scene
	return not get_tree().paused and cena != null and cena.scene_file_path in CENAS_DE_JOGO


func abrir() -> void:
	if not _pode_pausar():
		return
	var no_hub := get_tree().current_scene.scene_file_path == HUB
	_menu_inicial.visible = no_hub
	$Fundo/Janela.offset_top = -77.0 if no_hub else -63.0
	$Fundo/Janela.offset_bottom = 77.0 if no_hub else 63.0
	$Fundo/Janela/Dica.offset_top = 128.0 if no_hub else 100.0
	$Fundo/Janela/Dica.offset_bottom = 144.0 if no_hub else 116.0
	var botoes: Array[Button] = [_continuar, _fechar]
	if no_hub:
		botoes.insert(1, _menu_inicial)
	for indice in botoes.size():
		var botao := botoes[indice]
		var anterior := botao.get_path_to(botoes[(indice - 1 + botoes.size()) % botoes.size()])
		var proximo := botao.get_path_to(botoes[(indice + 1) % botoes.size()])
		botao.focus_neighbor_top = anterior
		botao.focus_previous = anterior
		botao.focus_neighbor_bottom = proximo
		botao.focus_next = proximo
	var viewport := get_viewport()
	if viewport.gui_is_dragging():
		viewport.gui_cancel_drag()
	_foco_anterior = viewport.gui_get_focus_owner()
	var campo := _foco_anterior as LineEdit
	_retomar_edicao = campo != null and campo.is_editing()
	get_tree().paused = true
	show()
	_continuar.grab_focus()


func _voltar_ao_menu() -> void:
	var erro := get_tree().change_scene_to_file(MENU_INICIAL)
	if erro != OK:
		push_error("Falha ao voltar ao menu inicial: %s" % error_string(erro))
		return
	hide()
	get_tree().paused = false
	_foco_anterior = null
	_retomar_edicao = false


func _retomar() -> void:
	hide()
	get_tree().paused = false
	if is_instance_valid(_foco_anterior) and _foco_anterior.is_visible_in_tree():
		_foco_anterior.grab_focus()
		if _retomar_edicao:
			(_foco_anterior as LineEdit).edit()
	_foco_anterior = null
