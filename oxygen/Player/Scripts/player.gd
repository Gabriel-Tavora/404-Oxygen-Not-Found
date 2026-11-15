class_name Player
extends CharacterBody2D
## Astronauta: física de plataforma (estilo Mario), vida, dano e mineração.
## O movimento de cada situação fica nos estados (StateMachine/<estado>).

signal died
signal health_changed(current: int, maximum: int)
signal mined(target: Object, point: Vector2)

const ACTION_LEFT := &"player_left"
const ACTION_RIGHT := &"player_right"
const ACTION_JUMP := &"player_jump"
const ACTION_DUCK := &"player_duck"
const ACTION_RUN := &"player_run"
const ACTION_MINE := &"player_mine"

## Teclas padrão, criadas sozinhas se a ação não existir no Mapa de Entrada
const DEFAULT_KEYS := {
	&"player_left": [KEY_A, KEY_LEFT],
	&"player_right": [KEY_D, KEY_RIGHT],
	&"player_jump": [KEY_SPACE, KEY_W, KEY_UP],
	&"player_duck": [KEY_S, KEY_DOWN],
	&"player_run": [KEY_SHIFT],
	&"player_mine": [KEY_J, KEY_E],
}

@export_group("Movimento")
@export var walk_speed := 75.0
@export var run_speed := 150.0
@export var ground_accel := 320.0
## Freada ao soltar o direcional
@export var ground_friction := 400.0
## Freada da derrapada
@export var skid_decel := 900.0
@export var air_accel := 320.0

@export_group("Pulo")
@export var jump_velocity := -300.0
## Pula mais alto quanto mais rápido estiver (vel_x x este valor)
@export var jump_speed_bonus := 0.25
## Gravidade normal
@export var gravity := 1350.0
## Gravidade subindo com o pulo segurado (pulo variável)
@export var gravity_hold := 675.0
@export var max_fall_speed := 300.0
## Ainda dá para pular logo depois de sair da beirada
@export var coyote_time := 0.1
## Aperto do pulo fica guardado antes de tocar o chão
@export var jump_buffer_time := 0.1

@export_group("Vida")
@export var max_health := 3
@export var invulnerable_time := 1.5
@export var knockback := Vector2(120.0, -180.0)
## Abaixo desta altura (caiu do mapa) morre
@export var kill_y := 2000.0

@export_group("Mineração")
## Distância à frente onde a picareta acerta
@export var mine_reach := 14.0
## Altura do golpe em relação à origem (positivo = para baixo)
@export var mine_height := 8.0
## Apaga o tile acertado em um TileMapLayer
@export var mine_breaks_tiles := true

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: PlayerStateMachine = $StateMachine
## GPUParticles2D ou CPUParticles2D (os dois têm "emitting")
@onready var skid_particles: Node2D = get_node_or_null("SkidParticles")
## Usa "StandingShape" se existir; senão a "CollisionShape2D" normal
@onready var standing_shape: CollisionShape2D = _find_standing_shape()
## Opcional: se não existir, a forma em pé é encolhida ao agachar
@onready var duck_shape: CollisionShape2D = get_node_or_null("DuckShape")

@export_group("Agachar")
## Altura da colisão agachado (fração da altura em pé), quando não há DuckShape
@export_range(0.3, 1.0) var crouch_height_ratio := 0.75

var _stand_res: Shape2D
var _stand_pos := Vector2.ZERO
var _duck_res: Shape2D
var _duck_pos := Vector2.ZERO

var facing := 1
var health := 0
var is_invulnerable := false
var is_dead := false

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0


func _ready() -> void:
	_ensure_input_actions()
	_setup_shapes()
	health = max_health
	set_skid_particles(false)
	state_machine.init(self)


func _physics_process(delta: float) -> void:
	_update_jump_timers(delta)

	var state := state_machine.current_state
	if state == null or state.can_apply_gravity():
		_apply_gravity(delta)

	state_machine.process_physics(delta)
	move_and_slide()

	if not is_dead and global_position.y > kill_y:
		die()


