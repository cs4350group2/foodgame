extends Control

const DRINK_ENTRY_SCENE: PackedScene = preload("res://src/ui/drink_menu/DrinkEntry.tscn")

@export var buy_timeout := 0.2

@onready var coins_label: Label = %CoinsLabel
@onready var drink_list: GridContainer = %DrinkList
@onready var drink_scroll: ScrollContainer = drink_list.get_parent() as ScrollContainer
@onready var menu_panel: PanelContainer = $Panel
@onready var panel_margin: MarginContainer = $Panel/Margin
@onready var menu_content: VBoxContainer = $Panel/Margin/Content
@onready var close_button: Button = %CloseButton

var _player: Player
var _run: RestaurantRun
var _entries: Array[DrinkEntry] = []
var _session_id: int = 0
var _active := false
var _closing := false
var _buying := false
var _previous_crosshair_visible := true


func _ready() -> void:
	hide()
	close_button.pressed.connect(close_menu)
	_build_drink_list()
	resized.connect(_update_drink_columns)
	_update_drink_columns.call_deferred()


func _build_drink_list() -> void:
	for drink: Dictionary in RestaurantManager.get_drinks_menu().get("drinks", []):
		var drink_name: String = drink.get("name", "")
		var scene_path: String = drink.get("scene_path", "")
		if scene_path.is_empty():
			continue
		var price := float(drink.get("price", 0.0))
		if price < 0.0 or not is_finite(price):
			continue

		var entry := DRINK_ENTRY_SCENE.instantiate() as DrinkEntry
		drink_list.add_child(entry)
		var drink_data := Drink.new(
			drink_name, price, drink.get("description", ""), drink.get("usage", ""), scene_path
		)
		entry.add_child(drink_data)
		entry.setup(drink_data)
		entry.buy_requested.connect(_buy_drink.bind(entry))
		_entries.append(entry)


func _update_drink_columns() -> void:
	var entry_count := drink_list.get_child_count()
	if entry_count == 0:
		drink_list.columns = 1
		return
	var entry_width := 0.0
	for entry: Control in drink_list.get_children():
		entry_width = maxf(entry_width, entry.get_combined_minimum_size().x)
	var spacing := float(drink_list.get_theme_constant("h_separation"))
	var panel_padding := menu_panel.get_theme_stylebox("panel").get_minimum_size().x
	panel_padding += panel_margin.get_theme_constant("margin_left") + panel_margin.get_theme_constant("margin_right")
	# Use the viewport budget rather than the shrinking panel to avoid feedback.
	var scrollbar_width := drink_scroll.get_v_scroll_bar().get_combined_minimum_size().x
	var available_width := size.x * 0.84 - panel_padding - scrollbar_width
	var columns_that_fit := floori((available_width + spacing) / maxf(entry_width + spacing, 1.0))
	drink_list.columns = clampi(columns_that_fit, 1, entry_count)
	var content_width := drink_list.get_combined_minimum_size().x + scrollbar_width
	for child: Control in menu_content.get_children():
		if child != drink_scroll:
			content_width = maxf(content_width, child.get_combined_minimum_size().x)
	var panel_width := content_width + panel_padding
	menu_panel.offset_left = -panel_width / 2.0
	menu_panel.offset_right = panel_width / 2.0


func open_menu(player: Player) -> void:
	if _active or get_tree().paused or not is_instance_valid(player):
		return
	if RunManager.current_run == null:
		return
	_player = player
	_run = RunManager.current_run
	_previous_crosshair_visible = player.crosshair.visible
	_active = true
	_closing = false
	_session_id += 1
	for entry in _entries:
		entry.reset_feedback()
	_run.coins_updated.connect(_on_coins_updated)
	player.release_mouse()
	player.crosshair.hide()
	show()
	_update_drink_columns.call_deferred()
	_refresh_availability()
	get_tree().paused = true


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("pause_game") and not event.is_echo():
		get_viewport().set_input_as_handled()
		close_menu()


func _on_coins_updated(_amount: float) -> void:
	_refresh_availability()


func _refresh_availability() -> void:
	if not _active:
		return
	coins_label.text = "Coins: %s" % str(_run.coins)
	_update_drink_columns.call_deferred()
	var hands_full := is_instance_valid(_player) and is_instance_valid(_player.held_edible)
	for entry in _entries:
		var reason := ""
		if _closing:
			reason = "CLOSING..."
		elif _buying:
			reason = "DISPENSING..."
		elif hands_full:
			reason = "HANDS FULL"
		elif _run.coins < entry.price:
			reason = "NOT ENOUGH COINS"
		entry.set_availability(reason.is_empty(), reason)


func _buy_drink(_drink_name: String, price: float, entry: DrinkEntry) -> void:
	if not _active or _closing or _buying or not is_instance_valid(_player):
		return
	if is_instance_valid(_player.held_edible):
		_refresh_availability()
		entry.show_rejected("HANDS FULL")
		return
	_buying = true
	if not _run.try_remove_coins(price):
		_buying = false
		_refresh_availability()
		entry.show_rejected("NOT ENOUGH COINS")
		return
	_refresh_availability()
	var scene := load(entry.current_drink.scene_path) as PackedScene
	if scene == null:
		_purchase_failed(entry, price)
		return
	var instance := scene.instantiate()
	var drink := instance as EdibleItem
	if drink == null:
		_purchase_failed(entry, price, instance)
		return
	get_tree().current_scene.add_child(drink)
	drink.global_position = _player.hold_point.global_position
	if drink.drink_data == null or not is_instance_valid(drink.interaction):
		_purchase_failed(entry, price, drink)
		return
	_player.pick_up_edible(drink)
	if _player.held_edible != drink:
		_purchase_failed(entry, price, drink)
		return
	entry.show_accepted()
	var purchase_session := _session_id
	# Leave time to see the confirmation while the world remains paused.
	await get_tree().create_timer(buy_timeout, true).timeout
	if not _active or _closing or purchase_session != _session_id:
		return
	_buying = false
	close_menu()


func _purchase_failed(entry: DrinkEntry, price: float, instance: Node = null) -> void:
	if is_instance_valid(instance):
		instance.queue_free()
	_buying = false
	_run.add_coins(price)
	_refresh_availability()
	entry.show_rejected("DISPENSE FAILED")
	push_warning("Could not dispense this drink. The payment was refunded.")


func close_menu() -> void:
	if not _active or _closing:
		return
	_closing = true
	_refresh_availability()
	_finish_close_after_input()


func _finish_close_after_input() -> void:
	var closing_session := _session_id
	# Finish input routing, then resume outside the deferred physics-query flush.
	await get_tree().process_frame
	if _active and closing_session == _session_id:
		_finish_close()


func _finish_close() -> void:
	if not _active:
		return
	_active = false
	_session_id += 1
	_buying = false
	hide()
	for entry in _entries:
		entry.reset_feedback()
	if is_instance_valid(_run) and _run.coins_updated.is_connected(_on_coins_updated):
		_run.coins_updated.disconnect(_on_coins_updated)
	get_tree().paused = false
	if is_instance_valid(_player):
		_player.crosshair.visible = _previous_crosshair_visible
		_player.capture_mouse()
	_player = null
	_run = null
	_closing = false


func _exit_tree() -> void:
	if _active:
		_finish_close()
