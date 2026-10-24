# Drink act as purchasable consumables that provides 
# gameplay advantages for the player

class_name Drink
extends Edible

var description: String = "A regular drink." # General description
var usage: String = "Does nothing." # Practical description
var scene_path: String = ""

func _init(edible_name: String, base_price: float, description: String, usage: String, scene_path: String = "") -> void:
	super(edible_name, base_price)
	self.description = description
	self.usage = usage
	self.scene_path = scene_path

func get_price() -> float:
	return price

func get_description() -> String:
	return description

func get_usage() -> String:
	return usage

func is_equal(other: Edible) -> bool:
	return (
		edible_name == other.edible_name
	)
