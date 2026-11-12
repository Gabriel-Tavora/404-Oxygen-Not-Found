extends SceneTree
## Seção 3: decoração da parede, desenhada diretamente em PNGs sem suavização.
## Cada objeto é independente; não altera a base nem a bancada existente.

const ASSET_DIR := "res://assets/lab-fisica"
const OUTLINE := Color("293b43")
const WOOD_DARK := Color("4e4840")
const WOOD_SHADE := Color("78604b")
const WOOD := Color("a98057")
const WOOD_LIGHT := Color("c9a16d")
const WOOD_GLEAM := Color("e4c28c")
const PANEL_DARK := Color("334f56")
const PANEL_SHADE := Color("436e73")
const PANEL := Color("588b88")
const PANEL_LIGHT := Color("7ba49a")
const CREAM := Color("e6d9b0")
const CREAM_LIGHT := Color("f3e9ca")
const SHADOW := Color(0.18, 0.22, 0.23, 0.25)
const CHALK := Color("d9dfbf")
const CHALK_YELLOW := Color("e6cd8c")
const FONT := {
	"A": ["010", "101", "111", "101", "101"],
	"C": ["011", "100", "100", "100", "011"],
	"D": ["110", "101", "101", "101", "110"],
	"E": ["111", "100", "110", "100", "111"],
	"F": ["111", "100", "110", "100", "100"],
	"I": ["111", "010", "010", "010", "111"],
	"L": ["100", "100", "100", "100", "111"],
	"Q": ["010", "101", "101", "111", "011"],
	"S": ["011", "100", "010", "001", "110"],
	"U": ["101", "101", "101", "101", "111"],
	"Z": ["111", "001", "010", "100", "111"],
}


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ASSET_DIR))
	var error := _save_window_layers()
	var window_only := "--window-only" in OS.get_cmdline_user_args()
	if error == OK and not window_only:
		error = _board().save_png(ASSET_DIR.path_join("fundo-quadro.png"))
	if error == OK and not window_only:
		error = _shelves().save_png(ASSET_DIR.path_join("fundo-prateleiras.png"))
	if error != OK:
		push_error("Não foi possível salvar a decoração: %s" % error)
		quit(1)
		return
	print("Camadas da janela criadas." if window_only else "Fundo criado: janela, quadro e prateleiras.")
	quit()


func _blank(width: int, height: int) -> Image:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	return image


