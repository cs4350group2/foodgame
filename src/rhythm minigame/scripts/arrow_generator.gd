extends Node2D

@export var arrow_to_generate : PackedScene

func make_arrow() -> void:
	add_child(arrow_to_generate.instantiate())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
