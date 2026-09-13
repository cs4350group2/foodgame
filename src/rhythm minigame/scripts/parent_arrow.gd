extends Node2D
class_name Arrow

@export var arrow_speed : float = 1 # time taken for note to reach judgment line from top, in seconds
@export var y_destination : float = 700

var target_hit_time_ms: float 
var pair_target_arrow: Arrow = null

@onready var connector_line: Line2D = $ArrowDown/ConnectorLine # connector line for simultaneous notes/arrows

func _ready() -> void:
	var initial_position : Vector2 = self.position # arrow's initial position when spawned
	var tween = create_tween()
	tween.tween_property(self, "position", Vector2(initial_position.x, y_destination), arrow_speed)

func setup_connector(target_arrow : Arrow) -> void:
	pair_target_arrow = target_arrow
	
	# initialise the connector line
	connector_line.clear_points()
	connector_line.add_point(Vector2.ZERO)
	connector_line.add_point(Vector2.ZERO)
	
	connector_line.visible = true

func _process(_delta : float) -> void:
	if is_instance_valid(pair_target_arrow) and connector_line.visible:
		var local_target_pos: Vector2 = to_local(pair_target_arrow.global_position)
		connector_line.set_point_position(0, Vector2.ZERO)
		connector_line.set_point_position(1, local_target_pos)
	
	else:
		connector_line.visible = false
