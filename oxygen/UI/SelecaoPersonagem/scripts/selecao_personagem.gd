extends Control
## Tela de seleção: personagem -> cor do cabelo -> cor da mochila.
## Cada card é uma cena separada (cards/*.tscn) que puxa o seu .tres
## (personagens/*.tres, cabelos/*.tres, mochilas/*.tres).
##
## Teclado / controle:
##   ← → (ou A / D)   troca dentro da etapa ativa
##   ↑ ↓ (ou W / S)   muda de etapa
##   Enter / Espaço   avança para a próxima etapa (na última, confirma)
##   Esc / Backspace  volta uma etapa
## Mouse: clicar escolhe (em qualquer etapa, então dá para voltar e trocar);
## clicar de novo no escolhido ou em PRÓXIMO avança; VOLTAR ou botão direito volta.

signal escolha_confirmada(personagem: PersonagemDados, cabelo: CabeloDados, mochila: MochilaDados)

const TAMANHO := Vector2(1536, 1024)
const TITULOS := ["— ESCOLHA SEU PERSONAGEM —", "— ESCOLHA A COR DO CABELO —", "— ESCOLHA A COR DA MOCHILA —"]

## Cena aberta depois de confirmar (vazio = fica nesta tela)
@export_file("*.tscn") var proxima_cena := "res://Mapa/mapa.tscn"

@onready var tela: Control = $Tela
@onready var caixa_cards: Control = $Tela/Cards
@onready var caixa_cabelos: Control = $Tela/Cabelos
@onready var caixa_mochilas: Control = $Tela/Mochilas
@onready var titulo: Label = $Tela/Titulo
@onready var fade: ColorRect = $Fade

var etapa := 0            ## 0 = personagem, 1 = cabelo, 2 = mochila
var i_pers := 0
var i_cab := 0
var i_moch := 1
var _travado := false
var _bt_voltar: Button
var _bt_proximo: Button


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
	i_pers = clampi(PersonagemEscolhido.indice, 0, cards().size() - 1)
	i_cab = clampi(PersonagemEscolhido.indice_cabelo, 0, cabelos().size() - 1)
	i_moch = clampi(PersonagemEscolhido.indice_mochila, 0, mochilas().size() - 1)
	_criar_botoes()
	_atualizar()
	SomJogo.tocar_trilha(get_tree())
	fade.visible = true
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


func _unhandled_input(event: InputEvent) -> void:
	if _travado:
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
		if etapa < 2:
			_mudar_etapa(etapa + 1)
		else:
			confirmar()
	elif event.is_action_pressed(&"ui_cancel") or _tecla(event, KEY_BACKSPACE) or _botao_direito(event):
		_mudar_etapa(etapa - 1)


func _botao_direito(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT


## Botões grandes VOLTAR / PRÓXIMO embaixo do painel (para quem joga só com o mouse)
func _criar_botoes() -> void:
	_bt_voltar = _novo_botao("◀  VOLTAR", Rect2(264, 922, 300, 70))
	_bt_proximo = _novo_botao("PRÓXIMO  ▶", Rect2(970, 922, 300, 70))
	_bt_voltar.pressed.connect(_voltar)
	_bt_proximo.pressed.connect(_avancar)


func _novo_botao(texto: String, r: Rect2) -> Button:
	var b := Button.new()
	b.text = texto
	b.position = r.position
	b.size = r.size
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if titulo.label_settings and titulo.label_settings.font:
		b.add_theme_font_override("font", titulo.label_settings.font)
	b.add_theme_font_size_override("font_size", 34)
	b.add_theme_color_override("font_color", Color("f6e3b0"))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	for estado in ["normal", "hover", "pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("1d3a4a") if estado == "normal" else Color("2b5a70")
		sb.border_color = Color("d9a441")
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(6)
		b.add_theme_stylebox_override(estado, sb)
	tela.add_child(b)
	return b


func _voltar() -> void:
	if not _travado:
		_mudar_etapa(etapa - 1)


func _avancar() -> void:
	if _travado:
		return
	if etapa < 2:
		_mudar_etapa(etapa + 1)
	else:
		confirmar()


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
	SomJogo.som(get_tree())
	_atualizar()


func _mudar_etapa(e: int) -> void:
	var nova := clampi(e, 0, 2)
	if nova != etapa:
		# avançar soa um pouco mais agudo, voltar um pouco mais grave
		SomJogo.som(get_tree(), 1.2 if nova > etapa else 0.85)
	etapa = nova
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
	if _bt_voltar:
		_bt_voltar.visible = etapa > 0
		_bt_proximo.text = "JOGAR!  ▶" if etapa == 2 else "PRÓXIMO  ▶"


func _piscar(brilho: CanvasItem) -> void:
	brilho.modulate.a = 0.55
	create_tween().tween_property(brilho, "modulate:a", 0.0, 0.2)


# --- mouse ---

func _focar(e: int, i: int) -> void:
	if _travado or i < 0:
		return
	if e != etapa or i != ([i_pers, i_cab, i_moch][e] as int):
		SomJogo.som(get_tree())
	etapa = e
	match e:
		0: i_pers = i
		1: i_cab = i
		2: i_moch = i
	_atualizar()


func _clicar(e: int, i: int) -> void:
	if _travado or i < 0:
		return
	var atual := [i_pers, i_cab, i_moch][e] as int
	if e == etapa and i == atual:
		_avancar()
	else:
		# clicar em outro card troca a escolha, mesmo de uma etapa anterior
		_focar(e, i)


# --- confirmação ---

func confirmar() -> void:
	if _travado:
		return
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
	escolha_confirmada.emit(card.dados, cab.dados, moch.dados)
	SomJogo.som(get_tree(), 1.5)
	card.piscar()
	await moch.piscar().finished
	if proxima_cena != "" and ResourceLoader.exists(proxima_cena):
		var f := create_tween()
		f.tween_property(fade, "modulate:a", 1.0, 0.35)
		await f.finished
		get_tree().change_scene_to_file(proxima_cena)
	else:
		if proxima_cena != "":
			push_warning("Seleção de personagem: cena não encontrada: " + proxima_cena)
		_travado = false
