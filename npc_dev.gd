extends Node3D

@onready var player = $ProtoController
@onready var sittingNodes = $SittingNodes.get_children()

func _physics_process(delta):
	get_tree().call_group("customers", "update_target_location", player.global_transform.origin)

func find_vacant_sittingNode() -> SittingNode:
		for node in sittingNodes:
			if node.is_vacant():
				node.reserve()
				return node
		
		return null

func assign_sittingNode(customer: Customer):
	var sittingNode: SittingNode = find_vacant_sittingNode()
	
	if sittingNode == null:
		print("No vacant sittingNode!")
		return
		
	customer.update_target_location(sittingNode.global_position)
	customer.assigned_sittingNode = sittingNode
	
	print("Assigned sittingNode: ", sittingNode.name)
