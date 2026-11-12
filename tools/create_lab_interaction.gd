extends SceneTree

const SIGNAL_PATH := "res://assets/laboratorios/sinal-atividade.png"
const OUTLINE := Color("293b43")
const CREAM := Color("e6d9b0")
const LIGHT := Color("f3e9ca")
const GOLD := Color("e4c28c")
const RUST := Color("bf635a")
const GLYPHS := {
	"A": "01110 10001 10001 11111 10001 10001 10001",
	"B": "11110 10001 10001 11110 10001 10001 11110",
	"C": "01111 10000 10000 10000 10000 10000 01111",
	"D": "11110 10001 10001 10001 10001 10001 11110",
	"E": "11111 10000 10000 11110 10000 10000 11111",
	"F": "11111 10000 10000 11110 10000 10000 10000",
	"G": "01111 10000 10000 10111 10001 10001 01111",
	"H": "10001 10001 10001 11111 10001 10001 10001",
	"I": "111 010 010 010 010 010 111",
	"J": "00111 00010 00010 00010 00010 10010 01100",
	"K": "10001 10010 10100 11000 10100 10010 10001",
	"L": "10000 10000 10000 10000 10000 10000 11111",
	"M": "10001 11011 10101 10101 10001 10001 10001",
	"N": "10001 11001 10101 10011 10001 10001 10001",
	"O": "01110 10001 10001 10001 10001 10001 01110",
	"P": "11110 10001 10001 11110 10000 10000 10000",
	"Q": "01110 10001 10001 10001 10101 10010 01101",
	"R": "11110 10001 10001 11110 10100 10010 10001",
	"S": "01111 10000 10000 01110 00001 00001 11110",
	"T": "11111 00100 00100 00100 00100 00100 00100",
	"U": "10001 10001 10001 10001 10001 10001 01110",
	"V": "10001 10001 10001 10001 01010 01010 00100",
	"W": "10001 10001 10001 10101 10101 11011 10001",
	"X": "10001 10001 01010 00100 01010 10001 10001",
	"Y": "10001 10001 01010 00100 00100 00100 00100",
	"Z": "11111 00001 00010 00100 01000 10000 11111",
	"a": "00000 00000 01110 00001 01111 10001 01111",
	"b": "10000 10000 11110 10001 10001 10001 11110",
	"c": "0000 0000 0111 1000 1000 1000 0111",
	"d": "00001 00001 01111 10001 10001 10001 01111",
	"e": "00000 00000 01110 10001 11111 10000 01111",
	"f": "0011 0100 1110 0100 0100 0100 0100",
	"g": "00000 00000 01111 10001 10001 01111 00001 01110",
	"h": "10000 10000 11110 10001 10001 10001 10001",
	"i": "1 0 1 1 1 1 1",
	"j": "001 000 001 001 001 001 101 010",
	"k": "1000 1000 1001 1010 1100 1010 1001",
	"l": "10 10 10 10 10 10 01",
	"m": "00000 00000 11010 10101 10101 10101 10101",
	"n": "00000 00000 11110 10001 10001 10001 10001",
	"o": "00000 00000 01110 10001 10001 10001 01110",
	"p": "00000 00000 11110 10001 10001 11110 10000 10000",
	"q": "00000 00000 01111 10001 10001 01111 00001 00001",
	"r": "0000 0000 1011 1100 1000 1000 1000",
	"s": "0000 0000 0111 1000 0110 0001 1110",
	"t": "0100 0100 1111 0100 0100 0100 0011",
	"u": "00000 00000 10001 10001 10001 10001 01111",
	"v": "00000 00000 10001 10001 10001 01010 00100",
	"w": "00000 00000 10001 10101 10101 10101 01010",
	"x": "00000 00000 10001 01010 00100 01010 10001",
	"y": "00000 00000 10001 10001 10001 01111 00001 01110",
	"z": "0000 0000 1111 0001 0010 0100 1111",
	" ": "000",
	"!": "1 1 1 1 1 0 1",
	"?": "01110 10001 00001 00010 00100 00000 00100",
	".": "0 0 0 0 0 0 1",
	",": "00 00 00 00 00 00 01 10",
	":": "0 0 1 0 0 1 0",
}
const ACCENTS := {
	"Í": ["I", "acute"],
	"ã": ["a", "tilde"],
	"é": ["e", "acute"],
	"ê": ["e", "circumflex"],
	"á": ["a", "acute"],
	"ç": ["c", "cedilla"],
	"ó": ["o", "acute"],
	"í": ["i", "acute"],
	"ú": ["u", "acute"],
}


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SIGNAL_PATH.get_base_dir()))
	if "--signal-only" in OS.get_cmdline_user_args():
		var error := _signal_tile().save_png(SIGNAL_PATH)
		if error != OK:
			push_error("Falha ao salvar o sinal de atividade.")
		quit(0 if error == OK else 1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/ui"))
	var images := {
		SIGNAL_PATH: _signal_tile(),
		"res://assets/ui/resistencia.png": _shield(),
		"res://assets/ui/icone-movimento.png": _ramp_icon(),
	}
	for path: String in images:
		var image: Image = images[path]
		if image.save_png(path) != OK:
			push_error("Falha ao salvar " + path)
			quit(1)
			return
	if not _save_font():
		push_error("Falha ao salvar a fonte de pixel art.")
		quit(1)
		return
	print("Sinal e elementos dos convites criados.")
	quit()


func _blank(width: int, height: int) -> Image:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	return image


func _rect(image: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	image.fill_rect(Rect2i(x, y, width, height), color)


func _signal_tile() -> Image:
	var image := _blank(32, 18)
	_signal_ring(image, 1, [4, 8, 12, 16, 20, 24, 28, 30, 30, 28, 24, 20, 16, 12, 8, 4], Color(0.47, 0.86, 0.75, 0.34))
	_signal_ring(image, 2, [4, 8, 12, 16, 20, 24, 28, 28, 24, 20, 16, 12, 8, 4], OUTLINE)
	_signal_ring(image, 3, [4, 8, 12, 16, 20, 24, 24, 20, 16, 12, 8, 4], Color("89ddc5"))
	_signal_ring(image, 5, [4, 8, 12, 18, 18, 12, 8, 4], Color("38696a"))
	_rect(image, 15, 5, 2, 5, LIGHT)
	_rect(image, 15, 11, 2, 2, LIGHT)
	return image


func _signal_ring(image: Image, top: int, widths: Array[int], color: Color) -> void:
	for row in range(widths.size()):
		var width := widths[row]
		var x := (image.get_width() - width) >> 1
		_rect(image, x, top + row, width, 1, color)


func _shield() -> Image:
	var image := _blank(20, 20)
	_rect(image, 4, 3, 12, 10, OUTLINE)
	_rect(image, 6, 13, 8, 2, OUTLINE)
	_rect(image, 8, 15, 4, 2, OUTLINE)
	_rect(image, 5, 4, 10, 8, GOLD)
	_rect(image, 7, 12, 6, 2, Color("a98057"))
	_rect(image, 9, 14, 2, 1, Color("a98057"))
	_rect(image, 9, 5, 2, 7, LIGHT)
	_rect(image, 7, 7, 6, 2, LIGHT)
	return image


func _ramp_icon() -> Image:
	var image := _blank(24, 24)
	for x in range(3, 22):
		var y := 9 + floori((x - 3) * 0.45)
		_rect(image, x, y, 1, 22 - y, OUTLINE)
		_rect(image, x, y + 1, 1, 20 - y, GOLD)
	_rect(image, 4, 4, 5, 5, OUTLINE)
	_rect(image, 5, 5, 3, 3, RUST)
	_rect(image, 5, 5, 1, 1, LIGHT)
	return image


func _save_font() -> bool:
	var characters := GLYPHS.keys() + ACCENTS.keys()
	var height := ceili(characters.size() / 16.0) * 10
	var atlas := _blank(128, height)
	var description := PackedStringArray([
		'info face="Lab Pixel" size=8 bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=0,0',
		"common lineHeight=10 base=9 scaleW=128 scaleH=%d pages=1 packed=0" % height,
		'page id=0 file="lab-pixel.png"',
		"chars count=%d" % characters.size(),
	])
	for index in range(characters.size()):
		var character: String = characters[index]
		var origin := Vector2i((index % 16) * 8, (index >> 4) * 10)
		var accent: Array = ACCENTS.get(character, [character, ""])
		var rows: PackedStringArray = GLYPHS[accent[0]].split(" ")
		var width := rows[0].length()
		for y in range(rows.size()):
			for x in range(width):
				if rows[y][x] == "1":
					atlas.set_pixelv(origin + Vector2i(x, y + 2), Color.WHITE)
		match accent[1]:
			"acute":
				if character == "í":
					atlas.set_pixelv(origin + Vector2i(0, 2), Color.TRANSPARENT)
				atlas.set_pixelv(origin + Vector2i(mini(2, width - 1), 0), Color.WHITE)
				atlas.set_pixelv(origin + Vector2i(mini(1, width - 1), 1), Color.WHITE)
			"tilde":
				_rect(atlas, origin.x + 1, origin.y + 1, 2, 1, Color.WHITE)
				atlas.set_pixelv(origin + Vector2i(3, 0), Color.WHITE)
			"circumflex":
				atlas.set_pixelv(origin + Vector2i(2, 0), Color.WHITE)
				atlas.set_pixelv(origin + Vector2i(1, 1), Color.WHITE)
				atlas.set_pixelv(origin + Vector2i(3, 1), Color.WHITE)
			"cedilla":
				atlas.set_pixelv(origin + Vector2i(1, 9), Color.WHITE)
		description.append("char id=%d x=%d y=%d width=%d height=10 xoffset=0 yoffset=0 xadvance=%d page=0 chnl=15" % [
			character.unicode_at(0), origin.x, origin.y, width, width + 1,
		])
	if atlas.save_png("res://assets/ui/lab-pixel.png") != OK:
		return false
	var file := FileAccess.open("res://assets/ui/lab-pixel.fnt", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string("\n".join(description) + "\n")
	return true
