extends Control

signal fechado
signal concluido

enum Etapa { ESCOLHER_SEMENTE, COBRIR, CRESCIMENTO, FOLHAS, MUDA_GUARDADA }
enum Umidade { SECA, UMIDA, ENCHARCADA }

const INSTRUCAO_PLANTIO := "Arraste o feijão para dentro do vaso."
const INSTRUCAO_TERRA := "Arraste a terra para cobrir o feijão."
const INSTRUCAO_REGADOR := "Arraste o regador e segure sobre o vaso."
const INSTRUCAO_LUZ := "O broto apareceu!\nArraste o vaso para perto da janela."
const INSTRUCAO_EXCESSO := "Tem água demais!\nArraste o vaso para o local de escorrer."
const INSTRUCAO_MUDA := "As folhas se abriram!\nArraste a planta para a bandeja."
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
const AreaDeArraste := preload("res://scenes/lab-biologia/area_de_arraste_broto.gd")

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
@onready var _icone_lupa: TextureRect = $Janela/Lupa/Icone
@onready var _ampliacao: Panel = $Janela/Ampliacao
@onready var _nome_detalhe: Label = $Janela/Ampliacao/Detalhe
@onready var _alvos_lupa: Array[Panel] = [
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
@onready var _area_de_luz: Panel = $Janela/Bancada/AreaDeLuz
@onready var _drenagem: Panel = $Janela/Drenagem
@onready var _proximo_dia: Button = $Janela/ProximoDia
@onready var _regador: Button = $Janela/Regador
@onready var _icone_regador: TextureRect = $Janela/Regador/Icone
@onready var _bandeja: TextureRect = $Janela/Bandeja
@onready var _contorno_bandeja: Panel = $Janela/Bandeja/Contorno
@onready var _muda_na_bandeja: TextureRect = $Janela/Bandeja/MudaFeijao
@onready var _voltar: Button = $Janela/Voltar
@onready var _resultado: ResultadoMissao = $Resultado
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
var _posicao_ponteiro := Vector2.ZERO
var _ajuste_previa_vaso := Vector2.ZERO
var _instrucao_antes_do_arraste := ""
var _instrucao_antes_da_lupa := ""
var _pulso_bandeja: Tween


func _ready() -> void:
	_instrucao.text = INSTRUCAO_PLANTIO
	_dia.add_theme_font_override("font", ThemeDB.fallback_font)
	_semente.set_drag_forwarding(
		_arrastar_material.bind(_semente, _feijao_no_saco), Callable(), Callable()
	)
	_terra_na_bancada.set_drag_forwarding(
		_arrastar_material.bind(_terra_na_bancada, _icone_terra), Callable(), Callable()
	)
	_vaso.set_drag_forwarding(_arrastar_vaso, _pode_receber_material, _soltar_material)
	_acima_do_vaso.set_drag_forwarding(_arrastar_vaso, _pode_receber_material, _soltar_acima_do_vaso)
	_regador.set_drag_forwarding(_arrastar_regador, Callable(), Callable())
	_lupa.set_drag_forwarding(_arrastar_lupa, Callable(), Callable())
	for indice in range(_alvos_lupa.size()):
		_alvos_lupa[indice].set_drag_forwarding(
			Callable(), _pode_soltar.bind(_lupa), _observar.bind(indice)
		)
	_area_de_luz.set_drag_forwarding(
		Callable(), _pode_soltar.bind(_vaso), _mover_para_luz
	)
	_drenagem.set_drag_forwarding(
		Callable(), _pode_soltar.bind(_vaso), _escorrer_excesso
	)
	_bandeja.set_drag_forwarding(
		Callable(), _pode_soltar.bind(_vaso), _colocar_na_bandeja
	)
	_agua.draw.connect(_desenhar_agua)
	_feixe.draw.connect(_desenhar_feixe)
	_proximo_dia.pressed.connect(_avancar_dia)
	_voltar.pressed.connect(_fechar)
	_resultado.voltar_solicitado.connect(_fechar)
	_atualizar_fases()
	_atualizar_umidade()
	_atualizar_controles()
	set_process(false)


func _notification(what: int) -> void:
	if what != NOTIFICATION_DRAG_END or _item_arrastado == null:
		return
	var item := _item_arrastado
	_item_arrastado = null
	if item == _regador:
		_encerrar_arraste_regador()
	elif item == _vaso:
		_vaso.modulate.a = 1.0
		if _etapa == Etapa.FOLHAS:
			_folhas.show()
	elif item == _lupa:
		for alvo in _alvos_lupa:
			alvo.hide()
	elif item == _semente:
		_feijao_no_saco.visible = not _queda_em_curso
	elif item == _terra_na_bancada:
		_icone_terra.visible = not _queda_em_curso
	if item != _regador and not get_viewport().gui_is_drag_successful():
		_instrucao.text = _instrucao_antes_do_arraste
	_atualizar_controles()


func _unhandled_input(event: InputEvent) -> void:
	if _etapa != Etapa.MUDA_GUARDADA and event.is_action_pressed(&"voltar_contexto"):
		get_viewport().set_input_as_handled()
		if _item_arrastado != null:
			get_viewport().gui_cancel_drag()
		elif _ampliacao.visible:
			_fechar_lupa()
		else:
			_fechar()


func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		_posicao_ponteiro = event.position


func _process(delta: float) -> void:
	var area := Rect2(Vector2.ZERO, _vaso.size).grow_individual(0, 24, 0, 0)
	area = area.grow(AreaDeArraste.MARGEM)
	var sobre_o_vaso := area.has_point(_vaso.make_canvas_position_local(_posicao_ponteiro))
	var pode_despejar := sobre_o_vaso and not _regador.disabled
	_previa_regador.visible = not pode_despejar
	if pode_despejar != _despejando:
		_mostrar_rega(pode_despejar)
		_instrucao.text = "A água está caindo no vaso!" if pode_despejar else INSTRUCAO_REGADOR
	if not _despejando:
		return
	_tempo_regando += delta
	_agua.queue_redraw()
	if _umidade == Umidade.SECA and _tempo_regando >= TEMPO_PARA_UMEDECER:
		_regar()
		_tempo_regando = 0.0
	elif _umidade == Umidade.UMIDA and _tempo_regando >= TEMPO_PARA_ENCHARCAR:
		_regar()


func _fechar() -> void:
	fechado.emit()


func _iniciar_arraste(item: Button, previa: Control, instrucao: String) -> void:
	_fechar_lupa()
	_instrucao_antes_do_arraste = _instrucao.text
	_item_arrastado = item
	item.set_drag_preview(previa)
	_instrucao.text = instrucao
	_atualizar_controles()


func _arrastar_material(_posicao: Vector2, item: Button, icone: TextureRect) -> Variant:
	if _queda_em_curso or not item.visible:
		return null
	var previa := _criar_imagem(icone)
	previa.position = -previa.size / 2.0
	icone.hide()
	var instrucao := "Solte o feijão sobre o vaso." if item == _semente else "Solte a terra sobre o vaso."
	_iniciar_arraste(item, previa, instrucao)
	return item


func _criar_imagem(icone: TextureRect) -> TextureRect:
	var imagem := TextureRect.new()
	imagem.texture = icone.texture
	imagem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	imagem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	imagem.size = icone.size
	return imagem


func _pode_soltar(_posicao: Vector2, dado: Variant, item: Button) -> bool:
	return _item_arrastado == item and dado == item


func _pode_receber_material(_posicao: Vector2, dado: Variant) -> bool:
	return not _queda_em_curso and dado == _item_arrastado and (
		(_etapa == Etapa.ESCOLHER_SEMENTE and dado == _semente)
		or (_etapa == Etapa.COBRIR and dado == _terra_na_bancada)
	)


func _soltar_acima_do_vaso(posicao: Vector2, item: Button) -> void:
	_soltar_material(posicao + _acima_do_vaso.position, item)


func _soltar_material(posicao: Vector2, item: Button) -> void:
	if not _pode_receber_material(posicao, item):
		return
	_queda_em_curso = true
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


func _colocar_semente() -> void:
	if _etapa != Etapa.ESCOLHER_SEMENTE:
		return
	_etapa = Etapa.COBRIR
	_semente.hide()
	_feijao_no_vaso.show()
	_instrucao.text = INSTRUCAO_TERRA
	_terra_na_bancada.show()
	_estourar_pixels(_feijao_no_vaso, Color("#e8af75"), 5)
	_atualizar_controles()


func _cobrir_com_terra() -> void:
	if _etapa != Etapa.COBRIR:
		return
	_etapa = Etapa.CRESCIMENTO
	_terra.show()
	_terra_na_bancada.hide()
	_painel_umidade.show()
	_regador.disabled = false
	_regador.show()
	_instrucao.text = INSTRUCAO_REGADOR
	_estourar_pixels(_terra, Color("#d6a06c"), 6)
	_atualizar_controles()


func _arrastar_lupa(_posicao: Vector2) -> Variant:
	if _movendo_vaso:
		return null
	var previa := _criar_imagem(_icone_lupa)
	previa.position = -previa.size / 2.0
	_iniciar_arraste(_lupa, previa, "Solte a lupa sobre uma parte destacada da planta.")
	_alvos_lupa[0].visible = _raiz.visible
	_alvos_lupa[1].visible = _broto.visible
	_alvos_lupa[2].visible = _folhas.visible
	return _lupa


func _observar(posicao: Vector2, dado: Variant, indice: int) -> void:
	if not _pode_soltar(posicao, dado, _lupa):
		return
	_instrucao_antes_da_lupa = _instrucao_antes_do_arraste
	_ampliacao.position.x = _painel_umidade.position.x + 8.0
	_painel_umidade.hide()
	_imagens_lupa[indice].show()
	_nome_detalhe.text = ROTULOS_PARTES[indice]
	_ampliacao.show()
	_instrucao.text = DESCOBERTAS[indice]


func _fechar_lupa() -> void:
	if not _ampliacao.visible:
		return
	_ampliacao.hide()
	for imagem in _imagens_lupa:
		imagem.hide()
	_painel_umidade.show()
	_instrucao.text = _instrucao_antes_da_lupa


func _arrastar_regador(_posicao: Vector2) -> Variant:
	if _regador.disabled or _movendo_vaso:
		return null
	_previa_regador = _criar_imagem(_icone_regador)
	_previa_regador.position = -_previa_regador.size / 2.0
	_icone_regador.hide()
	_iniciar_arraste(_regador, _previa_regador, INSTRUCAO_REGADOR)
	set_process(true)
	return _regador


func _encerrar_arraste_regador() -> void:
	set_process(false)
	_previa_regador = null
	_icone_regador.show()
	_mostrar_rega(false)
	_instrucao.text = _instrucao_cuidado()


func _mostrar_rega(visivel: bool) -> void:
	_despejando = visivel
	_tempo_regando = 0.0
	_agua.visible = visivel
	_regador_sobre_vaso.position = POSICAO_REGADOR_SOBRE_VASO
	_regador_sobre_vaso.visible = visivel


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
	if _umidade == Umidade.SECA:
		_umidade = Umidade.UMIDA
		_instrucao.text = "Já está úmida. Solte o regador!"
		_estourar_pixels(_terra, Color("#a5e2e2"), 6)
	else:
		_umidade = Umidade.ENCHARCADA
		_instrucao.text = INSTRUCAO_EXCESSO
	_atualizar_umidade()


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


func _escorrer_excesso(posicao: Vector2, dado: Variant) -> void:
	if not _precisa_drenar() or not _pode_soltar(posicao, dado, _vaso):
		return
	_movendo_vaso = true
	var origem := _vaso.position
	_vaso.position = _posicao_vaso_solto()
	_vaso.pivot_offset = Vector2(40, 32)
	var inclinacao := create_tween().set_trans(Tween.TRANS_SINE)
	inclinacao.tween_property(_vaso, "rotation", 0.85, 0.2)
	await inclinacao.finished
	_umidade = Umidade.UMIDA
	_atualizar_umidade()
	_estourar_pixels(_drenagem, Color("#a5e2e2"), 8)
	var retorno := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	retorno.tween_property(_vaso, "rotation", 0.0, 0.26)
	retorno.tween_property(_vaso, "position", origem, 0.26)
	await retorno.finished
	_movendo_vaso = false
	_instrucao.text = _instrucao_cuidado()
	_atualizar_controles()


func _instrucao_cuidado() -> String:
	if _umidade == Umidade.SECA:
		return INSTRUCAO_REGADOR
	if _umidade == Umidade.ENCHARCADA:
		return INSTRUCAO_EXCESSO
	if _dias_passados == 2 and not _vaso_na_luz:
		return INSTRUCAO_LUZ
	return "A terra está úmida! Veja o que cresce amanhã."


func _arrastar_vaso(_posicao: Vector2) -> Variant:
	if _movendo_vaso or not (_precisa_drenar() or _precisa_de_luz() or _etapa == Etapa.FOLHAS):
		return null
	if _etapa == Etapa.FOLHAS:
		var muda := _criar_imagem(_muda_na_bandeja)
		muda.position = -muda.size / 2.0
		_folhas.hide()
		_iniciar_arraste(_vaso, muda, "Solte a muda na bandeja.")
		return _vaso
	var previa := Control.new()
	previa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ajuste_previa_vaso = _vaso.make_canvas_position_local(_posicao_ponteiro)
	previa.position = -_ajuste_previa_vaso
	for filho in _vaso.get_children():
		if filho is TextureRect and filho.visible:
			var imagem := _criar_imagem(filho)
			imagem.position = filho.position
			imagem.modulate = filho.modulate
			previa.add_child(imagem)
	_vaso.modulate.a = 0.28
	_iniciar_arraste(_vaso, previa, _instrucao_cuidado())
	return _vaso


func _posicao_vaso_solto() -> Vector2:
	var bancada := _vaso.get_parent() as Control
	return bancada.make_canvas_position_local(_posicao_ponteiro) - _ajuste_previa_vaso


func _mover_para_luz(posicao: Vector2, dado: Variant) -> void:
	if not _precisa_de_luz() or not _pode_soltar(posicao, dado, _vaso):
		return
	_movendo_vaso = true
	var destino := Vector2(POSICAO_VASO_NA_LUZ, _vaso.position.y)
	_vaso.position = _posicao_vaso_solto()
	var deslize := create_tween().set_trans(Tween.TRANS_SINE)
	deslize.tween_property(_painel_umidade, "modulate:a", 0.0, 0.10)
	deslize.parallel().tween_property(_vaso, "position", destino, 0.23)
	deslize.tween_property(_painel_umidade, "position:x", POSICAO_UMIDADE_NA_LUZ, 0.0)
	deslize.tween_property(_painel_umidade, "modulate:a", 1.0, 0.10)
	await deslize.finished
	_vaso_na_luz = true
	_movendo_vaso = false
	_estourar_pixels(_luz, Color("#f7df95"), 8)
	_instrucao.text = "O broto ganhou luz! Veja como ele cresce."
	_atualizar_controles()


func _avancar_dia() -> void:
	if not _proximo_dia.visible:
		return
	_fechar_lupa()
	_dias_passados += 1
	_dia.text = "Dia %d" % (_dias_passados + 1)
	_atualizar_fases()
	match _dias_passados:
		1:
			_revelar(_raiz, Vector2(12, 0))
			_lupa.show()
			_instrucao.text = "Olhe embaixo da terra: nasceu uma raiz!\nArraste a lupa até a raiz para ver de perto."
		2:
			_revelar(_broto, Vector2(12, 54))
			_luz.show()
			_feixe.show()
			_instrucao.text = INSTRUCAO_LUZ
		3:
			_mostrar_folhas()
	_atualizar_controles()


func _mostrar_folhas() -> void:
	_etapa = Etapa.FOLHAS
	_broto.hide()
	_revelar(_folhas, _folhas.pivot_offset)
	_estourar_pixels(_folhas, Color("#d8e78b"), 10)
	_regador.disabled = true
	_regador.hide()
	_bandeja.show()
	_contorno_bandeja.show()
	_pulso_bandeja = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulso_bandeja.tween_property(_contorno_bandeja, "modulate:a", 0.4, 0.55)
	_pulso_bandeja.tween_property(_contorno_bandeja, "modulate:a", 1.0, 0.55)
	_instrucao.text = INSTRUCAO_MUDA


func _colocar_na_bandeja(posicao: Vector2, dado: Variant) -> void:
	if _etapa != Etapa.FOLHAS or not _pode_soltar(posicao, dado, _vaso):
		return
	_fechar_lupa()
	_etapa = Etapa.MUDA_GUARDADA
	_pulso_bandeja.kill()
	_contorno_bandeja.hide()
	_lupa.hide()
	_vaso.hide()
	_luz.hide()
	_feixe.hide()
	_painel_umidade.hide()
	_revelar(_muda_na_bandeja, Vector2(18, 36))
	_estourar_pixels(_muda_na_bandeja, Color("#f5de92"), 16)
	_instrucao.text = "Muda pronta! Você fez o feijão crescer.\nSua muda agora está na bandeja do laboratório."
	_atualizar_fases()
	_atualizar_controles()
	_voltar.hide()
	await get_tree().create_timer(0.55, false).timeout
	_resultado.mostrar("Missão Broto", "Você cultivou um pé de feijão. Sua muda ficou na bandeja do laboratório.")
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


func _precisa_de_luz() -> bool:
	return _etapa == Etapa.CRESCIMENTO and _umidade == Umidade.UMIDA and _dias_passados == 2 and not _vaso_na_luz


func _precisa_drenar() -> bool:
	return _etapa == Etapa.CRESCIMENTO and _umidade == Umidade.ENCHARCADA


func _atualizar_controles() -> void:
	var crescendo := _etapa == Etapa.CRESCIMENTO
	var drenagem := _precisa_drenar()
	var luz := _precisa_de_luz()
	var livre := _item_arrastado == null and not _movendo_vaso
	_area_de_luz.visible = luz and _item_arrastado == _vaso and not _movendo_vaso
	_drenagem.visible = drenagem and _item_arrastado != _regador
	_regador.visible = crescendo and (not drenagem or _item_arrastado == _regador)
	_vaso.mouse_default_cursor_shape = Control.CURSOR_DRAG if drenagem or luz or _etapa == Etapa.FOLHAS else Control.CURSOR_ARROW
	_acima_do_vaso.mouse_default_cursor_shape = _vaso.mouse_default_cursor_shape
	var pode_avancar := crescendo and _umidade == Umidade.UMIDA and not luz
	_proximo_dia.visible = pode_avancar and livre


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
