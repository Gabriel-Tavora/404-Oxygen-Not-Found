extends Node2D

@onready var _player = $Player
@onready var _convite = $Interface/ConviteAtividade
@onready var _treinamento = $Interface/PainelTreinamento
@onready var _letras_quadro: Sprite2D = $Cenario/QuadroPalavrasCruzadas/LetrasResolvidas
@onready var _tarefa_quadro: StringName = $Sinais/SinalPalavrasCruzadas.tarefa
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
		missao.concluido.connect(ProgressoConhecimento.concluir_tarefa.bind(sinal.tarefa))
		missao.fechado.connect(_liberar_controles)
	_convite.respondido.connect(_responder_convite)
	ProgressoConhecimento.atualizado.connect(_atualizar_quadro.unbind(1))
	_atualizar_quadro()


func _atualizar_quadro() -> void:
	_letras_quadro.visible = ProgressoConhecimento.tarefa_concluida(_tarefa_quadro)


func _abrir_convite(atividade: StringName, tarefa: StringName) -> void:
	if _player.controles_bloqueados:
		return
	if _convite.abrir(atividade, ProgressoConhecimento.tarefa_concluida(tarefa)):
		_player.controles_bloqueados = true


func _responder_convite(atividade: StringName, aceitou: bool) -> void:
	if aceitou:
		_player.definir_visual_de_missao(true)
		_treinamento.ocultar_durante_missao()
		_missoes[atividade].abrir()
	else:
		_liberar_controles()


func _liberar_controles() -> void:
	_player.controles_bloqueados = false
	_player.definir_visual_de_missao(false)
	_treinamento.restaurar_apos_missao()
