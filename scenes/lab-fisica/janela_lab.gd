extends Node2D

@onready var _ceu: Sprite2D = $Ceu
@onready var _colinas: Sprite2D = get_node_or_null("Colinas")
@onready var _nuvens: Sprite2D = $Nuvens

var _tempo: float = 0.0


func _process(delta: float) -> void:
	_tempo += delta
	_deslizar(_ceu, _tempo * 1.5)
	if _colinas:
		_deslizar(_colinas, _tempo * 3.0)
	_deslizar(_nuvens, _tempo * 7.0)


func _deslizar(sprite: Sprite2D, distancia: float) -> void:
	var regiao := sprite.region_rect
	# Desloca apenas pixels inteiros e repete a textura no fim da faixa.
	var deslocamento := floori(distancia) % sprite.texture.get_width()
	if regiao.position.x != deslocamento:
		regiao.position.x = deslocamento
		sprite.region_rect = regiao
