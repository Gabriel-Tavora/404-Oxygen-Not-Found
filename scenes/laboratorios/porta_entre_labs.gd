extends Area2D

@export_file("*.tscn") var destino: String

@onready var _dica: Control = $Dica

var _jogador: CharacterBody2D


func _ready() -> void:
	body_entered.connect(_ao_aproximar)
	body_exited.connect(_ao_afastar)


func _ao_aproximar(corpo: Node2D) -> void:
	if corpo.is_in_group(&"jogador"):
		_jogador = corpo as CharacterBody2D
		_dica.show()


func _ao_afastar(corpo: Node2D) -> void:
	if corpo == _jogador:
		_jogador = null
		_dica.hide()


func _unhandled_input(evento: InputEvent) -> void:
	if not evento.is_action_pressed(&"usar_porta") or not is_instance_valid(_jogador):
		return
	if _jogador.controles_bloqueados:
		return

	_jogador.controles_bloqueados = true
	get_viewport().set_input_as_handled()
	_atravessar.call_deferred(_jogador)


func _atravessar(jogador: CharacterBody2D) -> void:
	# Carrega a sala no momento da passagem para evitar dependência circular entre as cenas.
	var sala := load(destino) as PackedScene
	if sala == null:
		jogador.controles_bloqueados = false
		return

	var chegada := sala.instantiate()
	var porta_chegada: Area2D = chegada.get_node("PortaEntreLabs")
	var ponto_chegada: Marker2D = porta_chegada.get_node("Chegada")
	chegada.get_node("Player").position = porta_chegada.transform * ponto_chegada.position
	var erro := get_tree().change_scene_to_node(chegada)
	if erro != OK:
		chegada.free()
		jogador.controles_bloqueados = false