# --- Entrada ---

func get_input_x() -> float:
	return Input.get_axis(ACTION_LEFT, ACTION_RIGHT)


func is_run_held() -> bool:
	return Input.is_action_pressed(ACTION_RUN)


func target_speed() -> float:
	return run_speed if is_run_held() else walk_speed


# --- Movimento ---

func ground_move(delta: float) -> void:
	var input := get_input_x()
	if input != 0.0:
		velocity.x = move_toward(velocity.x, input * target_speed(), ground_accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)


## No ar, soltar o direcional não freia (como no Mario)
func air_move(delta: float) -> void:
	var input := get_input_x()
	if input == 0.0:
		return
	var max_speed := maxf(target_speed(), absf(velocity.x))
	velocity.x = move_toward(velocity.x, input * max_speed, air_accel * delta)


func brake(delta: float, amount: float = ground_friction) -> void:
	velocity.x = move_toward(velocity.x, 0.0, amount * delta)


func update_facing() -> void:
	var input := get_input_x()
	if input != 0.0:
		set_facing(int(signf(input)))


func set_facing(dir: int) -> void:
	if dir == 0:
		return
	facing = dir
	animated_sprite.flip_h = facing < 0  # o sprite olha para a direita


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var g := gravity
	if velocity.y < 0.0 and Input.is_action_pressed(ACTION_JUMP):
		g = gravity_hold
	velocity.y = minf(velocity.y + g * delta, max_fall_speed)


# --- Pulo ---

func _update_jump_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta
	if Input.is_action_just_pressed(ACTION_JUMP):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer -= delta


func can_jump() -> bool:
	return _coyote_timer > 0.0


func wants_jump() -> bool:
	return _jump_buffer_timer > 0.0


func jump() -> void:
	velocity.y = jump_velocity - absf(velocity.x) * jump_speed_bonus
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	play_sound("JumpSound")
	state_machine.change_state(state_machine.jump)


# --- Agachar ---

func set_ducking(on: bool) -> void:
	if standing_shape == null:
		return
	if duck_shape:  # modo com duas formas (StandingShape + DuckShape)
		standing_shape.set_deferred("disabled", on)
		duck_shape.set_deferred("disabled", not on)
	elif _duck_res:  # modo com uma forma só: troca por uma versão mais baixa
		standing_shape.set_deferred("shape", _duck_res if on else _stand_res)
		standing_shape.set_deferred("position", _duck_pos if on else _stand_pos)


## Tem espaço para levantar (nada em cima da cabeça)?
func can_stand_up() -> bool:
	if _stand_res == null or (duck_shape == null and _duck_res == null):
		return true
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _stand_res
	query.transform = Transform2D(0.0, to_global(_stand_pos) + Vector2(0, -1))
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


# --- Vida ---

func take_damage(amount: int = 1, from_position: Vector2 = global_position) -> void:
	if is_dead or is_invulnerable:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health <= 0:
		die()
		return
	var dir := signf(global_position.x - from_position.x)
	if dir == 0.0:
		dir = -facing
	velocity = Vector2(knockback.x * dir, knockback.y)
	state_machine.change_state(state_machine.hurt)
	_start_invulnerability()


func heal(amount: int = 1) -> void:
	if is_dead:
		return
	health = mini(health + amount, max_health)
	health_changed.emit(health, max_health)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	state_machine.change_state(state_machine.death)


func _start_invulnerability() -> void:
	is_invulnerable = true
	var blink := create_tween().set_loops(int(invulnerable_time / 0.1))
	blink.tween_property(animated_sprite, "modulate:a", 0.3, 0.05)
	blink.tween_property(animated_sprite, "modulate:a", 1.0, 0.05)
	await get_tree().create_timer(invulnerable_time).timeout
	blink.kill()
	animated_sprite.modulate.a = 1.0
	is_invulnerable = false


# --- Mineração ---

