extends RefCounted

const CREDITOS := [
	["Direção de Arte, Direção de Minigames e Direção de Gameplay", "Pedro Mapurunga"],
	["Direção de Arte, Direção de Gameplay do HUB", "João Gabriel"],
	["Direção e revisão de Lógica do Minigame de Dança", "Ana Karolina"],
	["Construção de Lógica do Minigame da Esteira", "Luis Gustavo"],
	["Ideação e Planejamento de Minigames", "Daniel Silva"],
]


static func preencher_lista(lista: VBoxContainer) -> void:
	for credito: Array in CREDITOS:
		var linha := VBoxContainer.new()
		linha.add_theme_constant_override(&"separation", 2)
		lista.add_child(linha)
		linha.add_child(_criar_rotulo(credito[0], 11, Color("#a9c5dc")))
		linha.add_child(_criar_rotulo(credito[1], 17, Color("#f4f8ff")))


static func _criar_rotulo(texto: String, tamanho: int, cor: Color) -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.add_theme_font_size_override(&"font_size", tamanho)
	rotulo.add_theme_color_override(&"font_color", cor)
	return rotulo
