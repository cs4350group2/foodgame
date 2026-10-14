class_name ImpatientCustomer
extends Customer

@onready var impatient_animation_player: AnimationPlayer = $CharacterBody3D/ModelOffset/Impatient/AnimationPlayer
@onready var model_offset: Node3D = $CharacterBody3D/ModelOffset

var default_position: Vector3

func _ready() -> void:
	super._ready()
	default_position = model_offset.position

func play_animation(anim: String) -> void:
	reset_offset()
	match anim:
		"Idle":
			impatient_animation_player.play("Idle")
		
		"Walk":
			impatient_animation_player.play("Walk")
		
		"Sitting_Idle":
			model_offset.position.y -= 0.2
			impatient_animation_player.play("Sitting_Idle")
		_:
			pass

func reset_offset() -> void:
	model_offset.position = default_position
