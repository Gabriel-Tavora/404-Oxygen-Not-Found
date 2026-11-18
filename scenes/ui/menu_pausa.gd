extends CanvasLayer

const CENAS_DE_JOGO := [
	"res://scenes/hub-missoes/mapa.tscn",
	"res://scenes/lab-biologia/lab-bio.tscn",
	"res://scenes/lab-fisica/lab-fisica.tscn",
	"res://scenes/lab-resistencia/lab-resistencia.tscn",
	"res://scenes/sala-emocoes/sala-emocoes.tscn",
]

@onready var _continuar: Button = $Fundo/Janela/Botoes/Continuar
@onready var _fechar: Button = $Fundo/Janela/Botoes/Fechar

var _foco_anterior: Control
var _retomar_edicao := false


func _ready() -> void:
	_continuar.pressed.connect(_retomar)
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
	var viewport := get_viewport()
	if viewport.gui_is_dragging():
		viewport.gui_cancel_drag()
	_foco_anterior = viewport.gui_get_focus_owner()
	var campo := _foco_anterior as LineEdit
	_retomar_edicao = campo != null and campo.is_editing()
	get_tree().paused = true
	show()
	_continuar.grab_focus()


func _retomar() -> void:
	hide()
	get_tree().paused = false
	if is_instance_valid(_foco_anterior) and _foco_anterior.is_visible_in_tree():
		_foco_anterior.grab_focus()
		if _retomar_edicao:
			(_foco_anterior as LineEdit).edit()
	_foco_anterior = null
