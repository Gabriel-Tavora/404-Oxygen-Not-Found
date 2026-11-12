extends SceneTree
## Desenha as três camadas raster da bancada em resolução-base, pixel a pixel.
## Não altera a cena da fase nem os tiles da primeira seção.

const ASSET_DIR := "res://assets/laboratorios"
const SIZE := Vector2i(288, 128)
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
const TOP_SHADE := Color("ae9d74")
const TOP_EDGE := Color("cbbb91")
const TOP := Color("e6d9b0")
const TOP_LIGHT := Color("f3e9ca")


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ASSET_DIR))
	var error := _save(_draw_shadow(), "bancada-sombra.png")
	if error == OK:
		error = _save(_draw_body(), "bancada-estrutura.png")
	if error == OK:
		error = _save(_draw_top(), "bancada-tampo.png")
	if error != OK:
		push_error("Não foi possível salvar a bancada: %s" % error)
		quit(1)
		return
	print("Bancada raster criada: sombra, estrutura e tampo de 288 × 128 pixels.")
	quit()


func _blank(size: Vector2i = SIZE) -> Image:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	return image


func _rect(image: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	image.fill_rect(Rect2i(x, y, width, height), color)


func _stepped_rect(image: Image, area: Rect2i, color: Color) -> void:
	# Cantos em degraus de 2 px, sem antialiasing nem curvas vetoriais.
	_rect(image, area.position.x + 2, area.position.y, area.size.x - 4, area.size.y, color)
	_rect(image, area.position.x, area.position.y + 2, area.size.x, area.size.y - 4, color)


func _draw_shadow() -> Image:
	var image := _blank(Vector2i(304, 136))
	var shadow := Color(0.18, 0.22, 0.23, 0.27)
	var contact := Color(0.18, 0.22, 0.23, 0.42)
	_stepped_rect(image, Rect2i(8, 12, 288, 112), shadow)
	_rect(image, 18, 120, 28, 10, shadow)
	_rect(image, 266, 120, 28, 10, shadow)
	_rect(image, 16, 124, 28, 5, contact)
	_rect(image, 264, 124, 28, 5, contact)
	return image


func _draw_body() -> Image:
	var image := _blank()
	# Pernas: 16 px de largura e pés visíveis abaixo do avental frontal.
	for x in [14, 258]:
		_rect(image, x, 100, 16, 27, OUTLINE)
		_rect(image, x + 2, 102, 12, 23, WOOD)
		_rect(image, x + 2, 102, 3, 23, WOOD_LIGHT)
		_rect(image, x + 11, 102, 3, 23, WOOD_SHADE)
		_rect(image, x + 7, 113, 1, 8, WOOD_SHADE)
		_rect(image, x - 2, 122, 20, 6, OUTLINE)
		_rect(image, x, 123, 16, 3, WOOD_SHADE)
		_rect(image, x, 123, 4, 2, WOOD_LIGHT)
	# Travessa baixa, recuada em relação à frente da mesa.
	_rect(image, 30, 115, 228, 6, WOOD_DARK)
	_rect(image, 30, 115, 228, 2, WOOD_SHADE)
	_rect(image, 30, 117, 228, 1, WOOD)
	# Faixa frontal sombreada e duas gavetas. O tampo fica sobre esta camada.
	_rect(image, 6, 88, 276, 26, OUTLINE)
	_rect(image, 8, 90, 272, 22, PANEL_SHADE)
	_rect(image, 10, 94, 268, 16, PANEL)
	_rect(image, 10, 94, 268, 2, PANEL_LIGHT)
	_rect(image, 10, 109, 268, 2, PANEL_DARK)
	_rect(image, 142, 94, 3, 16, PANEL_DARK)
	_rect(image, 145, 96, 1, 13, PANEL_LIGHT)
	# Moldura e montantes que conectam visualmente as pernas ao tampo.
	for x in [8, 268]:
		_rect(image, x, 91, 12, 23, OUTLINE)
		_rect(image, x + 2, 92, 8, 21, WOOD)
		_rect(image, x + 2, 93, 2, 19, WOOD_LIGHT)
		_rect(image, x + 8, 93, 2, 20, WOOD_SHADE)
	# Puxadores pequenos no avental, fora da superfície da atividade.
	for x in [72, 202]:
		_rect(image, x, 101, 15, 5, PANEL_DARK)
		_rect(image, x + 1, 101, 13, 2, WOOD_GLEAM)
		_rect(image, x + 1, 103, 13, 1, WOOD)
		_rect(image, x + 2, 104, 2, 1, WOOD_SHADE)
		_rect(image, x + 11, 104, 2, 1, WOOD_SHADE)
	return image


func _draw_top() -> Image:
	var image := _blank()
	# A face superior ampla e a borda frontal visível definem a perspectiva 3/4.
	_stepped_rect(image, Rect2i(0, 0, 288, 96), OUTLINE)
	_stepped_rect(image, Rect2i(2, 2, 284, 90), WOOD)
	_rect(image, 4, 2, 280, 2, WOOD_GLEAM)
	_rect(image, 2, 4, 3, 84, WOOD_LIGHT)
	_rect(image, 283, 4, 3, 86, WOOD_SHADE)
	_rect(image, 4, 88, 280, 3, WOOD_SHADE)
	_rect(image, 4, 92, 280, 2, WOOD_DARK)
	# Painel claro contínuo: nada de emendas, objetos ou textura no miolo.
	_stepped_rect(image, Rect2i(8, 6, 272, 80), WOOD_DARK)
	_stepped_rect(image, Rect2i(9, 7, 270, 78), TOP_EDGE)
	_rect(image, 10, 8, 268, 76, TOP)
	_rect(image, 11, 8, 266, 1, TOP_LIGHT)
	_rect(image, 10, 9, 1, 73, TOP_LIGHT)
	_rect(image, 277, 9, 1, 74, TOP_EDGE)
	_rect(image, 11, 83, 266, 1, TOP_EDGE)
	# A área de atividade é completamente uniforme: 256 × 64 px.
	# Detalhes restritos à moldura, usando a paleta já presente na sala.
	for x in [20, 116, 204]:
		_rect(image, x, 4, 18, 1, WOOD_LIGHT)
		_rect(image, x + 7, 87, 24, 1, WOOD_LIGHT)
	# Quatro encaixes de canto e pinos com brilho de um único pixel.
	for x in [4, 280]:
		for y in [4, 85]:
			_rect(image, x, y, 4, 3, WOOD_SHADE)
			_rect(image, x + 1, y, 2, 1, WOOD_GLEAM)
			_rect(image, x + 1, y + 1, 1, 1, WOOD_DARK)
	return image


func _save(image: Image, filename: String) -> Error:
	return image.save_png(ASSET_DIR.path_join(filename))
