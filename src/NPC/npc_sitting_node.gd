class_name SittingNode
extends CSGBox3D

var vacant := true
var serving_customer: Customer = null

func is_vacant() -> bool:
	return vacant and serving_customer == null

func reserve() -> void:
	vacant = false

func assign_customer(customer: Customer) -> void:
	serving_customer = customer
	vacant = false

func clear() -> void:
	serving_customer = null
	vacant = true
