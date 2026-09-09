extends Node

class_name InteractComponent

signal interacted(player: Player)

@export var enabled: bool = true

func interact(player: Player) -> void:
	if enabled:
		interacted.emit(player)
