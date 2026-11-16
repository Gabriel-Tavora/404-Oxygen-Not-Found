@tool
extends Node2D

const ARTE := preload("res://assets/lab-resistencia/painel-central.png")
const TOTAL_SEGMENTOS := 10
const SEGMENTOS_POR_MISSAO := 5
const CONTORNO := Color("#506f76")
const FUNDO_SEGMENTO := Color("#162d38")
const PREENCHIMENTO := Color("#62d1b5")
const BRILHO := Color("#a1f1d7")

## Quantidade de missões concluídas exibida no painel. Também permite prévia no editor.
@export_range(0, 2) var missoes_concluidas: int = 0:
	set(valor):
		missoes_concluidas = clampi(valor, 0, 2)
		queue_redraw()


func _draw() -> void:
	var preenchidos := missoes_concluidas * SEGMENTOS_POR_MISSAO
	for segmento in range(TOTAL_SEGMENTOS):
		var origem := Vector2(138 + segmento * 7, 20)
		var preenchido := segmento < preenchidos
		draw_rect(Rect2(origem, Vector2(6, 10)), CONTORNO)
		draw_rect(Rect2(origem + Vector2.ONE, Vector2(4, 8)), PREENCHIMENTO if preenchido else FUNDO_SEGMENTO)
		if preenchido:
			draw_rect(Rect2(origem + Vector2.ONE, Vector2(4, 1)), BRILHO)
	var percentual := Rect2(0, 120 + missoes_concluidas * 8, 24, 8)
	draw_texture_rect_region(ARTE, Rect2(206, 21, 24, 8), percentual)
