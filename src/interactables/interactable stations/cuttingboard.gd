extends StaticBody3D
class_name ChoppingBoard

const CHOPPED_SCENES = {
	"res://models/physics/food/ingredients/meatRaw.tscn":
		preload("res://models/physics/food/ingredients/pattyRaw.tscn"),
	"res://models/physics/food/ingredients/tomatoWhole.tscn":
		preload("res://models/physics/food/ingredients/tomatoSliced.tscn"),
	"res://models/physics/food/ingredients/potato.tscn":
		preload("res://models/physics/food/ingredients/potatoSliced.tscn")
}

const REQUIRED_CLICKS: int = 4

@onready var interaction: InteractComponent = $InteractComponent
@onready var food_point: Marker3D = $FoodPoint

var stored_edible: EdibleItem
var _stored_original_freeze: bool
var _stored_original_interaction_enabled: bool
var _chop_clicks: int = 0


func _ready() -> void:
	interaction.supports_primary = true
	interaction.supports_secondary = true
	interaction.accepts_primary_while_holding = true

	interaction.interacted.connect(_on_interacted)
	interaction.alt_interacted.connect(_on_alt_interacted)


func _on_interacted(player: Player) -> void:
	if not is_instance_valid(stored_edible):
		stored_edible = null
		_chop_clicks = 0

	if is_instance_valid(player.held_edible):
		if stored_edible != null:
			print("The chopping board is occupied.")
			return

		var food := player._release_held_edible()
		if is_instance_valid(food):
			_store_food(food)

	elif stored_edible != null:
		_take_food(player)


func _on_alt_interacted(player: Player) -> void:
	# Confirm the player is still looking at this board.
	player.interact_ray.force_raycast_update()
	if player.get_look_component() != interaction:
		return

	if not can_chop():
		return

	_chop_clicks += 1

	if _chop_clicks >= REQUIRED_CLICKS:
		_finish_chopping()


func can_chop() -> bool:
	return is_instance_valid(stored_edible) \
		and CHOPPED_SCENES.has(stored_edible.scene_file_path)


func get_chopping_progress() -> float:
	if not can_chop():
		return 0.0

	return float(_chop_clicks) / float(REQUIRED_CLICKS)


func _store_food(food: EdibleItem) -> void:
	_stored_original_freeze = food.freeze
	_stored_original_interaction_enabled = food.interaction.enabled

	food.interaction.set_highlighted(false)
	food.interaction.enabled = false
	food.freeze = true
	food.linear_velocity = Vector3.ZERO
	food.angular_velocity = Vector3.ZERO

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
	_chop_clicks = 0


func _take_food(player: Player) -> void:
	var food := stored_edible

	food.reparent(get_tree().current_scene, true)
	food.freeze = _stored_original_freeze
	food.interaction.enabled = _stored_original_interaction_enabled

	player.pick_up_edible(food)

	if player.held_edible == food:
		stored_edible = null
		_chop_clicks = 0
	else:
		food.reparent(self, true)
		food.freeze = true
		food.interaction.enabled = false


func _finish_chopping() -> void:
	var output_scene: PackedScene = \
		CHOPPED_SCENES[stored_edible.scene_file_path]

	var instance := output_scene.instantiate()
	var chopped := instance as EdibleItem

	if chopped == null:
		instance.queue_free()
		_chop_clicks = REQUIRED_CLICKS - 1
		push_error("Chopped food must use EdibleItem.")
		return

	# Initialize its @onready references before accessing interaction.
	add_child(chopped)

	if not is_instance_valid(chopped.interaction):
		chopped.queue_free()
		_chop_clicks = REQUIRED_CLICKS - 1
		push_error("Chopped food needs an InteractComponent.")
		return

	var original := stored_edible
	var original_name := original.get_edible_item_name()

	_store_food(chopped)

	# Remove the old collider immediately before deferred deletion.
	original.collision_layer = 0
	original.collision_mask = 0
	original.queue_free()

	print(
		"Chopped ",
		original_name,
		" into ",
		chopped.get_edible_item_name(),
		"."
	)
