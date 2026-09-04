extends Node3D
class_name Interactable

func _ready() -> void:
	add_to_group("interactables")

func interact(_player: Player) -> void:
	push_warning("%s does not override interact()" % name)
