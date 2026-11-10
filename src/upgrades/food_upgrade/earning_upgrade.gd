extends Upgrade
class_name EarningUpgrade

@export var effects: Array[EarningParams]

func apply_effect(level: Level):
	for effect: EarningParams in effects:
		if effect.overwrite_existing_value:
			level.set_meal_payout_mult(effect.food, effect.multiplier)
		else:
			var old := level.get_meal_payout_mult(effect.food)
			level.set_meal_payout_mult(effect.food, effect.multiplier * old)
