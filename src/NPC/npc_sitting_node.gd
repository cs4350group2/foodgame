class_name SittingNode
extends CSGBox3D

@onready var seat_pose: Marker3D = $SeatPose
var vacant := true
var serving_customer: Customer = null

func _ready() -> void:
	hide()

func get_seating_transform() -> Transform3D:
	return seat_pose.global_transform

func is_vacant() -> bool:
	return vacant and serving_customer == null

func reserve() -> void:
	vacant = false

func assign_customer(customer: Customer) -> void:
	serving_customer = customer
	vacant = false

func clear() -> void:
	serving_customer = null
	vacant = true
