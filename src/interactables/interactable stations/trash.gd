extends Node3D

@onready var interaction: InteractComponent = $"InteractComponent"

func _ready() -> void:
	interaction.interact_while_holding = true
	interaction.interacted.connect(_on_interacted)

func _on_interacted(player: Player) -> void:
	if not is_instance_valid(player.held_food):
		return

	var food := player.held_food
	player.held_food = null
	food.queue_free()
	print("Threw out ", food.food_name, ".")
