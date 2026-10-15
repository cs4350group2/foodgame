extends ProtoController
class_name Player

@export var max_hold_retraction: float = 0.35

@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay
var focused_component: InteractComponent

@onready var hold_point: Marker3D = $Head/Camera3D/HoldPoint
@onready var hold_visual_point: Marker3D = \
	$Head/Camera3D/HoldVisualPoint
var held_edible: EdibleItem
var _interact_requested: bool = false
var _alt_interact_requested : bool = false

var _saved_collision_layer: int
var _saved_collision_mask: int
var _saved_freeze: bool
var _saved_interaction_enabled: bool
var _held_scale: Vector3

@onready var crosshair: Control = $CanvasLayer/Crosshair # added reticle reference for easy access
@onready var tooltip: Tooltip = \
	$CanvasLayer/Crosshair/Tooltip

func _ready() -> void:
	super._ready()
	interact_ray.add_exception(self)
	# the moment this player enters, take control of the mouse
	capture_mouse()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if is_instance_valid(held_edible):
		update_held_food_transform()
	else:
		held_edible = null

	if _alt_interact_requested and _can_alt_interact():
		try_alt_interact()
	elif _interact_requested:
		try_interact()

	_alt_interact_requested = false
	_interact_requested = false

	update_focus()
	update_chopping_progress()
	update_tooltip()
	
# Interaction funcs
func update_focus() -> void:
	interact_ray.force_raycast_update()
	var next_component := get_look_component()

	if is_instance_valid(next_component) \
			and not next_component.supports_primary \
			and not next_component.supports_secondary:
		next_component = null

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
	_release_held_edible()

	if is_instance_valid(focused_component):
		focused_component.set_highlighted(false)

	focused_component = null

func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)

	if event.is_action_pressed("interact") and not event.is_echo():
		_interact_requested = true
	if event.is_action_pressed("alt_interact") and not event.is_echo():
		_alt_interact_requested = true
		
func get_look_component() -> InteractComponent:
	if not interact_ray.is_colliding():
		return null

	var target := interact_ray.get_collider() as Node

	while target != null:
		var component := target.get_node_or_null(
			"InteractComponent"
		) as InteractComponent

		if component != null and component.enabled:
			return component

		target = target.get_parent()

	return null
	
func try_alt_interact() -> void:
	interact_ray.force_raycast_update()
	var component := get_look_component()

	if is_instance_valid(component) and component.supports_secondary:
		component.alt_interact(self)
	
func try_interact() -> void:
	interact_ray.force_raycast_update()
	var component := get_look_component()
	
	if is_instance_valid(held_edible) and is_instance_valid(component):
		var target := component.get_parent() as EdibleItem
		if is_instance_valid(target):
			swap_edible(target)
			return

	if is_instance_valid(held_edible):
		if is_instance_valid(component) \
				and component.supports_primary \
				and component.accepts_primary_while_holding:
			component.interact(self)
			return

		drop_edible()
		return

	if is_instance_valid(component) and component.supports_primary:
		component.interact(self)

# Pickup funcs
func pick_up_edible(edible : EdibleItem) -> void:
	if is_instance_valid(held_edible):
		return

	if not is_instance_valid(edible):
		return

	# Remember the item's settings before changing them
	_saved_collision_layer = edible.collision_layer
	_saved_collision_mask = edible.collision_mask
	_saved_freeze = edible.freeze
	_saved_interaction_enabled = edible.interaction.enabled
	_held_scale = edible.global_basis.get_scale()

	# Remove the highlight before entering the holding state
	if is_instance_valid(focused_component):
		focused_component.set_highlighted(false)

	focused_component = null
	edible.interaction.set_highlighted(false)
	edible.interaction.enabled = false

	# Stop physics from moving or colliding with the held item
	edible.freeze = true
	edible.linear_velocity = Vector3.ZERO
	edible.angular_velocity = Vector3.ZERO
	edible.collision_layer = 0
	edible.collision_mask = 0

	held_edible = edible
	update_held_food_transform()
	edible.reset_physics_interpolation()
	print("Picked up: ", edible.get_edible_item_name())
	
