class_name ResultadoMissao
extends ColorRect

signal voltar_solicitado

@onready var _atividade: Label = $Janela/Atividade
@onready var _resumo: Label = $Janela/Resumo
@onready var _voltar: Button = $Janela/Voltar


func _ready() -> void:
	_voltar.pressed.connect(_voltar_ao_laboratorio)


func mostrar(atividade: String, resumo: String) -> void:
	_atividade.text = atividade
	_resumo.text = resumo
	show()
	_voltar.grab_focus()


func _unhandled_input(evento: InputEvent) -> void:
	if is_visible_in_tree() and evento.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_voltar_ao_laboratorio()


func _voltar_ao_laboratorio() -> void:
	hide()
	voltar_solicitado.emit()
