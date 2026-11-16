extends AudioStreamPlayer

const CLIQUE := "res://assets/ui/clique-botao.wav"
const TONS: Array[float] = [1.0, 0.97, 1.03]

var _variacao := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	stream = load(CLIQUE)
	volume_db = -11.0
	get_tree().node_added.connect(_registrar_botao)


func tocar_clique() -> void:
	pitch_scale = TONS[_variacao]
	_variacao = (_variacao + 1) % TONS.size()
	play()


func _registrar_botao(no: Node) -> void:
	if no is BaseButton and not no.pressed.is_connected(tocar_clique):
		no.pressed.connect(tocar_clique)
