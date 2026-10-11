extends StaticBody3D

@onready var interaction: InteractComponent = $InteractComponent
@onready var food_point: Marker3D = $FoodPoint

var stored_edible: EdibleItem
var _stored_original_freeze: bool
var _stored_original_interaction_enabled: bool


func _ready() -> void:
	interaction.supports_primary = true
	interaction.accepts_primary_while_holding = true
	interaction.interacted.connect(_on_interacted)


func _on_interacted(player: Player) -> void:
	if not is_instance_valid(stored_edible):
		stored_edible = null

	if is_instance_valid(player.held_edible):
		if stored_edible != null:
			print("The chopping board is occupied.")
			return

		_place_food(player)
	elif stored_edible != null:
		_take_food(player)


func _place_food(player: Player) -> void:
	var food := player._release_held_edible()
	if not is_instance_valid(food):
		return

	_stored_original_freeze = food.freeze
	_stored_original_interaction_enabled = food.interaction.enabled

	food.interaction.set_highlighted(false)
	food.interaction.enabled = false
	food.freeze = true
	food.linear_velocity = Vector3.ZERO
	food.angular_velocity = Vector3.ZERO

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


func _take_food(player: Player) -> void:
	var food := stored_edible

	food.reparent(get_tree().current_scene, true)
	food.freeze = _stored_original_freeze
	food.interaction.enabled = _stored_original_interaction_enabled

	player.pick_up_edible(food)

	if player.held_edible == food:
		stored_edible = null
	else:
		food.reparent(self, true)
		food.freeze = true
		food.interaction.enabled = false
