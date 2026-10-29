extends Node3D

@onready var interaction: InteractComponent = $InteractComponent


func _ready() -> void:
	interaction.display_name = "Microwave"
	interaction.supports_primary = true
	interaction.supports_secondary = false
	interaction.interacted.connect(_on_interacted)

func _on_interacted(_player: Player) -> void:
	print("Interacted with the microwave.")
