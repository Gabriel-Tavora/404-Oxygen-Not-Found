class_name OverworldState
extends RefCounted
## Guarda o progresso do mapa entre as trocas de cena (enquanto o jogo está aberto).
## Para salvar em disco, grave "completed" e "current_node" num arquivo (ConfigFile).

## Nó onde o jogador está (nome do nó dentro de "Nodes")
static var current_node: StringName = &"casa_azul"
## Fases completas: { &"foguete": true, ... }
static var completed := {}


## Chame ao terminar uma fase, ex.: OverworldState.complete(&"foguete")
static func complete(node_id: StringName) -> void:
	completed[node_id] = true


static func is_completed(node_id: StringName) -> bool:
	return completed.has(node_id)
