class_name Edible
extends Node3D

var edible_name: String
var price: float

func _init(edible_name: String, base_price: float) -> void:
	self.edible_name = edible_name
	self.price = base_price

func get_edible_name() -> String:
	return edible_name

func get_price() -> float:
	return price

func is_equal(other: Edible) -> bool:
	return edible_name == other.edible_name

func get_bonus() -> float:
	return 0.0
