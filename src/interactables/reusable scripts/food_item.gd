extends RigidBody3D
class_name FoodItem

@export var food_name: String = "Food"

@onready var interaction: InteractComponent = $InteractComponent

func _ready() -> void:
	interaction.interacted.connect(_on_interacted)

func _on_interacted(player: Player) -> void:
	print("Interacted with ", food_name)
	# Add shared food pickup behavior here later.
	player.pick_up_food(self)
