extends Resource
class_name ArrivalConfig

@export_range(0, 1000, 1) var gradual_customer_count: int = 1
@export var wave_sizes: Array[int] = [2]
@export_range(0, 1000, 1) var danger_rating: int = 0
## Adds one Celebrity after the final rush, independently of special unlocks.
@export var celebrity_boss: bool = false
@export_range(0.1, 60.0) var wave_spawn_interval: float = 2.0
@export_range(0.1, 10.0) var wave_special_weight: float = 2.0
@export var first_arrival_delay: float = 5.0
@export var total_time: float = 0.0
