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
	current = node
	position = node.position
	moving = false
	_play("idle")


func try_move(dir: Vector2) -> bool:
	if moving:
		var return_direction := (_from.position - _target.position).normalized()
		if return_direction.dot(dir.normalized()) <= 0.7:
			return false
		var previous := _from
		_from = _target
		_target = previous
		_face(return_direction)
		_play("walk")
		return true
	if current == null:
		return false
	var nb := current.neighbor_in_direction(dir)
	if nb == null:
		return false
	_from = current
	_target = nb
	current = null
	moving = true
	_face(_target.position - position)
	_play("walk")
	departed.emit()
	return true


func _process(delta: float) -> void:
	if not moving:
		return
	position = position.move_toward(_target.position, walk_speed * delta)
	if position != _target.position:
		return
	var node := _target
	if node.kind == MapNode.Kind.PATH:
		var nbs := node.get_neighbors()
		if nbs.size() == 2:
			var nxt: MapNode = nbs[0] if nbs[1] == _from else nbs[1]
			_from = node
			_target = nxt
			_face(_target.position - position)
			_play("walk")
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
