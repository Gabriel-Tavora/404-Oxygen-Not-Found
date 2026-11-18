extends Control

signal concluido
signal fechado

const PISTA := preload("res://assets/lab-resistencia/pista-de-danca.png")
const ASTRONAUTA := preload("res://assets/astronauta/astronauta-animacoes.tres")
const META := 25
# A música marca os passos com um acento a cada duas batidas.
const BATIDA := 0.9
const INTERVALO_MOVIMENTOS := 2 * BATIDA
const PRIMEIRO_MOVIMENTO := 4 * BATIDA
const TEMPO_DE_PERCURSO := 1.42
const JANELA_DE_ACERTO := 0.35
const ACOES: Array[StringName] = [&"andar_esquerda", &"andar_baixo", &"andar_cima", &"andar_direita"]
const PASSOS: Array[StringName] = [&"walk_right", &"walk_down", &"walk_up", &"walk_right"]
const PASSOS_PADRAO: Array[StringName] = [&"andar_oeste", &"andar_sul", &"andar_norte", &"andar_leste"]
const SEQUENCIA: Array[int] = [0, 1, 2, 3, 2, 1, 3, 0, 1, 2, 0, 3, 1, 0, 2, 3]
const CORES: Array[Color] = [Color("#c18be9"), Color("#55d7ef"), Color("#79efb5"), Color("#ffbe63")]
const ROTACOES: Array[float] = [-PI / 2, PI, 0.0, PI / 2]
const NOTAS_ACERTO: Array[float] = [0.90, 1.0, 1.12, 1.20]
const DESLOCAMENTOS_PASSO: Array[Vector2] = [Vector2(-23, 0), Vector2(0, 8), Vector2(0, -6), Vector2(23, 0)]
const SETA: Array[Vector2] = [Vector2(0, -10), Vector2(10, 0), Vector2(4, 0),
	Vector2(4, 9), Vector2(-4, 9), Vector2(-4, 0), Vector2(-10, 0)]
const ESCURO := Color("#112833")
const DOURADO := Color("#ffd284")
const VERDE := Color("#a0f3c9")
const CENTRO_CRUZ := Vector2(348, 173)
const TAMANHO_CASA := 36.0
const DIRECOES: Array[Vector2] = [Vector2.LEFT, Vector2.DOWN, Vector2.UP, Vector2.RIGHT]
const EXTENSOES: Array[float] = [103.0, 82.0, 82.0, 103.0]


class Movimento:
	var faixa: int
	var instante: float

	func _init(nova_faixa: int, novo_instante: float) -> void:
		faixa = nova_faixa
		instante = novo_instante


@onready var _personagem := $Personagem
@onready var _alvos: Control = $Alvos
@onready var _batida: AudioStreamPlayer = $Batida
@onready var _som_acerto: AudioStreamPlayer = $SomAcerto
@onready var _contador: Label = $Contador
@onready var _dica: Label = $Dica
@onready var _resultado: ResultadoMissao = $Resultado

var _movimentos: Array[Movimento] = []
var _proximo_movimento := 0
var _acertos := 0
var _tempo := 0.0
var _duracao_musica := 0.0
var _ultima_posicao_audio := 0.0
var _voltas_audio := 0
var _latencia_audio := 0.0
var _faixa_ativa := 0
var _ultimo_passo := -1.0
var _ultimo_aviso := -1.0


func _ready() -> void:
	_personagem.aplicar_selecao()
	_contador.text = "0 / %d" % META
	for faixa in range(ACOES.size()):
		var alvo := _alvos.get_child(faixa) as Button
		var area := _area_alvo(faixa)
		alvo.position = area.position
		alvo.size = area.size
		alvo.pressed.connect(_tentar_movimento.bind(faixa))
	$Pausar.pressed.connect(MenuPausa.abrir)
	$Voltar.pressed.connect(_fechar)
	_resultado.voltar_solicitado.connect(_fechar)

	var musica := _batida.stream.duplicate() as AudioStreamWAV
	_duracao_musica = musica.get_length()
	musica.loop_mode = AudioStreamWAV.LOOP_FORWARD
	musica.loop_end = roundi(_duracao_musica * musica.mix_rate)
	_batida.stream = musica
	_latencia_audio = AudioServer.get_output_latency()
	TrilhaAmbiente.silenciar_durante(self)
	_batida.play()


