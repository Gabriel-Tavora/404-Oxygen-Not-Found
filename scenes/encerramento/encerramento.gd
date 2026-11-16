extends CanvasLayer

const DURACAO_ESCURECIMENTO := 0.65
const ENTRADA_DO_ASTRONAUTA := 22.0 / 30.0
const TEMPO_ULTIMO_CREDITO := 4.0
const CREDITOS := [
	["DESIGN LAB-FÍSICA", "PEDRO MAPURUNGA"],
	["DESIGN LAB-BIO", "PEDRO MAPURUNGA"],
	["DESIGN LAB-RESISTÊNCIA", "PEDRO MAPURUNGA"],
	["DESIGN HUB-MISSÕES", "JOÃO GABRIEL"],
	["DESIGN DO MENU DE PERSONAGEM", "JOÃO GABRIEL"],
	["LÓGICA DO MENU DE PERSONAGEM", "JOÃO GABRIEL"],
	["DESIGN MINIGAME ESTEIRA", "PEDRO MAPURUNGA"],
	["DESIGN MINIGAME LANÇAMENTO", "PEDRO MAPURUNGA"],
	["DESIGN MINIGAME BORBOLETA", "PEDRO MAPURUNGA"],
	["DESIGN MINIGAME DE MEMÓRIA", "PEDRO MAPURUNGA"],
	["DESIGN MINIGAME DE PALAVRAS CRUZADAS", "PEDRO MAPURUNGA"],
	["DESIGN MINIGAME MAGNÉTICO", "PEDRO MAPURUNGA"],
	["LÓGICA MINIGAME MAGNÉTICO", "PEDRO MAPURUNGA"],
	["TRILHA SONORA", "CODEX"],
	["TILES", "CODEX"],
	["SPRITES", "CODEX"],
	["LÓGICA DO MINIGAME DE ESTEIRA", "ANA KAROLINA"],
	["LÓGICA DO MINIGAME DE DANÇA", "LUIS GUSTAVO"],
	["PARTICIPAÇÃO NA IDEAÇÃO E PLANEJAMENTO", "DANIEL SILVA"],
]

@onready var _escurecimento: ColorRect = $Escurecimento
@onready var _fundo: ColorRect = $Fundo
@onready var _video: VideoStreamPlayer = $Quadro/Video
@onready var _musica: AudioStreamPlayer = $Musica
@onready var _creditos: Control = $Creditos
@onready var _rolagem: Control = $Creditos/Rolagem
@onready var _lista: VBoxContainer = $Creditos/Rolagem/Lista
@onready var _fim: Control = $Fim
@onready var _voltar: Button = $Fim/Conteudo/VoltarAoMapa

var _musica_iniciada := false
var _inicio_dos_creditos := 0.0


func _ready() -> void:
	set_process(false)
	get_tree().paused = true
	_video.finished.connect(_mostrar_creditos)
	_musica.finished.connect(_mostrar_tela_final)
	_voltar.pressed.connect(_voltar_ao_mapa)

	var transicao := create_tween().set_trans(Tween.TRANS_SINE)
	transicao.tween_property(_escurecimento, "color:a", 1.0, DURACAO_ESCURECIMENTO)
	await transicao.finished
	_fundo.show()
	_escurecimento.hide()
	_video.play()
	set_process(true)


func _process(_delta: float) -> void:
	if not _musica_iniciada and _video.stream_position >= ENTRADA_DO_ASTRONAUTA:
		_iniciar_musica()
	if _creditos.visible:
		var duracao_rolagem := _musica.stream.get_length() - _inicio_dos_creditos - TEMPO_ULTIMO_CREDITO
		var tempo := _musica.get_playback_position() - _inicio_dos_creditos
		var fracao := clampf(tempo / maxf(duracao_rolagem, 1.0), 0.0, 1.0)
		var destino := minf(12.0, _rolagem.size.y * 0.5 + 16.0 - _lista.size.y)
		_lista.position.y = roundf(lerpf(12.0, destino, fracao))


func _iniciar_musica() -> void:
	_musica_iniciada = true
	_musica.play()


func _mostrar_creditos() -> void:
	if not _musica_iniciada:
		_iniciar_musica()
	_inicio_dos_creditos = _musica.get_playback_position()
	_video.hide()
	for credito: Array in CREDITOS:
		var linha := VBoxContainer.new()
		linha.add_theme_constant_override(&"separation", 2)
		_lista.add_child(linha)
		linha.add_child(_criar_rotulo(credito[0], 11, Color("#a9c5dc")))
		linha.add_child(_criar_rotulo(credito[1], 17, Color("#f4f8ff")))
	_creditos.show()
	create_tween().tween_property(_creditos, "modulate:a", 1.0, 0.5)


func _criar_rotulo(texto: String, tamanho: int, cor: Color) -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.add_theme_font_size_override(&"font_size", tamanho)
	rotulo.add_theme_color_override(&"font_color", cor)
	return rotulo


func _mostrar_tela_final() -> void:
	set_process(false)
	_creditos.hide()
	_fim.show()
	_voltar.grab_focus()


func _voltar_ao_mapa() -> void:
	var arvore := get_tree()
	if arvore.change_scene_to_file(OverworldState.MAPA) == OK:
		arvore.paused = false
		queue_free()
