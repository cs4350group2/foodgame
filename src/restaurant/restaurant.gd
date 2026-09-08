extends Node

@onready var sittingNodes = $SittingNodes.get_children()

func _ready():
	RestaurantManager.register_sitting_nodes(sittingNodes)

func _physics_process(delta: float) -> void:
	for child in self.get_children():
		if child is Customer:
			RestaurantManager.add_customer(child)
