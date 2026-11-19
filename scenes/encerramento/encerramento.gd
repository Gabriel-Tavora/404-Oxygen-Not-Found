extends CanvasLayer

const Creditos = preload("res://scenes/encerramento/creditos.gd")
const MENU_INICIAL := "res://scenes/ui/menu-inicial/menu-inicial.tscn"
const DURACAO_ESCURECIMENTO := 0.65
const DURACAO_CREDITOS := 12.0
const ENTRADA_DO_ASTRONAUTA := 22.0 / 30.0

@onready var _escurecimento: ColorRect = $Escurecimento
@onready var _fundo: ColorRect = $Fundo
@onready var _video: VideoStreamPlayer = $Quadro/Video
@onready var _musica: AudioStreamPlayer = $Musica
@onready var _creditos: Control = $Creditos
@onready var _lista: VBoxContainer = $Creditos/Conteudo/Lista
@onready var _pular: Button = $Creditos/Conteudo/Pular
@onready var _fim: Control = $Fim
@onready var _tempo_final: Label = $Fim/Conteudo/TempoFinal
@onready var _jogar_de_novo: Button = $Fim/Conteudo/JogarDeNovo
@onready var _botao_ranking: Button = $Fim/Conteudo/Ranking
@onready var _ranking = $Ranking
@onready var _voltar: Button = $Fim/Conteudo/VoltarAoMapa
@onready var _sair: Button = $Fim/Conteudo/Sair

var _musica_iniciada := false


func _ready() -> void:
	set_process(false)
	get_tree().paused = true
	_video.finished.connect(_mostrar_creditos)
	_pular.pressed.connect(_mostrar_tela_final)
	_jogar_de_novo.pressed.connect(_reiniciar_treinamento)
	_botao_ranking.pressed.connect(_abrir_ranking)
	_ranking.fechado.connect(_fechar_ranking)
	_voltar.pressed.connect(_voltar_ao_mapa)
	_sair.pressed.connect(func() -> void: get_tree().quit())

	var transicao := create_tween().set_trans(Tween.TRANS_SINE)
	transicao.tween_property(_escurecimento, "color:a", 1.0, DURACAO_ESCURECIMENTO)
	await transicao.finished
	_fundo.show()
	_escurecimento.hide()
	_video.play()
	set_process(true)


func _process(_delta: float) -> void:
	if _video.stream_position >= ENTRADA_DO_ASTRONAUTA:
		_iniciar_musica()


func _iniciar_musica() -> void:
	_musica_iniciada = true
	_musica.play()
	set_process(false)


func _mostrar_creditos() -> void:
	if not _musica_iniciada:
		_iniciar_musica()
	_video.hide()
	Creditos.preencher_lista(_lista)
	_creditos.show()
	_pular.grab_focus()
	get_tree().create_timer(DURACAO_CREDITOS).timeout.connect(_mostrar_tela_final)


func _mostrar_tela_final() -> void:
	if not _creditos.visible:
		return
	_creditos.hide()
	_tempo_final.visible = Partida.foi_iniciada()
	if _tempo_final.visible:
		var tempo := Partida.formatar_tempo(Partida.tempo_decorrido_ms())
		var nome := Partida.nome_jogador
		_tempo_final.text = "Tempo final · %s" % tempo if nome.is_empty() else "%s  ·  %s" % [tempo, nome]
		_tempo_final.tooltip_text = _tempo_final.text
	$Fim/Conteudo/ErroAoSalvar.visible = Partida.erro_ao_salvar != OK
	_fim.show()
	_jogar_de_novo.grab_focus()


func _abrir_ranking() -> void:
	_fim.hide()
	_ranking.abrir()


func _fechar_ranking() -> void:
	_fim.show()
	_botao_ranking.grab_focus()


func _reiniciar_treinamento() -> void:
	var arvore := get_tree()
	if arvore.change_scene_to_file(MENU_INICIAL) == OK:
		Partida.reiniciar()
		ProgressoConhecimento.reiniciar()
		BorboletaSolta.reiniciar()
		OverworldState.current_node = OverworldState.NO_INICIAL
		arvore.paused = false
		queue_free()


func _voltar_ao_mapa() -> void:
	var arvore := get_tree()
	if arvore.change_scene_to_file(OverworldState.MAPA) == OK:
		arvore.paused = false
		queue_free()
