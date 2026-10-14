class_name Food
extends Edible

var rarity_level: int # Currently have 1 -> 3 levels.
var dish_quality: float # Dish quality determined by cooking minigame

func _init(edible_name: String, base_price: float, rarity_level: int, dish_quality: float = 50.0) -> void:
	super(edible_name, base_price)
	self.rarity_level = rarity_level
	self.dish_quality = dish_quality

func get_rarity_level() -> int:
	return rarity_level

func get_dish_quality() -> float:
	return dish_quality

func set_dish_quality(new_dish_quality: float) -> void:
	dish_quality = minf(new_dish_quality, 100.0)

func get_price() -> float:
	return price

# Calculates the bonus according to dish_quality
func get_bonus() -> float:
	var max_bonus: float
	# More rare, more bonus multiplier it can get based on dish_quality
	match rarity_level:
		1:
			max_bonus = price * 0.25
			
		2:
			max_bonus = price * 0.5
			
		3:
			max_bonus = price * 0.75
			
		_: # Default
			max_bonus = 0
	
	return snappedf(max_bonus * (dish_quality / 100), 0.01)

func is_equal(other: Edible) -> bool:
	return (
		edible_name == other.edible_name
		and rarity_level == other.rarity_level
	)