func update_held_food_transform() -> void:
	if not is_instance_valid(held_edible):
		return

	var camera := hold_visual_point.get_parent() as Camera3D
	var start := camera.global_position
	var motion := hold_visual_point.global_position - start
	var held_basis := (
		hold_visual_point.global_basis.orthonormalized()
		* Basis.from_scale(_held_scale)
	)
	var space := get_world_3d().direct_space_state
	var safe_fraction: float = 1.0
	var exclusions: Array[RID] = [get_rid(), held_edible.get_rid()]

	for child in held_edible.get_children():
		var collider := child as CollisionShape3D
		if collider == null:
			continue
		if collider.disabled or collider.shape == null:
			continue

		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = collider.shape
		query.transform = (
			Transform3D(held_basis, start) * collider.transform
		)
		query.motion = motion
		query.collision_mask = _saved_collision_mask
		query.exclude = exclusions
		query.margin = 0.03

		var fractions := space.cast_motion(query)
		safe_fraction = minf(safe_fraction, fractions[0])

	var distance := motion.length()
	var min_fraction: float = 0.0

	if distance > 0.001:
		min_fraction = maxf(
			0.0,
			1.0 - max_hold_retraction / distance
		)

	safe_fraction = maxf(safe_fraction, min_fraction)

	held_edible.global_transform = Transform3D(
		held_basis,
		start + motion * safe_fraction
	)
	
func _held_drop_transform() -> Transform3D:
	return Transform3D(
		hold_point.global_basis.orthonormalized()
			* Basis.from_scale(_held_scale),
		hold_point.global_position
	)
		
func drop_edible() -> void:
	if not is_instance_valid(held_edible):
		held_edible = null
		return

	if not _can_drop_food():
		print("Not enough space to drop the food.")
		return
	
	print("Dropped edible/ingredient: ", held_edible.get_edible_item_name())
	_release_held_edible()
	
func _can_drop_food(ignore_item: EdibleItem = null) -> bool:
	var space := get_world_3d().direct_space_state

	for child in held_edible.get_children():
		var collider := child as CollisionShape3D

		if collider == null:
			continue
		if collider.disabled or collider.shape == null:
			continue

		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = collider.shape
		query.transform = _held_drop_transform() * collider.transform
		query.collision_mask = _saved_collision_mask
		var exclusions: Array[RID] = [held_edible.get_rid()]
		
		if is_instance_valid(ignore_item):
			exclusions.append(ignore_item.get_rid())
		query.exclude = exclusions
		query.margin = 0.01

		var hits := space.intersect_shape(query, 8)
		if not hits.is_empty():
			for hit in hits:
				var blocker := hit["collider"] as Node
				if is_instance_valid(blocker):
					print(
						"Cannot release ", held_edible.get_edible_item_name(),
						"; blocked by ", blocker.get_path()
					)
			return false

	return true
	
func _release_held_edible() -> EdibleItem:
	var food := held_edible
	held_edible = null

	# The food may already have been deleted.
	if not is_instance_valid(food):
		return null
		
	food.global_transform = _held_drop_transform()
	food.reset_physics_interpolation()
	
	food.collision_layer = _saved_collision_layer
	food.collision_mask = _saved_collision_mask

	food.linear_velocity = Vector3.ZERO
	food.angular_velocity = Vector3.ZERO
	food.freeze = _saved_freeze
	food.sleeping = false

	if is_instance_valid(food.interaction):
		food.interaction.set_highlighted(false)
		food.interaction.enabled = _saved_interaction_enabled
	return food
	
func swap_edible(target: EdibleItem) -> bool:
	if not is_instance_valid(held_edible):
		return false
	if not is_instance_valid(target) or target == held_edible:
		return false
	if not is_instance_valid(target.interaction):
		return false
	if not target.interaction.enabled:
		return false

	if not _can_drop_food(target):
		print("Swap blocked: no room to release held item.")
		return false

	_release_held_edible()
	pick_up_edible(target)

	if held_edible == target:
		print("Swap successful: now holding ", target.get_edible_item_name())
		return true

	return false
		
func _can_alt_interact() -> bool:
	interact_ray.force_raycast_update()
	var component := get_look_component()

	return is_instance_valid(component) \
		and component.supports_secondary

# Chopping
func update_chopping_progress() -> void:
	var progress: float = 0.0

	if is_instance_valid(focused_component):
		var board := focused_component.get_parent() as ChoppingBoard

		if board != null:
			progress = board.get_chopping_progress()

	crosshair.set_chopping_progress(progress)
	
# Tooltip on hover
func update_tooltip() -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		tooltip.hide()
		return

	tooltip.show_target(focused_component, self)
