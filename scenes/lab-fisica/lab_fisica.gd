extends Node2D

signal atividade_escolhida(atividade: StringName)

@onready var _player = $Player
@onready var _convite = $Interface/ConviteAtividade
@onready var _expedicao = $Interface/ExpedicaoMagnetica
@onready var _lancamento = $Interface/LancamentoObliquo


func _ready() -> void:
	for sinal in $Sinais.get_children():
		sinal.convite_solicitado.connect(_iniciar_atividade)
	_convite.respondido.connect(_responder_convite)
	_expedicao.fechado.connect(_liberar_controles)
	_expedicao.concluido.connect(_ao_concluir_expedicao)
	_lancamento.fechado.connect(_liberar_controles)
	_lancamento.concluido.connect(_ao_concluir_lancamento)


func _iniciar_atividade(atividade: StringName) -> void:
	if _player.controles_bloqueados:
		return
	var concluida := ProgressoConhecimento.tarefa_concluida(StringName("fisica/" + String(atividade)))
	if _convite.abrir(atividade, concluida):
		_player.controles_bloqueados = true


func _liberar_controles() -> void:
	_player.controles_bloqueados = false


func _ao_concluir_expedicao() -> void:
	ProgressoConhecimento.concluir_tarefa(&"fisica/ima")


func _ao_concluir_lancamento() -> void:
	ProgressoConhecimento.concluir_tarefa(&"fisica/movimento")


func _responder_convite(atividade: StringName, aceitou: bool) -> void:
	if not aceitou:
		_liberar_controles()
		return
	match atividade:
		&"ima":
			_expedicao.abrir()
		&"movimento":
			_lancamento.abrir()
	atividade_escolhida.emit(atividade)
