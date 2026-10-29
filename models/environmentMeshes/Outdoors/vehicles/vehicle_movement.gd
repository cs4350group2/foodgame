
extends Node3D

@export var speed: float = 10.0
	
func _physics_process(delta: float) -> void:
	global_position += global_transform.basis.z * speed * delta

@export var lifetime: float = 15.0

func _ready() -> void:
	await get_tree().create_timer(lifetime).timeout
	queue_free()
