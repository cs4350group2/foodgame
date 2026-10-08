extends Node2D
class_name Arrow

@export var arrow_speed : float = 1 # time taken for note to reach judgment line from top, in seconds
@export var y_destination : float = 600 # judgment line y-coordinate
@export var miss_overflow_distance : float = 100 # the y-distance travelled past the judgment line before arrow disappears

var target_hit_time_ms: float 
var pair_target_arrow: Arrow = null
var is_hit: bool = false
var move_tween: Tween # store reference so we can kill it on hit

@onready var connector_line: Line2D = $ArrowDown/ConnectorLine # connector line for simultaneous notes/arrows
@onready var animation_player: AnimationPlayer = $AnimationPlayer # animation player for popping/explosion effect
@onready var hit_effect_player: AudioStreamPlayer = $HitEffectPlayer # hit effect player to play the note SFX
 
func _ready() -> void:
	var initial_position : Vector2 = self.position # arrow's initial position when spawned
	
	move_tween = create_tween()
	
	# main fall to judgment line
	move_tween.tween_property(self, "position", Vector2(initial_position.x, y_destination), arrow_speed)
	
	# falling past judgment line at the same speed (to not mess with the initial fall's maths)
	var overflow_time: float = arrow_speed * (miss_overflow_distance / y_destination)
	move_tween.tween_property(self, "position", Vector2(initial_position.x, y_destination + miss_overflow_distance), overflow_time)

func setup_connector(target_arrow : Arrow) -> void:
	pair_target_arrow = target_arrow
	
	# initialise the connector line
	connector_line.clear_points()
	connector_line.add_point(Vector2.ZERO)
	connector_line.add_point(Vector2.ZERO)
	
	connector_line.visible = true

func _process(_delta : float) -> void:
	if is_hit or not is_instance_valid(pair_target_arrow) or pair_target_arrow.is_hit:
		if is_instance_valid(connector_line):
			connector_line.visible = false
			
	if is_instance_valid(pair_target_arrow) and connector_line.visible:
		var local_target_pos: Vector2 = to_local(pair_target_arrow.global_position)
		connector_line.set_point_position(0, Vector2.ZERO)
		connector_line.set_point_position(1, local_target_pos)
	
	else:
		connector_line.visible = false

func play_hit_anim() -> void:
	is_hit = true
	set_process(false)
	set_physics_process(false)
	
	# prevent any wacky connector line distorting	
	if connector_line: 
		connector_line.visible = false
		connector_line.clear_points()
		
	if is_instance_valid(pair_target_arrow):
		if is_instance_valid(pair_target_arrow.connector_line):
			pair_target_arrow.connector_line.visible = false
			pair_target_arrow.connector_line.clear_points()
		
		pair_target_arrow.pair_target_arrow = null
		pair_target_arrow = null
	
	if move_tween and move_tween.is_running():
		move_tween.kill()
	
	# snap arrow position to judgment line
	global_position.y = y_destination
	
	# the animation handles freeing the arrow, so no other method call needed
	animation_player.play("successful_hit")
