extends Control
## Tela de seleção: personagem -> cor do cabelo -> cor da mochila -> nome do jogador.
## Cada card é uma cena separada (cards/*.tscn) que puxa o seu .tres
## (personagens/*.tres, cabelos/*.tres, mochilas/*.tres).
##
## Teclado / controle:
##   ← → (ou A / D)   troca dentro da etapa ativa
##   ↑ ↓ (ou W / S)   muda de etapa
##   Enter / Espaço   avança até a tela de nome
##   Esc              volta uma etapa
## Mouse: clicar em uma opção seleciona e avança.

signal escolha_confirmada(personagem: PersonagemDados, cabelo: CabeloDados, mochila: MochilaDados)

const CENA_COMANDANTE := preload("res://scenes/encerramento/comandante.tscn")
const TAMANHO := Vector2(1536, 1024)
const TITULOS := [
	"ESCOLHA O PERSONAGEM  ·  CLIQUE OU ENTER",
	"COR DO CABELO  ·  CLIQUE OU ENTER",
	"COR DA MOCHILA  ·  CLIQUE OU ENTER",
]

## Cena aberta depois de confirmar (vazio = fica nesta tela)
@export_file("*.tscn") var proxima_cena := OverworldState.MAPA

@onready var tela: Control = $Tela
@onready var caixa_cards: Control = $Tela/Cards
@onready var caixa_cabelos: Control = $Tela/Cabelos
@onready var caixa_mochilas: Control = $Tela/Mochilas
@onready var titulo: Label = $Tela/Titulo
@onready var fade: ColorRect = $Fade
@onready var tela_nome: Control = %TelaNome
@onready var campo_nome: LineEdit = %NomeJogador
@onready var botao_continuar: Button = %BotaoContinuar

var etapa := 0            ## 0 = personagem, 1 = cabelo, 2 = mochila
var i_pers := 0
var i_cab := 0
var i_moch := 1
var _travado := false


func _ready() -> void:
	resized.connect(_ajustar_tela)
	_ajustar_tela()
	for c in cards():
		c.clicado.connect(func(card): _clicar(0, cards().find(card)))
	for c in cabelos():
		c.clicado.connect(func(card): _clicar(1, cabelos().find(card)))
	for m in mochilas():
		m.clicado.connect(func(card): _clicar(2, mochilas().find(card)))
	$Tela/BotaoEsquerda.pressed.connect(func(): etapa = 0; mover(-1))
	$Tela/BotaoDireita.pressed.connect(func(): etapa = 0; mover(1))
	campo_nome.text_changed.connect(_atualizar_botao_continuar)
	campo_nome.text_submitted.connect(_enviar_nome_pelo_teclado)
	%BotaoVoltar.pressed.connect(_voltar_do_nome)
	botao_continuar.pressed.connect(_confirmar_nome)
	campo_nome.text = PersonagemEscolhido.nome_jogador
	_atualizar_botao_continuar(campo_nome.text)
	i_pers = clampi(PersonagemEscolhido.indice, 0, cards().size() - 1)
	i_cab = clampi(PersonagemEscolhido.indice_cabelo, 0, cabelos().size() - 1)
	i_moch = clampi(PersonagemEscolhido.indice_mochila, 0, mochilas().size() - 1)
	_atualizar()
	fade.modulate.a = 1.0
	create_tween().tween_property(fade, "modulate:a", 0.0, 0.35)


func cards() -> Array:
	return caixa_cards.get_children().filter(func(n): return n is CardPersonagem)


func cabelos() -> Array:
	return caixa_cabelos.get_children().filter(func(n): return n is CardCabelo)


func mochilas() -> Array:
	return caixa_mochilas.get_children().filter(func(n): return n is CardMochila)


func _ajustar_tela() -> void:
	var s := minf(size.x / TAMANHO.x, size.y / TAMANHO.y)
	tela.scale = Vector2(s, s)
	tela.position = ((size - TAMANHO * s) / 2.0).round()


func _input(event: InputEvent) -> void:
	if tela_nome.visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_voltar_do_nome()


func _unhandled_input(event: InputEvent) -> void:
	if _travado or tela_nome.visible:
		return
	if event.is_action_pressed(&"ui_left") or _tecla(event, KEY_A):
		mover(-1)
	elif event.is_action_pressed(&"ui_right") or _tecla(event, KEY_D):
		mover(1)
	elif event.is_action_pressed(&"ui_up") or _tecla(event, KEY_W):
		_mudar_etapa(etapa - 1)
	elif event.is_action_pressed(&"ui_down") or _tecla(event, KEY_S):
		_mudar_etapa(etapa + 1)
	elif event.is_action_pressed(&"ui_accept"):
		SomBotoes.tocar_clique()
		if etapa < 2:
			_mudar_etapa(etapa + 1)
		else:
			confirmar()
	elif event.is_action_pressed(&"ui_cancel"):
		_mudar_etapa(etapa - 1)


func _tecla(event: InputEvent, key: Key) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).physical_keycode == key


