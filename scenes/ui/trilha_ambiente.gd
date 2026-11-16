extends AudioStreamPlayer

const VOLUME_DISCRETO_DB := -30.0
const VOLUME_LAB_DB := -24.0
const SILENCIO_DB := -80.0
const DURACAO_TRANSICAO := 0.45
const VOLUMES_POR_CENA := {
	"res://scenes/ui/menu-inicial/menu-inicial.tscn": -13.0,
	"res://scenes/ui/selecao-personagem/selecao_personagem.tscn": VOLUME_DISCRETO_DB,
	"res://scenes/hub-missoes/mapa.tscn": VOLUME_DISCRETO_DB,
	"res://scenes/lab-biologia/lab-bio.tscn": VOLUME_LAB_DB,
	"res://scenes/lab-fisica/lab-fisica.tscn": VOLUME_LAB_DB,
	"res://scenes/lab-resistencia/lab-resistencia.tscn": VOLUME_LAB_DB,
	"res://scenes/sala-emocoes/sala-emocoes.tscn": VOLUME_LAB_DB,
}

var _volume_da_cena := SILENCIO_DB
var _silenciamentos := 0
var _transicao: Tween


func _ready() -> void:
	stream = preload("res://assets/ui/janela-para-saturno.wav")
	get_tree().scene_changed.connect(_atualizar_cena)
	_atualizar_cena.call_deferred()


func silenciar_durante(no: Node) -> void:
	_silenciamentos += 1
	no.tree_exited.connect(_retomar, CONNECT_ONE_SHOT)
	_ajustar_volume()


func _retomar() -> void:
	_silenciamentos -= 1
	_ajustar_volume()


func _atualizar_cena() -> void:
	var cena := get_tree().current_scene
	var caminho := cena.scene_file_path if cena else ""
	_volume_da_cena = VOLUMES_POR_CENA.get(caminho, SILENCIO_DB)
	_ajustar_volume()


func _ajustar_volume() -> void:
	var destino := _volume_da_cena if _silenciamentos == 0 else SILENCIO_DB
	if _transicao:
		_transicao.kill()
	if not playing:
		if destino != SILENCIO_DB:
			volume_db = destino
			play()
		return
	_transicao = create_tween()
	_transicao.tween_property(self, "volume_db", destino, DURACAO_TRANSICAO)
	if _volume_da_cena == SILENCIO_DB:
		_transicao.tween_callback(stop)
