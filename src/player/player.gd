extends ProtoController
class_name Player

@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay

func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)

	if event.is_action_pressed("interact"):
		try_interact()

func get_look_component() -> InteractComponent:
	if not interact_ray.is_colliding():
		return null

	var target := interact_ray.get_collider() as Node

	while target != null:
		var component := target.get_node_or_null(
	        "InteractComponent"
		) as InteractComponent

		if component != null:
			if component.enabled:
				return component
			return null

		target = target.get_parent()

	return null
	
func try_interact() -> void:
	interact_ray.force_raycast_update()
	
	var component := get_look_component()
	if component != null:
		component.interact(self)
