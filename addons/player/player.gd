extends ProtoController
class_name Player

@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay

func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)

	if event.is_action_pressed("interact"):
		try_interact()

func try_interact() -> void:
	if not interact_ray.is_colliding():
		return

	var target := interact_ray.get_collider() as Node
	while target != null and not target.is_in_group("interactables"):
		target = target.get_parent()

	if target != null and target.has_method("interact"):
		target.interact(self)
