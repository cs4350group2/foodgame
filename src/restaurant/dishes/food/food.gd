class_name Food
extends Edible

var rarity_level: int # Currently have 1 -> 3 levels.

func _init(edible_name: String, base_price: float, rarity_level: int) -> void:
	super(edible_name, base_price, rarity_level)
	self.rarity_level = rarity_level

func get_rarity_level() -> int:
	return rarity_level

# Price is base price multiplied by rarity.
func get_price() -> float:
	return price * rarity_level
