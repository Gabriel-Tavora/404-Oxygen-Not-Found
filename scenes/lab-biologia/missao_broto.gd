extends Control

signal fechado
signal concluido

enum Etapa { ESCOLHER_SEMENTE, COBRIR, CRESCIMENTO, FOLHAS, MUDA_GUARDADA }
enum Umidade { SECA, UMIDA, ENCHARCADA }

const INSTRUCAO_PLANTIO := "Vamos plantar um feijão!\nArraste a semente ou use o botão."
const INSTRUCAO_TERRA := "O feijão está no vaso.\nCubra a semente com um pouco de terra."
const INSTRUCAO_REGADOR := "A terra está seca. Regue o vaso!"
const INSTRUCAO_ARRASTE_REGADOR := "Segure o regador sobre o vaso."
const INSTRUCAO_LUZ := "O broto apareceu!\nLeve o vaso para perto da janela."
const INSTRUCAO_EXCESSO := "Tem água demais! Escorra o excesso."
const INSTRUCAO_LUPA := "Escolha uma parte iluminada da planta."
const DESCOBERTAS := [
	"A raiz absorve água da terra.",
	"O broto cresce para cima\ne carrega as primeiras folhas.",
	"As folhas usam a luz\npara ajudar a planta a crescer.",
]
const ROTULOS_TERRA := ["Terra seca", "Terra úmida", "Terra encharcada"]
const ROTULOS_PARTES := ["Raiz", "Broto", "Folhas"]
const CORES_TERRA := [Color.WHITE, Color("#d2ba9c"), Color("#a6a9a5")]
const POSICAO_VASO_NA_LUZ := 64.0
const POSICAO_UMIDADE_NA_LUZ := 146.0
const TEMPO_PARA_UMEDECER := 0.45
const TEMPO_PARA_ENCHARCAR := 1.0
const BOCA_DO_VASO := Vector2(40, 0)
const POSICAO_REGADOR_SOBRE_VASO := Vector2(36, -19)

@export var fase_pendente: StyleBox
@export var fase_atual: StyleBox
@export var fase_completa: StyleBox

@onready var _semente: Button = $Janela/Bancada/Sementes
@onready var _feijao_no_saco: TextureRect = $Janela/Bancada/Sementes/Feijao
@onready var _terra_na_bancada: Button = $Janela/Bancada/Terra
@onready var _icone_terra: TextureRect = $Janela/Bancada/Terra/Icone
@onready var _vaso: Button = $Janela/Bancada/Vaso
@onready var _acima_do_vaso: Control = $Janela/Bancada/Vaso/Acima
@onready var _feijao_no_vaso: TextureRect = $Janela/Bancada/Vaso/Feijao
@onready var _terra: TextureRect = $Janela/Bancada/Vaso/Terra
@onready var _poca: TextureRect = $Janela/Bancada/Vaso/Poca
@onready var _agua: Node2D = $Janela/Bancada/Vaso/Agua
@onready var _regador_sobre_vaso: TextureRect = $Janela/Bancada/Vaso/RegadorEmUso
@onready var _raiz: TextureRect = $Janela/Bancada/Vaso/Raiz
@onready var _broto: TextureRect = $Janela/Bancada/Vaso/Broto
@onready var _folhas: TextureRect = $Janela/Bancada/Vaso/Folhas
@onready var _luz: TextureRect = $Janela/Bancada/Luz
@onready var _feixe: Node2D = $Janela/Bancada/Feixe
@onready var _lupa: Button = $Janela/Lupa
@onready var _nome_lupa: Label = $Janela/Lupa/Nome
@onready var _ampliacao: Panel = $Janela/Ampliacao
@onready var _nome_detalhe: Label = $Janela/Ampliacao/Detalhe
@onready var _centro_lupa: ColorRect = $Janela/Ampliacao/Ponto
@onready var _alvos_lupa: Array[Button] = [
	$Janela/Bancada/Vaso/ObservarRaiz,
	$Janela/Bancada/Vaso/ObservarBroto,
	$Janela/Bancada/Vaso/ObservarFolhas,
]
@onready var _imagens_lupa: Array[TextureRect] = [
	$Janela/Ampliacao/Raiz,
	$Janela/Ampliacao/Broto,
	$Janela/Ampliacao/Folhas,
]
@onready var _painel_umidade: Panel = $Janela/Bancada/Umidade
@onready var _estado_terra: Label = $Janela/Bancada/Umidade/EstadoTerra
@onready var _gotas: Array[TextureRect] = [
	$Janela/Bancada/Umidade/Gota1,
	$Janela/Bancada/Umidade/Gota2,
	$Janela/Bancada/Umidade/Gota3,
]
@onready var _instrucao: Label = $Janela/Instrucao
@onready var _dia: Label = $Janela/Calendario/Dia
@onready var _fases: Array[Panel] = [
	$Janela/Crescimento/Fase1,
	$Janela/Crescimento/Fase2,
	$Janela/Crescimento/Fase3,
	$Janela/Crescimento/Fase4,
]
@onready var _plantar: Button = $Janela/Plantar
@onready var _cobrir: Button = $Janela/Cobrir
@onready var _regar_vaso: Button = $Janela/Regar
@onready var _escorrer: Button = $Janela/Escorrer
@onready var _mover: Button = $Janela/MoverParaLuz
@onready var _proximo_dia: Button = $Janela/ProximoDia
@onready var _regador: Button = $Janela/Regador
@onready var _icone_regador: TextureRect = $Janela/Regador/Icone
@onready var _bandeja: TextureRect = $Janela/Bandeja
@onready var _muda_na_bandeja: TextureRect = $Janela/Bandeja/MudaFeijao
@onready var _guardar_muda: Button = $Janela/GuardarMuda
@onready var _voltar: Button = $Janela/Voltar
@onready var _efeitos: Node2D = $Janela/Efeitos

