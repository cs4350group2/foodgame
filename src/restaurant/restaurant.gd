class_name Restaurant
extends Node

@onready var sittingNodes = $SittingNodes.get_children()

func _ready():
	RestaurantManager.register_sitting_nodes(sittingNodes)
