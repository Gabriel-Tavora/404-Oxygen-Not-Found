extends Panel

@onready var _fala: Label = $Fala


func mostrar(fala: String) -> void:
	_fala.text = fala
	show()
