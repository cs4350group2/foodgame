extends ProtoController
class_name Player

@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay
var focused_component: InteractComponent

func _ready() -> void:
	super._ready()
	interact_ray.add_exception(self)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	update_focus()

func update_focus() -> void:
	interact_ray.force_raycast_update()
	var next_component := get_look_component()

	if not is_instance_valid(focused_component):
		focused_component = null

	if next_component == focused_component:
		return

	if focused_component != null:
		focused_component.set_highlighted(false)

	focused_component = next_component

	if focused_component != null:
		focused_component.set_highlighted(true)

func _exit_tree() -> void:
	if is_instance_valid(focused_component):
		focused_component.set_highlighted(false)

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
	update_focus()

	if is_instance_valid(focused_component):
		focused_component.interact(self)
