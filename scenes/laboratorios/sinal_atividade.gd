extends Area2D

signal convite_solicitado(atividade: StringName)

@export var atividade: StringName = &"ima"
@onready var _luz: Sprite2D = $Luz

var _fase: float = 0.0


func _ready() -> void:
	body_entered.connect(_ao_entrar)


func _process(delta: float) -> void:
	_fase = fposmod(_fase + delta * 2.6, TAU)
	_luz.self_modulate.a = 0.93 + 0.07 * sin(_fase)


func _ao_entrar(corpo: Node2D) -> void:
	if corpo.is_in_group(&"jogador"):
		convite_solicitado.emit(atividade)
