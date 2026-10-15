extends Node3D

@onready var interaction: InteractComponent = $InteractComponent


func _ready() -> void:
	interaction.supports_primary = true
	interaction.accepts_primary_while_holding = true
	interaction.interacted.connect(_on_interacted)
	interaction.display_name = "Trashcan"
	interaction.tooltip_provider = _get_tooltip_actions

func _on_interacted(player: Player) -> void:
	if not is_instance_valid(player.held_edible):
		return

	var item_name := player.held_edible.get_edible_item_name()
	var food := player._release_held_edible()

	food.queue_free()
	print("Threw out ", item_name, ".")

func _get_tooltip_actions(player: Player) -> Dictionary:
	var primary := ""

	if is_instance_valid(player.held_edible):
		primary = "Discard held item"

	return {"primary": primary}
