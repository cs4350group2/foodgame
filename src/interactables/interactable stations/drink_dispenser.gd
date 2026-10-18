extends Node3D

@onready var interaction: InteractComponent = $InteractComponent


func _ready() -> void:
	interaction.supports_primary = false
	interaction.supports_secondary = true
	interaction.display_name = "Drink Dispenser"
	interaction.secondary_description = "Open drink menu"
	interaction.alt_interacted.connect(_on_alt_interacted)


func _on_alt_interacted(player: Player) -> void:
	var menu := get_tree().current_scene.get_node_or_null("RestaurantUi/DrinkMenu")
	if menu == null:
		push_warning("Drink Dispenser: RestaurantUi/DrinkMenu was not found.")
		return
	menu.open_menu(player)
