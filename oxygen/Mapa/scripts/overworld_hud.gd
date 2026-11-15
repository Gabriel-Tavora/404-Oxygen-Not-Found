class_name OverworldHUD
extends Control
## HUD do mapa: nome do mundo, placa com o nome do ponto atual, avisos e fade.

var px := 2.0
var world_name := "MUNDO 1"
var location := ""
var hint := ""
var _flash := ""
var _flash_t := 0.0
var _fade := 1.0
var _t := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_location(n: String, h: String) -> void:
	location = n
	hint = h
	queue_redraw()


func flash(msg: String) -> void:
	_flash = msg
	_flash_t = 1.2


func fade_in() -> void:
	_fade = 1.0
	var tw := create_tween()
	tw.tween_property(self, "_fade", 0.0, 0.4)


func fade_out() -> void:
	var tw := create_tween()
	tw.tween_property(self, "_fade", 1.0, 0.4)
	await tw.finished


func _process(delta: float) -> void:
	_t += delta
	if _flash_t > 0.0:
		_flash_t -= delta
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var w := size.x
	var hgt := size.y
	var dark := Color("1a1e2c")
	# Nome do mundo
	_panel(Rect2(6 * px, 6 * px, 70 * px, 15 * px))
	_text(font, Vector2(12 * px, 17 * px), world_name, int(8 * px), Color("8ad8ff"))
	# Placa do ponto atual
	if location != "":
		var fs := int(10 * px)
		var tw := font.get_string_size(location, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var hs := int(7 * px)
		var hw := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, hs).x
		var bw := maxf(tw, hw) + 20 * px
		var bh := (33.0 if hint != "" else 21.0) * px
		var r := Rect2((w - bw) / 2.0, hgt - bh - 8 * px, bw, bh)
		_panel(r)
		_text(font, Vector2((w - tw) / 2.0, r.position.y + 14 * px), location, fs, Color.WHITE)
		if hint != "":
			var blink := 0.65 + 0.35 * sin(_t * 5.0)
			_text(font, Vector2((w - hw) / 2.0, r.position.y + 27 * px), hint, hs, Color(1, 0.86, 0.45, blink))
	# Aviso rápido (EM BREVE / BLOQUEADO)
	if _flash_t > 0.0:
		var fs2 := int(12 * px)
		var fw := font.get_string_size(_flash, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x
		_text(font, Vector2((w - fw) / 2.0, hgt * 0.4), _flash, fs2, Color("ffd45a"))
	# Fade preto nas trocas de cena
	if _fade > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, _fade))


func _panel(r: Rect2) -> void:
	draw_rect(r.grow(px), Color("1a1e2c"))
	draw_rect(r, Color("2a3550"))
	draw_rect(Rect2(r.position, Vector2(r.size.x, px)), Color("46aaff"))


func _text(font: Font, pos: Vector2, txt: String, fs: int, col: Color) -> void:
	draw_string_outline(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(maxf(px * 1.5, 2.0)), Color("1a1e2c"))
	draw_string(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
