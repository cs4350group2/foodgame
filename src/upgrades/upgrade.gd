@abstract
class_name Upgrade
extends Resource

@export var name: StringName
@export var display_name: StringName
@export var icon: Texture2D
@export_multiline("Put a description here!") var description: String
# an array of upgrade names that this depends on. not strictly enforced
@export var dependencies: Array[StringName]
@export var price: float = 100.0

@abstract func apply_effect(level: Level)
