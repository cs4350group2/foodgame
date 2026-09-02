extends Node3D

@onready var player = $ProtoController

func _physics_process(delta):
	return
	#get_tree().call_group("customers", "update_target_location", player.global_transform.origin)