func _input(evento: InputEvent) -> void:
	if evento.is_action_pressed(&"voltar_contexto"):
		get_viewport().set_input_as_handled()
		_fechar()
		return
	for faixa in range(ACOES.size()):
		if evento.is_action_pressed(ACOES[faixa]):
			get_viewport().set_input_as_handled()
			_tentar_movimento(faixa)
			return


func _process(_delta: float) -> void:
	_atualizar_relogio()
	_atualizar_movimentos()
	if _tempo < PRIMEIRO_MOVIMENTO - JANELA_DE_ACERTO:
		var restantes := ceili((PRIMEIRO_MOVIMENTO - _tempo) / BATIDA)
		_mostrar_dica("Vai começar  %d" % restantes, DOURADO)
	elif _tempo - _ultimo_aviso > BATIDA:
		_mostrar_dica("Aperte quando a seta chegar", Color("#a8cbce"))
	queue_redraw()


func _atualizar_relogio() -> void:
	# As setas acompanham a posição audível da música, inclusive após uma pausa.
	var posicao := _batida.get_playback_position()
	if posicao < _ultima_posicao_audio - _duracao_musica * 0.5:
		_voltas_audio += 1
	_ultima_posicao_audio = posicao
	var ajuste := AudioServer.get_time_since_last_mix() - _latencia_audio
	_tempo = maxf(_tempo, _voltas_audio * _duracao_musica + posicao + ajuste)


func _atualizar_movimentos() -> void:
	var instante := PRIMEIRO_MOVIMENTO + _proximo_movimento * INTERVALO_MOVIMENTOS
	while instante <= _tempo + TEMPO_DE_PERCURSO:
		var faixa := SEQUENCIA[_proximo_movimento % SEQUENCIA.size()]
		_movimentos.append(Movimento.new(faixa, instante))
		_proximo_movimento += 1
		instante = PRIMEIRO_MOVIMENTO + _proximo_movimento * INTERVALO_MOVIMENTOS
	while not _movimentos.is_empty() and _movimentos[0].instante < _tempo - JANELA_DE_ACERTO:
		_movimentos.pop_front()
		_mostrar_aviso("Siga a próxima seta", DOURADO)


func _tentar_movimento(faixa: int) -> void:
	if _resultado.visible or _tempo < PRIMEIRO_MOVIMENTO - JANELA_DE_ACERTO:
		return
	if _movimentos.is_empty() or absf(_movimentos[0].instante - _tempo) > JANELA_DE_ACERTO:
		_mostrar_aviso("Espere a seta chegar", DOURADO)
		return
	if _movimentos[0].faixa != faixa:
		_mostrar_aviso("Aperte a seta correspondente", DOURADO)
		return
	_movimentos.pop_front()
	_faixa_ativa = faixa
	_ultimo_passo = _tempo
	_acertos += 1
	_som_acerto.pitch_scale = 1.35 if _acertos == META else NOTAS_ACERTO[faixa]
	_som_acerto.play()
	_contador.text = "%d / %d" % [_acertos, META]
	if _acertos == META:
		_encerrar_rodada()
	else:
		_mostrar_aviso("Boa!", VERDE)


func _encerrar_rodada() -> void:
	set_process(false)
	set_process_input(false)
	_batida.stop()
	_alvos.hide()
	$Pausar.hide()
	$Voltar.hide()
	$Instrucao.hide()
	_dica.hide()
	_resultado.mostrar("Dança no ritmo", "Você acertou %d passos no ritmo!" % META)
	queue_redraw()
	concluido.emit()


func _mostrar_aviso(texto: String, cor: Color) -> void:
	_ultimo_aviso = _tempo
	_mostrar_dica(texto, cor)


func _mostrar_dica(texto: String, cor: Color) -> void:
	if _dica.text != texto:
		_dica.text = texto
		_dica.add_theme_color_override("font_color", cor)


func _fechar() -> void:
	_batida.stop()
	_som_acerto.stop()
	fechado.emit()


