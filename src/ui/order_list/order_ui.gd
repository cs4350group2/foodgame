extends PanelContainer
class_name OrderUI

const ORDER_ITEM_SCENE: PackedScene = preload("res://src/ui/order_list/OrderItemUI.tscn")

@export var maximum_height: float = 600.0
@export var viewport_margin: float = 24.0

@onready var rows: VBoxContainer = %Rows
@onready var no_order_label: Label = %NoOrders
@onready var scroll: ScrollContainer = %OrderScroll
@onready var content: VBoxContainer = $Content

var order_rows: Dictionary[Order, OrderItemUI] = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for control: Control in find_children("*", "Control", true, false):
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.minimum_size_changed.connect(_update_height.call_deferred)
	get_viewport().size_changed.connect(_update_height.call_deferred)
	visibility_changed.connect(_update_height.call_deferred)
	_update_height.call_deferred()


func _update_height() -> void:
	var fixed_height := get_theme_stylebox("panel").get_minimum_size().y
	fixed_height += content.get_theme_constant("separation") * (content.get_child_count() - 1)
	for child: Control in content.get_children():
		if child != scroll:
			fixed_height += child.get_combined_minimum_size().y
	var height_limit := minf(maximum_height, get_viewport_rect().size.y - viewport_margin * 2.0)
	var rows_height := minf(rows.get_combined_minimum_size().y, maxf(height_limit - fixed_height, 0.0))
	scroll.custom_minimum_size.y = rows_height
	size.y = fixed_height + rows_height
	position.y = maxf(viewport_margin, (get_viewport_rect().size.y - size.y) / 2.0)


func add_order(order: Order) -> void:
	var row := ORDER_ITEM_SCENE.instantiate() as OrderItemUI
	rows.add_child(row)
	row.set_order(order)
	order_rows[order] = row
	_update_row_separators()
	no_order_label.hide()


func remove_order(order: Order) -> void:
	var row: OrderItemUI = order_rows[order]
	order.order_item_received.disconnect(row._on_receive_item)
	rows.remove_child(row)
	row.queue_free()
	order_rows.erase(order)
	_update_row_separators()
	no_order_label.visible = order_rows.is_empty()


func _update_row_separators() -> void:
	var entries := order_rows.values()
	for i in entries.size():
		entries[i].get_node("Separator").visible = i < entries.size() - 1


func scroll_orders(amount: int) -> void:
	scroll.scroll_vertical += amount
