class_name Food
extends Edible

var rarity_level: int # Currently have 1 -> 3 levels.
var dish_quality: float # Dish quality determined by cooking minigame

func _init(edible_name: String, base_price: float, rarity_level: int, dish_quality: float) -> void:
	super(edible_name, base_price, rarity_level)
	self.rarity_level = rarity_level
	self.dish_quality = dish_quality

func get_rarity_level() -> int:
	return rarity_level

# Price is base price multiplied by rarity.
func get_price() -> float:
	return price * rarity_level

func is_equal(other: Edible) -> bool:
	return (
		edible_name == other.edible_name
		and rarity_level == other.rarity_level
	)
