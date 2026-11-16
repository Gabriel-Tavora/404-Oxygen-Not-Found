extends Control

signal concluido
signal fechado

const FUNDO := preload("res://assets/lab-resistencia/corrida-fundo.png")
const MOEDA := preload("res://assets/lab-resistencia/corrida-moeda.png")
const OBSTACULO := preload("res://assets/lab-resistencia/corrida-obstaculo.png")
const CORREDOR := preload("res://assets/astronauta/astronauta-animacoes.tres")
const META_MOEDAS := 30
const CENTRO := 240.0
const ESPACAMENTO := 0.19
const PROFUNDIDADE_CORREDOR := 0.91
const DURACAO_SALTO := 0.66
const TEMPO_TROPECO := 0.58

class Fileira:
	var profundidade: float
	var moedas: Array[int] = []
	var barreira := -1


@onready var _contador: Label = $Placar/Contador
@onready var _objetivo: Label = $Placar/Objetivo
@onready var _pausar: Button = $Pausar
@onready var _pausa: Control = $Pausa
@onready var _continuar: Button = $Pausa/Janela/Continuar
@onready var _total_pausa: Label = $Pausa/Janela/Total
@onready var _som_moeda: AudioStreamPlayer = $SomMoeda

var _fileiras: Array[Fileira] = []
var _faixa := 1
var _faixa_visual := 1.0
var _faixa_moedas := 1
var _numero_fileiras := 0
var _ate_proxima := 0.0
var _rolagem := 0.0
var _tempo := 0.0
var _salto := 0.0
var _tropeco := 0.0
var _brilho := 0.0
var _moedas := 0


func _ready() -> void:
	_pausar.pressed.connect(_pausar_corrida)
	_continuar.pressed.connect(_retomar)
	$Pausa/Janela/Voltar.pressed.connect(func() -> void: fechado.emit())
	# As primeiras moedas chegam pelo meio para a criança aprender o ritmo.
	for indice in range(4):
		_criar_fileira(0.60 - indice * ESPACAMENTO)
	_ate_proxima = ESPACAMENTO - _fileiras.back().profundidade


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		if _pausa.visible:
			_retomar()
		else:
			_pausar_corrida()
	elif _pausa.visible:
		return
	elif event.is_action_pressed(&"andar_esquerda"):
		_faixa = maxi(0, _faixa - 1)
	elif event.is_action_pressed(&"andar_direita"):
		_faixa = mini(2, _faixa + 1)
	elif event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"andar_cima"):
		if is_zero_approx(_salto):
			_salto = DURACAO_SALTO
	else:
		return
	get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if _pausa.visible:
		return

	_tempo += delta
	_salto = maxf(0.0, _salto - delta)
	_tropeco = maxf(0.0, _tropeco - delta)
	_brilho = maxf(0.0, _brilho - delta)
	_faixa_visual = move_toward(_faixa_visual, _faixa, 7.5 * delta)

	var velocidade := minf(0.43, 0.27 + _tempo * 0.0028)
	if _tropeco > 0.0:
		velocidade *= 0.56
	var avanco := velocidade * delta
	_rolagem = fposmod(_rolagem + avanco, ESPACAMENTO)
	for fileira in _fileiras:
		var anterior := fileira.profundidade
		fileira.profundidade += avanco
		if anterior < PROFUNDIDADE_CORREDOR and fileira.profundidade >= PROFUNDIDADE_CORREDOR:
			_cruzar_fileira(fileira)
	while not _fileiras.is_empty() and _fileiras[0].profundidade > 1.05:
		_fileiras.pop_front()

	_ate_proxima -= avanco
	while _ate_proxima <= 0.0:
		_criar_fileira(-_ate_proxima)
		_ate_proxima += ESPACAMENTO
	queue_redraw()


func _criar_fileira(profundidade: float) -> void:
	var fileira := Fileira.new()
	fileira.profundidade = profundidade
	# A trilha principal fica na mesma faixa por quatro fileiras, com trocas adjacentes.
	if _numero_fileiras > 0 and _numero_fileiras % 4 == 0:
		var direcao := 1 if _faixa_moedas == 0 or (_faixa_moedas == 1 and randf() < 0.5) else -1
		_faixa_moedas += direcao
	fileira.moedas.append(_faixa_moedas)
	if _numero_fileiras >= 3:
		var lateral := (_faixa_moedas + randi_range(1, 2)) % 3
		if _numero_fileiras % 2 == 1:
			fileira.barreira = lateral
		if _numero_fileiras % 3 == 0:
			fileira.moedas.append(3 - _faixa_moedas - lateral)
	_fileiras.append(fileira)
	_numero_fileiras += 1


func _cruzar_fileira(fileira: Fileira) -> void:
	if fileira.barreira >= 0 and absf(_faixa_visual - fileira.barreira) < 0.43 and _altura_salto() < 10.0:
		_tropeco = TEMPO_TROPECO
	var faixa := roundi(_faixa_visual)
	if absf(_faixa_visual - faixa) < 0.44 and faixa in fileira.moedas:
		fileira.moedas.erase(faixa)
		_pegar_moeda()