var _etapa := Etapa.ESCOLHER_SEMENTE
var _umidade := Umidade.SECA
var _dias_passados := 0
var _vaso_na_luz := false
var _movendo_vaso := false
var _item_arrastado: Button
var _queda_em_curso := false
var _previa_regador: TextureRect
var _tempo_regando := 0.0
var _despejando := false
var _rega_por_selecao := false
var _posicao_ponteiro := Vector2.ZERO
var _instrucao_antes_da_lupa := ""


func _ready() -> void:
	_instrucao.text = INSTRUCAO_PLANTIO
	_dia.add_theme_font_override("font", ThemeDB.fallback_font)
	_atualizar_fases()
	_atualizar_umidade()
	_atualizar_acao()
	_semente.toggled.connect(_selecionar_semente)
	_semente.set_drag_forwarding(
		_arrastar_material.bind(_semente, _feijao_no_saco), Callable(), Callable()
	)
	_terra_na_bancada.toggled.connect(_selecionar_terra)
	_terra_na_bancada.set_drag_forwarding(
		_arrastar_material.bind(_terra_na_bancada, _icone_terra), Callable(), Callable()
	)
	_vaso.pressed.connect(_usar_vaso)
	_vaso.set_drag_forwarding(Callable(), _pode_receber_material, _soltar_material)
	_acima_do_vaso.set_drag_forwarding(Callable(), _pode_receber_material, _soltar_acima_do_vaso)
	_plantar.pressed.connect(_soltar_material.bind(BOCA_DO_VASO, _semente))
	_cobrir.pressed.connect(_soltar_material.bind(BOCA_DO_VASO, _terra_na_bancada))
	_regar_vaso.pressed.connect(_iniciar_rega)
	_regador.toggled.connect(_selecionar_regador)
	_regador.set_drag_forwarding(_arrastar_regador, Callable(), Callable())
	_lupa.toggled.connect(_alternar_lupa)
	for indice in range(_alvos_lupa.size()):
		var alvo := _alvos_lupa[indice]
		alvo.mouse_entered.connect(_observar.bind(indice))
		alvo.pressed.connect(_observar.bind(indice))
	_agua.draw.connect(_desenhar_agua)
	_feixe.draw.connect(_desenhar_feixe)
	_escorrer.pressed.connect(_escorrer_excesso)
	_mover.pressed.connect(_mover_para_luz)
	_proximo_dia.pressed.connect(_avancar_dia)
	_guardar_muda.pressed.connect(_colocar_na_bandeja)
	_voltar.pressed.connect(_fechar)
	_plantar.grab_focus()
	set_process(false)


func _notification(what: int) -> void:
	if what != NOTIFICATION_DRAG_END or _item_arrastado == null:
		return
	var item := _item_arrastado
	_item_arrastado = null
	item.set_pressed_no_signal(false)
	if item == _regador:
		_encerrar_arraste_regador()
	elif not _queda_em_curso:
		_feijao_no_saco.visible = item == _semente
		_icone_terra.show()
		_instrucao.text = INSTRUCAO_PLANTIO if item == _semente else INSTRUCAO_TERRA
		item.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		if _lupa.button_pressed:
			_fechar_lupa()
			_lupa.grab_focus()
		else:
			_fechar()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_posicao_ponteiro = event.position


