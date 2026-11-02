extends Node3D
class_name WashingSink

const WASHED_SCENES = {
	"res://models/physics/food/ingredients/dirtyTomato.tscn":
		preload("res://models/physics/food/ingredients/cleanTomato.tscn"),
	"res://models/physics/food/ingredients/dirtyPotato.tscn":
		preload("res://models/physics/food/ingredients/cleanPotato.tscn"),
	"res://models/physics/food/ingredients/fishRaw.tscn":
		preload("res://models/physics/food/ingredients/fishSkinned.tscn"),
}
@export_range(1.0, 10.0, 0.5) var required_turns: float = 3.0

@onready var interaction: InteractComponent = $InteractComponent
@onready var food_point: Marker3D = $FoodPoint

var stored_edible: EdibleItem

var _original_freeze: bool
var _original_interaction_enabled: bool
var _original_collision_layer: int
var _original_collision_mask: int
var _wash_angle: float = 0.0


func _ready() -> void:
	interaction.supports_primary = true
	interaction.supports_secondary = true
	interaction.accepts_primary_while_holding = true

	interaction.display_name = "Sink"
	interaction.tooltip_provider = _get_tooltip_actions

	interaction.interacted.connect(_on_interacted)
	interaction.alt_interacted.connect(_on_alt_interacted)

func _on_interacted(player: Player) -> void:
	if not is_instance_valid(stored_edible):
		stored_edible = null
		_wash_angle = 0.0

	if is_instance_valid(player.held_edible):
		if stored_edible != null:
			return

		if not WASHED_SCENES.has(player.held_edible.scene_file_path):
			return

		var food := player._release_held_edible()
		if is_instance_valid(food):
			_store_food(food)

	elif stored_edible != null:
		_take_food(player)

func _on_alt_interacted(player: Player) -> void:
	if can_wash():
		player.start_washing(self)


func can_wash() -> bool:
	return is_instance_valid(stored_edible) \
		and WASHED_SCENES.has(stored_edible.scene_file_path)


func get_washing_progress() -> float:
	if not can_wash():
		return 0.0

	return clampf(
		absf(_wash_angle) / (TAU * required_turns),
		0.0,
		1.0
	)


# Returns true only when the dirty ingredient was successfully replaced.
func add_washing_rotation(angle_change: float) -> bool:
	if not can_wash():
		return false

	_wash_angle += angle_change

	if get_washing_progress() >= 1.0:
		return _finish_washing()

	return false
	
func _store_food(food: EdibleItem) -> void:
	_original_freeze = food.freeze
	_original_interaction_enabled = food.interaction.enabled
	_original_collision_layer = food.collision_layer
	_original_collision_mask = food.collision_mask

	food.interaction.set_highlighted(false)
	food.interaction.enabled = false
	food.freeze = true
	food.linear_velocity = Vector3.ZERO
	food.angular_velocity = Vector3.ZERO

	# Stored food must not block the player's ray from hitting the sink.
	food.collision_layer = 0
	food.collision_mask = 0

	if food.get_parent() != self:
		food.reparent(self, true)

	var food_scale := food.global_basis.get_scale()
	var placed_basis := food_point.global_basis.orthonormalized() \
		* Basis.from_scale(food_scale)

	food.global_transform = Transform3D(
		placed_basis,
		food_point.global_position
	)
	food.reset_physics_interpolation()

	stored_edible = food
	_wash_angle = 0.0


func _take_food(player: Player) -> void:
	var food := stored_edible

	food.reparent(get_tree().current_scene, true)
	food.freeze = _original_freeze
	food.interaction.enabled = _original_interaction_enabled
	food.collision_layer = _original_collision_layer
	food.collision_mask = _original_collision_mask

	player.pick_up_edible(food)

	if player.held_edible == food:
		stored_edible = null
		_wash_angle = 0.0
	else:
		food.reparent(self, true)
		food.freeze = true
		food.interaction.enabled = false
		food.collision_layer = 0
		food.collision_mask = 0


func _finish_washing() -> bool:
	var original := stored_edible
	var original_transform := original.global_transform

	var output_scene: PackedScene = \
		WASHED_SCENES[original.scene_file_path]

	var instance := output_scene.instantiate()
	var washed := instance as EdibleItem

	if washed == null:
		instance.queue_free()
		push_error("Washed ingredient must use EdibleItem.")
		return false

	# Initialize @onready references, as the chopping board does.
	add_child(washed)

	if not is_instance_valid(washed.interaction):
		washed.queue_free()
		push_error("Washed ingredient needs an InteractComponent.")
		return false

	# Cancel the scale inherited from the sink's transformed parent.
	# _store_food() will now preserve the original ingredient's world scale.
	washed.global_transform = original_transform

	_store_food(washed)

	original.collision_layer = 0
	original.collision_mask = 0
	original.queue_free()

	return true


func _get_tooltip_actions(player: Player) -> Dictionary:
	var primary := ""
	var secondary := ""
	var details := "Contents: Empty"

	var occupied := is_instance_valid(stored_edible)
	var holding := is_instance_valid(player.held_edible)

	if occupied:
		details = "Contents: %s" % stored_edible.get_edible_item_name()

		if can_wash():
			details += "\nWashing: %d%%" % int(
				get_washing_progress() * 100.0
			)
		else:
			details += "\nClean — ready to take"

	if holding:
		if occupied:
			details += "\nThe sink is occupied"
		elif WASHED_SCENES.has(player.held_edible.scene_file_path):
			primary = "Place ingredient"
		else:
			details += "\nCannot wash %s" \
				% player.held_edible.get_edible_item_name()
	elif occupied:
		primary = "Take ingredient"

		if can_wash():
			secondary = "Start washing"

	return {
		"details": details,
		"primary": primary,
		"secondary": secondary,
	}
