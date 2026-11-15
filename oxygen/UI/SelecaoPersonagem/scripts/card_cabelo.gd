@tool
class_name CardCabelo
extends Control
## Card de uma cor de cabelo. Mostra a cabeça do personagem selecionado nessa cor.

signal focado(card: CardCabelo)
signal clicado(card: CardCabelo)

@export var dados: CabeloDados:
	set(v):
		dados = v
		_aplicar()
## Personagem cuja cabeça aparece no card (a tela atualiza ao trocar de personagem)
@export var personagem: PersonagemDados:
	set(v):
		personagem = v
		_aplicar()

@onready var cabeca: TextureRect = $Cabeca
@onready var selecao: TextureRect = $Selecao
@onready var seta: TextureRect = $Seta

var selecionado := false
var ativo := false
var _t := 0.0
var _seta_y := 0.0


func _ready() -> void:
	_seta_y = seta.position.y
	if not Engine.is_editor_hint():
		$Botao.mouse_entered.connect(func(): focado.emit(self))
		$Botao.pressed.connect(func(): clicado.emit(self))
	_aplicar()
	set_selecionado(selecionado)


func _aplicar() -> void:
	if not is_node_ready() or dados == null or personagem == null:
		return
	tooltip_text = dados.nome
	var sf := personagem.frames(dados.indice)
	if sf == null or not sf.has_animation(&"idle_down"):
		return
	var base := sf.get_frame_texture(&"idle_down", 0) as AtlasTexture
	if base == null:
		return
	# recorte da cabeça: quadrado no topo do recorte do personagem
	var head := AtlasTexture.new()
	head.atlas = base.atlas
	var r := base.region
	var lado := minf(r.size.x, roundf(r.size.y * 0.5))
	head.region = Rect2(r.position.x + roundf((r.size.x - lado) / 2.0), r.position.y, lado, lado)
	cabeca.texture = head


func set_selecionado(v: bool) -> void:
	selecionado = v
	if not is_node_ready():
		return
	selecao.visible = v
	seta.visible = v


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
