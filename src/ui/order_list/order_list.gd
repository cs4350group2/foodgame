extends Control
class_name OrderList

@onready var order_ui: OrderUI = $OrderUI


func _ready() -> void:
	RestaurantManager.order_added.connect(order_ui.add_order)
	RestaurantManager.order_removed.connect(order_ui.remove_order)
	for order: Order in RestaurantManager.orders:
		order_ui.add_order(order)
	hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("show_orders"):
		show()
		get_viewport().set_input_as_handled()
	elif event.is_action_released("show_orders"):
		hide()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_up"):
		order_ui.scroll_orders(-60)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		order_ui.scroll_orders(60)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				order_ui.scroll_orders(-60)
				get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_DOWN:
				order_ui.scroll_orders(60)
				get_viewport().set_input_as_handled()
