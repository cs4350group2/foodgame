extends Resource
class_name CustomerArrival

@export var customer_type: StringName
@export var arrival_time: float = 0.0

func _init(ct: StringName = "regular", at: float = 0.0) -> void:
	customer_type = ct
	arrival_time = at
