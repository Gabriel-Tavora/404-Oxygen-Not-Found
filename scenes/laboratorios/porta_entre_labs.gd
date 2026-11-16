extends Area2D

const TRANSICAO := preload("res://scenes/ui/transicao_escurecida.gd")

@export_file("*.tscn") var destino: String
@export var porta_de_chegada: NodePath = ^"PortaEntreLabs"

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
	var arvore := get_tree()
	if porta_de_chegada.is_empty():
		if arvore.change_scene_to_node(chegada) != OK:
			chegada.free()
			jogador.controles_bloqueados = false
		return

	var porta_chegada: Area2D = chegada.get_node(porta_de_chegada)
	var ponto_chegada: Marker2D = porta_chegada.get_node("Chegada")
	var jogador_chegada: CharacterBody2D = chegada.get_node("Player")
	jogador_chegada.position = porta_chegada.transform * ponto_chegada.position
	jogador_chegada.controles_bloqueados = true

	var transicao := TRANSICAO.new()
	transicao.name = "TransicaoEscurecida"
	transicao.layer = 100
	# O fade precisa continuar visível enquanto a sala de origem é removida.
	arvore.root.add_child(transicao)
	await transicao.animar_para(1.0).finished
	var erro := arvore.change_scene_to_node(chegada)
	if erro != OK:
		chegada.free()
		await transicao.animar_para(0.0).finished
		transicao.queue_free()
		jogador.controles_bloqueados = false
		return

	transicao.tree_exited.connect(jogador_chegada.set.bind(&"controles_bloqueados", false))
	arvore.scene_changed.connect(transicao.revelar_e_remover, CONNECT_ONE_SHOT)
