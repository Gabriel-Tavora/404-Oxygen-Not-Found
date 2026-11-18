extends Node

signal atualizado(total_concluido: int)
signal missao_finalizada(laboratorio: StringName, premiada: bool)

const CENA_COMANDANTE := preload("res://scenes/encerramento/comandante.tscn")
const TAREFAS_POR_LABORATORIO := {
	&"fisica": [&"fisica/ima", &"fisica/movimento"],
	&"biologia": [&"biologia/borboleta", &"biologia/botanica"],
	&"resistencia": [&"resistencia/esteira", &"resistencia/danca"],
	&"emocoes": [&"emocoes/palavras_cruzadas", &"emocoes/memoria"],
}

var embarque_liberado := false
var lancamento_iniciado := false

var _concluidas: Dictionary[StringName, bool] = {}
var _comandante_apresentado := false


func reiniciar() -> void:
	_concluidas.clear()
	_comandante_apresentado = false
	embarque_liberado = false
	lancamento_iniciado = false
	atualizado.emit(0)


func total_tarefas(laboratorio: StringName) -> int:
	var tarefas: Array = TAREFAS_POR_LABORATORIO.get(laboratorio, [])
	return tarefas.size()


func total_concluido() -> int:
	return _concluidas.size()


func treinamento_completo() -> bool:
	var total := 0
	for tarefas: Array in TAREFAS_POR_LABORATORIO.values():
		total += tarefas.size()
	return total_concluido() == total


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


func apresentar_comandante() -> void:
	if _comandante_apresentado or not treinamento_completo():
		return
	_comandante_apresentado = true
	get_tree().root.add_child.call_deferred(CENA_COMANDANTE.instantiate())
