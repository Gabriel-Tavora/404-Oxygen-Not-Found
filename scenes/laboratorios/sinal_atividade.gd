extends Area2D

signal convite_solicitado(atividade: StringName)

const AZUL_PENDENTE := Color("#31a3ff")
const VERDE_CONCLUIDO := Color("#44ff76")

@export var atividade: StringName = &"ima"
@export var tarefa: StringName
@onready var _luz: Sprite2D = $Luz
@onready var _material: ShaderMaterial = _luz.material

var _fase: float = 0.0


func _ready() -> void:
	body_entered.connect(_ao_entrar)
	ProgressoConhecimento.atualizado.connect(_atualizar_luz)
	_atualizar_luz(ProgressoConhecimento.total_concluido())


func _atualizar_luz(_total_concluido: int) -> void:
	var cor := VERDE_CONCLUIDO if ProgressoConhecimento.tarefa_concluida(tarefa) else AZUL_PENDENTE
	_material.set_shader_parameter(&"cor_luz", cor)


func _process(delta: float) -> void:
	_fase = fposmod(_fase + delta * 2.6, TAU)
	_luz.self_modulate.a = 0.93 + 0.07 * sin(_fase)


func _ao_entrar(corpo: Node2D) -> void:
	if corpo.is_in_group(&"jogador"):
		convite_solicitado.emit(atividade)
