extends Node

signal solta(cor: Color)

var esta_solta := false
var cor_asas := Color.TRANSPARENT


func soltar(cor: Color) -> void:
	esta_solta = true
	cor_asas = cor
	solta.emit(cor_asas)
