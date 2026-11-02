extends Resource
class_name CustomerSpawnRule

@export var customer_type: StringName
@export_range(1, 100, 1) var danger_rating: int = 1
@export_range(0.0, 100.0) var selection_weight: float = 1.0

func _init(type: StringName = &"", danger: int = 1) -> void:
	customer_type = type
	danger_rating = danger
