extends SceneTree
## Seção 4: mesinha, ímã em ferradura e peças ferromagnéticas.
## Pinta PNGs na resolução-base; não modifica as seções anteriores.

const ASSET_DIR := "res://assets/lab-fisica"
const SHADOW_PATH := "res://assets/laboratorios/mesa-lateral-sombra.png"
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
const SILVER_DARK := Color("536378")
const SILVER := Color("9aadb3")
const SILVER_LIGHT := Color("cbd3c6")
const RED_DARK := Color("8a4c4b")
const RED := Color("bf635a")
const RED_LIGHT := Color("e29476")
const BLUE_DARK := Color("445c78")
const BLUE := Color("607f9c")
const BLUE_LIGHT := Color("90b0bf")
const SHADOW := Color(0.18, 0.22, 0.23, 0.27)


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ASSET_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHADOW_PATH.get_base_dir()))
	var error := _shadow().save_png(SHADOW_PATH)
	if error == OK:
		error = _table().save_png(ASSET_DIR.path_join("magnetismo-mesa.png"))
	if error == OK:
		error = _magnet().save_png(ASSET_DIR.path_join("magnetismo-ima.png"))
	if error == OK:
		error = _iron_parts().save_png(ASSET_DIR.path_join("magnetismo-pecas.png"))
	if error != OK:
		push_error("Não foi possível salvar o experimento de magnetismo: %s" % error)
		quit(1)
		return
	print("Magnetismo criado: mesa, ímã com polos N/S, prego, clipes de aço e esfera.")
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


func _glyph(image: Image, x: int, y: int, rows: Array[String], color: Color) -> void:
	for row in range(rows.size()):
		for column in range(rows[row].length()):
			if rows[row][column] == "1":
				image.set_pixel(x + column, y + row, color)


func _shadow() -> Image:
	var image := _blank(72, 104)
	_stepped(image, Rect2i(5, 8, 64, 85), SHADOW)
	_rect(image, 11, 94, 17, 6, SHADOW)
	_rect(image, 53, 94, 17, 6, SHADOW)
	return image


func _table() -> Image:
	var image := _blank(64, 96)
	# Pernas e travessa, com a mesma altura aparente da bancada principal.
	for x in [6, 48]:
		_rect(image, x, 72, 10, 23, OUTLINE)
		_rect(image, x + 2, 74, 6, 19, WOOD)
		_rect(image, x + 2, 74, 2, 19, WOOD_LIGHT)
		_rect(image, x + 7, 75, 1, 18, WOOD_SHADE)
		_rect(image, x - 1, 91, 12, 5, OUTLINE)
		_rect(image, x, 92, 10, 2, WOOD_SHADE)
		_rect(image, x, 92, 3, 1, WOOD_LIGHT)
	_rect(image, 16, 85, 32, 5, WOOD_DARK)
	_rect(image, 16, 85, 32, 2, WOOD_SHADE)
	_rect(image, 4, 60, 56, 21, OUTLINE)
	_rect(image, 6, 62, 52, 17, PANEL)
	_rect(image, 6, 63, 52, 2, PANEL_LIGHT)
	_rect(image, 6, 77, 52, 2, PANEL_SHADE)
	_rect(image, 6, 79, 52, 1, PANEL_DARK)
	# Montantes de madeira emolduram a frente verde-água.
	for x in [4, 52]:
		_rect(image, x, 61, 8, 21, OUTLINE)
		_rect(image, x + 2, 62, 4, 19, WOOD)
		_rect(image, x + 2, 62, 1, 18, WOOD_LIGHT)
		_rect(image, x + 5, 63, 1, 18, WOOD_SHADE)
	# Tampo com superfície um pouco mais escura que a área central da fase.
	_stepped(image, Rect2i(0, 0, 64, 64), OUTLINE)
	_stepped(image, Rect2i(2, 2, 60, 59), WOOD)
	_rect(image, 4, 2, 56, 2, WOOD_GLEAM)
	_rect(image, 2, 4, 2, 54, WOOD_LIGHT)
	_rect(image, 60, 4, 2, 55, WOOD_SHADE)
	_rect(image, 4, 59, 56, 2, WOOD_SHADE)
	_rect(image, 4, 62, 56, 1, WOOD_DARK)
	_rect(image, 5, 5, 54, 52, WOOD_DARK)
	_rect(image, 6, 6, 52, 50, Color("b5cbb8"))
	_rect(image, 7, 6, 50, 1, Color("d0d9bd"))
	_rect(image, 6, 7, 1, 48, Color("d0d9bd"))
	_rect(image, 57, 7, 1, 48, Color("93b7af"))
	_rect(image, 7, 55, 50, 1, Color("93b7af"))
	# Placa pequena: ÍMÃ, desenhada em pixels, fora da superfície do experimento.
	_rect(image, 20, 67, 25, 11, PANEL_DARK)
	_rect(image, 21, 68, 23, 9, WOOD_DARK)
	_glyph(image, 26, 71, ["111", "010", "010", "010", "111"], CREAM)
	_glyph(image, 30, 71, ["101", "111", "111", "101", "101"], CREAM)
	_glyph(image, 34, 71, ["010", "101", "111", "101", "101"], CREAM)
	image.set_pixel(28, 69, CREAM)
	image.set_pixel(34, 69, CREAM)
	image.set_pixel(35, 68, CREAM)
	image.set_pixel(36, 69, CREAM)
	return image


