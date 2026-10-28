extends Node3D

const WASHED_SCENES = {
	"res://models/physics/food/ingredients/dirtyTomato.tscn":
		preload("res://models/physics/food/ingredients/cleanTomato.tscn"),
	"res://models/physics/food/ingredients/dirtyPotato.tscn":
		preload("res://models/physics/food/ingredients/cleanPotato.tscn"),
	"res://models/physics/food/ingredients/fishRaw.tscn":
		preload("res://models/physics/food/ingredients/fishSkinned.tscn"),
}

@onready var interaction: InteractComponent = $InteractComponent


func _ready() -> void:
	interaction.supports_primary = false
	interaction.supports_secondary = true
	interaction.display_name = "Sink"
	interaction.tooltip_provider = _get_tooltip_actions
	interaction.alt_interacted.connect(_on_alt_interacted)


func _on_alt_interacted(player: Player) -> void:
	var original := player.held_edible
	if not is_instance_valid(original):
		return

	var original_path := original.scene_file_path
	if not WASHED_SCENES.has(original_path):
		return

	var washed_scene: PackedScene = WASHED_SCENES[original_path]
	var instance := washed_scene.instantiate()
	var washed := instance as EdibleItem

	if washed == null:
		instance.queue_free()
		push_error("Washed ingredient must use EdibleItem.")
		return

	# Initialize the replacement before changing the held item.
	get_tree().current_scene.add_child(washed)
	washed.global_transform = original.global_transform

	if not is_instance_valid(washed.interaction):
		washed.queue_free()
		push_error("Washed ingredient needs an InteractComponent.")
		return

	player._release_held_edible()
	player.pick_up_edible(washed)

	if player.held_edible != washed:
		washed.queue_free()
		player.pick_up_edible(original)
		return

	# Disable the old collider immediately; deletion happens later.
	original.collision_layer = 0
	original.collision_mask = 0
	original.queue_free()


func _get_tooltip_actions(player: Player) -> Dictionary:
	var secondary := ""
	var details := ""

	if is_instance_valid(player.held_edible):
		var ingredient := player.held_edible
		if WASHED_SCENES.has(ingredient.scene_file_path):
			secondary = "Wash ingredient"
			details = ingredient.get_edible_item_name()
		else:
			details = "Cannot wash %s" \
					% ingredient.get_edible_item_name()

	return {
		"details": details,
		"secondary": secondary,
	}
