extends CanvasLayer

const DURACAO := 0.4

var _fundo := ColorRect.new()
var _animacao: Tween


func _ready() -> void:
	_fundo.color = Color(0, 0, 0, 0)
	_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fundo)
	_fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func animar_para(opacidade: float) -> Tween:
	if _animacao:
		_animacao.kill()
	_animacao = create_tween()
	_animacao.tween_property(_fundo, "color:a", opacidade, DURACAO)
	return _animacao


func revelar() -> Tween:
	_fundo.color.a = 1.0
	return animar_para(0.0)


func revelar_e_remover() -> void:
	await revelar().finished
	queue_free()
