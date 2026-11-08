extends Node

var notification_data: Dictionary

func _ready() -> void:
	var file = FileAccess.open("res://data/notification.json", FileAccess.READ)
	if file == null:
		push_error("Could not open notification.json")
		return
	notification_data = JSON.parse_string(file.get_as_text())

func get_notification_data() -> Dictionary:
	return notification_data

func get_restaurant_ui() -> RestaurantUI:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return null
	return current_scene.get_node_or_null("RestaurantUi") as RestaurantUI

func show_top(message: String, show_description: bool = false, description_message: String = "") -> void:
	var restaurant_ui := get_restaurant_ui()
	if restaurant_ui == null:
		push_warning("Cannot show notification: RestaurantUi is not in the current scene.")
		return
	restaurant_ui.show_notification_top(message, show_description, description_message)

func show_error(message: String) -> void:
	var restaurant_ui := get_restaurant_ui()
	if restaurant_ui == null:
		push_warning("Cannot show notification: RestaurantUi is not in the current scene.")
		return
	restaurant_ui.show_notification_error_bottom(message)

func show_side(message: String) -> void:
	var restaurant_ui := get_restaurant_ui()
	if restaurant_ui == null:
		push_warning("Cannot show notification: RestaurantUi is not in the current scene.")
		return
	restaurant_ui.show_side(message)
