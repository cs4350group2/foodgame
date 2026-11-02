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
	
const WASHING_UI_SCRIPT = preload("res://src/player/washing.gd")

var _washing_ui: WashingUI
var _washing_sink: WashingSink
var _washing_food: EdibleItem
var _washing_complete: bool = false
var _washing_origin: Vector3
var _crosshair_visible_before_washing: bool = true

var _washing_ui_was_visible: bool = false

func _ready() -> void:
	super._ready()
	interact_ray.add_exception(self)
	# the moment this player enters, take control of the mouse
	capture_mouse()
	
	_washing_ui = WASHING_UI_SCRIPT.new()
	$CanvasLayer.add_child(_washing_ui)
	_washing_ui.configure_from_tooltip(tooltip.text_label)

func _physics_process(delta: float) -> void:
	if _washing_sink != null and not _washing_session_valid():
		_stop_washing()

	super._physics_process(delta)

	if _washing_sink != null and not _washing_session_valid():
		_stop_washing()

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

	if is_instance_valid(_washing_sink):
		tooltip.hide()
	else:
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
	_stop_washing()
	_release_held_edible()

	if is_instance_valid(focused_component):
		focused_component.set_highlighted(false)

	focused_component = null

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(_washing_sink):
		if event is InputEventMouseMotion:
			if not _washing_session_valid():
				_stop_washing()
			elif not _washing_complete:
				var angle_change := _washing_ui.move_cursor(
					event.relative
				)

				if _washing_sink.add_washing_rotation(angle_change):
					_washing_complete = true
					_washing_food = _washing_sink.stored_edible
					_washing_ui.show_complete()
				else:
					_washing_ui.set_progress(
						_washing_sink.get_washing_progress()
					)

			# Also consume motion after completion, preventing a sudden
			# camera turn while the player is finishing their gesture.
			get_viewport().set_input_as_handled()
			return

		if event.is_action_pressed("alt_interact") \
				and not event.is_echo():
			_stop_washing()
			get_viewport().set_input_as_handled()
			return

		if event.is_action_pressed("interact") \
				and not event.is_echo():
			_stop_washing()
			_interact_requested = true
			get_viewport().set_input_as_handled()
			return

		# Ignore F key repeats and secondary-button release.
		# Washing continues after the initiating button is released.
		if event.is_action("alt_interact"):
			get_viewport().set_input_as_handled()
			return

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

# Washing
func start_washing(sink: WashingSink) -> void:
	if is_instance_valid(_washing_sink):
		return

	if not is_instance_valid(sink) or not sink.can_wash():
		return

	if get_tree().paused \
			or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	if is_instance_valid(held_edible) or _washing_movement_requested():
		return

	interact_ray.force_raycast_update()
	if get_look_component() != sink.interaction:
		return

	_washing_sink = sink
	_washing_food = sink.stored_edible
	_washing_complete = false
	_washing_origin = global_position

	_interact_requested = false
	_alt_interact_requested = false

	_crosshair_visible_before_washing = crosshair.visible
	tooltip.hide()
	crosshair.hide()
	
	_washing_ui_was_visible = true
	_washing_ui.begin(sink.get_washing_progress())


func _stop_washing() -> void:
	_washing_sink = null
	_washing_food = null
	_washing_complete = false

	if is_instance_valid(_washing_ui):
		_washing_ui.hide()

		# Only restore visibility if a washing session was actually visible.
		if _washing_ui_was_visible:
			crosshair.visible = _crosshair_visible_before_washing

	_washing_ui_was_visible = false


func _washing_movement_requested() -> bool:
	return Input.get_vector(
		input_left,
		input_right,
		input_forward,
		input_back
	).length_squared() > 0.0 \
		or Input.is_action_pressed(input_jump)


func _washing_session_valid() -> bool:
	if not is_instance_valid(_washing_sink):
		return false

	if not is_instance_valid(_washing_food):
		return false

	if _washing_sink.stored_edible != _washing_food:
		return false

	if not is_instance_valid(_washing_sink.interaction) \
			or not _washing_sink.interaction.enabled:
		return false

	if get_tree().paused \
			or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return false

	if is_instance_valid(held_edible):
		return false

	if _washing_movement_requested():
		return false

	# Also stop if something physically moves the player.
	if global_position.distance_to(_washing_origin) > 0.05:
		return false

	if not _washing_complete and not _washing_sink.can_wash():
		return false

	interact_ray.force_raycast_update()
	return get_look_component() == _washing_sink.interaction


func release_mouse() -> void:
	_stop_washing()
	super.release_mouse()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_stop_washing()
		_interact_requested = false
		_alt_interact_requested = false
