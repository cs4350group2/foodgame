class_name Edible
extends Node3D

var edible_name: String
var price: float

func _init(edible_name: String, base_price: float, rarity_level: int) -> void:
	self.edible_name = edible_name
	self.base_price = base_price

func get_edible_name() -> String:
	return edible_name

func get_price() -> float:
	return price
