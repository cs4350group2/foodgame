class_name OrderItem
extends RefCounted

var edible: Edible
var quantity: int

func _init(edible: Edible, quantity: int):
	self.edible = edible
	self.quantity = quantity

func get_edible() -> Edible:
	return edible

func get_quantity() -> int:
	return quantity

func add_quantity(qty: int) -> void:
	self.quantity += qty

func get_edible_price() -> float:
	return edible.get_price()
	
func get_total_price() -> float:
	return edible.get_price() * quantity