func mover(direcao: int) -> void:
	if _travado:
		return
	match etapa:
		0:
			i_pers = wrapi(i_pers + direcao, 0, cards().size())
			_piscar($Tela/BotaoEsquerda/Brilho if direcao < 0 else $Tela/BotaoDireita/Brilho)
		1:
			i_cab = wrapi(i_cab + direcao, 0, cabelos().size())
		2:
			i_moch = wrapi(i_moch + direcao, 0, mochilas().size())
	_atualizar()


func _mudar_etapa(e: int) -> void:
	etapa = clampi(e, 0, 2)
	_atualizar()


func _atualizar() -> void:
	var lista_c := cards()
	var lista_cab := cabelos()
	var lista_m := mochilas()
	var cab: CabeloDados = lista_cab[i_cab].dados
	var cor_m: Color = lista_m[i_moch].dados.cor if lista_m[i_moch].dados else Color.WHITE
	# personagens: todos mostram a cor de cabelo e de mochila escolhidas
	for i in lista_c.size():
		var c: CardPersonagem = lista_c[i]
		c.ativo = etapa == 0
		c.mostrar_mochila = etapa == 2
		c.indice_cabelo = cab.indice if cab else 0
		c.cor_mochila = cor_m
		if c.selecionado != (i == i_pers):
			c.set_selecionado(i == i_pers)
	# cabelos: mostram a cabeça do personagem selecionado
	var pers: PersonagemDados = lista_c[i_pers].dados
	for i in lista_cab.size():
		var k: CardCabelo = lista_cab[i]
		k.ativo = etapa == 1
		if k.personagem != pers:
			k.personagem = pers
		if k.selecionado != (i == i_cab):
			k.set_selecionado(i == i_cab)
	for i in lista_m.size():
		var m: CardMochila = lista_m[i]
		m.ativo = etapa == 2
		if m.selecionado != (i == i_moch):
			m.set_selecionado(i == i_moch)
	# o painel de baixo mostra cabelos (etapas 0 e 1) ou mochilas (etapa 2)
	caixa_cabelos.visible = etapa < 2
	caixa_mochilas.visible = etapa == 2
	titulo.text = TITULOS[etapa]


func _piscar(brilho: CanvasItem) -> void:
	brilho.modulate.a = 0.55
	create_tween().tween_property(brilho, "modulate:a", 0.0, 0.2)


# --- mouse ---

func _clicar(e: int, i: int) -> void:
	if _travado or i < 0:
		return
	match e:
		0: i_pers = i
		1: i_cab = i
		2: i_moch = i
	_mudar_etapa(e + 1)
	if e == 2:
		confirmar()


# --- confirmação ---

func confirmar() -> void:
	if _travado or tela_nome.visible:
		return
	cards()[i_pers].piscar()
	mochilas()[i_moch].piscar()
	if Partida.foi_iniciada() and not Partida.nome_jogador.is_empty():
		_confirmar_escolha(Partida.nome_jogador)
		return
	tela_nome.show()
	campo_nome.grab_focus()
	campo_nome.edit()
	campo_nome.caret_column = campo_nome.text.length()


func _voltar_do_nome() -> void:
	if not _travado:
		tela_nome.hide()


func _atualizar_botao_continuar(nome: String) -> void:
	botao_continuar.disabled = nome.strip_edges().is_empty()


func _enviar_nome_pelo_teclado(_nome: String) -> void:
	if not botao_continuar.disabled and not _travado:
		SomBotoes.tocar_clique()
		_confirmar_nome()


func _confirmar_nome() -> void:
	var nome := campo_nome.text.strip_edges()
	if _travado or nome.is_empty():
		return
	_confirmar_escolha(nome)


func _confirmar_escolha(nome: String) -> void:
	var primeiro_nome := PersonagemEscolhido.nome_jogador.is_empty()
	_travado = true
	var card: CardPersonagem = cards()[i_pers]
	var cab: CardCabelo = cabelos()[i_cab]
	var moch: CardMochila = mochilas()[i_moch]
	PersonagemEscolhido.indice = i_pers
	PersonagemEscolhido.indice_cabelo = i_cab
	PersonagemEscolhido.indice_mochila = i_moch
	PersonagemEscolhido.dados = card.dados
	PersonagemEscolhido.cabelo = cab.dados
	PersonagemEscolhido.mochila = moch.dados
	PersonagemEscolhido.nome_jogador = nome
	escolha_confirmada.emit(card.dados, cab.dados, moch.dados)
	if proxima_cena != "" and ResourceLoader.exists(proxima_cena):
		var f := create_tween()
		f.tween_property(fade, "modulate:a", 1.0, 0.35)
		await f.finished
		if primeiro_nome:
			var comandante := CENA_COMANDANTE.instantiate()
			comandante.apresentacao = true
			add_child(comandante)
			await comandante.apresentacao_concluida
		if get_tree().change_scene_to_file(proxima_cena) == OK:
			return
		create_tween().tween_property(fade, "modulate:a", 0.0, 0.35)
	else:
		if proxima_cena != "":
			push_warning("Seleção de personagem: cena não encontrada: " + proxima_cena)
	_travado = false
