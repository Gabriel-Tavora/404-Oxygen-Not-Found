class_name SomJogo
extends RefCounted
## Sons do jogo: a trilha sonora (toca sem parar e continua entre a seleção e o mapa)
## e o som curto de cada ação na tela de seleção.
## Os tocadores ficam na raiz da árvore, então não são apagados na troca de cena.

const TRILHA := "res://UI/audio/trilha_selecao_e_mapa.mp3"
const SOM_CARD := "res://UI/audio/som_card.wav"

## Volume da trilha e do som de ação (dB)
static var volume_trilha := -10.0
static var volume_som := -4.0


## Começa a trilha (se já estiver tocando, não faz nada).
static func tocar_trilha(tree: SceneTree) -> void:
	if tree == null or tree.root.has_node(^"TrilhaSonora") or not ResourceLoader.exists(TRILHA):
		return
	var musica := load(TRILHA) as AudioStream
	if musica == null:
		return
	if musica is AudioStreamMP3:
		(musica as AudioStreamMP3).loop = true
	var p := AudioStreamPlayer.new()
	p.name = "TrilhaSonora"
	p.stream = musica
	p.volume_db = volume_trilha
	p.autoplay = true
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child.call_deferred(p)


static func parar_trilha(tree: SceneTree) -> void:
	var p := tree.root.get_node_or_null(^"TrilhaSonora")
	if p:
		p.queue_free()


## Toca o som de ação. "tom" muda a altura (1.0 = normal, maior = mais agudo).
static func som(tree: SceneTree, tom := 1.0) -> void:
	if tree == null:
		return
	var p := tree.root.get_node_or_null(^"SomCard") as AudioStreamPlayer
	if p == null:
		if not ResourceLoader.exists(SOM_CARD):
			return
		p = AudioStreamPlayer.new()
		p.name = "SomCard"
		p.stream = load(SOM_CARD)
		p.volume_db = volume_som
		p.max_polyphony = 4
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		tree.root.add_child(p)
	p.pitch_scale = tom
	p.play()
