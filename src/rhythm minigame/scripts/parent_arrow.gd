extends Node2D
class_name Arrow

@export var arrow_speed : float = 1 # time taken for note to reach judgment line from top, in seconds
@export var y_destination : float = 700
var target_hit_time_ms: float 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var initial_position : Vector2 = self.position # arrow's initial position when spawned
	var tween = create_tween()
	tween.tween_property(self, "position", Vector2(initial_position.x, y_destination), arrow_speed)