func _process(delta: float) -> void:
	if _item_arrastado == _regador:
		var area := Rect2(Vector2.ZERO, _vaso.size).grow_individual(0, 24, 0, 0)
		var posicao_local := _vaso.get_global_transform_with_canvas().affine_inverse() * _posicao_ponteiro
		var sobre_o_vaso := area.has_point(posicao_local)
		var pode_despejar := sobre_o_vaso and not _regador.disabled
		_previa_regador.visible = not pode_despejar
		if pode_despejar != _despejando:
			_mostrar_rega(pode_despejar)
			_instrucao.text = "A água está caindo no vaso!" if pode_despejar else INSTRUCAO_ARRASTE_REGADOR

	if not _despejando:
		return
	_tempo_regando += delta
	_agua.queue_redraw()
	if _rega_por_selecao and _tempo_regando >= TEMPO_PARA_UMEDECER:
		_rega_por_selecao = false
		_mostrar_rega(false)
		set_process(false)
		_regar()
	elif _umidade == Umidade.SECA and _tempo_regando >= TEMPO_PARA_UMEDECER:
		_regar()
		_tempo_regando = 0.0
	elif _umidade == Umidade.UMIDA and _tempo_regando >= TEMPO_PARA_ENCHARCAR:
		_regar()


func _fechar() -> void:
	fechado.emit()


func _selecionar_semente(selecionada: bool) -> void:
	if selecionada:
		_instrucao.text = "Agora escolha o vaso."
		_vaso.grab_focus()
	else:
		_instrucao.text = INSTRUCAO_PLANTIO


func _selecionar_terra(selecionada: bool) -> void:
	_instrucao.text = "Agora escolha o vaso para colocar a terra." if selecionada else INSTRUCAO_TERRA
	if selecionada:
		_vaso.grab_focus()


func _arrastar_material(_posicao: Vector2, item: Button, icone: TextureRect) -> Variant:
	if not _pode_receber_material(Vector2.ZERO, item):
		return null
	var previa := _criar_imagem(icone)
	previa.position = -previa.size / 2.0
	item.set_drag_preview(previa)
	_item_arrastado = item
	icone.hide()
	_instrucao.text = "Solte o feijão sobre o vaso." if item == _semente else "Solte a terra sobre o vaso."
	return item


func _criar_imagem(icone: TextureRect) -> TextureRect:
	var imagem := TextureRect.new()
	imagem.texture = icone.texture
	imagem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	imagem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	imagem.size = icone.size
	return imagem


func _pode_receber_material(_posicao: Vector2, dado: Variant) -> bool:
	return not _queda_em_curso and (
		(_etapa == Etapa.ESCOLHER_SEMENTE and dado == _semente)
		or (_etapa == Etapa.COBRIR and dado == _terra_na_bancada)
	)


func _soltar_acima_do_vaso(posicao: Vector2, item: Button) -> void:
	_soltar_material(posicao + _acima_do_vaso.position, item)


