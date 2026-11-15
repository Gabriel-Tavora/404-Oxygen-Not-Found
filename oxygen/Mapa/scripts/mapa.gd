extends Node2D
## Mapa do mundo: o personagem anda pelas ruas entre os pontos.
## Ao parar numa fase, abre o menu (COMEÇAR FASE / SAIR).
## Setas/WASD andam, Espaço/Enter abrem o menu de novo no ponto atual.

const ACTIONS := {
	&"map_up": [KEY_UP, KEY_W],
	&"map_down": [KEY_DOWN, KEY_S],
	&"map_left": [KEY_LEFT, KEY_A],
	&"map_right": [KEY_RIGHT, KEY_D],
	&"map_confirm": [KEY_SPACE, KEY_ENTER, KEY_Z],
}
## Altura visível em pixels do mapa (o zoom é ajustado em passos inteiros)
const VIEW_HEIGHT := 360.0

@export var world_name := "MUNDO 1"
@export var start_node: StringName = &"casa_azul"

@onready var player: OverworldPlayer = $Player
@onready var nodes: Node2D = $Nodes
@onready var camera: Camera2D = $Player/Camera2D
@onready var hud: OverworldHUD = $HUD/HUDControl
@onready var menu: MenuFase = $Menu/MenuFase

var _busy := false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ensure_actions()
	get_viewport().size_changed.connect(_fit_camera)
	_fit_camera()
	var start := nodes.get_node_or_null(NodePath(String(OverworldState.current_node))) as MapNode
	if start == null:
		start = nodes.get_node_or_null(NodePath(String(start_node))) as MapNode
	player.place_at(start)
	camera.reset_smoothing()
	player.arrived.connect(_on_arrived)
	player.departed.connect(func(): hud.set_location("", ""))
	menu.escolhido.connect(_on_menu)
	hud.world_name = world_name
	_mostrar_placa(start)
	hud.fade_in()


func _fit_camera() -> void:
	var vs := get_viewport_rect().size
	var z := maxf(1.0, floorf(vs.y / VIEW_HEIGHT))
	camera.zoom = Vector2(z, z)
	hud.px = z
	hud.queue_redraw()


func _process(_delta: float) -> void:
	if _busy or menu.aberto or player.moving:
		return
	var dir := Vector2.ZERO
	if Input.is_action_pressed(&"map_up"): dir = Vector2.UP
	elif Input.is_action_pressed(&"map_down"): dir = Vector2.DOWN
	elif Input.is_action_pressed(&"map_left"): dir = Vector2.LEFT
	elif Input.is_action_pressed(&"map_right"): dir = Vector2.RIGHT
	if dir != Vector2.ZERO:
		player.try_move(dir)
	elif Input.is_action_just_pressed(&"map_confirm"):
		_abrir_menu(player.current)


func _on_arrived(node: MapNode) -> void:
	OverworldState.current_node = node.name
	_mostrar_placa(node)
	if node.kind == MapNode.Kind.LEVEL:
		_abrir_menu(node)


func _mostrar_placa(node: MapNode) -> void:
	if node == null:
		return
	var hint := ""
	match node.kind:
		MapNode.Kind.LEVEL:
			hint = "COMPLETA!" if node.is_completed() else "ESPAÇO para abrir"
		MapNode.Kind.LOCKED:
			hint = "bloqueado"
	hud.set_location(node.display_name, hint)


func _abrir_menu(node: MapNode) -> void:
	if node == null or node.kind != MapNode.Kind.LEVEL or menu.aberto:
		return
	hud.set_location("", "")
	var texto := node.descricao
	if node.is_completed():
		texto += "\n(fase completa)"
	menu.abrir(node.display_name, texto)


func _on_menu(comecar: bool) -> void:
	var node := player.current
	_mostrar_placa(node)
	if not comecar or node == null:
		return
	if node.level_scene == "" or not ResourceLoader.exists(node.level_scene):
		hud.flash("EM BREVE!")
		return
	_busy = true
	OverworldState.current_node = node.name
	await hud.fade_out()
	get_tree().change_scene_to_file(node.level_scene)


func _ensure_actions() -> void:
	for action: StringName in ACTIONS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
		var joy := {&"map_up": JOY_BUTTON_DPAD_UP, &"map_down": JOY_BUTTON_DPAD_DOWN,
			&"map_left": JOY_BUTTON_DPAD_LEFT, &"map_right": JOY_BUTTON_DPAD_RIGHT, &"map_confirm": JOY_BUTTON_A}
		var jb := InputEventJoypadButton.new()
		jb.button_index = joy[action]
		InputMap.action_add_event(action, jb)
