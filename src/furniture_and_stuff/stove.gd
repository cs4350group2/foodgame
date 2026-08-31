extends StaticBody2D

func _ready() -> void:
	add_to_group("Interactables")

func interact(player: CharacterBody2D) -> void:
	print("The player uses the stove.")
