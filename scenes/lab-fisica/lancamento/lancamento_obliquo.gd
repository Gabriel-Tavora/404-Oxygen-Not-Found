extends Control

signal fechado
signal concluido

enum Estado { PREPARANDO, EM_VOO, ACERTOU, CONCLUIDO }

const FONTE_PIXEL := preload("res://assets/ui/lab-pixel.fnt")
const SPRITES := preload("res://assets/astronauta/astronauta-animacoes.tres")
const HUD := preload("res://scenes/ui/hud_missao_fisica.gd")
const ORIGEM := Vector2(65, 179)
const ALTURA_CAIXAS := 198.0
const ALTURA_CHAO := 220.0
const GRAVIDADE := 440.0
const FORCA_MINIMA := 115.0
const FORCA_MAXIMA := 430.0
const ANGULO_MINIMO := deg_to_rad(14.0)
const ANGULO_MAXIMO := deg_to_rad(46.0)
const ANGULO_INICIAL := deg_to_rad(34.0)
const TEMPO_CARGA := 2.4
const RAIO_BOLA := 5.0
const MEIA_ABERTURA := 24.0
const CAIXAS: Array[float] = [199.0, 304.0, 408.0]
const NOMES: Array[String] = ["verde", "amarela", "vermelha"]
const CORES: Array[Color] = [Color("#8aeca7"), Color("#ffdb74"), Color("#ff8c83")]
const VENTOS: Array[float] = [0.0, -67.0, 67.0]
const MARINHO := Color("#142734")
const AZUL := Color("#a2cbd8")

@onready var _dialogo = $DialogoAstronauta
var _estado := Estado.PREPARANDO
var _rodada := 0
var _angulo := ANGULO_INICIAL
var _carga := 0.0
var _carregando := false
var _mirando := false
var _tempo := 0.0
var _velocidade := Vector2.ZERO
var _bola := ORIGEM
var _aviso := ""


func _ready() -> void:
	set_process(false)
	get_window().focus_exited.connect(_cancelar_mouse)


func abrir() -> void:
	_rodada = 0
	_angulo = ANGULO_INICIAL
	_dialogo.hide()
	_preparar("Acerte a caixa verde com a bola verde.")
	show()
	set_process(true)


func _preparar(aviso: String) -> void:
	_estado = Estado.PREPARANDO
	_cancelar_mouse()
	_bola = ORIGEM
	_aviso = aviso
	queue_redraw()


func _cancelar_mouse() -> void:
	_mirando = false
	_carregando = false
	_carga = 0.0


func _gui_input(event: InputEvent) -> void:
	if _estado != Estado.PREPARANDO:
		return
	if event is InputEventMouseMotion and _mirando:
		_mirar(event.position)
		accept_event()
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				_mirando = event.pressed
				if _mirando:
					_mirar(event.position)
				accept_event()
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					_carregando = true
					_carga = 0.0
				elif _carregando:
					_lancar()
				accept_event()


func _mirar(ponto: Vector2) -> void:
	var direcao := ponto - ORIGEM
	if direcao.length_squared() > 16.0:
		_angulo = clampf(atan2(-direcao.y, maxf(direcao.x, 0.0)), ANGULO_MINIMO, ANGULO_MAXIMO)


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel") or (_estado == Estado.CONCLUIDO and event.is_action_pressed(&"ui_accept")):
		get_viewport().set_input_as_handled()
		_cancelar_mouse()
		set_process(false)
		hide()
		fechado.emit()


func _velocidade_inicial() -> Vector2:
	return Vector2(cos(_angulo), -sin(_angulo)) * lerpf(FORCA_MINIMA, FORCA_MAXIMA, _carga)


func _posicao(tempo: float, inicial: Vector2) -> Vector2:
	return ORIGEM + inicial * tempo + Vector2(VENTOS[_rodada], GRAVIDADE) * (tempo * tempo * 0.5)


func _tempo_na_altura(altura: float, inicial: Vector2) -> float:
	var distancia := altura - ORIGEM.y
	return (-inicial.y + sqrt(inicial.y * inicial.y + 2.0 * GRAVIDADE * distancia)) / GRAVIDADE


func _caixa_atingida(inicial: Vector2) -> int:
	var centro := _posicao(_tempo_na_altura(ALTURA_CAIXAS, inicial), inicial)
	for i in CAIXAS.size():
		if absf(centro.x - CAIXAS[i]) <= MEIA_ABERTURA - RAIO_BOLA:
			return i
	return -1


func _lancar() -> void:
	_velocidade = _velocidade_inicial()
	_cancelar_mouse()
	_tempo = 0.0
	_estado = Estado.EM_VOO
	_aviso = ""


func _process(delta: float) -> void:
	match _estado:
		Estado.PREPARANDO:
			if _carregando:
				_carga = minf(1.0, _carga + delta / TEMPO_CARGA)
		Estado.EM_VOO:
			_atualizar_bola(delta)
		Estado.ACERTOU:
			_tempo += delta
			if _tempo >= 0.85:
				_avancar()
	queue_redraw()


