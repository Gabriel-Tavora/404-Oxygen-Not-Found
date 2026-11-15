@tool
class_name CardPersonagem
extends Control
## Card de um personagem. Mostra o personagem do .tres (PersonagemDados) parado;
## quando selecionado, aparece a moldura azul, a seta e ele anda.

signal focado(card: CardPersonagem)       ## mouse passou por cima
signal clicado(card: CardPersonagem)

@export var dados: PersonagemDados:
	set(v):
		dados = v
		_aplicar_dados()
## Cor do cabelo mostrada (índice nas listas do PersonagemDados)
@export var indice_cabelo := 0:
	set(v):
		indice_cabelo = v
		_aplicar_dados()
@export var cor_mochila := Color(0.27, 0.47, 0.86):
	set(v):
		cor_mochila = v
		_aplicar_cor()
## Escala do personagem dentro do card
@export var escala_sprite := 1.5:
	set(v):
		escala_sprite = v
		if is_node_ready():
			corpo.scale = Vector2(v, v); mochila.scale = Vector2(v, v)

@onready var corpo: AnimatedSprite2D = $Corpo
@onready var mochila: AnimatedSprite2D = $Mochila
@onready var selecao: TextureRect = $Selecao
@onready var seta: TextureRect = $Seta

var selecionado := false
var ativo := true          ## a fileira dos personagens está com o foco
## Enquanto escolhe a mochila, o selecionado anda de lado para a mochila aparecer
var mostrar_mochila := false:
	set(v):
		if v != mostrar_mochila:
			mostrar_mochila = v
			if is_node_ready():
				_tocar()
var _t := 0.0
var _seta_y := 0.0


func _ready() -> void:
	_seta_y = seta.position.y
	mochila.material = mochila.material.duplicate()
	corpo.frame_changed.connect(func(): mochila.frame = corpo.frame)
	if not Engine.is_editor_hint():
		$Botao.mouse_entered.connect(func(): focado.emit(self))
		$Botao.pressed.connect(func(): clicado.emit(self))
	_aplicar_dados()
	_aplicar_cor()
	set_selecionado(selecionado, true)


func _aplicar_dados() -> void:
	if not is_node_ready() or dados == null:
		return
	var anim := corpo.animation
	var quadro := corpo.frame
	corpo.sprite_frames = dados.frames(indice_cabelo)
	mochila.sprite_frames = dados.mochila(indice_cabelo)
	_tocar()
	if corpo.animation == anim:
		corpo.frame = quadro
		mochila.frame = quadro


func _aplicar_cor() -> void:
	if is_node_ready() and mochila.material is ShaderMaterial:
		(mochila.material as ShaderMaterial).set_shader_parameter("cor", cor_mochila)


func set_selecionado(v: bool, instantaneo := false) -> void:
	selecionado = v
	if not is_node_ready():
		return
	selecao.visible = v
	seta.visible = v
	_tocar()


func _tocar() -> void:
	var anim := &"idle_down"
	if selecionado:
		anim = &"walk_right" if mostrar_mochila else &"walk_down"
	for s in [corpo, mochila]:
		if s.sprite_frames and s.sprite_frames.has_animation(anim):
			s.play(anim)
	mochila.frame = corpo.frame


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not selecionado:
		return
	_t += delta
	seta.position.y = _seta_y + (roundf(sin(_t * 5.0) * 4.0) if ativo else 0.0)
	selecao.modulate = Color(1, 1, 1, (0.82 + 0.18 * sin(_t * 4.0)) if ativo else 0.75)


## Pisca forte ao confirmar
func piscar() -> Tween:
	var tw := create_tween()
	for i in 3:
		tw.tween_property(selecao, "modulate", Color(2.2, 2.2, 2.2, 1), 0.07)
		tw.tween_property(selecao, "modulate", Color(1, 1, 1, 1), 0.09)
	return tw
