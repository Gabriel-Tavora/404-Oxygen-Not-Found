@tool
class_name CardMochila
extends Control
## Card de uma cor de mochila. A cor vem do .tres (MochilaDados).

signal focado(card: CardMochila)
signal clicado(card: CardMochila)

@export var dados: MochilaDados:
	set(v):
		dados = v
		_aplicar()

@onready var icone: TextureRect = $Icone
@onready var selecao: TextureRect = $Selecao
@onready var seta: TextureRect = $Seta

var selecionado := false
var ativo := false
var _t := 0.0
var _seta_y := 0.0


func _ready() -> void:
	_seta_y = seta.position.y
	icone.material = icone.material.duplicate()
	if not Engine.is_editor_hint():
		$Botao.mouse_entered.connect(func(): focado.emit(self))
		$Botao.pressed.connect(func(): clicado.emit(self))
	_aplicar()
	set_selecionado(selecionado)


func _aplicar() -> void:
	if is_node_ready() and dados and icone.material is ShaderMaterial:
		(icone.material as ShaderMaterial).set_shader_parameter("cor", dados.cor)
		tooltip_text = dados.nome


func set_selecionado(v: bool) -> void:
	selecionado = v
	if not is_node_ready():
		return
	selecao.visible = v
	seta.visible = v
	var tw := create_tween()
	tw.tween_property(icone, "scale", Vector2(1.08, 1.08) if v else Vector2.ONE, 0.1)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not selecionado:
		return
	_t += delta
	seta.position.y = _seta_y + (roundf(sin(_t * 5.0) * 3.0) if ativo else 0.0)
	selecao.modulate = Color(1, 1, 1, (0.82 + 0.18 * sin(_t * 4.0)) if ativo else 0.75)


func piscar() -> Tween:
	var tw := create_tween()
	for i in 3:
		tw.tween_property(selecao, "modulate", Color(2.2, 2.2, 2.2, 1), 0.07)
		tw.tween_property(selecao, "modulate", Color(1, 1, 1, 1), 0.09)
	return tw
