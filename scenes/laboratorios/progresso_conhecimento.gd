extends Node

signal atualizado(total_concluido: int)

const TAREFAS: Array[StringName] = [
	&"fisica/ima",
	&"fisica/movimento",
	&"biologia/borboleta",
]

var _concluidas: Dictionary[StringName, bool] = {}


func total_concluido() -> int:
	return _concluidas.size()


func tarefa_concluida(tarefa: StringName) -> bool:
	return _concluidas.has(tarefa)


func concluir_tarefa(tarefa: StringName) -> void:
	if tarefa not in TAREFAS or tarefa_concluida(tarefa):
		return

	_concluidas[tarefa] = true
	atualizado.emit(total_concluido())
