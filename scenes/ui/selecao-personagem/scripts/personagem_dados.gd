class_name PersonagemDados
extends Resource
## Dados de um personagem (penteado). Crie um .tres deste tipo para cada um
## e arraste no card (CardPersonagem.dados).
## As listas seguem a ordem das cores de cabelo (CabeloDados.indice):
##   0 preto, 1 castanho, 2 loiro, 3 ruivo, 4 branco

@export var nome := ""
@export_multiline var descricao := ""
@export var material_corpo: ShaderMaterial
## Animações do corpo para cada cor de cabelo:
## idle_down, walk_down, idle_up, walk_up, idle_right, walk_right
## (res://assets/selecao-personagem/frames/pN_cor.tres, quadros de 128x176 com os pés na base;
## para a esquerda use a animação *_right com flip_h = true)
@export var frames_cabelo: Array[SpriteFrames] = []
## Mesmas animações, só a mochila em tons de cinza (pintada com a cor escolhida)
## (res://assets/selecao-personagem/frames/pN_cor_mochila.tres)
@export var frames_mochila: Array[SpriteFrames] = []


func frames(indice_cabelo: int) -> SpriteFrames:
	if frames_cabelo.is_empty():
		return null
	return frames_cabelo[clampi(indice_cabelo, 0, frames_cabelo.size() - 1)]


func mochila(indice_cabelo: int) -> SpriteFrames:
	if frames_mochila.is_empty():
		return null
	return frames_mochila[clampi(indice_cabelo, 0, frames_mochila.size() - 1)]