func _magnet() -> Image:
	var image := _blank(48, 48)
	var mask := _blank(48, 48)
	# Silhueta em ferradura: abertura no alto e base curva feita em degraus.
	_rect(mask, 4, 8, 9, 20, Color.WHITE)
	_rect(mask, 27, 8, 9, 20, Color.WHITE)
	_rect(mask, 5, 28, 10, 3, Color.WHITE)
	_rect(mask, 25, 28, 10, 3, Color.WHITE)
	_rect(mask, 7, 31, 11, 3, Color.WHITE)
	_rect(mask, 22, 31, 11, 3, Color.WHITE)
	_rect(mask, 10, 34, 20, 3, Color.WHITE)
	_rect(mask, 14, 37, 12, 2, Color.WHITE)
	var neighbours: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	# Sombra curta do ímã sobre o tampo, sem desfoque.
	for y in range(8, 39):
		for x in range(4, 36):
			if mask.get_pixel(x, y).a > 0:
				image.set_pixel(x + 2, y + 2, SHADOW)
	for y in range(8, 39):
		for x in range(4, 36):
			if mask.get_pixel(x, y).a == 0:
				continue
			var edge := false
			for offset in neighbours:
				if mask.get_pixelv(Vector2i(x, y) + offset).a == 0:
					edge = true
			var color := RED if x < 20 else BLUE
			if y < 15:
				color = SILVER
			elif y >= 35 or mask.get_pixel(x + 2, y).a == 0:
				color = RED_DARK if x < 20 else BLUE_DARK
			elif mask.get_pixel(x - 2, y).a == 0:
				color = RED_LIGHT if x < 20 else BLUE_LIGHT
			if edge:
				color = OUTLINE
			image.set_pixel(x, y, color)
	_rect(image, 5, 9, 7, 1, SILVER_LIGHT)
	_rect(image, 5, 10, 1, 4, SILVER_LIGHT)
	_rect(image, 11, 10, 1, 4, SILVER_DARK)
	_rect(image, 28, 9, 7, 1, SILVER_LIGHT)
	_rect(image, 28, 10, 1, 4, SILVER_LIGHT)
	_rect(image, 34, 10, 1, 4, SILVER_DARK)
	_rect(image, 5, 14, 7, 1, RED_DARK)
	_rect(image, 28, 14, 7, 1, BLUE_DARK)
	_glyph(image, 6, 19, ["10001", "11001", "10101", "10011", "10001"], CREAM)
	_glyph(image, 30, 19, ["011", "100", "010", "001", "110"], CREAM)
	return image


func _iron_parts() -> Image:
	var image := _blank(64, 64)
	# Prego de ferro com a ponta encostada no polo norte, à esquerda.
	_rect(image, 12, 7, 8, 3, OUTLINE)
	_rect(image, 13, 7, 6, 1, SILVER_LIGHT)
	_rect(image, 15, 10, 3, 6, OUTLINE)
	_rect(image, 16, 10, 1, 5, SILVER)
	image.set_pixel(16, 15, SILVER_DARK)
	# Clipe de aço junto ao polo sul. A abertura revela a cor do tampo.
	_rect(image, 36, 7, 7, 9, OUTLINE)
	_rect(image, 37, 8, 5, 7, SILVER)
	_rect(image, 38, 9, 3, 5, Color.TRANSPARENT)
	_rect(image, 37, 8, 4, 1, SILVER_LIGHT)
	_rect(image, 39, 11, 1, 3, SILVER_DARK)
	# Uma pequena esfera de aço e outro clipe apoiados no tampo.
	_stepped(image, Rect2i(11, 47, 7, 6), SHADOW)
	_stepped(image, Rect2i(10, 46, 6, 6), OUTLINE)
	_rect(image, 11, 47, 4, 4, SILVER)
	_rect(image, 11, 47, 2, 1, SILVER_LIGHT)
	_rect(image, 14, 49, 1, 2, SILVER_DARK)
	_rect(image, 45, 46, 10, 6, OUTLINE)
	_rect(image, 46, 47, 8, 4, SILVER)
	_rect(image, 47, 48, 6, 2, Color.TRANSPARENT)
	_rect(image, 46, 47, 7, 1, SILVER_LIGHT)
	_rect(image, 49, 49, 4, 1, SILVER_DARK)
	return image
