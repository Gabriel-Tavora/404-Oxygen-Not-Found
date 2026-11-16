extends Node2D

const DISTANCIA_ENTRE_SETAS := 36.0
var _seta := PackedVector2Array([
	Vector2(10, 0), Vector2(0, 7), Vector2(0, 3), Vector2(-8, 3),
	Vector2(-8, -3), Vector2(0, -3), Vector2(0, -7),
])

var _pontos := PackedVector2Array()


func _ready() -> void:
	var brilho := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	brilho.tween_property(self, "modulate:a", 0.72, 0.9)
	brilho.tween_property(self, "modulate:a", 1.0, 0.9)


func tracar(origem: MapNode, destino: MapNode) -> void:
	_pontos.clear()
	var fila: Array[MapNode] = [origem]
	var anteriores: Dictionary[MapNode, MapNode] = {}
	anteriores[origem] = null

	while not fila.is_empty() and not anteriores.has(destino):
		var atual: MapNode = fila.pop_front()
		for vizinho in atual.get_neighbors():
			if anteriores.has(vizinho):
				continue
			anteriores[vizinho] = atual
			fila.append(vizinho)

	if anteriores.has(destino):
		var ponto := destino
		while ponto != null:
			_pontos.append(to_local(ponto.global_position))
			ponto = anteriores[ponto]
		_pontos.reverse()
	queue_redraw()


func _draw() -> void:
	if _pontos.size() < 2:
		return
	draw_polyline(_pontos, Color(1.0, 0.58, 0.12, 0.20), 26.0, true)
	draw_polyline(_pontos, Color(1.0, 0.76, 0.22, 0.26), 16.0, true)

	for i in range(_pontos.size() - 1):
		var inicio := _pontos[i]
		var trecho := _pontos[i + 1] - inicio
		var quantidade := maxi(1, ceili(trecho.length() / DISTANCIA_ENTRE_SETAS))
		for j in range(quantidade):
			var centro := inicio + trecho * ((j + 0.5) / quantidade)
			var seta := Transform2D(trecho.angle(), centro) * _seta
			draw_colored_polygon(seta, Color("#fff09b"))
			seta.append(seta[0])
			draw_polyline(seta, Color("#815018"), 2.0, true)
