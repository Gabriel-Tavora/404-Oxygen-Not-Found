extends CharacterBody2D

@export_range(1.0, 300.0, 1.0) var velocidade: float = 68.0
@onready var _visual: Node2D = $Visual
@onready var _sprite: AnimatedSprite2D = $Visual/Sprite
@onready var _mochila: AnimatedSprite2D = $Visual/Mochila
@onready var _escala_exploracao: Vector2 = _visual.scale

var controles_bloqueados: bool = false
var _direcao: String = "sul"
var _personagem_personalizado := false


func _ready() -> void:
	_personagem_personalizado = PersonagemEscolhido.dados != null
	if not _personagem_personalizado:
		return
	_sprite.position = Vector2.ZERO
	_sprite.centered = true
	_sprite.offset = _mochila.offset
	_sprite.scale = _mochila.scale
	PersonagemEscolhido.aplicar(_sprite, _mochila)
	_sprite.frame_changed.connect(_sincronizar_mochila)
	_mochila.show()
	_animar_personagem(false)


func definir_visual_de_missao(em_missao: bool) -> void:
	_visual.scale = Vector2.ONE if em_missao else _escala_exploracao


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
	if _personagem_personalizado:
		_animar_personagem(andando)
		return
	var animacao := StringName(("andar_" if andando else "parado_") + _direcao)
	if _sprite.animation != animacao:
		_sprite.play(animacao)


func _animar_personagem(andando: bool) -> void:
	var direcao := "down"
	match _direcao:
		"norte": direcao = "up"
		"leste", "oeste": direcao = "right"
	var animacao := StringName(("walk_" if andando else "idle_") + direcao)
	var espelhado := _direcao == "oeste"
	_sprite.flip_h = espelhado
	_mochila.flip_h = espelhado
	if _mochila.animation != animacao:
		_mochila.animation = animacao
	if not _sprite.is_playing() or _sprite.animation != animacao:
		_sprite.play(animacao)
	_sincronizar_mochila()


func _sincronizar_mochila() -> void:
	_mochila.frame = _sprite.frame
