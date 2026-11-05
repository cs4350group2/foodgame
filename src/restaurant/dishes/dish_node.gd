class_name DishNode
extends Node3D

@onready var dish_marker: Marker3D = $DishMarker
@export var display_dish: PackedScene
var displayed_dish: Node3D
var sitting_node: SittingNode

func _ready() -> void:
	_display_dish()
	if get_parent() is SittingNode:
		sitting_node = get_parent()

func set_display_dish(scene: PackedScene) -> void:
	display_dish = scene
	if is_inside_tree():
		_display_dish()

func _display_dish() -> void:
	if is_instance_valid(displayed_dish):
		displayed_dish.queue_free()
		displayed_dish = null

	if display_dish == null:
		return

	var instance := display_dish.instantiate()
	if not instance is Node3D:
		push_error("DishNode.display_dish must have a Node3D root.")
		instance.free()
		return

	displayed_dish = instance as Node3D
	add_child(displayed_dish)
	displayed_dish.global_transform = dish_marker.global_transform
	_make_display_dish_inert(displayed_dish)

func _make_display_dish_inert(node: Node) -> void:
	if node is CollisionObject3D:
		var collision_object := node as CollisionObject3D
		collision_object.collision_layer = 0
		collision_object.collision_mask = 0
		if collision_object is RigidBody3D:
			(collision_object as RigidBody3D).freeze = true
		elif collision_object is CharacterBody3D:
			(collision_object as CharacterBody3D).set_physics_process(false)
		elif collision_object is AnimatableBody3D:
			(collision_object as AnimatableBody3D).sync_to_physics = false

	if node is Area3D:
		var area := node as Area3D
		area.monitoring = false
		area.monitorable = false

	if node is CollisionShape3D or node is CollisionPolygon3D:
		node.set("disabled", true)

	if node is InteractComponent:
		(node as InteractComponent).enabled = false

	for child in node.get_children():
		_make_display_dish_inert(child)

func get_dish_marker_transform() -> Transform3D:
	return dish_marker.global_transform

func clear() -> void:
	if is_instance_valid(displayed_dish):
		displayed_dish.queue_free()
		displayed_dish = null