func _draw() -> void:
	_desenhar_palco()
	_desenhar_painel(Vector2(33, 65), Vector2(183, 72))
	draw_rect(Rect2(44, 87, 161, 1), Color("#385e66"))
	_desenhar_painel(Vector2(232, 44), Vector2(232, 225))
	draw_rect(Rect2(246, 58, 204, 10), Color("#5b8086"), false, 1.0)
	draw_rect(Rect2(248, 60, floorf(200.0 * _acertos / META), 6), DOURADO if _acertos < META else VERDE)
	_desenhar_cruz()


func _desenhar_painel(origem: Vector2, dimensoes: Vector2) -> void:
	draw_rect(Rect2(origem + Vector2(3, 4), dimensoes), Color("#11242eb0"))
	draw_rect(Rect2(origem, dimensoes), Color("#1d3038"))
	draw_rect(Rect2(origem + Vector2(2, 2), dimensoes - Vector2(4, 4)), Color("#ae794d"))
	draw_rect(Rect2(origem + Vector2(4, 3), Vector2(dimensoes.x - 8, 2)), Color("#f1bd7b"))
	draw_rect(Rect2(origem + Vector2(5, 5), dimensoes - Vector2(10, 10)), Color("#725137"))
	draw_rect(Rect2(origem + Vector2(7, 6), dimensoes - Vector2(14, 12)), ESCURO)
	for x in [origem.x + 3, origem.x + dimensoes.x - 5]:
		for y in [origem.y + 3, origem.y + dimensoes.y - 5]:
			draw_rect(Rect2(x, y, 2, 2), Color("#704a36"))


func _desenhar_palco() -> void:
	# Aproveita as caixas e o piso luminoso da própria pista do laboratório.
	draw_texture_rect_region(PISTA, Rect2(39, 140, 35, 48), Rect2(3, 12, 18, 32))
	draw_texture_rect_region(PISTA, Rect2(175, 140, 35, 48), Rect2(73, 12, 18, 32))
	draw_rect(Rect2(80, 151, 89, 43), Color("#162d3a"))
	draw_rect(Rect2(80, 151, 89, 43), Color("#335764"), false, 2.0)
	var batida := fposmod(_tempo, BATIDA) / BATIDA
	for barra in range(7):
		var altura := 2 + roundi((1.0 - batida) * (3.0 + sin(barra * 1.5 + _tempo * 2.0) * 2.0))
		for segmento in range(altura):
			draw_rect(Rect2(87 + barra * 11, 186 - segmento * 4, 8, 2), CORES[barra % CORES.size()])
	draw_texture_rect_region(PISTA, Rect2(22, 168, 205, 85), Rect2(0, 45, 94, 68))

	var tempo_passo := _tempo - _ultimo_passo
	var dancando := tempo_passo < 0.42
	var curva := sin(clampf(tempo_passo / 0.42, 0.0, 1.0) * PI)
	var deslocamento := curva * DESLOCAMENTOS_PASSO[_faixa_ativa]
	var pes := (Vector2(124, 211) + deslocamento).round()
	draw_rect(Rect2(pes + Vector2(-12, -3), Vector2(24, 5)), Color("#193747bb"))
	if dancando:
		var brilho := pes + Vector2(18, -40 - tempo_passo * 24.0).round()
		draw_rect(Rect2(pes + Vector2(-11, -2), Vector2(22, 2)), CORES[_faixa_ativa].lightened(0.5))
		draw_rect(Rect2(brilho + Vector2(-3, 0), Vector2(7, 1)), DOURADO)
		draw_rect(Rect2(brilho + Vector2(0, -3), Vector2(1, 7)), DOURADO)
	var salto := roundf(curva * 9.0) if dancando else roundf(sin(batida * TAU) * 2.0)
	if _personagem.visible:
		_personagem.position = pes - Vector2(0, salto)
		if dancando:
			_personagem.definir_pose(PASSOS[_faixa_ativa], tempo_passo, _faixa_ativa == 0)
		else:
			_personagem.definir_pose(&"idle_down")
		return
	var textura := ASTRONAUTA.get_frame_texture(&"parado_sul", 0)
	if dancando:
		textura = ASTRONAUTA.get_frame_texture(PASSOS_PADRAO[_faixa_ativa], 0 if tempo_passo < 0.21 else 2)
	draw_texture_rect(textura, Rect2(pes - Vector2(24, 61 + salto), Vector2(48, 64)), false)


