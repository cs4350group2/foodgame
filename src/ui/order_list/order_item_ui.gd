extends VBoxContainer
class_name OrderItemUI

@onready var customer_label: Label = $Details/CustomerName
@onready var items_container: VBoxContainer = $Details/Items

var order: Order
var item_labels: Array[Label] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for control: Control in find_children("*", "Control", true, false):
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_order(new_order: Order) -> void:
	order = new_order
	var type_label := "Regular" if order.customer_type == &"" else String(order.customer_type).replace("FoodCritic", "Food Critic")
	customer_label.text = "%s (%s)" % [order.customer_name, type_label]
	for item: OrderItem in order.items:
		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_color_override("font_color", Color.BLACK)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = "%s (0/%d)" % [item.edible.get_edible_name(), item.quantity]
		items_container.add_child(label)
		item_labels.append(label)
	for received_item: OrderItem in order.items_received:
		_on_receive_item(received_item, received_item.quantity)
	order.order_item_received.connect(_on_receive_item)


func _on_receive_item(item: OrderItem, quantity: int) -> void:
	for i in order.items.size():
		if order.items[i].edible.is_equal(item.edible):
			item_labels[i].text = "%s (%d/%d)" % [
				order.items[i].edible.get_edible_name(), quantity, order.items[i].quantity
			]
			return
