extends Node2D

@onready var _player = $Player
@onready var _convite = $Interface/ConviteAtividade
@onready var _treinamento = $Interface/PainelTreinamento
@onready var _missoes: Dictionary[StringName, Control] = {
	&"palavras_cruzadas": $Interface/PalavrasCruzadas,
	&"memoria": $Interface/JogoMemoria,
}


func _ready() -> void:
	for sinal in $Sinais.get_children():
		var missao: Control = _missoes.get(sinal.atividade)
		if missao == null:
			continue
		sinal.convite_solicitado.connect(_abrir_convite.bind(sinal.tarefa))
		missao.concluido.connect(_concluir_missao.bind(sinal.tarefa, missao))
		missao.fechado.connect(_liberar_controles)
	_convite.respondido.connect(_responder_convite)


func _abrir_convite(atividade: StringName, tarefa: StringName) -> void:
	if _player.controles_bloqueados:
		return
	if _convite.abrir(atividade, ProgressoConhecimento.tarefa_concluida(tarefa)):
		_player.controles_bloqueados = true


func _concluir_missao(tarefa: StringName, missao: Control) -> void:
	var pontos_anteriores := ProgressoConhecimento.pontos_mental()
	ProgressoConhecimento.concluir_tarefa(tarefa)
	if ProgressoConhecimento.pontos_mental() > pontos_anteriores:
		missao.mostrar_recompensa()


func _responder_convite(atividade: StringName, aceitou: bool) -> void:
	if aceitou:
		_treinamento.ocultar_durante_missao()
		_missoes[atividade].abrir()
	else:
		_liberar_controles()


func _liberar_controles() -> void:
	_player.controles_bloqueados = false
	_treinamento.restaurar_apos_missao()
