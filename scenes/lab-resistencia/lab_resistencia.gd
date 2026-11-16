extends Node2D

const ATIVIDADES := {
	&"esteira": preload("res://scenes/lab-resistencia/corrida-esteira.tscn"),
	&"danca": preload("res://scenes/lab-resistencia/danca-ritmica.tscn"),
}

@onready var _player = $Player
@onready var _painel = $PainelCentral/ProgressoResistencia
@onready var _interface: CanvasLayer = $Interface
@onready var _convite = $Interface/ConviteAtividade
@onready var _treinamento = $Interface/PainelTreinamento

var _marcadores: Dictionary[StringName, Area2D] = {}
var _minigame: Control


func _ready() -> void:
	for marcador in [$Esteira/Marcador, $PistaDeDanca/Marcador]:
		_marcadores[marcador.atividade] = marcador
		marcador.convite_solicitado.connect(_abrir_convite)
	_convite.respondido.connect(_responder_convite)
	ProgressoConhecimento.atualizado.connect(_atualizar_painel)
	_atualizar_painel()


func _atualizar_painel(_total_concluido: int = 0) -> void:
	_painel.missoes_concluidas = ProgressoConhecimento.total_concluido_no_laboratorio(&"resistencia")


func _abrir_convite(atividade: StringName) -> void:
	if _player.controles_bloqueados:
		return
	if _convite.abrir(atividade, ProgressoConhecimento.tarefa_concluida(_marcadores[atividade].tarefa)):
		_player.controles_bloqueados = true


func _responder_convite(atividade: StringName, aceitou: bool) -> void:
	if not aceitou:
		_player.controles_bloqueados = false
		return

	var cena: PackedScene = ATIVIDADES[atividade]
	_minigame = cena.instantiate()
	_player.definir_visual_de_missao(true)
	_treinamento.ocultar_durante_missao()
	_minigame.connect(&"concluido", ProgressoConhecimento.concluir_tarefa.bind(_marcadores[atividade].tarefa))
	_minigame.connect(&"fechado", _fechar_minigame)
	_interface.add_child(_minigame)


func _fechar_minigame() -> void:
	_minigame.hide()
	_minigame.queue_free()
	_minigame = null
	_player.controles_bloqueados = false
	_player.definir_visual_de_missao(false)
	_treinamento.restaurar_apos_missao()
