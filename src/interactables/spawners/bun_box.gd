extends Node3D

@onready var interaction: InteractComponent = $"InteractComponent"

func _ready() -> void:
	interaction.interacted.connect(_on_interacted)

func _on_interacted(_player: Player) -> void:
	print("Interacted with the burger bun box.")
	# Spawn an ingredient here.
