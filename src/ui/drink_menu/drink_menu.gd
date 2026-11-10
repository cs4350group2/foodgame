extends Control

const DRINK_ENTRY_SCENE: PackedScene = preload("res://src/ui/drink_menu/DrinkEntry.tscn")

@export var buy_timeout := 0.05
@export var upgrades_panel_style: StyleBox
@export var drink_unlock_upgrades: Array[Unlock_Upgrade] = [
	preload("res://src/upgrades/drink_unlock/alcohol_unlock.tres"),
	preload("res://src/upgrades/drink_unlock/cooler_soda_unlock.tres"),	
	preload("res://src/upgrades/drink_unlock/covid19_serum_unlock.tres"),
	preload("res://src/upgrades/drink_unlock/extremely_safe_drink_unlock.tres"),
	preload("res://src/upgrades/drink_unlock/iced_lemon_tea_unlock.tres"),
	preload("res://src/upgrades/drink_unlock/liquid_food_unlock.tres"),
	preload("res://src/upgrades/drink_unlock/one_day_blinding_stew_unlock.tres"),
	preload("res://src/upgrades/drink_unlock/soda_unlock.tres"),
	preload("res://src/upgrades/drink_unlock/soup_of_oblivion_unlock.tres")
	
]

@onready var coins_label: Label = %CoinsLabel
@onready var drink_list: GridContainer = %DrinkList
@onready var drink_scroll: ScrollContainer = drink_list.get_parent() as ScrollContainer
@onready var menu_panel: PanelContainer = $Panel
@onready var panel_margin: MarginContainer = $Panel/Margin
@onready var menu_content: VBoxContainer = $Panel/Margin/Content
@onready var close_button: Button = %CloseButton
@onready var drinks_tab: Button = %DrinksTab
@onready var upgrades_tab: Button = %UpgradesTab
@onready var upgrade_menu: UpgradeMenu = %UpgradeMenu
@onready var tab_bar: HBoxContainer = $Tabs
@onready var menu_title: Label = $Panel/Margin/Content/Header/Title
@onready var drinks_banner: PanelContainer = $Panel/Margin/Content/TextureRect
@onready var drinks_panel_style: StyleBox = menu_panel.get_theme_stylebox("panel")

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
	drinks_tab.pressed.connect(_select_tab.bind(false))
	upgrades_tab.pressed.connect(_select_tab.bind(true))
	upgrade_menu.purchased.connect(_refresh_availability)
	_build_drink_list()
	_select_tab(false)
	resized.connect(_update_drink_columns)
	_update_drink_columns.call_deferred()

func _on_drink_purchase_requested(
	_drink_name: String,
	_price: float,
	entry: DrinkEntry
) -> void:
	if not _active or _closing or _buying:
		return

	var drink_name := StringName(entry.current_drink.edible_name)

	if not _run.has_drink_unlock(drink_name):
		var upgrade := _get_drink_unlock(drink_name)
		if upgrade == null:
			return

		if _buy_drink_unlock(upgrade):
			entry.reset_feedback()
		return

	_buy_drink(entry.current_drink.edible_name, entry.price, entry)

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
		entry.buy_requested.connect(_on_drink_purchase_requested.bind(entry))
		_entries.append(entry)


func _select_tab(show_upgrades: bool) -> void:
	if _closing or _buying:
		return
	drink_scroll.visible = not show_upgrades
	upgrade_menu.visible = show_upgrades
	drinks_banner.visible = not show_upgrades
	menu_title.text = "UPGRADES" if show_upgrades else "EZ-DRINKS"
	menu_panel.add_theme_stylebox_override(
		"panel", upgrades_panel_style if show_upgrades else drinks_panel_style)
	drinks_tab.set_pressed_no_signal(not show_upgrades)
	upgrades_tab.set_pressed_no_signal(show_upgrades)
	_refresh_availability()
	_update_drink_columns.call_deferred()


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
	# Both tabs share a stable width, including when the drinks grid is hidden.
	var panel_width := minf(size.x * 0.84, 1050.0)
	var available_width := panel_width - panel_padding - scrollbar_width
	var columns_that_fit := floori((available_width + spacing) / maxf(entry_width + spacing, 1.0))
	drink_list.columns = clampi(columns_that_fit, 1, entry_count)
	menu_panel.offset_left = -panel_width / 2.0
	menu_panel.offset_right = panel_width / 2.0
	tab_bar.offset_left = -panel_width / 2.0
	tab_bar.offset_right = panel_width / 2.0


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
	_select_tab(false)
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
	drinks_tab.disabled = _closing or _buying
	upgrades_tab.disabled = _closing or _buying
	upgrade_menu.refresh(_closing or _buying or not upgrade_menu.visible)
	_update_drink_columns.call_deferred()

	var hands_full := (
		is_instance_valid(_player)
		and is_instance_valid(_player.held_edible)
	)

	for entry in _entries:
		var drink_name := StringName(entry.current_drink.edible_name)
		var upgrade := _get_drink_unlock(drink_name)
		var unlocked := _run.has_drink_unlock(drink_name)

		entry.set_unlock_state(upgrade, unlocked)

		var reason := ""
		var cost := entry.get_purchase_price()

		if _closing:
			reason = "CLOSING..."
		elif _buying:
			reason = "PROCESSING..."
		elif not unlocked and upgrade == null:
			reason = "UNAVAILABLE"
		elif cost < 0.0 or not is_finite(cost):
			reason = "UNAVAILABLE"
		elif unlocked and hands_full:
			reason = "HANDS FULL"
		elif _run.coins < cost:
			reason = "NOT ENOUGH COINS"

		entry.set_availability(reason.is_empty(), reason)

func _get_drink_unlock(drink_name: StringName) -> Unlock_Upgrade:
	for upgrade: Unlock_Upgrade in drink_unlock_upgrades:
		if upgrade.drink_to_unlock == drink_name:
			return upgrade
	return null

func _buy_drink_unlock(upgrade: Unlock_Upgrade) -> bool:
	if not _active or _closing or _buying:
		return false
	if _run.has_drink_unlock(upgrade.drink_to_unlock):
		return false
	
	_buying =  true
	if not _run.try_remove_coins(upgrade.price):
		_buying = false
		_refresh_availability()
		return false
	
	RunManager.add_upgrade(upgrade.duplicate() as Upgrade)
	
	_buying = false
	_refresh_availability()
	return true

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
