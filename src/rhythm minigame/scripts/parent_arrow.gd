extends Node2D
class_name Arrow

@export var arrow_speed : float = 1
@export var y_destination : float = 700

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var initial_position : Vector2 = self.position # arrow's initial position when spawned
	var tween = create_tween()
	tween.tween_property(self, "position", Vector2(initial_position.x, y_destination), arrow_speed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
