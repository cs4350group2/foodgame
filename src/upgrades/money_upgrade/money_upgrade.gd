extends Upgrade
class_name MoneyUpgrade

@export var amount: float = 100.0
var fired := false

func apply_effect(level: Level):
	if not fired:
		RestaurantManager.receive_payment(amount)
		fired = true