func _rect(image: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	image.fill_rect(Rect2i(x, y, width, height), color)


func _stepped(image: Image, area: Rect2i, color: Color) -> void:
	_rect(image, area.position.x + 2, area.position.y, area.size.x - 4, area.size.y, color)
	_rect(image, area.position.x, area.position.y + 2, area.size.x, area.size.y - 4, color)


func _line(image: Image, start: Vector2i, end: Vector2i, color: Color) -> void:
	# Bresenham: linhas de giz com espessura de um pixel, sem antialiasing.
	var point := start
	var delta := Vector2i(absi(end.x - point.x), -absi(end.y - point.y))
	var step := Vector2i(1 if point.x < end.x else -1, 1 if point.y < end.y else -1)
	var error := delta.x + delta.y
	while true:
		image.set_pixelv(point, color)
		if point == end:
			break
		var twice := error * 2
		if twice >= delta.y:
			error += delta.y
			point.x += step.x
		if twice <= delta.x:
			error += delta.x
			point.y += step.y


func _text(image: Image, value: String, x: int, y: int, color: Color) -> void:
	for character in value:
		var glyph: Array = FONT.get(character, [])
		for row in range(glyph.size()):
			for column in range(3):
				if glyph[row][column] == "1":
					image.set_pixel(x + column, y + row, color)
		x += 4


func _save_window_layers() -> Error:
	var layers := {
		"fundo-janela.png": _window_frame(),
		"fundo-janela-ceu.png": _sky(),
		"fundo-janela-colinas.png": _near_hills(),
		"fundo-janela-nuvens.png": _clouds(),
		"fundo-janela-sol.png": _sun(),
	}
	for filename: String in layers:
		var layer: Image = layers[filename]
		var error := layer.save_png(ASSET_DIR.path_join(filename))
		if error != OK:
			return error
	return OK


func _window_frame() -> Image:
	var image := _blank(68, 60)
	_stepped(image, Rect2i(3, 4, 64, 54), SHADOW)
	_stepped(image, Rect2i(0, 0, 64, 54), OUTLINE)
	_rect(image, 2, 2, 60, 50, WOOD)
	_rect(image, 2, 2, 60, 2, WOOD_GLEAM)
	_rect(image, 2, 4, 2, 46, WOOD_LIGHT)
	_rect(image, 60, 4, 2, 47, WOOD_SHADE)
	_rect(image, 5, 5, 54, 44, WOOD_DARK)
	_rect(image, 6, 6, 52, 42, Color.TRANSPARENT)
	# Reflexos nítidos e discretos, restritos aos cantos superiores.
	_rect(image, 8, 8, 2, 9, Color("b3d3d1"))
	_rect(image, 10, 8, 7, 1, Color("b3d3d1"))
	_rect(image, 35, 8, 2, 6, Color("b3d3d1"))
	# Caixilhos e peitoril: luz no alto/esquerda, sombra embaixo/direita.
	_rect(image, 29, 5, 5, 44, WOOD_DARK)
	_rect(image, 30, 5, 3, 44, WOOD_LIGHT)
	_rect(image, 30, 5, 1, 44, WOOD_GLEAM)
	_rect(image, 5, 25, 54, 4, WOOD_DARK)
	_rect(image, 6, 25, 52, 2, WOOD_LIGHT)
	_rect(image, 6, 25, 52, 1, WOOD_GLEAM)
	_rect(image, 0, 50, 64, 6, OUTLINE)
	_rect(image, 1, 50, 62, 2, WOOD_GLEAM)
	_rect(image, 1, 52, 62, 2, WOOD)
	_rect(image, 2, 54, 60, 1, WOOD_SHADE)
	return image


func _sky() -> Image:
	var image := _blank(128, 42)
	var hills := Color("94af95")
	image.fill(Color("8db8c5"))
	_rect(image, 0, 0, 128, 4, Color("7c9fac"))
	_rect(image, 0, 25, 128, 17, hills)
	_rect(image, 0, 22, 12, 3, hills)
	_rect(image, 5, 19, 9, 6, hills)
	_rect(image, 13, 24, 10, 1, hills)
	_rect(image, 32, 23, 20, 2, hills)
	_rect(image, 38, 20, 14, 5, hills)
	_rect(image, 63, 22, 17, 3, hills)
	_rect(image, 70, 17, 10, 8, hills)
	_rect(image, 85, 23, 12, 2, hills)
	_rect(image, 104, 19, 10, 6, hills)
	_rect(image, 112, 21, 7, 4, hills)
	_rect(image, 122, 22, 6, 3, hills)
	return image


func _near_hills() -> Image:
	var image := _blank(128, 42)
	var hills := Color("708e79")
	_rect(image, 0, 33, 128, 9, hills)
	_rect(image, 0, 30, 14, 3, hills)
	_rect(image, 13, 31, 8, 2, hills)
	_rect(image, 37, 30, 15, 3, hills)
	_rect(image, 54, 31, 10, 2, hills)
	_rect(image, 74, 29, 14, 4, hills)
	_rect(image, 92, 31, 18, 2, hills)
	_rect(image, 118, 30, 10, 3, hills)
	return image


func _clouds() -> Image:
	var image := _blank(128, 42)
	var underside := Color("b5cbb8")
	_rect(image, 7, 11, 15, 3, CREAM_LIGHT)
	_rect(image, 11, 8, 7, 4, CREAM_LIGHT)
	_rect(image, 17, 10, 7, 3, CREAM_LIGHT)
	_rect(image, 8, 14, 13, 1, underside)
	_rect(image, 54, 13, 19, 3, CREAM_LIGHT)
	_rect(image, 60, 10, 8, 4, CREAM_LIGHT)
	_rect(image, 55, 16, 16, 1, underside)
	_rect(image, 103, 8, 14, 3, CREAM_LIGHT)
	_rect(image, 107, 6, 6, 4, CREAM_LIGHT)
	_rect(image, 104, 11, 12, 1, underside)
	return image


func _sun() -> Image:
	var image := _blank(8, 5)
	_rect(image, 1, 0, 6, 5, CHALK_YELLOW)
	_rect(image, 0, 1, 8, 3, CHALK_YELLOW)
	return image


func _board() -> Image:
	var image := _blank(100, 56)
	_stepped(image, Rect2i(3, 4, 96, 49), SHADOW)
	_stepped(image, Rect2i(0, 0, 96, 48), OUTLINE)
	_rect(image, 2, 2, 92, 44, WOOD)
	_rect(image, 2, 2, 92, 1, WOOD_GLEAM)
	_rect(image, 2, 3, 1, 42, WOOD_LIGHT)
	_rect(image, 92, 3, 2, 43, WOOD_SHADE)
	_rect(image, 5, 5, 86, 38, PANEL_DARK)
	_rect(image, 6, 6, 84, 36, Color("3c6162"))
	_rect(image, 6, 6, 84, 1, Color("355658"))
	_rect(image, 6, 7, 1, 34, Color("355658"))
	# Título e dois desenhos reconhecíveis, sem fórmulas ou tarefas extras.
	_text(image, "FISICA", 36, 9, CHALK)
	image.set_pixel(42, 7, CHALK) # Acento do Í em FÍSICA.
	_rect(image, 10, 16, 75, 1, PANEL_SHADE)
	# Lâmpada: filamento, base e três pequenos raios de luz.
	_rect(image, 23, 20, 7, 1, CHALK_YELLOW)
	_rect(image, 21, 21, 2, 2, CHALK_YELLOW)
	_rect(image, 30, 21, 2, 2, CHALK_YELLOW)
	_rect(image, 20, 23, 1, 4, CHALK_YELLOW)
	_rect(image, 32, 23, 1, 4, CHALK_YELLOW)
	_line(image, Vector2i(21, 27), Vector2i(24, 30), CHALK_YELLOW)
	_line(image, Vector2i(31, 27), Vector2i(28, 30), CHALK_YELLOW)
	_rect(image, 24, 30, 5, 1, CHALK_YELLOW)
	_line(image, Vector2i(24, 24), Vector2i(26, 28), CHALK)
	_line(image, Vector2i(28, 24), Vector2i(26, 28), CHALK)
	_rect(image, 24, 32, 5, 1, CHALK)
	_rect(image, 25, 34, 3, 1, CHALK)
	_rect(image, 16, 23, 2, 1, CHALK_YELLOW)
	_rect(image, 35, 23, 2, 1, CHALK_YELLOW)
	_rect(image, 26, 17, 1, 1, CHALK_YELLOW)
	_text(image, "LUZ", 21, 37, CHALK)
	# Queda: bola no alto e seta apontando para o chão.
	_stepped(image, Rect2i(62, 20, 7, 6), CHALK)
	_rect(image, 64, 21, 3, 3, Color("3c6162"))
	_rect(image, 65, 27, 1, 6, CHALK_YELLOW)
	_line(image, Vector2i(62, 30), Vector2i(65, 33), CHALK_YELLOW)
	_line(image, Vector2i(68, 30), Vector2i(65, 33), CHALK_YELLOW)
	_rect(image, 59, 35, 13, 1, CHALK)
	_text(image, "QUEDA", 56, 37, CHALK)
	# Calha e giz: detalhes na borda, sem invadir os desenhos.
	_rect(image, 2, 45, 92, 5, OUTLINE)
	_rect(image, 3, 45, 90, 1, WOOD_GLEAM)
	_rect(image, 3, 46, 90, 2, WOOD)
	_rect(image, 13, 44, 6, 1, CHALK)
	_rect(image, 78, 43, 8, 2, WOOD_DARK)
	_rect(image, 79, 43, 6, 1, WOOD_LIGHT)
	return image


func _book(image: Image, x: int, bottom: int, width: int, height: int, colors: Array[Color]) -> void:
	_rect(image, x, bottom - height, width, height, OUTLINE)
	_rect(image, x + 1, bottom - height + 1, width - 2, height - 2, colors[0])
	_rect(image, x + 1, bottom - height + 1, 1, height - 2, colors[1])
	_rect(image, x + width - 2, bottom - height + 1, 1, height - 2, colors[2])
	_rect(image, x + 2, bottom - height + 3, width - 4, 1, CREAM)
	_rect(image, x + 2, bottom - 4, width - 4, 1, CREAM)


func _shelf(image: Image, y: int) -> void:
	_rect(image, 3, y + 4, 63, 5, SHADOW)
	_rect(image, 7, y + 4, 5, 9, WOOD_DARK)
	_rect(image, 8, y + 5, 2, 6, WOOD_SHADE)
	_rect(image, 52, y + 4, 5, 9, WOOD_DARK)
	_rect(image, 53, y + 5, 2, 6, WOOD_SHADE)
	_rect(image, 0, y, 64, 6, OUTLINE)
	_rect(image, 1, y, 62, 1, WOOD_GLEAM)
	_rect(image, 1, y + 1, 62, 2, WOOD)
	_rect(image, 1, y + 3, 62, 1, WOOD_SHADE)
	_rect(image, 10, y + 2, 10, 1, WOOD_LIGHT)
	_rect(image, 44, y + 2, 8, 1, WOOD_LIGHT)


func _shelves() -> Image:
	var image := _blank(68, 70)
	# Duas prateleiras finas com suportes, deixando a parede aparecer entre elas.
	_shelf(image, 24)
	_shelf(image, 56)
	# Livros de alturas diferentes: cores contidas e lombadas bem definidas.
	_book(image, 5, 24, 7, 20, [Color("ae6c5a"), Color("cf9472"), Color("805349")])
	_book(image, 12, 24, 7, 17, [PANEL, PANEL_LIGHT, PANEL_SHADE])
	_book(image, 20, 24, 6, 22, [WOOD, WOOD_GLEAM, WOOD_SHADE])
	_book(image, 26, 24, 7, 19, [Color("72869a"), Color("9aadb3"), Color("536378")])
	# Régua de madeira e dois pequenos pesos de calibração.
	_rect(image, 42, 5, 6, 19, OUTLINE)
	_rect(image, 43, 6, 4, 18, WOOD_LIGHT)
	_rect(image, 43, 6, 1, 18, WOOD_GLEAM)
	for y in range(8, 23, 3):
		_rect(image, 45, y, 2, 1, WOOD_SHADE)
	_rect(image, 50, 20, 9, 4, OUTLINE)
	_rect(image, 51, 20, 7, 2, Color("9aadb3"))
	_rect(image, 53, 17, 3, 3, OUTLINE)
	_rect(image, 54, 18, 1, 2, CREAM)
	# Livros deitados, com páginas visíveis.
	_rect(image, 6, 49, 23, 7, OUTLINE)
	_rect(image, 7, 50, 21, 1, Color("ae6c5a"))
	_rect(image, 8, 51, 19, 3, CREAM)
	_rect(image, 9, 52, 17, 1, WOOD_LIGHT)
	_rect(image, 7, 54, 21, 1, Color("ae6c5a"))
	_rect(image, 8, 43, 20, 6, OUTLINE)
	_rect(image, 9, 44, 18, 1, PANEL_LIGHT)
	_rect(image, 10, 45, 16, 2, CREAM_LIGHT)
	_rect(image, 9, 47, 18, 1, PANEL)
	# Caixa de peças de madeira com ferragens pequenas.
	_rect(image, 36, 42, 24, 14, OUTLINE)
	_rect(image, 37, 43, 22, 11, WOOD)
	_rect(image, 37, 43, 22, 2, WOOD_LIGHT)
	_rect(image, 37, 46, 22, 1, WOOD_SHADE)
	_rect(image, 57, 45, 2, 9, WOOD_SHADE)
	_rect(image, 38, 50, 18, 1, WOOD_LIGHT)
	_rect(image, 46, 45, 4, 5, WOOD_DARK)
	_rect(image, 47, 46, 2, 2, WOOD_GLEAM)
	return image
