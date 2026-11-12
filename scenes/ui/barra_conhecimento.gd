extends CanvasLayer

@onready var _barra: ProgressBar = $Painel/Conteudo/Progresso


func _ready() -> void:
	_barra.max_value = ProgressoConhecimento.TAREFAS.size()
	ProgressoConhecimento.atualizado.connect(_atualizar)
	_atualizar(ProgressoConhecimento.total_concluido())


func _atualizar(total_concluido: int) -> void:
	_barra.value = total_concluido
