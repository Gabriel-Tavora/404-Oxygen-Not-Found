extends Control

const GRAVIDADE := 1.8
const TEMPO_ARRASTO_FOLHA := 0.30
const ALTURA_INICIAL := 30.0
const ALTURA_CHAO := 81.0
const PISTA := Color("#46606a")
const BORDA := Color("#63858b")
const LINHA_CHAO := Color("#c6a16d")

var queda_bola := 0.0
var queda_folha := 0.0


func atualizar(tempo: float, com_ar: bool) -> bool:
	# As duas trajetórias partem do repouso com a mesma gravidade.
	# O arrasto linear reduz a velocidade da folha em relação à queda livre.
	var queda_livre := 0.5 * GRAVIDADE * tempo * tempo
	var queda_com_arrasto := GRAVIDADE * TEMPO_ARRASTO_FOLHA * (
		tempo - TEMPO_ARRASTO_FOLHA * (1.0 - exp(-tempo / TEMPO_ARRASTO_FOLHA))
	)
	queda_bola = minf(queda_livre, 1.0)
	queda_folha = minf(queda_com_arrasto if com_ar else queda_livre, 1.0)
	queue_redraw()
	return queda_bola == 1.0 and queda_folha == 1.0


func _draw() -> void:
	var pista_bola := roundf(size.x * 0.25)
	var pista_folha := roundf(size.x * 0.75)

	draw_rect(Rect2(Vector2.ZERO, size), Color("#1a272f"))
	draw_rect(Rect2(Vector2.ZERO, size), BORDA, false, 1.0)
	draw_rect(Rect2(1, ALTURA_CHAO, size.x - 2, size.y - ALTURA_CHAO - 1), Color("#304950"))
	draw_rect(Rect2(1, ALTURA_CHAO, size.x - 2, 1), LINHA_CHAO)
	draw_rect(Rect2(floorf(size.x * 0.5), 4, 1, ALTURA_CHAO - 8), PISTA)
	for x in range(8, floori(size.x) - 6, 12):
		draw_rect(Rect2(x, ALTURA_CHAO + 3, 6, 2), PISTA)

	for x: float in [pista_bola, pista_folha]:
		draw_rect(Rect2(x - 27, ALTURA_INICIAL, 54, 1), PISTA)
		for y in range(32, floori(ALTURA_CHAO), 5):
			draw_rect(Rect2(x, y, 1, 2), PISTA)

	var bola := Vector2(pista_bola, _base_objeto(queda_bola))
	var folha := Vector2(pista_folha, _base_objeto(queda_folha))
	_desenhar_bola(bola)
	_desenhar_folha(folha)


func _base_objeto(queda: float) -> float:
	return roundf(lerpf(ALTURA_INICIAL, ALTURA_CHAO, queda))


func _desenhar_bola(base: Vector2) -> void:
	draw_rect(Rect2(base + Vector2(-5, -13), Vector2(10, 13)), Color("#ad533a"))
	draw_rect(Rect2(base + Vector2(-7, -11), Vector2(14, 9)), Color("#ad533a"))
	draw_rect(Rect2(base + Vector2(-5, -12), Vector2(10, 9)), Color("#f2a65e"))
	draw_rect(Rect2(base + Vector2(-6, -10), Vector2(12, 5)), Color("#f2a65e"))
	draw_rect(Rect2(base + Vector2(-4, -11), Vector2(5, 2)), Color("#ffe4a6"))
	draw_rect(Rect2(base + Vector2(-5, -9), Vector2(2, 2)), Color("#ffe4a6"))


func _desenhar_folha(base: Vector2) -> void:
	draw_rect(Rect2(base + Vector2(-7, -11), Vector2(14, 11)), Color("#9aa6a1"))
	draw_rect(Rect2(base + Vector2(-6, -10), Vector2(12, 9)), Color("#fff0c7"))
	draw_rect(Rect2(base + Vector2(3, -11), Vector2(4, 3)), Color("#d0c6a7"))
	draw_rect(Rect2(base + Vector2(-4, -7), Vector2(6, 1)), Color("#b5ad96"))
	draw_rect(Rect2(base + Vector2(-4, -4), Vector2(8, 1)), Color("#b5ad96"))
