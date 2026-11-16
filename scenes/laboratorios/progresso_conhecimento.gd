extends Node

signal atualizado(total_concluido: int)
signal missao_finalizada(laboratorio: StringName, premiada: bool)

const TAREFAS_POR_LABORATORIO := {
	&"fisica": [&"fisica/ima", &"fisica/movimento"],
	&"biologia": [&"biologia/borboleta", &"biologia/botanica"],
	&"resistencia": [&"resistencia/esteira", &"resistencia/danca"],
	&"emocoes": [&"emocoes/palavras_cruzadas", &"emocoes/memoria"],
}

var _concluidas: Dictionary[StringName, bool] = {}


func total_tarefas(laboratorio: StringName) -> int:
	var tarefas: Array = TAREFAS_POR_LABORATORIO.get(laboratorio, [])
	return tarefas.size()


func total_concluido() -> int:
	return _concluidas.size()


func total_concluido_no_laboratorio(laboratorio: StringName) -> int:
	var tarefas: Array = TAREFAS_POR_LABORATORIO.get(laboratorio, [])
	var total := 0
	for tarefa in tarefas:
		if tarefa_concluida(tarefa):
			total += 1
	return total


func tarefa_concluida(tarefa: StringName) -> bool:
	return _concluidas.has(tarefa)


func pontos_mental() -> int:
	return total_concluido_no_laboratorio(&"emocoes")


func concluir_tarefa(tarefa: StringName) -> void:
	var laboratorio := StringName(String(tarefa).get_slice("/", 0))
	var tarefas: Array = TAREFAS_POR_LABORATORIO.get(laboratorio, [])
	if tarefa not in tarefas:
		return

	var premiada := not tarefa_concluida(tarefa)
	if premiada:
		_concluidas[tarefa] = true
		atualizado.emit(total_concluido())
	missao_finalizada.emit(laboratorio, premiada)
