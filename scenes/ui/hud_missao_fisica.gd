extends RefCounted

const TINTA := Color("#482e3c")
const CONTORNO := Color("#583d48")
const BRILHO := Color("#fcebd5")
const FONTE := preload("res://assets/ui/lab-pixel.fnt")


static func painel(tela: CanvasItem, area: Rect2, cor: Color) -> void:
	tela.draw_rect(Rect2(area.position + Vector2(2, 3), area.size), Color("#182632"))
	tela.draw_rect(area.grow_individual(0, -2, 0, -2), CONTORNO)
	tela.draw_rect(area.grow_individual(-2, 0, -2, 0), CONTORNO)
	tela.draw_rect(area.grow(-2), cor)
	tela.draw_rect(Rect2(area.position + Vector2(4, 2), Vector2(area.size.x - 8, 1)), BRILHO)
	tela.draw_rect(Rect2(area.position + Vector2(4, area.size.y - 4), Vector2(area.size.x - 8, 2)), cor.darkened(0.15))


static func controle(tela: CanvasItem, x: int, largura: int, tecla: String, acao: String, cor: Color) -> void:
	tela.draw_rect(Rect2(x, 261, largura, 14), CONTORNO)
	tela.draw_rect(Rect2(x + 1, 262, largura - 2, 11), cor)
	var texto := FONTE.get_string_size(tecla, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	tela.draw_string(FONTE, Vector2(roundf(x + (largura - texto) / 2.0), 270), tecla, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, TINTA)
	tela.draw_string(FONTE, Vector2(x + largura + 5, 270), acao, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, TINTA)
