extends Node3D
class_name FoodSpawner

@export var food_scene: PackedScene
@export var spawner_name: String = "spawner"
@onready var interaction: InteractComponent = $"InteractComponent"

var _ingredient_name: String = ""

func _ready() -> void:
	interaction.supports_primary = true
	interaction.interacted.connect(_on_interacted)
	interaction.display_name = spawner_name
	interaction.tooltip_provider = _get_tooltip_actions

	if food_scene != null:
		var preview := food_scene.instantiate()
		if preview is EdibleItem:
			_ingredient_name = preview.ingredient_name
		preview.free()


func _on_interacted(player: Player) -> void:
	if is_instance_valid(player.held_edible):
		return
	if food_scene == null:
		return
	var food := food_scene.instantiate() as EdibleItem
	get_tree().current_scene.add_child(food)
	player.pick_up_edible(food)
	print("Pulled %s from the %s." % [
		food.ingredient_name,
		spawner_name,
	])
	var message: String = NotificationManager.get_notification_data()["action_notification"].get("pulled_ingredient")
	message = message % [food.ingredient_name, spawner_name]
	NotificationManager.show_side(message)

func _get_tooltip_actions(_player: Player) -> Dictionary:
	var prompt := ""
	if food_scene != null:
		prompt = "Grab ingredient"
		if not _ingredient_name.is_empty():
			prompt = "Grab %s" % _ingredient_name

	return {"primary": prompt}