func _soltar_material(posicao: Vector2, item: Button) -> void:
	if not _pode_receber_material(posicao, item):
		return
	_queda_em_curso = true
	item.set_pressed_no_signal(false)
	item.disabled = true
	_vaso.disabled = true
	_atualizar_acao()
	var e_semente := item == _semente
	var destino := _feijao_no_vaso if e_semente else _terra
	var origem := _feijao_no_saco if e_semente else _icone_terra
	origem.hide()
	var imagem := _criar_imagem(destino)
	_vaso.add_child(imagem)
	var deslocamento := clampf(posicao.x - BOCA_DO_VASO.x, -7.0, 7.0)
	imagem.position = Vector2(destino.position.x + deslocamento, -12.0)
	var queda := create_tween()
	queda.tween_property(imagem, "position", destino.position, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await queda.finished
	imagem.queue_free()
	_queda_em_curso = false
	if e_semente:
		_colocar_semente()
	else:
		_cobrir_com_terra()


func _usar_vaso() -> void:
	if _queda_em_curso or _despejando or _movendo_vaso or _lupa.button_pressed:
		return
	if _etapa == Etapa.CRESCIMENTO:
		if _regador.button_pressed:
			_iniciar_rega()
		else:
			_instrucao.text = _instrucao_cuidado()
		return
	if _etapa == Etapa.COBRIR:
		if _terra_na_bancada.button_pressed:
			_soltar_material(BOCA_DO_VASO, _terra_na_bancada)
		else:
			_terra_na_bancada.grab_focus()
	elif _semente.button_pressed:
		_soltar_material(BOCA_DO_VASO, _semente)
	else:
		_semente.grab_focus()


func _colocar_semente() -> void:
	if _etapa != Etapa.ESCOLHER_SEMENTE:
		return
	_etapa = Etapa.COBRIR
	_semente.hide()
	_vaso.disabled = false
	_feijao_no_vaso.show()
	_instrucao.text = INSTRUCAO_TERRA
	_terra_na_bancada.show()
	_estourar_pixels(_feijao_no_vaso, Color("#e8af75"), 5)
	_atualizar_acao().grab_focus()


func _cobrir_com_terra() -> void:
	if _etapa != Etapa.COBRIR:
		return
	_etapa = Etapa.CRESCIMENTO
	_terra.show()
	_terra_na_bancada.hide()
	_painel_umidade.show()
	_vaso.disabled = false
	_regador.disabled = false
	_regador.show()
	_instrucao.text = INSTRUCAO_REGADOR
	_estourar_pixels(_terra, Color("#d6a06c"), 6)
	_atualizar_acao().grab_focus()


func _iniciar_rega() -> void:
	if _regador.disabled or _despejando or _movendo_vaso or _lupa.button_pressed:
		return
	_regador.set_pressed_no_signal(false)
	_rega_por_selecao = true
	_instrucao.text = "A água está caindo no vaso!"
	_mostrar_rega(true)
	set_process(true)


func _selecionar_regador(selecionado: bool) -> void:
	if selecionado:
		_instrucao.text = "Agora escolha o vaso para regar."
		_vaso.grab_focus()
	else:
		_instrucao.text = _instrucao_cuidado()


func _alternar_lupa(selecionada: bool) -> void:
	if not selecionada:
		_fechar_lupa()
		return
	if _despejando or _movendo_vaso or _item_arrastado != null:
		_lupa.set_pressed_no_signal(false)
		return
	_instrucao_antes_da_lupa = _instrucao_cuidado() if _regador.button_pressed else _instrucao.text
	_instrucao.text = INSTRUCAO_LUPA
	_regador.set_pressed_no_signal(false)
	_regador.hide()
	_bandeja.hide()
	_nome_lupa.text = "Fechar"
	_lupa.accessibility_name = "Fechar lupa"
	_centro_lupa.show()
	_nome_detalhe.text = "Lupa"
	_ampliacao.show()
	_atualizar_acao()
	_alvos_lupa[0].visible = _raiz.visible
	_alvos_lupa[1].visible = _broto.visible
	_alvos_lupa[2].visible = _folhas.visible
	_alvos_lupa[0].grab_focus()


func _observar(indice: int) -> void:
	if not _lupa.button_pressed or not _alvos_lupa[indice].visible:
		return
	for imagem in _imagens_lupa:
		imagem.hide()
	_centro_lupa.hide()
	_imagens_lupa[indice].show()
	_nome_detalhe.text = ROTULOS_PARTES[indice]
	_instrucao.text = DESCOBERTAS[indice]


func _fechar_lupa() -> void:
	if not _ampliacao.visible:
		return
	_lupa.set_pressed_no_signal(false)
	_nome_lupa.text = "Lupa"
	_lupa.accessibility_name = "Lupa"
	_ampliacao.hide()
	for alvo in _alvos_lupa:
		alvo.hide()
	for imagem in _imagens_lupa:
		imagem.hide()
	_regador.visible = _etapa == Etapa.CRESCIMENTO
	_bandeja.visible = _etapa == Etapa.FOLHAS
	_instrucao.text = _instrucao_antes_da_lupa
	_atualizar_acao()


func _arrastar_regador(_posicao: Vector2) -> Variant:
	if _regador.disabled or _despejando or _movendo_vaso:
		return null
	_previa_regador = _criar_imagem(_icone_regador)
	_previa_regador.position = -_previa_regador.size / 2.0
	_regador.set_drag_preview(_previa_regador)
	_regador.set_pressed_no_signal(false)
	_icone_regador.hide()
	_item_arrastado = _regador
	_instrucao.text = INSTRUCAO_ARRASTE_REGADOR
	set_process(true)
	return _regador


func _encerrar_arraste_regador() -> void:
	_previa_regador = null
	_icone_regador.show()
	_mostrar_rega(false)
	set_process(false)
	_instrucao.text = _instrucao_cuidado()
	_atualizar_acao().grab_focus()


func _mostrar_rega(visivel: bool) -> void:
	_despejando = visivel
	_tempo_regando = 0.0
	_agua.visible = visivel
	_regador_sobre_vaso.position = POSICAO_REGADOR_SOBRE_VASO
	_regador_sobre_vaso.visible = visivel
	_atualizar_acao()


func _desenhar_agua() -> void:
	var ciclo := fposmod(_tempo_regando * 88.0, 9.0)
	for indice in range(4):
		var altura := floorf(ciclo + indice * 9.0)
		var gota := Vector2(42.0 + (indice % 2) * 3.0, altura + 2.0)
		_agua.draw_rect(Rect2(gota, Vector2(2, 5)), Color("#75cbd6"))
		_agua.draw_rect(Rect2(gota + Vector2(0, 1), Vector2(1, 2)), Color("#c2f1ee"))


func _desenhar_feixe() -> void:
	_feixe.draw_colored_polygon(
		PackedVector2Array([Vector2(72, 29), Vector2(98, 29), Vector2(139, 87), Vector2(69, 87)]),
		Color("#ffe7a23c")
	)


func _regar() -> void:
	_regador.set_pressed_no_signal(false)
	if _umidade == Umidade.SECA:
		_umidade = Umidade.UMIDA
		_instrucao.text = "Já está úmida. Solte o regador!" if _despejando else _instrucao_cuidado()
		_estourar_pixels(_terra, Color("#a5e2e2"), 6)
	else:
		_umidade = Umidade.ENCHARCADA
		_instrucao.text = INSTRUCAO_EXCESSO
	_atualizar_umidade()
	# Solte o regador antes de passar para a próxima ação.
	var acao := _atualizar_acao()
	if not _despejando:
		acao.grab_focus()


func _atualizar_umidade() -> void:
	_estado_terra.text = ROTULOS_TERRA[_umidade]
	_terra.modulate = CORES_TERRA[_umidade]
	var gotas_ativas := [0, 2, 3]
	for indice in range(_gotas.size()):
		_gotas[indice].modulate.a = 1.0 if indice < gotas_ativas[_umidade] else 0.2
	var encharcada := _umidade == Umidade.ENCHARCADA
	_poca.visible = encharcada
	_regador.disabled = _etapa != Etapa.CRESCIMENTO or encharcada
	_regador.modulate.a = 0.62 if encharcada else 1.0


func _escorrer_excesso() -> void:
	_umidade = Umidade.UMIDA
	_atualizar_umidade()
	_instrucao.text = _instrucao_cuidado()
	_atualizar_acao().grab_focus()


func _instrucao_cuidado() -> String:
	if _umidade == Umidade.SECA:
		return INSTRUCAO_REGADOR
	if _umidade == Umidade.ENCHARCADA:
		return INSTRUCAO_EXCESSO
	if _dias_passados == 2 and not _vaso_na_luz:
		return INSTRUCAO_LUZ
	return "A terra está úmida! Veja o que cresce amanhã."


func _mover_para_luz() -> void:
	if _despejando or _movendo_vaso:
		return
	_movendo_vaso = true
	_regador.disabled = true
	_regador.set_pressed_no_signal(false)
	_atualizar_acao()
	var deslize := create_tween().set_trans(Tween.TRANS_SINE)
	deslize.tween_property(_painel_umidade, "modulate:a", 0.0, 0.10)
	deslize.parallel().tween_property(_vaso, "position:x", POSICAO_VASO_NA_LUZ, 0.38)
	deslize.tween_property(_painel_umidade, "position:x", POSICAO_UMIDADE_NA_LUZ, 0.0)
	deslize.tween_property(_painel_umidade, "modulate:a", 1.0, 0.10)
	await deslize.finished
	_vaso_na_luz = true
	_movendo_vaso = false
	_regador.disabled = false
	_estourar_pixels(_luz, Color("#f7df95"), 8)
	_instrucao.text = "O broto ganhou luz! Veja como ele cresce."
	_atualizar_acao().grab_focus()


func _avancar_dia() -> void:
	if _etapa != Etapa.CRESCIMENTO or _despejando or _movendo_vaso:
		return
	_fechar_lupa()
	_regador.set_pressed_no_signal(false)
	if _umidade != Umidade.UMIDA or (_dias_passados == 2 and not _vaso_na_luz):
		_instrucao.text = _instrucao_cuidado()
		return
	_dias_passados += 1
	_dia.text = "Dia %d" % (_dias_passados + 1)
	_atualizar_fases()
	match _dias_passados:
		1:
			_revelar(_raiz, Vector2(12, 0))
			_lupa.show()
			_instrucao.text = "Olhe embaixo da terra: nasceu uma raiz!\nUse a lupa para ver de perto."
		2:
			_revelar(_broto, Vector2(12, 54))
			_luz.show()
			_feixe.show()
			_instrucao.text = INSTRUCAO_LUZ
		3:
			_mostrar_folhas()
	_atualizar_acao().grab_focus()


func _mostrar_folhas() -> void:
	_etapa = Etapa.FOLHAS
	_broto.hide()
	_revelar(_folhas, _folhas.pivot_offset)
	_estourar_pixels(_folhas, Color("#d8e78b"), 10)
	_vaso.disabled = true
	_regador.disabled = true
	_regador.hide()
	_bandeja.show()
	_instrucao.text = "As folhas se abriram!\nAgora coloque a muda na bandeja."


func _colocar_na_bandeja() -> void:
	if _etapa != Etapa.FOLHAS:
		return
	_fechar_lupa()
	_etapa = Etapa.MUDA_GUARDADA
	_lupa.hide()
	_vaso.hide()
	_luz.hide()
	_feixe.hide()
	_painel_umidade.hide()
	_bandeja.position = Vector2(177, 115)
	_revelar(_muda_na_bandeja, Vector2(18, 36))
	_estourar_pixels(_muda_na_bandeja, Color("#f5de92"), 16)
	_instrucao.text = "Muda pronta! Você fez o feijão crescer.\nSua muda agora está na bandeja do laboratório."
	_atualizar_fases()
	_atualizar_acao()
	_voltar.grab_focus()
	concluido.emit()


func _atualizar_fases() -> void:
	for indice in range(_fases.size()):
		var fase := _fases[indice]
		var concluida := indice < _dias_passados or _etapa == Etapa.MUDA_GUARDADA
		var atual := indice == _dias_passados and not concluida
		var estilo := fase_completa if concluida else (fase_atual if atual else fase_pendente)
		fase.add_theme_stylebox_override("panel", estilo)
		var icone := fase.get_node("Icone") as TextureRect
		icone.modulate.a = 1.0 if concluida or atual else 0.48


func _atualizar_acao() -> Button:
	var acao: Button
	if not _lupa.button_pressed:
		match _etapa:
			Etapa.ESCOLHER_SEMENTE:
				acao = _plantar
			Etapa.COBRIR:
				acao = _cobrir
			Etapa.CRESCIMENTO:
				if _umidade == Umidade.SECA:
					acao = _regar_vaso
				elif _umidade == Umidade.ENCHARCADA:
					acao = _escorrer
				elif _dias_passados == 2 and not _vaso_na_luz:
					acao = _mover
				else:
					acao = _proximo_dia
			Etapa.FOLHAS:
				acao = _guardar_muda
	for botao in [_plantar, _cobrir, _regar_vaso, _escorrer, _mover, _proximo_dia, _guardar_muda]:
		botao.visible = botao == acao
		botao.disabled = _queda_em_curso or _despejando or _movendo_vaso
	return acao


func _revelar(imagem: TextureRect, pivo: Vector2) -> void:
	imagem.pivot_offset = pivo
	imagem.scale = Vector2(0.65, 0.4)
	imagem.show()
	create_tween().tween_property(imagem, "scale", Vector2.ONE, 0.34) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _estourar_pixels(alvo: Control, cor: Color, quantidade: int) -> void:
	var centro := _efeitos.to_local(alvo.get_global_rect().get_center())
	for indice in range(quantidade):
		var pixel := ColorRect.new()
		pixel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pixel.color = Color("#fff4cd") if indice % 3 == 0 else cor
		pixel.size = Vector2.ONE * (3 if indice % 3 == 0 else 2)
		_efeitos.add_child(pixel)
		pixel.position = centro
		var direcao := Vector2.from_angle(TAU * indice / quantidade)
		var destino := centro + (direcao * (18 + (indice % 3) * 7)).round()
		var brilho := create_tween().set_parallel()
		brilho.tween_property(pixel, "position", destino, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		brilho.tween_property(pixel, "modulate:a", 0.0, 0.32).set_delay(0.08)
		brilho.chain().tween_callback(pixel.queue_free)
