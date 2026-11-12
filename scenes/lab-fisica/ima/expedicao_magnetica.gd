extends Control

signal fechado
signal concluido

const FONTE := preload("res://assets/ui/lab-pixel.fnt")
const SPRITES := preload("res://assets/astronauta/astronauta-animacoes.tres")
const CHAO := [
	Rect2(0, 214, 268, 38), Rect2(384, 214, 200, 38), Rect2(688, 214, 142, 38),
	Rect2(870, 204, 69, 48), Rect2(981, 214, 119, 38), Rect2(1220, 214, 210, 38),
	Rect2(1540, 214, 230, 38),
]
const VAOS := [Vector2(268, 384), Vector2(584, 688), Vector2(1100, 1220), Vector2(1430, 1540)]
const CHECKPOINTS := [44, 406, 708, 994, 1238, 1558]
const MOEDAS := [
	Vector2(120, 196), Vector2(198, 196), Vector2(326, 196), Vector2(438, 196),
	Vector2(515, 174), Vector2(632, 196), Vector2(730, 196), Vector2(807, 172),
	Vector2(899, 182), Vector2(1019, 196), Vector2(1060, 196), Vector2(1160, 196),
	Vector2(1280, 196), Vector2(1360, 174), Vector2(1485, 196), Vector2(1630, 196),
	Vector2(1700, 196),
]
const SAIDA := Vector2(1738, 214)
const ALCANCE := 148.0
const CAMADA_PLATAFORMA := 4
const NORTE := Color("#ff8c77")
const SUL := Color("#73cfff")
const TEXTO := Color("#fff1cb")
const METAL := Color("#345564")
const LUZ := Color("#65949b")
const HUD := preload("res://scenes/ui/hud_missao_fisica.gd")
const TINTA_HUD := HUD.TINTA
const FUNDO_TECLA := HUD.BRILHO

@onready var _dialogo = $DialogoAstronauta
var _corpo: CharacterBody2D
var _pontes: Array[CollisionShape2D] = []
var _abertas: Array[float] = []
var _coletadas: Dictionary[int, bool] = {}
var _norte := true
var _direcao := 1.0
var _checkpoint := 44
var _rolagem := 0.0
var _relogio := 0.0
var _feixe := 0.0
var _alvo_feixe := -1
var _pulou := false
var _terminou := false
var _aviso := ""
var _tempo_aviso := 0.0


func _ready() -> void:
	for trecho in CHAO:
		_criar_piso(trecho)
	for vao in VAOS:
		_pontes.append(_criar_piso(Rect2(vao.x, 214, vao.y - vao.x, 10), true))
		_abertas.append(0.0)
	_criar_piso(Rect2(-12, 40, 12, 240))
	_criar_piso(Rect2(1770, 40, 12, 240))
	_corpo = CharacterBody2D.new()
	_corpo.collision_layer = 0
	_corpo.collision_mask = CAMADA_PLATAFORMA
	var colisao := CollisionShape2D.new()
	var formato := RectangleShape2D.new()
	formato.size = Vector2(12, 26)
	colisao.shape = formato
	colisao.position.y = -13
	_corpo.add_child(colisao)
	add_child(_corpo)
	set_physics_process(false)


func _criar_piso(area: Rect2, desativado: bool = false) -> CollisionShape2D:
	var piso := StaticBody2D.new()
	piso.collision_layer = CAMADA_PLATAFORMA
	piso.collision_mask = 0
	var colisao := CollisionShape2D.new()
	var formato := RectangleShape2D.new()
	formato.size = area.size
	colisao.shape = formato
	colisao.disabled = desativado
	piso.position = area.get_center()
	piso.add_child(colisao)
	add_child(piso)
	return colisao


func abrir() -> void:
	_coletadas.clear()
	for i in VAOS.size():
		_abertas[i] = 0.0
		_pontes[i].set_deferred("disabled", true)
	_checkpoint = CHECKPOINTS[0]
	_rolagem = 0.0
	_relogio = 0.0
	_feixe = 0.0
	_norte = true
	_direcao = 1.0
	_terminou = false
	_dialogo.hide()
	_repor_astronauta()
	_mensagem("Colete todas as moedas e chegue até a saída.")
	show()
	set_physics_process(true)
	queue_redraw()


func _repor_astronauta() -> void:
	_corpo.position = Vector2(_checkpoint, 214)
	_corpo.velocity = Vector2.ZERO
	_pulou = false