func _desenhar_cruz() -> void:
	var tamanho := Vector2.ONE * TAMANHO_CASA
	var centro := Rect2(CENTRO_CRUZ - tamanho * 0.5, tamanho)
	draw_rect(centro, Color("#193640"))
	draw_rect(centro.grow(-2.0), Color("#31545c"), false, 1.0)

	for faixa in range(CORES.size()):
		_desenhar_entrada(faixa)
		_desenhar_alvo(faixa)

	for movimento in _movimentos:
		var restante := clampf((movimento.instante - _tempo) / TEMPO_DE_PERCURSO, 0.0, 1.0)
		var posicao := _posicao_nota(movimento.faixa, restante)
		var opacidade := clampf((1.0 - restante) * 9.0, 0.0, 1.0)
		var cor := CORES[movimento.faixa].lightened(0.23)
		_desenhar_seta(posicao + Vector2(0, 1), movimento.faixa, 1.25, Color(ESCURO, opacidade))
		_desenhar_seta(posicao, movimento.faixa, 1.05, Color(cor, opacidade))


func _desenhar_entrada(faixa: int) -> void:
	var area := _area_entrada(faixa)
	var direcao := DIRECOES[faixa]
	var lateral := direcao.orthogonal() * 12.0
	draw_rect(area, Color("#4c9079"))
	draw_rect(area.grow(-1.0), Color("#224d46"))
	for distancia: float in [5.0, 8.0]:
		var marca := CENTRO_CRUZ + direcao * (EXTENSOES[faixa] - distancia)
		draw_line(marca - lateral, marca + lateral, Color("#6db99a"))


func _desenhar_alvo(faixa: int) -> void:
	var area := _area_alvo(faixa)
	var cor := CORES[faixa]
	var acertou := faixa == _faixa_ativa and _tempo - _ultimo_passo < 0.30
	var borda := cor.lightened(0.55) if acertou else cor.darkened(0.52)
	if not _movimentos.is_empty() and _movimentos[0].faixa == faixa:
		var tempo_no_alvo := _tempo - _movimentos[0].instante
		if tempo_no_alvo >= 0.0 and tempo_no_alvo <= JANELA_DE_ACERTO:
			borda = DOURADO
	draw_rect(area.grow(-1.0), borda)
	draw_rect(area.grow(-3.0), cor.lightened(0.35) if acertou else cor)
	_desenhar_seta(area.get_center(), faixa, 0.85, ESCURO)


func _area_alvo(faixa: int) -> Rect2:
	var tamanho := Vector2.ONE * TAMANHO_CASA
	var centro := CENTRO_CRUZ + DIRECOES[faixa] * TAMANHO_CASA
	return Rect2(centro - tamanho * 0.5, tamanho)


func _area_entrada(faixa: int) -> Rect2:
	var direcao := DIRECOES[faixa]
	var inicio := TAMANHO_CASA * 1.5
	var fim := EXTENSOES[faixa]
	var tamanho := direcao.abs() * (fim - inicio) + direcao.orthogonal().abs() * TAMANHO_CASA
	var centro := CENTRO_CRUZ + direcao * ((inicio + fim) * 0.5)
	return Rect2(centro - tamanho * 0.5, tamanho)


func _posicao_nota(faixa: int, restante: float) -> Vector2:
	var origem := CENTRO_CRUZ + DIRECOES[faixa] * (EXTENSOES[faixa] - 12.0)
	return _area_alvo(faixa).get_center().lerp(origem, restante).round()


func _desenhar_seta(centro: Vector2, faixa: int, escala: float, cor: Color) -> void:
	var pontos := PackedVector2Array()
	for ponto in SETA:
		pontos.append((centro + ponto.rotated(ROTACOES[faixa]) * escala).round())
	draw_colored_polygon(pontos, cor)