func _atualizar_bola(delta: float) -> void:
	_tempo += delta
	var caixa := _caixa_atingida(_velocidade)
	var altura := ALTURA_CAIXAS if caixa >= 0 else ALTURA_CHAO - RAIO_BOLA
	var fim := _tempo_na_altura(altura, _velocidade)
	_bola = _posicao(minf(_tempo, fim), _velocidade)
	if _tempo < fim and _bola.x < size.x + RAIO_BOLA:
		return
	if caixa == _rodada:
		_estado = Estado.ACERTOU
		_tempo = 0.0
		_aviso = "Acertou a caixa %s!" % NOMES[_rodada]
		if _rodada == CAIXAS.size() - 1:
			concluido.emit()
	elif caixa >= 0:
		_preparar("Essa caixa é %s. Mire na caixa %s." % [NOMES[caixa], NOMES[_rodada]])
	else:
		_preparar("Fora da caixa. Ajuste a mira ou a força e tente de novo.")


func _avancar() -> void:
	if _rodada == CAIXAS.size() - 1:
		_estado = Estado.CONCLUIDO
		set_process(false)
		_dialogo.mostrar("Três caixas! O vento contrário encurtou a trajetória, e o vento a favor levou a bola mais longe. Enter para voltar.")
		return
	_rodada += 1
	if _rodada == 1:
		_preparar("Vento contrário: a bola perde alcance. Use a prévia para ajustar a força.")
	else:
		_preparar("Vento a favor: a bola ganha alcance. Use a prévia para ajustar a força.")


func _draw() -> void:
	_desenhar_sala()
	for i in CAIXAS.size():
		_desenhar_caixa(i)
	var retrato := SPRITES.get_frame_texture(&"parado_leste", 0)
	draw_texture(retrato, Vector2(38, 162))
	if _estado == Estado.PREPARANDO:
		_desenhar_trajetoria()
	if _estado in [Estado.PREPARANDO, Estado.EM_VOO]:
		_desenhar_bola(_bola, CORES[_rodada])
	_desenhar_hud()


func _desenhar_sala() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#233f4d"))
	draw_rect(Rect2(0, 66, 480, 143), Color("#2c4a56"))
	for x in [92, 240, 388]:
		draw_rect(Rect2(x, 74, 92, 79), Color("#213947"))
		draw_rect(Rect2(x + 3, 77, 86, 73), Color("#304f5d"))
		draw_rect(Rect2(x + 44, 77, 3, 73), Color("#284552"))
	draw_rect(Rect2(0, 170, 480, 3), Color("#345762"))
	draw_rect(Rect2(0, ALTURA_CHAO, 480, 68), MARINHO)
	draw_rect(Rect2(0, ALTURA_CHAO, 480, 5), Color("#6d908f"))
	for x in range(10, 480, 24):
		draw_rect(Rect2(x, ALTURA_CHAO + 6, 7, 2), Color("#40616a"))
	draw_rect(Rect2(35, 193, 42, 27), Color("#355965"))
	draw_rect(Rect2(33, 193, 46, 3), Color("#8aa8a1"))


