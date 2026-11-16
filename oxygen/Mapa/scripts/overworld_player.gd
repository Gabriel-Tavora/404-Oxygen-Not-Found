class_name OverworldPlayer
extends Node2D
## Personagem no mapa: anda livre (8 direções) mas só em cima da pista.
## A pista vem de uma imagem-máscara (branco = pode andar); sem a máscara,
## vale uma faixa em volta das ligações entre os pontos do mapa.
## Usa o personagem, a cor do cabelo e a cor da mochila escolhidos na tela de seleção.

## Chegou perto de um ponto do mapa (fase, casa...)
signal arrived(node: MapNode)
## Saiu de perto do ponto
signal departed

@export var walk_speed := 110.0
## Distância (px) para considerar que está "em cima" de um ponto
@export var raio_ponto := 28.0
## Meia largura da faixa usada quando não há máscara da pista
@export var meia_faixa := 14.0

@onready var corpo: AnimatedSprite2D = $Corpo
@onready var mochila: AnimatedSprite2D = $Mochila

var current: MapNode
var moving := false
var facing := "down"
## Máscara da pista (branco = pode andar)
var pista: Image

var _pontos: Array[MapNode] = []
var _segmentos: Array[PackedVector2Array] = []


func _ready() -> void:
	corpo.frame_changed.connect(func(): mochila.frame = corpo.frame)
	_vestir()


## Coloca o personagem escolhido. Se a tela de seleção ainda não foi usada
## (rodando o mapa direto), usa o Personagem 1 / cabelo preto / mochila azul.
func _vestir() -> void:
	if PersonagemEscolhido.dados == null:
		var base := "res://UI/SelecaoPersonagem"
		var p := base.path_join("personagens/p1.tres")
		if ResourceLoader.exists(p):
			PersonagemEscolhido.dados = load(p)
			var m := base.path_join("mochilas/azul.tres")
			if PersonagemEscolhido.mochila == null and ResourceLoader.exists(m):
				PersonagemEscolhido.mochila = load(m)
	PersonagemEscolhido.aplicar(corpo, mochila)
	_play("idle")


## Lê os pontos do mapa: os que não são só "caminho" viram lugares onde dá para parar,
## e as ligações viram a faixa de reserva da pista.
func configurar(nodes: Node) -> void:
	_pontos.clear()
	_segmentos.clear()
	for n in nodes.get_children():
		var mn := n as MapNode
		if mn == null:
			continue
		if mn.kind != MapNode.Kind.PATH:
			_pontos.append(mn)
		for p in mn.connections:
			var o := mn.get_node_or_null(p) as MapNode
			if o:
				_segmentos.append(PackedVector2Array([mn.position, o.position]))


func place_at(node: MapNode) -> void:
	position = node.position if node else position
	if not pode_andar(position):
		position = _ponto_mais_perto_da_faixa(position)
	moving = false
	current = null
	_play("idle")
	_atualizar_ponto()


func pode_andar(p: Vector2) -> bool:
	if pista:
		var x := int(p.x)
		var y := int(p.y)
		if x < 0 or y < 0 or x >= pista.get_width() or y >= pista.get_height():
			return false
		return pista.get_pixel(x, y).r > 0.5
	return _ponto_mais_perto_da_faixa(p).distance_to(p) <= meia_faixa


func _ponto_mais_perto_da_faixa(p: Vector2) -> Vector2:
	var melhor := p
	var menor := INF
	for s in _segmentos:
		var q := Geometry2D.get_closest_point_to_segment(p, s[0], s[1])
		var d := q.distance_squared_to(p)
		if d < menor:
			menor = d
			melhor = q
	return melhor


## Chame todo frame com a direção apertada (Vector2.ZERO = parado).
func andar(dir: Vector2, delta: float) -> void:
	if dir == Vector2.ZERO:
		if moving:
			moving = false
			_play("idle")
		return
	var passo := dir.normalized() * walk_speed * delta
	var novo := position + passo
	if not pode_andar(novo):
		# desliza pela borda da pista em vez de travar
		if passo.x != 0.0 and pode_andar(position + Vector2(passo.x, 0)):
			novo = position + Vector2(passo.x, 0)
		elif passo.y != 0.0 and pode_andar(position + Vector2(0, passo.y)):
			novo = position + Vector2(0, passo.y)
		else:
			novo = position
	_face(dir)
	moving = novo != position
	position = novo
	_play("walk" if moving else "idle")
	_atualizar_ponto()


func _atualizar_ponto() -> void:
	var perto: MapNode = null
	var menor := raio_ponto
	for n in _pontos:
		var d := n.position.distance_to(position)
		if d <= menor:
			menor = d
			perto = n
	if perto == current:
		return
	current = perto
	if perto:
		arrived.emit(perto)
	else:
		departed.emit()


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
