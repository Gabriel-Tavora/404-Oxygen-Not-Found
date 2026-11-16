class_name PersonagemEscolhido
extends Node
## Guarda a aparência e o nome do jogador entre as trocas de cena.
## Em qualquer script:
##   PersonagemEscolhido.dados    -> PersonagemDados
##   PersonagemEscolhido.cabelo   -> CabeloDados
##   PersonagemEscolhido.mochila  -> MochilaDados
## Para vestir o Player:  PersonagemEscolhido.aplicar($Corpo, $Mochila)

static var indice := 0
static var indice_cabelo := 0
static var indice_mochila := 1
static var dados: PersonagemDados
static var cabelo: CabeloDados
static var mochila: MochilaDados
static var nome_jogador := ""


## Aplica personagem + cor do cabelo + cor da mochila num par de AnimatedSprite2D.
## O sprite da mochila precisa do material com o shader tinge_mochila.
static func aplicar(corpo: AnimatedSprite2D, sprite_mochila: AnimatedSprite2D) -> void:
	if dados == null:
		return
	var ic := cabelo.indice if cabelo else indice_cabelo
	corpo.material = dados.material_corpo
	corpo.sprite_frames = dados.frames(ic)
	if sprite_mochila:
		sprite_mochila.sprite_frames = dados.mochila(ic)
		if sprite_mochila.material is ShaderMaterial and mochila:
			sprite_mochila.material = sprite_mochila.material.duplicate()
			(sprite_mochila.material as ShaderMaterial).set_shader_parameter("cor", mochila.cor)