## Chamado pelo estado "mine" no frame do golpe
func mine_hit() -> void:
	var point := global_position + Vector2(facing * mine_reach, mine_height)
	var query := PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collide_with_areas = true
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	for hit in get_world_2d().direct_space_state.intersect_point(query, 8):
		var target: Object = hit.collider
		if target.has_method("on_mined"):
			target.on_mined(self, point)
		elif mine_breaks_tiles and target is TileMapLayer:
			var layer := target as TileMapLayer
			layer.erase_cell(layer.local_to_map(layer.to_local(point)))
		mined.emit(target, point)


# --- Animação / Som ---

## Toca a animação. force = recomeça do frame 0 mesmo se já estiver tocando.
func play_anim(anim: StringName, speed: float = 1.0, force: bool = false) -> void:
	var frames := animated_sprite.sprite_frames
	if frames == null or not frames.has_animation(anim):
		return
	animated_sprite.speed_scale = speed
	if force:
		animated_sprite.stop()  # volta para o frame 0
		animated_sprite.play(anim)
	elif animated_sprite.animation != anim:
		animated_sprite.play(anim)
	elif not animated_sprite.is_playing() and frames.get_animation_loop(anim):
		animated_sprite.play(anim)
	# animação sem loop que já terminou fica parada no último frame


func set_skid_particles(on: bool) -> void:
	if skid_particles and "emitting" in skid_particles:
		skid_particles.set("emitting", on)


## Toca um som filho do nó Sound (ex.: "JumpSound"), se existir
func play_sound(sound_name: String) -> void:
	var s := get_node_or_null("Sound/" + sound_name)
	if s and s.has_method("play"):
		s.play()


func stop_sound(sound_name: String) -> void:
	var s := get_node_or_null("Sound/" + sound_name)
	if s and s.has_method("stop"):
		s.stop()


# --- Configuração automática ---

func _ensure_input_actions() -> void:
	for action: StringName in DEFAULT_KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in DEFAULT_KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)


func _find_standing_shape() -> CollisionShape2D:
	var shape := get_node_or_null("StandingShape") as CollisionShape2D
	if shape == null:
		shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	return shape


## Se a colisão estiver vazia, cria no tamanho do astronauta (frame 32x32).
## Sem DuckShape, prepara uma cópia mais baixa da forma para agachar.
func _setup_shapes() -> void:
	if standing_shape == null:
		push_warning("Player: nenhuma CollisionShape2D encontrada.")
		return
	if standing_shape.shape == null:
		var r := RectangleShape2D.new()
		r.size = Vector2(12, 24)
		standing_shape.shape = r
		standing_shape.position = Vector2(0, 2)
	# Cópia própria para não alterar o recurso compartilhado
	standing_shape.shape = standing_shape.shape.duplicate()
	_stand_res = standing_shape.shape
	_stand_pos = standing_shape.position

	if duck_shape:
		duck_shape.disabled = true
		return

	var h := _shape_height(_stand_res)
	if h <= 0.0:
		return  # forma sem altura conhecida: agacha sem mudar a colisão
	_duck_res = _stand_res.duplicate()
	var new_h := _set_shape_height(_duck_res, h * crouch_height_ratio)
	# Mantém os pés no mesmo lugar
	_duck_pos = _stand_pos + Vector2(0, (h - new_h) / 2.0)


func _shape_height(shape: Shape2D) -> float:
	if shape is RectangleShape2D:
		return (shape as RectangleShape2D).size.y
	if shape is CapsuleShape2D:
		return (shape as CapsuleShape2D).height
	return 0.0


## Muda a altura e devolve a altura que ficou de fato
func _set_shape_height(shape: Shape2D, h: float) -> float:
	if shape is RectangleShape2D:
		var r := shape as RectangleShape2D
		r.size.y = h
		return h
	if shape is CapsuleShape2D:
		var c := shape as CapsuleShape2D
		c.height = maxf(h, c.radius * 2.0)
		return c.height
	return h
