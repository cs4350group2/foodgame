extends RigidBody3D
class_name EdibleItem

@export var ingredient_name: String = "" # for ingredients

@export var food_data: Food
@export var drink_data: Drink
var is_drink: bool = false
# for now implementation is simple as we only have food. will make adjustments in future iterations

@onready var interaction: InteractComponent = $InteractComponent

var owning_level: Level

func _ready() -> void:
	interaction.supports_primary = true
	interaction.interacted.connect(_on_interacted)
	var ancestor := get_parent()
	while ancestor != null and not ancestor is Level:
		ancestor = ancestor.get_parent()
	owning_level = ancestor as Level
	if is_instance_valid(owning_level):
		owning_level.register_temp(self)
	interaction.primary_description = "Pick up"
	interaction.tooltip_provider = _get_tooltip_actions
	
func _exit_tree() -> void:
	if is_instance_valid(owning_level):
		owning_level.unregister_temp(self)
	owning_level = null

func initialize_data(item_name: String, is_drink: bool = false) -> void:
	if is_drink:
		self.is_drink = true
		var drinks_menu: Dictionary = RestaurantManager.get_drinks_menu()
		var drinks_list: Array = drinks_menu.get("drinks")
		
		for drink in drinks_list:
			if drink["name"] == item_name:
				drink_data = Drink.new(drink["name"], drink["price"], drink["description"],
					drink["usage"], drink.get("scene_path", ""))
	else:
		var restaurant_menu: Dictionary = RestaurantManager.get_menu()
		var foods_list: Array = restaurant_menu.get("foods")
		
		for food in foods_list:
			if food["name"] == item_name:
				food_data = Food.new(food["name"], food["price"], food["rarity"], 
				100.0)

func is_ingredient() -> bool:
	return food_data == null && drink_data == null

func _on_interacted(player: Player) -> void:
	if is_ingredient():
		print("Picked up ingredient: ", ingredient_name)
		var message: String = NotificationManager.get_notification_data()["action_notification"].get("picked_up_ingredient")
		message = message % ingredient_name
		NotificationManager.show_side(message)
	elif is_drink:
		print("Picked up edible: ", drink_data.get_edible_name())
		var message: String = NotificationManager.get_notification_data()["action_notification"].get("picked_up_edible")
		message = message % drink_data.get_edible_name()
		NotificationManager.show_side(message)
	else: # food
		print("Picked up edible: ", food_data.get_edible_name())
		var message: String = NotificationManager.get_notification_data()["action_notification"].get("picked_up_edible")
		message = message % food_data.get_edible_name()
		NotificationManager.show_side(message)
	# Add shared food pickup behavior here later.
	player.pick_up_edible(self)

func get_data() -> Edible:
	if is_drink:
		return drink_data
	else:
		return food_data

func get_edible_item_name() -> String:
	if is_ingredient():
		return ingredient_name
	elif is_drink:
		return drink_data.get_edible_name()
	else:
		return food_data.get_edible_name()

# Mainly used by drinks which will affect customers
func affect_customer(customer: Customer) -> bool:
	return true

func _get_tooltip_actions(player: Player) -> Dictionary:
	var details := ""
	
	if not is_drink and food_data:
		var dish_quality: float = food_data.get_dish_quality()
		details = "Quality: %.2f%%" % dish_quality
	
	return {
		"details": details,
	}
