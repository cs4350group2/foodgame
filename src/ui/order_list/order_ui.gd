extends ScrollContainer
class_name OrderUI
@onready var panel_container: PanelContainer = $PanelContainer
@onready var number_label: Label = $PanelContainer/VBoxContainer/Number

@export var item_ui: OrderItemUI
var order: Order

func _ready() -> void:
	self.size.x = panel_container.size.x

func set_number(number: int):
	number_label.text = str(number)

func set_order(new_order: Order, order_num: int):
	order = new_order
	order.order_item_received.connect(item_ui._on_receive_item)

	set_number(order_num)
	item_ui.set_order_items(order.items)

func get_order() -> Order:
	return order
	
func animate_completion():
	# do some fading or whatever here
	pass