func _physics_process(delta: float) -> void:
	_relogio += delta
	_feixe = maxf(0.0, _feixe - delta)
	_tempo_aviso = maxf(0.0, _tempo_aviso - delta)
	for i in VAOS.size():
		if _abertas[i] > 0.0 and _abertas[i] < 1.0:
			_abertas[i] = minf(1.0, _abertas[i] + delta * 2.4)
			if _abertas[i] == 1.0:
				_pontes[i].set_deferred("disabled", false)

	var movimento := Input.get_axis(&"andar_esquerda", &"andar_direita")
	_corpo.velocity.x = movimento * 113.0
	if not is_zero_approx(movimento):
		_direcao = signf(movimento)
	_corpo.velocity.y += 760.0 * delta
	if _pulou and _corpo.is_on_floor():
		_corpo.velocity.y = -235.0
	_pulou = false
	_corpo.move_and_slide()

	if _corpo.position.y > 274.0:
		_repor_astronauta()
		_mensagem("Você voltou ao último ponto seguro.")

	_registrar_progresso()
	_rolagem = move_toward(_rolagem, clampf(_corpo.position.x - 230.0, 0.0, 1290.0), delta * 350.0)
	queue_redraw()


func _registrar_progresso() -> void:
	if _corpo.is_on_floor():
		for ponto in CHECKPOINTS:
			if absf(_corpo.position.x - ponto) < 16.0:
				_checkpoint = ponto
	var centro := _corpo.position - Vector2(0, 14)
	for i in MOEDAS.size():
		if not _coletadas.has(i) and centro.distance_to(MOEDAS[i]) < 18.0:
			_coletadas[i] = true
	if absf(_corpo.position.x - SAIDA.x) >= 15.0 or not _corpo.is_on_floor():
		return
	if _coletadas.size() < MOEDAS.size():
		_mensagem("Ainda faltam %d moedas." % (MOEDAS.size() - _coletadas.size()))
		return
	_terminou = true
	set_physics_process(false)
	_dialogo.mostrar("Você coletou todas as moedas! Polos opostos se atraem. Pressione Enter para voltar ao laboratório.")
	concluido.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	var tecla: Key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if tecla == KEY_ESCAPE or (_terminou and tecla == KEY_ENTER):
		set_physics_process(false)
		hide()
		fechado.emit()
	elif _terminou:
		return
	elif tecla in [KEY_SPACE, KEY_W, KEY_UP]:
		_pulou = true
	elif tecla == KEY_X:
		_norte = not _norte
	elif tecla == KEY_E:
		_ativar_ima()
	else:
		return
	get_viewport().set_input_as_handled()
	queue_redraw()


func _eh_ponte(i: int) -> bool:
	return i % 2 == 0


func _alvo(i: int) -> Vector2:
	var vao: Vector2 = VAOS[i]
	if _eh_ponte(i):
		return Vector2(lerpf(vao.y - 26.0, vao.x + 7.0, _abertas[i]), 207)
	var angulo := _abertas[i] * PI / 2.0
	return Vector2(vao.y, 214) + Vector2(-sin(angulo), -cos(angulo)) * (vao.y - vao.x - 8)


func _origem_ima() -> Vector2:
	return _corpo.position + Vector2(_direcao * 10.0, -15)


func _procurar_alvo() -> int:
	var origem := _origem_ima()
	for i in VAOS.size():
		var distancia := _alvo(i) - origem
		if _abertas[i] == 0.0 and distancia.x * _direcao > 0.0 and distancia.length() <= ALCANCE:
			return i
	return -1


func _ativar_ima() -> void:
	var i := _procurar_alvo()
	if i < 0:
		_mensagem("Vire-se para um polo e chegue mais perto.")
		return
	_feixe = 0.55
	_alvo_feixe = i
	if _norte != _eh_ponte(i):
		_mensagem("Polos iguais se repelem. Aperte X para trocar.")
		return
	_abertas[i] = 0.001
	_mensagem("Polos opostos se atraem!")


func _mensagem(texto: String) -> void:
	_aviso = texto
	_tempo_aviso = 2.8


func _draw() -> void:
	if not is_instance_valid(_corpo):
		return
	_desenhar_cenario()
	draw_set_transform(Vector2(-roundf(_rolagem), 0))
	_desenhar_pisos()
	var alvo := _procurar_alvo()
	for i in VAOS.size():
		_desenhar_passagem(i, i == alvo)
	_desenhar_colecionaveis()
	_desenhar_astronauta()
	draw_set_transform(Vector2.ZERO)
	_desenhar_interface(alvo)


