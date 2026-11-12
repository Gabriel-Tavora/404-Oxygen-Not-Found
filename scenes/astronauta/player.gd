extends CharacterBody2D

@export_range(1.0, 300.0, 1.0) var velocidade: float = 68.0
@onready var _sprite: AnimatedSprite2D = $Sprite

var controles_bloqueados: bool = false
var _direcao: String = "sul"


func _physics_process(_delta: float) -> void:
	var entrada := Vector2.ZERO
	if not controles_bloqueados:
		entrada = Input.get_vector("andar_esquerda", "andar_direita", "andar_cima", "andar_baixo")
	velocity = entrada * velocidade
	if not controles_bloqueados:
		move_and_slide()

	var andando := not entrada.is_zero_approx()
	if andando:
		if absf(entrada.x) > absf(entrada.y):
			_direcao = "oeste" if entrada.x < 0.0 else "leste"
		else:
			_direcao = "norte" if entrada.y < 0.0 else "sul"
	var animacao := StringName(("andar_" if andando else "parado_") + _direcao)
	if _sprite.animation != animacao:
		_sprite.play(animacao)
