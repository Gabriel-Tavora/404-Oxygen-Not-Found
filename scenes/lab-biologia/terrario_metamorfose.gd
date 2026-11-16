extends Node2D

signal borboleta_pronta
signal voo_terminado

const DURACAO_VOO := 1.8
const POS_OVO := Vector2(43, 86)
const POS_LAGARTA := Vector2(68, 86)
const POS_CRISALIDA := Vector2(80, 39)
const POS_BORBOLETA := Vector2(63, 70)

@onready var _ovo: Sprite2D = $Ovo
@onready var _lagarta: Sprite2D = $Lagarta
@onready var _crisalida: Sprite2D = $Crisalida
@onready var _borboleta: Sprite2D = $Borboleta
@onready var _folhas: Node2D = $PedacosDeFolha

var _animacao: Tween


func mostrar_etapa(etapa: int, animar: bool = false) -> void:
	if _animacao:
		_animacao.kill()
	_resetar_sprites()

	match etapa:
		1:
			_ovo.show()
			if animar:
				_animar_ovo()
		2:
			if animar:
				_animar_lagarta()
			else:
				_lagarta.show()
		3:
			if animar:
				_animar_crisalida()
			else:
				_crisalida.show()
		4:
			if animar:
				_animar_borboleta()
			else:
				_borboleta.show()


func _resetar_sprites() -> void:
	_ovo.hide()
	_ovo.position = POS_OVO
	_lagarta.hide()
	_lagarta.position = POS_LAGARTA
	_lagarta.scale = Vector2.ONE
	_crisalida.hide()
	_crisalida.position = POS_CRISALIDA
	_crisalida.rotation = 0.0
	_borboleta.hide()
	_borboleta.position = POS_BORBOLETA
	_borboleta.scale = Vector2(2, 2)
	_borboleta.z_index = 0
	_folhas.hide()
	_folhas.position = POS_LAGARTA + Vector2(11, -4)
	_folhas.modulate.a = 1.0


func _animar_ovo() -> void:
	_ovo.position.y -= 8
	_animacao = create_tween()
	_animacao.tween_property(_ovo, "position", POS_OVO, 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func _animar_lagarta() -> void:
	_lagarta.position = POS_OVO
	_lagarta.scale = Vector2(0.5, 0.5)
	_ovo.show()
	_animacao = create_tween()
	for deslocamento in [-2, 2, 0]:
		_animacao.tween_property(_ovo, "position:x", POS_OVO.x + deslocamento, 0.07)
	_animacao.tween_callback(_ovo.hide)
	_animacao.tween_callback(_lagarta.show)
	_animacao.tween_property(_lagarta, "position", POS_LAGARTA, 0.34)
	_animacao.parallel().tween_property(_lagarta, "scale", Vector2.ONE, 0.34)
	for mordida in range(3):
		_animacao.tween_property(_lagarta, "scale", Vector2(1.08, 0.83), 0.09)
		_animacao.tween_property(_lagarta, "scale", Vector2.ONE, 0.09)
	_animacao.tween_callback(_folhas.show)
	_animacao.tween_property(_folhas, "position", _folhas.position + Vector2(7, -7), 0.25)
	_animacao.parallel().tween_property(_folhas, "modulate:a", 0.0, 0.25)
	_animacao.tween_callback(_folhas.hide)


func _animar_crisalida() -> void:
	_lagarta.show()
	_animacao = create_tween()
	_animacao.tween_property(_lagarta, "position", Vector2(99, 83), 0.23)
	_animacao.tween_property(_lagarta, "position", Vector2(99, 52), 0.25)
	_animacao.tween_property(_lagarta, "position", POS_CRISALIDA + Vector2(0, 10), 0.2)
	_animacao.parallel().tween_property(_lagarta, "scale", Vector2(0.35, 0.7), 0.2)
	_animacao.tween_callback(_lagarta.hide)
	_crisalida.rotation = deg_to_rad(12.0)
	_animacao.tween_callback(_crisalida.show)
	_animacao.tween_property(_crisalida, "rotation", deg_to_rad(-7.0), 0.18)
	_animacao.tween_property(_crisalida, "rotation", 0.0, 0.2)


func _animar_borboleta() -> void:
	_crisalida.show()
	_borboleta.position = POS_CRISALIDA + Vector2(0, 33)
	_borboleta.scale = Vector2(0.25, 0.8)
	_animacao = create_tween()
	for inclinacao in [8.0, -6.0, 0.0]:
		_animacao.tween_property(_crisalida, "rotation", deg_to_rad(inclinacao), 0.08)
	_animacao.tween_callback(_borboleta.show)
	_animacao.tween_property(_borboleta, "position", POS_BORBOLETA, 0.38)
	_animacao.parallel().tween_property(_borboleta, "scale", Vector2(2, 2), 0.38)
	_animacao.tween_callback(_crisalida.hide)
	_animacao.tween_callback(borboleta_pronta.emit)


func colorir_asas(cor: Color) -> void:
	_borboleta.material.set_shader_parameter("cor_asas", cor)


func soltar_borboleta() -> void:
	_borboleta.z_index = 1
	var fim_x := to_local(Vector2(get_viewport_rect().end.x, 0.0)).x + 36.0
	_animacao = create_tween()
	_animacao.tween_method(_mover_borboleta.bind(fim_x), 0.0, 1.0, DURACAO_VOO)
	_animacao.tween_callback(_borboleta.hide)
	_animacao.tween_callback(voo_terminado.emit)


func _mover_borboleta(progresso: float, fim_x: float) -> void:
	var x := lerpf(POS_BORBOLETA.x, fim_x, ease(progresso, 1.65))
	var y := POS_BORBOLETA.y - 58.0 * progresso + 14.0 * sin(progresso * TAU * 2.0)
	var abertura_asas := 0.65 + absf(cos(progresso * TAU * 5.0)) * 1.35
	_borboleta.position = Vector2(x, y).round()
	_borboleta.scale.x = abertura_asas