func _pegar_moeda() -> void:
	_moedas += 1
	_brilho = 0.30
	_contador.text = "%d / %d" % [_moedas, META_MOEDAS] if _moedas < META_MOEDAS else str(_moedas)
	_som_moeda.pitch_scale = 1.35 if _moedas == META_MOEDAS else 1.0
	_som_moeda.play()
	if _moedas == META_MOEDAS:
		_contador.add_theme_color_override("font_color", Color("#aff0c1"))
		_objetivo.add_theme_color_override("font_color", Color("#aff0c1"))
		_objetivo.text = "Missão concluída!"
		concluido.emit()


func _pausar_corrida() -> void:
	_total_pausa.text = "Moedas: %d / %d" % [_moedas, META_MOEDAS]
	if _moedas >= META_MOEDAS:
		_total_pausa.text = "Missão concluída! %d moedas" % _moedas
	_pausa.show()
	_continuar.grab_focus()


func _retomar() -> void:
	_pausa.hide()


func _altura_salto() -> float:
	var fase := _salto / DURACAO_SALTO
	return 35.0 * 4.0 * fase * (1.0 - fase)


func _ponto_pista(profundidade: float, faixa: float) -> Vector2:
	var perspectiva := pow(profundidade, 1.45)
	var largura_faixa := lerpf(51.0, 82.0, perspectiva)
	return Vector2(CENTRO + (faixa - 1.0) * largura_faixa, lerpf(40.0, 288.0, perspectiva))


func _draw() -> void:
	draw_texture(FUNDO, Vector2.ZERO)
	for faixa in [0.5, 1.5]:
		for indice in range(7):
			var inicio := indice * ESPACAMENTO + _rolagem - ESPACAMENTO
			var fim := minf(1.0, inicio + 0.102)
			if fim > 0.0 and inicio < 1.0:
				_desenhar_faixa(faixa, maxf(0.0, inicio), fim)

	var corredor_desenhado := false
	for indice in range(_fileiras.size() - 1, -1, -1):
		var fileira := _fileiras[indice]
		if fileira.profundidade > PROFUNDIDADE_CORREDOR and not corredor_desenhado:
			_desenhar_corredor()
			corredor_desenhado = true
		_desenhar_fileira(fileira)
	if not corredor_desenhado:
		_desenhar_corredor()


func _desenhar_faixa(faixa: float, inicio: float, fim: float) -> void:
	var topo := _ponto_pista(inicio, faixa)
	var base := _ponto_pista(fim, faixa)
	if base.y - topo.y < 1.0:
		return
	var espessura_topo := lerpf(0.75, 1.65, inicio)
	var espessura_base := lerpf(0.75, 1.65, fim)
	draw_colored_polygon(PackedVector2Array([
		topo - Vector2(espessura_topo, 0), topo + Vector2(espessura_topo, 0),
		base + Vector2(espessura_base, 0), base - Vector2(espessura_base, 0),
	]), Color("#738795"))


func _desenhar_fileira(fileira: Fileira) -> void:
	var profundidade := fileira.profundidade
	var escala := lerpf(0.62, 1.34, profundidade)
	if fileira.barreira >= 0:
		var ponto := _ponto_pista(profundidade, fileira.barreira)
		var tamanho := (OBSTACULO.get_size() * escala).round()
		var origem := ponto - Vector2(tamanho.x * 0.5, tamanho.y)
		draw_rect(Rect2((ponto - Vector2(tamanho.x * 0.48, 3)).round(), Vector2(tamanho.x * 0.96, 4)), Color("#12222c99"))
		draw_texture_rect(OBSTACULO, Rect2(origem.round(), tamanho), false)
	for faixa in fileira.moedas:
		var ponto := _ponto_pista(profundidade, faixa)
		var giro := absf(cos(_tempo * 5.0 + profundidade * 8.0))
		var tamanho := (MOEDA.get_size() * escala * Vector2(lerpf(0.63, 1.02, giro), 1.0)).round()
		var origem := ponto - Vector2(tamanho.x * 0.5, tamanho.y + 5.0)
		draw_texture_rect(MOEDA, Rect2(origem.round(), tamanho), false)
		if giro > 0.84 and profundidade > 0.28:
			_desenhar_brilho((origem + Vector2(tamanho.x + 3, 1)).round(), Color("#ffdf79"))


func _desenhar_corredor() -> void:
	var pes := _ponto_pista(PROFUNDIDADE_CORREDOR, _faixa_visual).round()
	draw_rect(Rect2(pes + Vector2(-9, -2), Vector2(18, 4)), Color("#172a35b0"))
	draw_rect(Rect2(pes + Vector2(-6, -3), Vector2(12, 6)), Color("#172a358c"))

	var altura := _altura_salto()
	var quadro := 0 if altura > 0.0 else int(_tempo * 15.0) % CORREDOR.get_frame_count(&"andar_norte")
	var textura := CORREDOR.get_frame_texture(&"andar_norte", quadro)
	var tinta := Color("#ffd09f") if _tropeco > 0.0 else Color.WHITE
	draw_texture_rect(textura, Rect2((pes - Vector2(19, 49 + altura)).round(), Vector2(38, 50)), false, tinta)
	if _brilho > 0.0:
		var brilho := pes + Vector2(19, -26 - altura - (0.30 - _brilho) * 42.0)
		_desenhar_brilho(brilho.round(), Color("#ffe283"))


func _desenhar_brilho(ponto: Vector2, cor: Color) -> void:
	draw_rect(Rect2(ponto - Vector2(2, 0), Vector2(5, 1)), cor)
	draw_rect(Rect2(ponto - Vector2(0, 2), Vector2(1, 5)), cor)
