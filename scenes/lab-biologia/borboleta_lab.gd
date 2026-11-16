extends Sprite2D

const DURACAO_VOLTA := 13.0

var _voo: Tween


func _ready() -> void:
	BorboletaSolta.solta.connect(_iniciar_voo)
	if BorboletaSolta.esta_solta:
		_iniciar_voo(BorboletaSolta.cor_asas)


func _iniciar_voo(cor: Color) -> void:
	material.set_shader_parameter("cor_asas", cor)
	if _voo:
		_voo.kill()
	_mover(0.0)
	show()
	_voo = create_tween().set_loops()
	_voo.tween_method(_mover, 0.0, TAU, DURACAO_VOLTA)


func _mover(angulo: float) -> void:
	position = Vector2(
		240.0 + 173.0 * cos(angulo),
		177.0 + 61.0 * sin(angulo) + 5.0 * sin(angulo * 5.0)
	).round()
	scale.x = 0.4 + absf(cos(angulo * 46.0)) * 0.85
