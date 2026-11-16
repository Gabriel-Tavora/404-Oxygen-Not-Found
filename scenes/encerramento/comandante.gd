extends CanvasLayer

const FALAS := [
	"Parabéns, astronauta! Você terminou todos os treinos.",
	"Você fez descobertas, treinou o corpo e aprendeu sobre suas emoções.",
	"Agora você pode ir ao espaço! Seu foguete está esperando.",
	"Siga as setas brilhantes até o foguete. Boa viagem!",
]

@onready var _painel: Panel = $Tela/Painel
@onready var _fala: Label = $Tela/Painel/Fala
@onready var _pular: Button = $Tela/Painel/Pular
@onready var _som: AudioStreamPlayer = $Som

var _indice := 0


func _ready() -> void:
	get_tree().paused = true
	_painel.modulate.a = 0.0
	create_tween().tween_property(_painel, "modulate:a", 1.0, 0.24)
	_pular.pressed.connect(_avancar)
	_pular.grab_focus()
	_mostrar_fala()


func _mostrar_fala() -> void:
	_fala.text = FALAS[_indice]
	_som.play()


func _avancar() -> void:
	if _indice < FALAS.size() - 1:
		_indice += 1
		_mostrar_fala()
		return
	var arvore := get_tree()
	if arvore.change_scene_to_file(OverworldState.MAPA) == OK:
		ProgressoConhecimento.embarque_liberado = true
		arvore.paused = false
		queue_free()