func _desenhar_cenario() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#142635"))
	draw_rect(Rect2(0, 37, 480, 163), Color("#203b4a"))
	draw_rect(Rect2(0, 83, 480, 67), Color("#253f4e"))
	for i in range(-1, 7):
		var x := i * 96 - fposmod(roundf(_rolagem * 0.45), 96)
		draw_rect(Rect2(x + 2, 37, 8, 165), Color("#142b38"))
		draw_rect(Rect2(x + 20, 56, 55, 49), Color("#182d39"))
		draw_rect(Rect2(x + 22, 58, 51, 45), Color("#2b485a"))
		draw_rect(Rect2(x + 28, 66, 34, 2), Color("#4b6b78"))
		draw_rect(Rect2(x + 43, 57, 2, 46), Color("#182d39"))
	draw_rect(Rect2(0, 246, 480, 42), Color("#0b1824"))


func _desenhar_pisos() -> void:
	for trecho: Rect2 in CHAO:
		draw_rect(trecho, METAL)
		draw_rect(Rect2(trecho.position, Vector2(trecho.size.x, 3)), LUZ)
		draw_rect(Rect2(trecho.position + Vector2(0, 16), Vector2(trecho.size.x, 3)), Color("#203948"))
		for x in range(int(trecho.position.x) + 8, int(trecho.end.x), 24):
			draw_rect(Rect2(x, trecho.position.y + 9, 3, 3), Color("#7da4a2"))
	for ponto in CHECKPOINTS:
		var cor := Color("#97e6aa") if ponto == _checkpoint else LUZ
		draw_rect(Rect2(ponto - 9, 210, 18, 4), cor)


func _desenhar_passagem(i: int, ao_alcance: bool) -> void:
	var vao: Vector2 = VAOS[i]
	var alvo := _alvo(i)
	if _eh_ponte(i):
		draw_rect(Rect2(alvo.x - 7, 214, vao.y - alvo.x + 7, 9), METAL)
		draw_rect(Rect2(alvo.x - 7, 214, vao.y - alvo.x + 7, 2), LUZ)
	else:
		var angulo := _abertas[i] * PI / 2.0
		var pivô := Vector2(vao.y, 214)
		draw_set_transform(pivô - Vector2(roundf(_rolagem), 0), -angulo)
		draw_rect(Rect2(-10, -(vao.y - vao.x), 10, vao.y - vao.x), METAL)
		draw_rect(Rect2(-2, -(vao.y - vao.x), 2, vao.y - vao.x), LUZ)
		draw_set_transform(Vector2(-roundf(_rolagem), 0))
	if _abertas[i] < 1.0:
		var sul := _eh_ponte(i)
		if ao_alcance:
			draw_rect(Rect2(alvo - Vector2(10, 10), Vector2(20, 20)), TEXTO, false, 1)
		draw_rect(Rect2(alvo - Vector2(8, 8), Vector2(16, 16)), SUL if sul else NORTE)
		draw_string(FONTE, alvo + Vector2(-3, 3), "S" if sul else "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#132532"))


func _desenhar_colecionaveis() -> void:
	for i in MOEDAS.size():
		if _coletadas.has(i):
			continue
		var p: Vector2 = MOEDAS[i] + Vector2(0, roundf(sin(_relogio * 5 + i) * 2))
		draw_rect(Rect2(p - Vector2(4, 6), Vector2(8, 12)), Color("#ad712d"))
		draw_rect(Rect2(p - Vector2(6, 4), Vector2(12, 8)), Color("#f3b845"))
		draw_rect(Rect2(p - Vector2(3, 4), Vector2(2, 7)), Color("#fff1a7"))
	var cor := Color("#97e6aa") if _coletadas.size() == MOEDAS.size() else LUZ
	draw_rect(Rect2(SAIDA - Vector2(15, 40), Vector2(30, 40)), METAL)
	draw_rect(Rect2(SAIDA - Vector2(11, 32), Vector2(22, 32)), Color("#102431"))
	draw_rect(Rect2(SAIDA - Vector2(10, 38), Vector2(20, 3)), cor)
	draw_string(FONTE, SAIDA - Vector2(13, 46), "SAÍDA", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, TEXTO)


