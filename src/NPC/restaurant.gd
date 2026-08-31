class_name Restaurant
extends Node2D

@onready var sittingNodes = $SittingNodes.get_children()

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
	
	# Assign sitting node for customer and customer for sitting node
	customer.assign_sitting_node(sittingNode)
	sittingNode.assign_customer(customer)
	
	print("Assigned sittingNode: ", sittingNode.name)
