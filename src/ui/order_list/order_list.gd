extends Control
class_name OrderList

var order_ui_scene: PackedScene = preload("res://src/ui/order_list/OrderUI.tscn")
var orders: Array[OrderUI]
var selected: int = 0
var animation: Tween
var order_num: int = 1
@export var animation_duration: float  = 1.0
@export var small_scale = 0.6
@export var left_slot: Control
@export var center_slot: Control
@export var right_slot: Control
@onready var no_order_label: Label = $CenterSlot/Label

# ideally maybe this should be moved to another handler? not sure
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
	var handled := false
	if event.is_action_pressed("menu_left"):
		selected = wrapi(selected - 1, 0, orders.size())
		handled = true
	elif event.is_action_pressed("menu_right"):
		selected = wrapi(selected + 1, 0, orders.size())
		handled = true
	if handled:
		get_viewport().set_input_as_handled()
		animate_selection()

func animate_selection() -> void:
	if orders.is_empty():
		no_order_label.visible = true
		return
	
	no_order_label.visible = false
	if animation:
		animation.kill()
	
	animation = create_tween().set_parallel(true)
	#animation.set_trans(Tween.TRANS_QUAD)
	#animation.set_ease(Tween.EASE_OUT)
	
	var count := orders.size()
	
	# there is probably a better way than iterating through the array
	# but it also probably isn't too computationally expensive
	for i in count:
		var order: OrderUI = orders[i]
		
		# we use a slot of -1 to indicate left, 0 center, 1 right
		var slot := posmod(i - selected, count)
		if slot > count / 2.0:
			slot -= count
			
		var was_visible := order.visible
		order.visible = absi(slot) <= 1
		
		if not order.visible:
			continue
		
		var destination: Control
		match slot:
			-1:
				destination = left_slot
			0:
				destination = center_slot
			1:
				destination = right_slot
		
		if order.get_parent() != destination:
			order.reparent(destination, true)
			order.set_anchors_preset(Control.PRESET_CENTER)
		
		order.pivot_offset = order.size / 2.0
		
		var target_scale = Vector2.ONE
		if slot != 0:
			target_scale *= small_scale
		# center on the control
		var target_pos = (destination.size - order.size) / 2.0
		
		if not was_visible:
			var entry_distance = order.size.x * small_scale + 40.0
			order.position = target_pos + Vector2(slot * entry_distance, 0.0)
			order.scale = target_scale
		
		animation.tween_property(order, "position",
			target_pos, animation_duration)
		animation.tween_property(order, "scale",
			target_scale, animation_duration)
	

func _on_order_added(order: Order):
	var order_ui: OrderUI = order_ui_scene.instantiate()
	add_child(order_ui)
	orders.append(order_ui)
	order_ui.set_order(order, order_num)
	order_num += 1
	animate_selection()

func _on_order_removed(order: Order):
	var to_remove: OrderUI = null
	for order_ui in orders:
		# they're ref counted so i think the ref should be same
		if order_ui.get_order() == order:
			# don't remove it from the array we're iterating through
			to_remove = order_ui
			break
	
	if to_remove:
		orders.erase(to_remove)
		to_remove.queue_free()

func __get_random_order(order_length: int) -> Order:
	var menu: Dictionary = RestaurantManager.get_menu()
	var test_items: Array[OrderItem]
	for i in order_length:
		var food_data = menu["foods"].pick_random()
		var food = Food.new(food_data["name"], food_data["price"], 
			food_data["rarity"], randf_range(0, 100))
		var order_item = OrderItem.new(food, 1)
		test_items.append(order_item)
	return Order.new(test_items)

func register(rm: RestaurantManager):
	rm.order_added.connect(_on_order_added)
	rm.order_removed.connect(_on_order_removed)

func _ready() -> void:
	order_num = 1
	register(RestaurantManager)
	hide()
