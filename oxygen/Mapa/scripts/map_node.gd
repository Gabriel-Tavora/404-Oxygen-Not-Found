@tool
class_name MapNode
extends Marker2D
## Ponto do mapa (estilo Super Mario World). Pode ser uma fase, um cruzamento
## ou só uma parada. Os vizinhos ficam em "connections"; a direção de cada um
## é calculada pela posição, então basta ligar os nós.

enum Kind { LEVEL, PATH, STOP, START, LOCKED }

## Nome mostrado no HUD quando o jogador para aqui
@export var display_name := ""
## Texto mostrado no menu da fase
@export_multiline var descricao := ""
@export var kind: Kind = Kind.PATH:
	set(v):
		kind = v
		queue_redraw()
## Cena da fase (vazio = "em breve")
@export_file("*.tscn") var level_scene := ""
## Nós ligados a este por rua
@export var connections: Array[NodePath] = []

var _t := 0.0


func _process(delta: float) -> void:
	if kind != Kind.PATH:
		_t += delta
		queue_redraw()


func get_neighbors() -> Array[MapNode]:
	var out: Array[MapNode] = []
	for p in connections:
		var n := get_node_or_null(p) as MapNode
		if n:
			out.append(n)
	# Ligações feitas só de um lado também valem
	if get_parent():
		for other in get_parent().get_children():
			if other is MapNode and other != self and not out.has(other):
				for p in (other as MapNode).connections:
					if other.get_node_or_null(p) == self:
						out.append(other)
	return out


## Vizinho na direção pedida (setas), ou null
func neighbor_in_direction(dir: Vector2) -> MapNode:
	var best: MapNode = null
	var best_dot := 0.7
	for n in get_neighbors():
		var d := (n.position - position).normalized().dot(dir.normalized())
		if d > best_dot:
			best_dot = d
			best = n
	return best


func is_completed() -> bool:
	return OverworldState.is_completed(name)


func _draw() -> void:
	match kind:
		Kind.PATH:
			_ellipse(Vector2.ZERO, Vector2(3, 2), Color(1, 1, 1, 0.55))
		Kind.LOCKED:
			_pad(Color("8a4a5a"), Color("c86478"), 0.6)
			draw_line(Vector2(-3, -2), Vector2(3, 2), Color("ffd6dc"), 1.0)
			draw_line(Vector2(-3, 2), Vector2(3, -2), Color("ffd6dc"), 1.0)
		Kind.STOP, Kind.START:
			_pad(Color("2c5a9a"), Color("78c8ff"), 0.8)
		Kind.LEVEL:
			if is_completed():
				_pad(Color("8a6a1e"), Color("ffd45a"), 1.0)
			else:
				_pad(Color("1f4a8c"), Color("6ad0ff"), 1.0)


func _pad(inner: Color, ring: Color, strength: float) -> void:
	var pulse := 0.5 + 0.5 * sin(_t * 4.0)
	_ellipse(Vector2.ZERO, Vector2(12, 6), Color(0.1, 0.12, 0.16, 0.9))
	_ellipse(Vector2.ZERO, Vector2(11, 5), ring.lerp(Color.WHITE, pulse * 0.35 * strength))
	_ellipse(Vector2.ZERO, Vector2(8, 3), inner)
	# brilho em volta
	_ellipse(Vector2.ZERO, Vector2(15, 8), Color(ring, 0.18 + 0.15 * pulse * strength))


func _ellipse(c: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	var steps := 20
	for i in steps:
		var a := TAU * i / steps
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	draw_colored_polygon(pts, col)
