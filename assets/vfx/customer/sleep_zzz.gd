extends Node3D

@onready var label: Label3D = $Label3D

func _ready() -> void:
	var float_tween := create_tween().set_loops()
	float_tween.tween_property(label, "position:y", 0.4, 0.8).from(0.0)
	float_tween.parallel().tween_property(label, "modulate:a", 0.45, 0.8).from(1.0)
	float_tween.tween_property(label, "position:y", 0.0, 0.8)
	float_tween.parallel().tween_property(label, "modulate:a", 1.0, 0.8)
