extends StaticBody3D


# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("interactables")

func interact(_player: CharacterBody3D) -> void:
	print("Interacted with the bar table.")