func _desenhar_astronauta() -> void:
	var p := _corpo.position.round()
	var direcao := "leste" if _direcao > 0 else "oeste"
	var andando := _corpo.is_on_floor() and absf(_corpo.velocity.x) > 0
	var animacao := StringName(("andar_" if andando else "parado_") + direcao)
	var quadro := floori(_relogio * 10) % SPRITES.get_frame_count(animacao) if andando else 0
	draw_texture(SPRITES.get_frame_texture(animacao, quadro), p - Vector2(12, 31))
	var origem := _origem_ima().round()
	var cor := NORTE if _norte else SUL
	if _feixe > 0.0:
		var alvo := _alvo(_alvo_feixe)
		for i in range(1, 13):
			var particula := origem.lerp(alvo, fposmod(i / 13.0 + _feixe * 2, 1.0)).round()
			draw_rect(Rect2(particula, Vector2(3, 2)), cor)
	var ponta := origem.x + (2.0 if _direcao > 0 else -4.0)
	draw_rect(Rect2(origem - Vector2(4, 5), Vector2(8, 10)), Color("#a8bcc0"))
	draw_rect(Rect2(ponta - 1, origem.y - 2, 4, 4), Color("#142635"))
	draw_rect(Rect2(ponta, origem.y - 5, 3, 3), cor)
	draw_rect(Rect2(ponta, origem.y + 2, 3, 3), SUL if _norte else NORTE)


func _desenhar_interface(alvo: int) -> void:
	var damasco := Color("#ffd6ad")
	var mel := Color("#ffdd81")
	var menta := Color("#a2ebc3")
	var cor_polo := NORTE if _norte else SUL
	HUD.painel(self, Rect2(8, 7, 196, 42), damasco)
	HUD.painel(self, Rect2(211, 7, 124, 42), mel)
	HUD.painel(self, Rect2(342, 7, 130, 42), menta)

	draw_rect(Rect2(17, 16, 20, 24), Color("#ec9b78"))
	draw_rect(Rect2(26, 20, 3, 15), FUNDO_TECLA)
	draw_rect(Rect2(21, 26, 13, 3), FUNDO_TECLA)
	draw_string(FONTE, Vector2(45, 32), "Expedição magnética", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, TINTA_HUD)

	draw_rect(Rect2(222, 18, 10, 18), Color("#a66636"))
	draw_rect(Rect2(219, 21, 16, 12), Color("#a66636"))
	draw_rect(Rect2(221, 21, 12, 11), Color("#f7b745"))
	draw_rect(Rect2(224, 22, 2, 7), Color("#fff4b2"))
	draw_string(FONTE, Vector2(244, 23), "Moedas", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, TINTA_HUD)
	draw_string(ThemeDB.fallback_font, Vector2(244, 39), "%02d / %02d" % [_coletadas.size(), MOEDAS.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, TINTA_HUD)
	draw_rect(Rect2(296, 32, 29, 6), Color("#dbab55"))
	var preenchimento := roundf(29.0 * _coletadas.size() / MOEDAS.size())
	draw_rect(Rect2(296, 32, preenchimento, 6), Color("#89502f"))

	draw_rect(Rect2(351, 16, 24, 24), Color("#32665e"))
	draw_rect(Rect2(355, 21, 4, 12), cor_polo)
	draw_rect(Rect2(367, 21, 4, 12), SUL if _norte else NORTE)
	draw_rect(Rect2(357, 31, 12, 4), FUNDO_TECLA)
	draw_string(FONTE, Vector2(384, 23), "Polo do ímã", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, TINTA_HUD)
	draw_string(FONTE, Vector2(384, 38), "NORTE" if _norte else "SUL", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, TINTA_HUD)
	draw_rect(Rect2(454, 28, 8, 8), cor_polo)
	draw_rect(Rect2(456, 30, 4, 4), FUNDO_TECLA)

	if _terminou:
		return
	HUD.painel(self, Rect2(8, 234, 464, 46), Color("#f8ddc6"))
	draw_rect(Rect2(14, 240, 452, 17), Color("#d8eed4"))
	draw_rect(Rect2(19, 243, 10, 9), Color("#448176"))
	draw_rect(Rect2(21, 252, 3, 2), Color("#448176"))
	draw_rect(Rect2(21, 247, 6, 1), FUNDO_TECLA)
	var dica := _aviso if _tempo_aviso > 0.0 else "Polos opostos se atraem."
	if _tempo_aviso == 0.0 and alvo >= 0:
		dica = "Aponte Norte para puxar a ponte." if _eh_ponte(alvo) else "Aponte Sul para derrubar o obstáculo."
	draw_string(ThemeDB.fallback_font, Vector2(36, 252), dica, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, TINTA_HUD)
	HUD.controle(self, 16, 32, "A   D", "Mover", damasco)
	HUD.controle(self, 105, 42, "Espaço", "Pular", mel)
	HUD.controle(self, 203, 17, "X", "Trocar polo", menta)
	HUD.controle(self, 299, 17, "E", "Usar ímã", Color("#c9defa"))
	HUD.controle(self, 391, 26, "Esc", "Voltar", Color("#e9d3f4"))
