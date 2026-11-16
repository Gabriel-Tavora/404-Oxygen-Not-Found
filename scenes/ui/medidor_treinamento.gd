extends Panel

const COR_VAZIO := Color("#12232d")
const DURACAO_PREENCHIMENTO := 0.42

@export var titulo: String
@export var cor: Color
@export var icone: Texture2D
@export var laboratorios: Array[StringName]

@onready var _segmentos: HBoxContainer = $Segmentos
@onready var _contador: Label = $Contador

var _preenchimentos: Array[ColorRect] = []
var concluidas_exibidas := 0


func _ready() -> void:
	$Titulo.text = titulo
	$Icone.texture = icone
	$Icone.self_modulate = cor

	var total := 0
	for laboratorio in laboratorios:
		total += ProgressoConhecimento.total_tarefas(laboratorio)
	for indice in total:
		var segmento := ColorRect.new()
		segmento.color = COR_VAZIO
		segmento.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segmento.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_segmentos.add_child(segmento)

		var preenchimento := ColorRect.new()
		preenchimento.color = cor
		preenchimento.mouse_filter = Control.MOUSE_FILTER_IGNORE
		segmento.add_child(preenchimento)
		preenchimento.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_preenchimentos.append(preenchimento)
	atualizar()


func atualizar(animar := false) -> bool:
	var concluidas := 0
	for laboratorio in laboratorios:
		concluidas += ProgressoConhecimento.total_concluido_no_laboratorio(laboratorio)
	exibir(concluidas, animar)
	return concluidas == _preenchimentos.size()


func exibir(concluidas: int, animar := false) -> void:
	_contador.text = "%d/%d" % [concluidas, _preenchimentos.size()]
	_contador.accessibility_name = "%s, %d de %d missões" % [titulo, concluidas, _preenchimentos.size()]
	for indice in _preenchimentos.size():
		var preenchimento := _preenchimentos[indice]
		preenchimento.visible = indice < concluidas
		if animar and indice == concluidas - 1 and concluidas > concluidas_exibidas:
			preenchimento.scale.x = 0.01
			create_tween().tween_property(preenchimento, "scale:x", 1.0, DURACAO_PREENCHIMENTO)
	concluidas_exibidas = concluidas
