class_name OverworldState
extends RefCounted
## Mantém a posição no mapa entre as trocas de cena.

const MAPA := "res://scenes/hub-missoes/mapa.tscn"

## Nó onde o jogador está (nome do nó dentro de "Nodes")
static var current_node: StringName = &"casa_azul"
