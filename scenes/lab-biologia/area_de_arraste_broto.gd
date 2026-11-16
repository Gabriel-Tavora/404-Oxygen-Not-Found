extends Control

const MARGEM := 10.0

@export var margem_extra_acima := 0.0


func _has_point(ponto: Vector2) -> bool:
	var area := Rect2(Vector2.ZERO, size).grow(MARGEM)
	return area.grow_individual(0.0, margem_extra_acima, 0.0, 0.0).has_point(ponto)
