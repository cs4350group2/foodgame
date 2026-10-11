class_name Unlock_Upgrade
extends Upgrade
@export_category("NPC Unlock/Modifier")
@export var npc_to_unlock: StringName
@export var npc_spawn_weight: float
@export_category("Food Unlock/Modifier")
@export var food_to_unlock: StringName
@export var food_price_modifier: float
@export_category("Drink Unlock/Modifier")
@export var drink_to_unlock: StringName
@export var drink_price_modifier: float
@export var drink_effect_multiplier: float

func apply_effect(level: Level):
	if npc_to_unlock != "":
		level.update_customer_type(npc_to_unlock, npc_spawn_weight)
	if food_to_unlock != "":
		# do something here
		print("unlocked ", food_to_unlock)
	if drink_to_unlock != "":
		print("unlocked ", drink_to_unlock)
