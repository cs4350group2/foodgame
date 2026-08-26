class_name SittingNode
extends CSGBox3D

var vacant
var serving_customer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	vacant = true
	pass # Replace with function body.

func is_vacant() -> bool:
	return vacant
	
func reserve():
	vacant = false
	
func free():
	vacant = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
