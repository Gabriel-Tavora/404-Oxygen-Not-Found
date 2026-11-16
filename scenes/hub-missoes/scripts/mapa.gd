extends Node2D
## Mapa do mundo: o personagem anda pelas ruas entre os pontos.
## Ao parar numa fase ou no foguete, abre o painel do ponto.
## Setas/WASD andam, Espaço/Enter abrem o menu de novo no ponto atual.

const ACTIONS := {
	&"map_up": [KEY_UP, KEY_W],
	&"map_down": [KEY_DOWN, KEY_S],
	&"map_left": [KEY_LEFT, KEY_A],
	&"map_right": [KEY_RIGHT, KEY_D],
	&"map_confirm": [KEY_SPACE, KEY_ENTER, KEY_Z],
}
const MOVE_DIRECTIONS := {
	&"map_up": Vector2.UP,
	&"map_down": Vector2.DOWN,
	&"map_left": Vector2.LEFT,
	&"map_right": Vector2.RIGHT,
}
## Altura visível do cenário, independente da resolução lógica dos laboratórios.
const VIEW_HEIGHT := 360.0
const SELECAO := "res://scenes/ui/selecao-personagem/selecao_personagem.tscn"

@export var world_name := "MAPA DE MISSÕES"
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
	var z := vs.y / VIEW_HEIGHT
	camera.zoom = Vector2(z, z)


func _unhandled_input(event: InputEvent) -> void:
	if _busy or menu.aberto:
		return
	if player.moving:
		for action: StringName in MOVE_DIRECTIONS:
			if event.is_action_pressed(action) and player.try_move(MOVE_DIRECTIONS[action]):
				get_viewport().set_input_as_handled()
				return
		return
	if not event.is_action_pressed(&"ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	_trocar_cena(SELECAO)


func _process(_delta: float) -> void:
	if _busy or menu.aberto or player.moving:
		return
	for action: StringName in MOVE_DIRECTIONS:
		if Input.is_action_pressed(action):
			player.try_move(MOVE_DIRECTIONS[action])
			return
	if Input.is_action_just_pressed(&"map_confirm"):
		_abrir_menu(player.current)


func _on_arrived(node: MapNode) -> void:
	OverworldState.current_node = node.name
	_mostrar_placa(node)
	_abrir_menu(node)


func _mostrar_placa(node: MapNode) -> void:
	if node == null:
		return
	var hint := ""
	match node.kind:
		MapNode.Kind.LEVEL:
			hint = "%s missões concluídas  ·  Espaço para abrir" % _progresso_da_area(node.laboratorio)
		MapNode.Kind.EMBARQUE:
			hint = "Espaço para ver os treinos"
		MapNode.Kind.LOCKED:
			hint = "bloqueado"
	hud.set_location(node.display_name, hint)


func _abrir_menu(node: MapNode) -> void:
	if node == null or menu.aberto:
		return
	match node.kind:
		MapNode.Kind.LEVEL:
			hud.set_location("", "")
			var texto := "%s\n%s missões concluídas" % [node.descricao, _progresso_da_area(node.laboratorio)]
			menu.abrir(node.display_name, texto)
		MapNode.Kind.EMBARQUE:
			hud.set_location("", "")
			var mensagem := "Leve Conhecimento, Resistência e Mental ao máximo."
			if ProgressoConhecimento.treinamento_completo():
				mensagem = "Treinamento completo!"
			menu.abrir(node.display_name, mensagem, true)


func _progresso_da_area(laboratorio: StringName) -> String:
	return "%d/%d" % [
		ProgressoConhecimento.total_concluido_no_laboratorio(laboratorio),
		ProgressoConhecimento.total_tarefas(laboratorio),
	]


func _on_menu(comecar: bool) -> void:
	var node := player.current
	_mostrar_placa(node)
	if not comecar or node == null or node.kind != MapNode.Kind.LEVEL:
		return
	if node.level_scene == "" or not ResourceLoader.exists(node.level_scene):
		hud.flash("EM BREVE!")
		return
	OverworldState.current_node = node.name
	_trocar_cena(node.level_scene)


func _trocar_cena(caminho: String) -> void:
	_busy = true
	await hud.fade_out()
	if get_tree().change_scene_to_file(caminho) != OK:
		_busy = false
		hud.fade_in()
		hud.flash("Não foi possível abrir a cena.")


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
