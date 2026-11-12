extends SceneTree
## Desenha os sprites da lateral de movimento na resolução-base.

const ASSET_DIR := "res://assets/lab-fisica"
const FRAME_SIZE := Vector2i(48, 56)
const FRAME_COUNT := 16
const OUTLINE := Color("293b43")
const WOOD_DARK := Color("4e4840")
const WOOD_SHADE := Color("78604b")
const WOOD := Color("a98057")
const WOOD_LIGHT := Color("c9a16d")
const WOOD_GLEAM := Color("e4c28c")
const PANEL_DARK := Color("334f56")
const PANEL := Color("588b88")
const CREAM := Color("e6d9b0")
const SHADOW := Color(0.18, 0.22, 0.23, 0.27)
const LETTERS := {
	"M": ["101", "111", "111", "101", "101"],
	"O": ["111", "101", "101", "101", "111"],
	"V": ["101", "101", "101", "101", "010"],
	"I": ["111", "010", "010", "010", "111"],
	"E": ["111", "100", "110", "100", "111"],
	"N": ["1001", "1101", "1011", "1001", "1001"],
	"T": ["111", "010", "010", "010", "010"],
}


func _initialize() -> void:
	var sprites := {
		"movimento-pendulo-suporte.png": _stand(),
		"movimento-pendulo-quadros.png": _swing_frames(),
		"movimento-rampa.png": _ramp(),
		"movimento-bolinha.png": _ball(),
		"movimento-placa.png": _label(),
	}
	for filename: String in sprites:
		var sprite: Image = sprites[filename]
		var error := sprite.save_png(ASSET_DIR.path_join(filename))
		if error != OK:
			push_error("Não foi possível salvar %s (%s)." % [filename, error])
			quit(1)
			return
	print("Lateral de movimento criada com pêndulo de %d quadros e rampa." % FRAME_COUNT)
	quit()


func _blank(size: Vector2i) -> Image:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	return image


func _rect(image: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	image.fill_rect(Rect2i(x, y, width, height), color)


func _line(image: Image, start: Vector2i, finish: Vector2i, color: Color) -> void:
	# Bresenham mantém o fio sobre a grade de pixels em todos os quadros.
	var point := start
	var delta := Vector2i(absi(finish.x - start.x), -absi(finish.y - start.y))
	var step := Vector2i(1 if start.x < finish.x else -1, 1 if start.y < finish.y else -1)
	var error := delta.x + delta.y
	while point != finish:
		image.set_pixelv(point, color)
		var twice := 2 * error
		if twice >= delta.y:
			error += delta.y
			point.x += step.x
		if twice <= delta.x:
			error += delta.x
			point.y += step.y
	image.set_pixelv(finish, color)


func _stand() -> Image:
	var image := _blank(FRAME_SIZE)
	_rect(image, 4, 46, 44, 7, SHADOW)
	_rect(image, 1, 43, 46, 7, OUTLINE)
	_rect(image, 2, 44, 44, 4, WOOD)
	_rect(image, 2, 44, 44, 1, WOOD_GLEAM)
	_rect(image, 2, 48, 44, 1, WOOD_SHADE)
	for x in [4, 38]:
		_rect(image, x, 6, 6, 39, OUTLINE)
		_rect(image, x + 1, 7, 4, 36, WOOD)
		_rect(image, x + 1, 8, 1, 35, WOOD_LIGHT)
		_rect(image, x + 4, 8, 1, 35, WOOD_SHADE)
		_rect(image, x - 1, 42, 8, 4, OUTLINE)
		_rect(image, x, 43, 6, 2, WOOD_LIGHT)
	_rect(image, 3, 3, 42, 7, OUTLINE)
	_rect(image, 4, 4, 40, 4, WOOD)
	_rect(image, 4, 4, 40, 1, WOOD_GLEAM)
	_rect(image, 4, 8, 40, 1, WOOD_SHADE)
	_rect(image, 22, 6, 4, 4, OUTLINE)
	_rect(image, 23, 7, 2, 2, CREAM)
	return image


func _sphere(image: Image, origin: Vector2i, mid: Color, light: Color, dark: Color) -> void:
	var x := origin.x
	var y := origin.y
	_rect(image, x + 2, y, 4, 8, OUTLINE)
	_rect(image, x, y + 2, 8, 4, OUTLINE)
	_rect(image, x + 1, y + 1, 6, 6, OUTLINE)
	_rect(image, x + 2, y + 1, 4, 6, mid)
	_rect(image, x + 1, y + 2, 6, 4, mid)
	_rect(image, x + 2, y + 2, 3, 2, light)
	_rect(image, x + 5, y + 4, 2, 2, dark)
	_rect(image, x + 3, y + 6, 3, 1, dark)


func _swing_frames() -> Image:
	var sheet := _blank(Vector2i(FRAME_SIZE.x * FRAME_COUNT, FRAME_SIZE.y))
	var pivot := Vector2i(24, 9)
	for index in range(FRAME_COUNT):
		var frame := _blank(FRAME_SIZE)
		var angle := deg_to_rad(25.0) * cos(TAU * index / FRAME_COUNT)
		var offset := Vector2i(roundi(sin(angle) * 27.0), roundi(cos(angle) * 27.0))
		var center := pivot + offset
		_line(frame, pivot, center, OUTLINE)
		_sphere(frame, center - Vector2i(4, 4), Color("c59a52"), Color("f1d28f"), Color("8e673c"))
		sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, FRAME_SIZE), Vector2i(index * FRAME_SIZE.x, 0))
	return sheet


func _ramp() -> Image:
	var image := _blank(Vector2i(56, 28))
	# Face lateral da cunha, pista clara e batente no fim.
	_rect(image, 6, 23, 45, 4, SHADOW)
	for x in range(4, 48):
		var surface := 7 + floori(float(x - 4) * 0.28)
		_rect(image, x, surface, 1, 25 - surface, OUTLINE)
		if x == 4 or x == 47:
			continue
		_rect(image, x, surface + 1, 1, 3, WOOD_GLEAM)
		_rect(image, x, surface + 4, 1, 1, WOOD_DARK)
		_rect(image, x, surface + 5, 1, 20 - surface, WOOD)
		_rect(image, x, 23, 1, 1, WOOD_SHADE)
	_rect(image, 10, 20, 9, 1, WOOD_LIGHT)
	_rect(image, 20, 21, 7, 1, WOOD_LIGHT)
	_rect(image, 47, 17, 4, 8, OUTLINE)
	_rect(image, 48, 18, 2, 5, PANEL)
	_rect(image, 48, 18, 2, 1, CREAM)
	return image


func _ball() -> Image:
	var image := _blank(Vector2i(8, 8))
	_sphere(image, Vector2i.ZERO, Color("bf635a"), Color("e29476"), Color("8a4c4b"))
	return image


func _label() -> Image:
	var image := _blank(Vector2i(40, 11))
	image.fill(PANEL_DARK)
	_rect(image, 1, 1, 38, 9, WOOD_DARK)
	var x := 2
	for character in "MOVIMENTO":
		var rows: Array = LETTERS[character]
		var width: int = rows[0].length()
		for row in range(rows.size()):
			for column in range(width):
				if rows[row][column] == "1":
					image.set_pixel(x + column, 3 + row, CREAM)
		x += width + 1
	return image
