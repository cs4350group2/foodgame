extends Node2D

@export var arrow_to_generate : PackedScene

func make_arrow() -> Arrow:
	var instance = arrow_to_generate.instantiate()
	add_child(instance)
	return instance
