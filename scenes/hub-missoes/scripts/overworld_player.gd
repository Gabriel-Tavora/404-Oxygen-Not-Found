class_name OverworldPlayer
extends Node2D
## Personagem no mapa: anda de um ponto até outro pela rua, com animação nas 4 direções
## (a esquerda usa a animação da direita espelhada).
## Usa o personagem, a cor do cabelo e a cor da mochila escolhidos na tela de seleção.
## Em curvas (ponto de caminho com só 2 ligações) segue sozinho, como no Super Mario World.

signal arrived(node: MapNode)
signal departed

@export var walk_speed := 120.0

@onready var corpo: AnimatedSprite2D = $Corpo
@onready var mochila: AnimatedSprite2D = $Mochila

var current: MapNode
var moving := false
var facing := "down"

var _from: MapNode
var _target: MapNode
var _caminho_automatico: Array[MapNode] = []


func _ready() -> void:
	corpo.frame_changed.connect(func(): mochila.frame = corpo.frame)
	_vestir()


## Coloca o personagem escolhido. Se a tela de seleção ainda não foi usada
## (rodando o mapa direto), usa o Personagem 1 / cabelo preto / mochila azul.
func _vestir() -> void:
	if PersonagemEscolhido.dados == null:
		var base := "res://scenes/ui/selecao-personagem"
		var p := base.path_join("personagens/p1.tres")
		if ResourceLoader.exists(p):
			PersonagemEscolhido.dados = load(p)
			var m := base.path_join("mochilas/azul.tres")
			if PersonagemEscolhido.mochila == null and ResourceLoader.exists(m):
				PersonagemEscolhido.mochila = load(m)
	PersonagemEscolhido.aplicar(corpo, mochila)
	_play("idle")


func place_at(node: MapNode) -> void:
	_caminho_automatico.clear()
	current = node
	position = node.position
	moving = false
	_play("idle")


func try_move(dir: Vector2) -> bool:
	if moving:
		_caminho_automatico.clear()
		var return_direction := (_from.position - _target.position).normalized()
		if return_direction.dot(dir.normalized()) <= 0.7:
			return false
		_seguir_trecho(_target, _from)
		return true
	if current == null:
		return false
	var nb := current.neighbor_in_direction(dir)
	if nb == null:
		return false
	_iniciar_caminhada(nb)
	return true


func caminhar_ate(destino: MapNode) -> bool:
	if moving or current == null:
		return false
	var caminho := current.caminho_ate(destino)
	if caminho.size() < 2:
		return false
	caminho.pop_front()
	_caminho_automatico = caminho
	_iniciar_caminhada(_caminho_automatico.front())
	return true


func cancelar_caminhada_automatica() -> bool:
	if _caminho_automatico.is_empty():
		return false
	_caminho_automatico.clear()
	return true


func _iniciar_caminhada(destino: MapNode) -> void:
	_seguir_trecho(current, destino)
	current = null
	moving = true
	departed.emit()


func _seguir_trecho(origem: MapNode, destino: MapNode) -> void:
	_from = origem
	_target = destino
	_face(_target.position - _from.position)
	_play("walk")


func _process(delta: float) -> void:
	if not moving:
		return
	position = position.move_toward(_target.position, walk_speed * delta)
	if position != _target.position:
		return
	var node := _target
	if not _caminho_automatico.is_empty():
		_caminho_automatico.pop_front()
		if not _caminho_automatico.is_empty():
			_seguir_trecho(node, _caminho_automatico.front())
			return
	elif node.kind == MapNode.Kind.PATH:
		var nbs := node.get_neighbors()
		if nbs.size() == 2:
			var nxt: MapNode = nbs[0] if nbs[1] == _from else nbs[1]
			_seguir_trecho(node, nxt)
			return
	moving = false
	current = node
	_play("idle")
	arrived.emit(node)


func _face(v: Vector2) -> void:
	if absf(v.x) > absf(v.y):
		facing = "right" if v.x > 0.0 else "left"
	else:
		facing = "down" if v.y > 0.0 else "up"


func _play(kind: String) -> void:
	# Os sprites só têm baixo / cima / direita: a esquerda é a direita espelhada.
	var espelhar := facing == "left"
	var anim := StringName(kind + "_" + ("right" if espelhar else facing))
	for s: AnimatedSprite2D in [corpo, mochila]:
		s.flip_h = espelhar
		if s.sprite_frames and s.sprite_frames.has_animation(anim) and s.animation != anim:
			s.play(anim)
	mochila.frame = corpo.frame