func _desenhar_caixa(i: int) -> void:
	var x := CAIXAS[i]
	var cor := CORES[i]
	var feita := i < _rodada or (i == _rodada and _estado in [Estado.ACERTOU, Estado.CONCLUIDO])
	draw_rect(Rect2(x - 28, 193, 56, 27), Color("#11232d"))
	draw_rect(Rect2(x - 26, 197, 52, 21), cor.darkened(0.47))
	draw_rect(Rect2(x - 24, 193, 48, 8), Color("#10212a"))
	draw_rect(Rect2(x - 28, 193, 56, 2), cor)
	draw_rect(Rect2(x - 26, 201, 52, 2), cor.darkened(0.17))
	draw_rect(Rect2(x - 7, 203, 14, 8), cor)
	if feita:
		draw_rect(Rect2(x - 4, 206, 2, 2), MARINHO)
		draw_rect(Rect2(x - 2, 207, 2, 2), MARINHO)
		draw_rect(Rect2(x, 205, 2, 3), MARINHO)
		draw_rect(Rect2(x + 2, 204, 2, 2), MARINHO)
	if i == _rodada and not feita:
		draw_rect(Rect2(x - 29, 192, 58, 28), cor, false, 1)
	var nome := NOMES[i].capitalize()
	var largura := FONTE_PIXEL.get_string_size(nome, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	draw_string(FONTE_PIXEL, Vector2(roundf(x - largura / 2), 188), nome, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, cor)


func _desenhar_bola(centro: Vector2, cor: Color) -> void:
	var p := centro.round()
	draw_rect(Rect2(p - Vector2(3, 5), Vector2(6, 10)), cor.darkened(0.23))
	draw_rect(Rect2(p - Vector2(5, 3), Vector2(10, 6)), cor.darkened(0.23))
	draw_rect(Rect2(p - Vector2(3, 4), Vector2(6, 7)), cor)
	draw_rect(Rect2(p - Vector2(3, 3), Vector2(3, 2)), cor.lightened(0.56))


func _desenhar_trajetoria() -> void:
	var inicial := _velocidade_inicial()
	var alvo := _caixa_atingida(inicial)
	var altura := ALTURA_CAIXAS if alvo >= 0 else ALTURA_CHAO - RAIO_BOLA
	var duracao := _tempo_na_altura(altura, inicial)
	var cor := CORES[_rodada] if alvo == _rodada else AZUL
	var passo := clampf(9.0 / inicial.length(), 0.024, 0.06)
	var tempo := passo
	while tempo < duracao:
		var p := _posicao(tempo, inicial).round()
		draw_rect(Rect2(p, Vector2(2, 2)), cor)
		tempo += passo
	var chegada := _posicao(duracao, inicial).round()
	draw_rect(Rect2(chegada - Vector2(3, 3), Vector2(7, 7)), cor, false, 1)


func _desenhar_hud() -> void:
	var fonte := ThemeDB.fallback_font
	var cor := CORES[_rodada]
	var damasco := Color("#ffd6ad")
	var mel := Color("#ffdd81")
	HUD.painel(self, Rect2(8, 7, 196, 42), damasco)
	HUD.painel(self, Rect2(211, 7, 113, 42), cor.lightened(0.22))
	HUD.painel(self, Rect2(331, 7, 141, 42), Color("#bce6ee"))

	draw_rect(Rect2(17, 16, 23, 24), Color("#ec9b78"))
	for ponto: Vector2 in [Vector2(20, 32), Vector2(23, 28), Vector2(27, 25), Vector2(32, 24)]:
		draw_rect(Rect2(ponto, Vector2(2, 2)), HUD.BRILHO)
	draw_rect(Rect2(33, 26, 4, 4), HUD.TINTA)
	draw_string(FONTE_PIXEL, Vector2(46, 32), "Lançamento oblíquo", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, HUD.TINTA)

	draw_rect(Rect2(220, 16, 23, 24), cor.darkened(0.58))
	_desenhar_bola(Vector2(231, 28), cor)
	draw_string(fonte, Vector2(251, 23), "Rodada %d / %d" % [_rodada + 1, CAIXAS.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, HUD.TINTA)
	draw_string(FONTE_PIXEL, Vector2(251, 38), NOMES[_rodada].capitalize(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, HUD.TINTA)
	_desenhar_vento()
	if _estado == Estado.CONCLUIDO:
		return

	HUD.painel(self, Rect2(8, 234, 464, 46), Color("#f8ddc6"))
	var dica := _aviso
	var pronto := _estado == Estado.PREPARANDO and _carregando and _caixa_atingida(_velocidade_inicial()) == _rodada
	if pronto:
		dica = "Solte agora!"
	elif _estado == Estado.EM_VOO:
		dica = "Observe a trajetória da bola."
	draw_rect(Rect2(14, 240, 452, 17), Color("#a2ebc3") if pronto else Color("#d8eed4"))
	draw_rect(Rect2(19, 243, 10, 9), Color("#448176"))
	draw_rect(Rect2(21, 252, 3, 2), Color("#448176"))
	draw_rect(Rect2(21, 247, 6, 1), HUD.BRILHO)
	draw_string(fonte, Vector2(36, 252), dica, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, HUD.TINTA)

	draw_string(FONTE_PIXEL, Vector2(16, 270), "Força", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, HUD.TINTA)
	draw_rect(Rect2(48, 262, 90, 11), HUD.CONTORNO)
	draw_rect(Rect2(49, 263, 88, 9), Color("#d7a88f"))
	if _estado == Estado.PREPARANDO:
		draw_rect(Rect2(49, 263, 6 + roundf(_carga * 82), 9), cor.darkened(0.18))
	HUD.controle(self, 151, 43, "Direito", "Mirar", damasco)
	HUD.controle(self, 235, 50, "Esquerdo", "Carregar e soltar", mel)
	HUD.controle(self, 395, 26, "Esc", "Voltar", Color("#e9d3f4"))


func _desenhar_vento() -> void:
	var vento := VENTOS[_rodada]
	var centro := Vector2(351, 28)
	var cor := Color("#366575")
	var texto := "Sem vento"
	draw_rect(Rect2(339, 16, 24, 24), Color("#93cbd7"))
	if vento != 0.0:
		var sentido := signf(vento)
		texto = "Contra o lançamento" if sentido < 0.0 else "A favor do lançamento"
		var ponta := centro + Vector2(sentido * 7, 0)
		draw_rect(Rect2(centro.x - 7, centro.y - 1, 15, 2), cor)
		for degrau in range(1, 6):
			var x := ponta.x - sentido * degrau
			draw_rect(Rect2(x, ponta.y - degrau - 1, 1, 2), cor)
			draw_rect(Rect2(x, ponta.y + degrau, 1, 2), cor)
	else:
		for x in [346, 350, 354]:
			draw_rect(Rect2(x, 27, 2, 2), cor)
	draw_string(FONTE_PIXEL, Vector2(369, 23), "Vento", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, HUD.TINTA)
	draw_string(ThemeDB.fallback_font, Vector2(369, 38), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, HUD.TINTA)
