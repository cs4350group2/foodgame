extends StaticBody3D
class_name ChoppingBoard

const CHOPPED_SCENES = {
	"res://models/physics/food/ingredients/meatRaw.tscn":
		preload("res://models/physics/food/ingredients/pattyRaw.tscn"),
	"res://models/physics/food/ingredients/cleanTomato.tscn":
		preload("res://models/physics/food/ingredients/tomatoSliced.tscn"),
	"res://models/physics/food/ingredients/cleanPotato.tscn":
		preload("res://models/physics/food/ingredients/potatoSliced.tscn"),
	"res://models/physics/food/ingredients/fishSkinned.tscn":
		preload("res://models/physics/food/ingredients/fishSliced.tscn"),
}

const REQUIRED_CLICKS: int = 4

@onready var interaction: InteractComponent = $InteractComponent
@onready var food_point: Marker3D = $FoodPoint
@onready var restaurant_ui: RestaurantUI = get_tree().current_scene.get_node("RestaurantUi")

var stored_edible: EdibleItem
var _stored_original_freeze: bool
var _stored_original_interaction_enabled: bool
var _chop_clicks: int = 0

# Notifications
var notification_data: Dictionary

func load_notification_data() -> void:
	var file = FileAccess.open("res://data/notification.json", FileAccess.READ)
	if file == null:
		push_error("Could not open notification.json")
		return
	notification_data = JSON.parse_string(file.get_as_text())

func _ready() -> void:
	interaction.supports_primary = true
	interaction.supports_secondary = true
	interaction.accepts_primary_while_holding = true

	interaction.interacted.connect(_on_interacted)
	interaction.alt_interacted.connect(_on_alt_interacted)
	
	interaction.display_name = "Chopping Board"
	interaction.tooltip_provider = _get_tooltip_actions
	load_notification_data()

func _on_interacted(player: Player) -> void:
	if not is_instance_valid(stored_edible):
		stored_edible = null
		_chop_clicks = 0

	if is_instance_valid(player.held_edible):
		if stored_edible != null:
			print("The chopping board is occupied.")
			var error_message: String = notification_data["error"].get("chopping_board_occupied")
			restaurant_ui.show_notification_error_bottom(error_message)
			return

		if not CHOPPED_SCENES.has(player.held_edible.scene_file_path):
			var error_message: String = notification_data["error"].get("item_cannot_be_chopped")
			restaurant_ui.show_notification_error_bottom(error_message)
			print("This item cannot be chopped.")
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

func _get_tooltip_actions(player: Player) -> Dictionary:
	var primary := ""
	var details := "Contents: Empty"

	var occupied := is_instance_valid(stored_edible)
	var holding := is_instance_valid(player.held_edible)

	if occupied:
		var item_name := stored_edible.get_edible_item_name()
		details = "Contents: %s" % item_name

		if not can_chop():
			details += "\nCannot chop %s" % item_name

	if holding:
		if occupied:
			details += "\nThe chopping board is occupied"
		else:
			var ingredient := player.held_edible

			if CHOPPED_SCENES.has(ingredient.scene_file_path):
				primary = "Place food"
			else:
				details += "\nCannot chop %s" \
					% ingredient.get_edible_item_name()
	elif occupied:
		primary = "Take food"

	return {
		"details": details,
		"primary": primary,
		"secondary": "Chop" if can_chop() else "",
	}
