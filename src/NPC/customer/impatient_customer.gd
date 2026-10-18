class_name ImpatientCustomer
extends Customer

@onready var impatient_animation_player: AnimationPlayer = $CharacterBody3D/ModelOffset/Impatient/AnimationPlayer
@onready var model_offset: Node3D = $CharacterBody3D/ModelOffset

var notification_data: Dictionary
var default_position: Vector3

func _ready() -> void:
	super._ready()
	default_position = model_offset.position
	show_spawn_notification()

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

func show_spawn_notification() -> void:
	var file := FileAccess.open("res://data/notification.json", FileAccess.READ)
	if file == null:
		push_error("Could not open notification.json")
		return

	notification_data = JSON.parse_string(file.get_as_text())
	
	var message: String = notification_data["special_customer_notification"].get(customer_type)
	var description_message: String = notification_data["special_customer_descriptions"].get(customer_type)
	restaurant_ui.show_notification_top(message, true, description_message)
