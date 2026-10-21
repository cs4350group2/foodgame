extends Control

const DRINK_SCENES: Dictionary = {
	"Soda": "res://models/physics/drinks/sodaRegular.tscn",
	"Cooler Soda": "res://models/physics/drinks/sodaSpecial.tscn",
	"Liquid Food": "res://models/physics/drinks/liquidFood.tscn",
	"Iced Lemon Tea": "res://models/physics/drinks/IcedLemonTea.tscn",
	"EXTREMELY SAFE Drink": "res://models/physics/drinks/extremelySafeDrink.tscn",
}

@onready var coins_label: Label = %CoinsLabel
@onready var drink_list: VBoxContainer = %DrinkList
@onready var close_button: Button = %CloseButton

var _player: Player
var _run: RestaurantRun
var _buttons: Array[Button] = []
var _prices: Array[float] = []
var _active := false
var _closing := false
var _buying := false
var _previous_crosshair_visible := true


func _ready() -> void:
	hide()
	close_button.pressed.connect(close_menu)
	_build_drink_list()


func _build_drink_list() -> void:
	for drink: Dictionary in RestaurantManager.get_drinks_menu().get("drinks", []):
		var drink_name: String = drink.get("name", "")
		if not DRINK_SCENES.has(drink_name):
			continue
		var price := float(drink.get("price", 0.0))
		if price < 0.0 or not is_finite(price):
			continue

		var panel := PanelContainer.new()
		drink_list.add_child(panel)
		var margin := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			margin.add_theme_constant_override("margin_" + side, 12)
		panel.add_child(margin)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		margin.add_child(row)
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(details)
		var title := Label.new()
		title.text = "%s — %s coins" % [drink_name, str(price)]
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_child(title)
		for field in ["description", "usage"]:
			var label := Label.new()
			label.text = drink.get(field, "")
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.add_theme_font_size_override("font_size", 16)
			details.add_child(label)
		var buy := Button.new()
		buy.text = "Buy"
		buy.custom_minimum_size.x = 90
		buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		buy.pressed.connect(_buy_drink.bind(drink_name, price))
		row.add_child(buy)
		_buttons.append(buy)
		_prices.append(price)


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
	_run.coins_updated.connect(_on_coins_updated)
	player.release_mouse()
	player.crosshair.hide()
	show()
	_refresh_availability()
	get_tree().paused = true
	close_button.grab_focus()


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
	var hands_full := is_instance_valid(_player) and is_instance_valid(_player.held_edible)
	for i in _buttons.size():
		_buttons[i].disabled = _buying or _closing or hands_full or _run.coins < _prices[i]
		_buttons[i].tooltip_text = "Put down your held item first." if hands_full else (
			"Not enough coins." if _run.coins < _prices[i] else "Buy this drink."
		)


func _buy_drink(drink_name: String, price: float) -> void:
	if not _active or _closing or _buying or not is_instance_valid(_player):
		return
	if is_instance_valid(_player.held_edible) or _run.coins < price:
		_refresh_availability()
		return
	_buying = true
	var scene := load(DRINK_SCENES[drink_name]) as PackedScene
	if scene == null:
		_purchase_failed()
		return
	var instance := scene.instantiate()
	var drink := instance as EdibleItem
	if drink == null:
		instance.free()
		_purchase_failed()
		return
	get_tree().current_scene.add_child(drink)
	drink.global_position = _player.hold_point.global_position
	if drink.drink_data == null or not is_instance_valid(drink.interaction):
		drink.queue_free()
		_purchase_failed()
		return
	if not _run.try_remove_coins(price):
		drink.queue_free()
		_buying = false
		_refresh_availability()
		return
	_player.pick_up_edible(drink)
	if _player.held_edible != drink:
		_run.add_coins(price)
		drink.queue_free()
		_purchase_failed()
		return
	_buying = false
	close_menu()


func _purchase_failed() -> void:
	_buying = false
	_refresh_availability()
	push_warning("Could not dispense this drink. No coins were spent.")


func close_menu() -> void:
	if not _active or _closing:
		return
	_closing = true
	_refresh_availability()
	# Keep the world paused until the closing click/Escape has finished routing.
	_finish_close.call_deferred()


func _finish_close() -> void:
	if not _active:
		return
	_active = false
	hide()
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
