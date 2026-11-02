extends Resource
class_name CustomerArrival

@export var customer_type: StringName
@export var arrival_time: float = 0.0
@export var wave_index: int = -1

func _init(ct: StringName = &"", at: float = 0.0, wave: int = -1) -> void:
	customer_type = ct
	arrival_time = at
	wave_index = wave
