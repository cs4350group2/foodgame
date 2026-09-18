extends Node3D

const MEAT_PATH = "res://models/physics/food/steak/meatRaw.tscn"
const BUNS_PATH = "res://models/physics/food/burger/buns.tscn"

@onready var interaction: InteractComponent = $InteractComponent
@onready var pot = $"../../pot/Cylinder_009/StaticBody3D"


func _ready() -> void:
	interaction.interact_while_holding = true
	interaction.interacted.connect(_on_interacted)


func _on_interacted(_player: Player) -> void:
	var has_meat: bool = pot.ingredient_buffer.has(MEAT_PATH)
	var has_buns: bool = pot.ingredient_buffer.has(BUNS_PATH)

	if not has_meat:
		print("invalid recipe")
	elif has_buns:
		print("burger")
	else:
		print("steak")
