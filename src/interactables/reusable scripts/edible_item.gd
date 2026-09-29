extends RigidBody3D
class_name EdibleItem

@export var food_name : String = "" # for ingredients

@export var food_data : Food
# can add drink_data for when we introduce drinks after MVP
# for now implementation is simple as we only have food. will make adjustments in future iterations

@onready var interaction: InteractComponent = $InteractComponent

func _ready() -> void:
	interaction.interacted.connect(_on_interacted)

func _on_interacted(player: Player) -> void:
	if food_data == null: # ingredient
		print("Picked up ingredient: ", food_name)
	else: # dish/drink
		print("Picked up edible: ", food_data.edible_name)
	# Add shared food pickup behavior here later.
	player.pick_up_edible(self)

func get_data() -> Food:
	return food_data

func get_food_name() -> String:
	if not food_data == null:
		return food_data.get_edible_name()
	else:
		return food_name
