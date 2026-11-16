extends Node2D

const ATIVIDADES := {
	&"botanica": {
		"tarefa": &"biologia/botanica",
		"cena": preload("res://scenes/lab-biologia/missao-broto.tscn"),
	},
	&"borboleta": {
		"tarefa": &"biologia/borboleta",
		"cena": preload("res://scenes/lab-biologia/do-ovo-ao-voo.tscn"),
	},
}

@onready var _player = $Player
@onready var _interface: CanvasLayer = $Interface
@onready var _convite = $Interface/ConviteAtividade
@onready var _treinamento = $Interface/PainelTreinamento
@onready var _muda_botanica: Sprite2D = $Cenario/LateralBotanica/BandejaMudas/MudaFeijao

var _minigame: Control


func _ready() -> void:
	$Sinais/SinalBotanica.convite_solicitado.connect(_abrir_convite)
	$Sinais/SinalBorboleta.convite_solicitado.connect(_abrir_convite)
	_convite.respondido.connect(_responder_convite)
	ProgressoConhecimento.atualizado.connect(_atualizar_muda)
	_atualizar_muda(ProgressoConhecimento.total_concluido())


func _atualizar_muda(_total_concluido: int) -> void:
	_muda_botanica.visible = ProgressoConhecimento.tarefa_concluida(ATIVIDADES[&"botanica"]["tarefa"])


func _abrir_convite(atividade: StringName) -> void:
	if _player.controles_bloqueados or not ATIVIDADES.has(atividade):
		return
	var concluida := ProgressoConhecimento.tarefa_concluida(ATIVIDADES[atividade]["tarefa"])
	if _convite.abrir(atividade, concluida):
		_player.controles_bloqueados = true


func _responder_convite(atividade: StringName, aceitou: bool) -> void:
	if not aceitou:
		_player.controles_bloqueados = false
		return

	var dados: Dictionary = ATIVIDADES[atividade]
	var cena: PackedScene = dados["cena"]
	_minigame = cena.instantiate()
	_treinamento.ocultar_durante_missao()
	if _minigame.has_signal(&"concluido"):
		_minigame.connect(&"concluido", ProgressoConhecimento.concluir_tarefa.bind(dados["tarefa"]))
	_minigame.connect(&"fechado", _fechar_minigame)
	_interface.add_child(_minigame)


func _fechar_minigame() -> void:
	_minigame.hide()
	_minigame.queue_free()
	_minigame = null
	_player.controles_bloqueados = false
	_treinamento.restaurar_apos_missao()
