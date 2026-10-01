extends MarginContainer
class_name OrderItemUI

@export var grid_container: GridContainer
@export var total_text: Label
@export var total_value: Label
@export var name_template: Label
@export var per_item_template: Label
@export var total_template: Label
var name_string_template := "%s (%d/%d)"

var order_items: Array[OrderItem]
var name_labels: Array[Label]
var per_item_labels: Array[Label]
var total_labels: Array[Label]

func set_order_items(order_items: Array[OrderItem]):
	self.order_items = order_items
	refresh_visuals()

func _on_receive_item(item: OrderItem, quantity: int):
	for i in range(len(order_items)):
		if order_items[i].edible.is_equal(item.edible):
			set_name_label(i, quantity, order_items[i].quantity)
			return

func set_name_label(i: int, received: int, total: int):
	var label: Label = name_labels[i]
	label.text = name_string_template % [order_items[i].edible.get_edible_name(), received, total]

func refresh_visuals() -> void:
	var total_cost: float = 0.0
	name_labels.clear()
	per_item_labels.clear()
	total_labels.clear()
	for item: OrderItem in order_items:
		var name_label: Label = name_template.duplicate()
		name_label.text = name_string_template % [item.edible.get_edible_name(), 0, item.quantity]
		name_labels.append(name_label)

		var per_item_label: Label = per_item_template.duplicate()
		per_item_label.text =  "%.2f" % item.get_edible_price()
		per_item_labels.append(per_item_label)

		var total_label: Label = total_template.duplicate()
		total_label.text = "$%.2f" % item.get_total_price()
		total_labels.append(total_label)

		total_cost += item.get_total_price()

		grid_container.add_child(name_label)
		grid_container.add_child(per_item_label)
		grid_container.add_child(total_label)

		name_label.visible = true
		per_item_label.visible = true
		total_label.visible = true
	
	total_value.text = "$%.2f" % total_cost
