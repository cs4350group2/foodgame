extends PanelContainer
class_name DrinkEntry

@onready var drink_price: Label = %Price
@onready var drink_name_label: Label = %DrinkName
@onready var drink_image: TextureRect = %DrinkImage
@onready var glass_texture: TextureRect = %GlassTexture
@onready var button: Button = $Button
@onready var _available_focus_mode: Control.FocusMode = button.focus_mode
@onready var status_label: Label = %SelectLabel
@onready var status_icon: Control = %StatusIcon

@export_group("Card Styleboxes")
@export var normal_style: StyleBoxFlat
@export var hover_style: StyleBoxFlat
@export var pressed_style: StyleBoxFlat
@export var disabled_style: StyleBoxFlat
@export var accepted_style: StyleBoxFlat
@export var rejected_style: StyleBoxFlat
@export var locked_style: StyleBoxFlat
@export var locked_hover_style: StyleBoxFlat
@export var locked_pressed_style: StyleBoxFlat

enum Feedback { NONE, ACCEPTED, REJECTED }

var _hovered := false
var _unavailable_reason := ""
var _feedback := Feedback.NONE
var _feedback_message := ""
var _feedback_remaining := 0.0

const TOOLTIP_SCENE: PackedScene = preload("res://src/ui/drink_menu/DrinkMenuTooltip.tscn")
const DRINK_IMAGES: Dictionary[String, String] = {
	"Soda": "res://assets/drinks/icons/soda.png",
	"Cooler Soda": "res://assets/drinks/icons/cooler_soda.png",
	"Liquid Food": "res://assets/drinks/icons/liquid_food.png",
	"Iced Lemon Tea": "res://assets/drinks/icons/iced_lemon_tea.png",
	"EXTREMELY SAFE Drink": "res://assets/drinks/icons/extremely_safe_drink.png",
	"Alcohol": "res://assets/drinks/icons/alcohol.png",
	"Covid-19 Serum": "res://assets/drinks/icons/covid19_serum.png",
	"1 Day Blinding Stew": "res://assets/drinks/icons/one_day_blinding_stew.png",
	"Soup Of Oblivion": "res://assets/drinks/icons/soup_of_oblivion.png",
}
var current_drink: Drink
var price: float
var limit: int = 2000

var unlock_upgrade: Unlock_Upgrade
var locked := true

func set_unlock_state(upgrade: Unlock_Upgrade, unlocked: bool) -> void:
	unlock_upgrade = upgrade
	locked = not unlocked

	if locked:
		drink_price.text = (
			"Unlock: %.2f" % upgrade.price
			if upgrade != null else "UNAVAILABLE"
		)
	else:
		drink_price.text = "%.2f coins" % price

	drink_image.modulate = Color(0, 0, 0, 1) if locked else Color(0.82, 0.88, 0.92, 1)
	_refresh_feedback()


func get_purchase_price() -> float:
	if locked and unlock_upgrade != null:
		return unlock_upgrade.price
	return price

signal buy_requested(drink_name: String, price: float)

func _ready() -> void:
	for child in find_children("*", "Control", true, false):
		if child != button:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.mouse_entered.connect(_on_mouse_entered)
	button.mouse_exited.connect(_on_mouse_exited)
	button.pressed.connect(_on_pressed)
	button.connect("unavailable_pressed", _on_unavailable_pressed)
	button.focus_entered.connect(_refresh_feedback)
	button.focus_exited.connect(_refresh_feedback)
	button.button_down.connect(_refresh_feedback)
	button.button_up.connect(_refresh_feedback)
	_refresh_feedback()
	set_process(false)

func _on_mouse_entered() -> void:
	_hovered = true
	_refresh_feedback()

func _on_mouse_exited() -> void:
	_hovered = false
	_refresh_feedback()

func set_availability(available: bool, reason: String = "") -> void:
	_unavailable_reason = reason
	button.disabled = not available
	if not available:
		button.release_focus()
	button.focus_mode = _available_focus_mode if available else Control.FOCUS_NONE
	_refresh_feedback()

func _on_unavailable_pressed() -> void:
	if _unavailable_reason in ["HANDS FULL", "NOT ENOUGH COINS"]:
		show_rejected(_unavailable_reason)

func show_rejected(message: String) -> void:
	_feedback = Feedback.REJECTED
	_feedback_message = message
	_feedback_remaining = 0.7
	set_process(true)
	_refresh_feedback()

func show_accepted() -> void:
	_feedback = Feedback.ACCEPTED
	_feedback_message = "DISPENSED!"
	_feedback_remaining = 0.0
	set_process(false)
	_refresh_feedback()

func reset_feedback() -> void:
	_feedback = Feedback.NONE
	_feedback_remaining = 0.0
	_hovered = false
	set_process(false)
	_refresh_feedback()

func _process(delta: float) -> void:
	_feedback_remaining -= delta
	if _feedback_remaining <= 0.0:
		_feedback = Feedback.NONE
		set_process(false)
		_refresh_feedback()

func _refresh_feedback() -> void:
	if normal_style == null or not is_visible_in_tree():
		return
	var state := "normal"
	var color := hover_style.border_color
	var icon_state := 0
	status_label.text = "PRESS TO UNLOCK" if locked else "PRESS TO BUY"
	if _feedback == Feedback.ACCEPTED:
		state = "accepted"
		color = accepted_style.border_color
		icon_state = 1
		status_label.text = _feedback_message
	elif _feedback == Feedback.REJECTED:
		state = "rejected"
		color = rejected_style.border_color
		icon_state = 2
		status_label.text = _feedback_message
	elif button.disabled:
		state = "disabled"
		color = rejected_style.border_color
		icon_state = 2
		status_label.text = _unavailable_reason
		if _unavailable_reason in ["DISPENSING...", "PROCESSING...", "CLOSING..."]:
			color = hover_style.border_color
			icon_state = 0
		elif _hovered or button.has_focus():
			state = "rejected"
	elif button.is_pressed():
		state = "pressed"
	elif _hovered or button.has_focus():
		state = "hover"
	var style := _get_state_style(state)
	if get_theme_stylebox("panel") != style:
		add_theme_stylebox_override("panel", style)
	if status_label.get_theme_color("font_color") != color:
		status_label.add_theme_color_override("font_color", color)
	status_icon.set_state(icon_state, color)
	var price_color := rejected_style.border_color if _unavailable_reason == "NOT ENOUGH COINS" and _feedback != Feedback.ACCEPTED else accepted_style.border_color
	if drink_price.get_theme_color("font_color") != price_color:
		drink_price.add_theme_color_override("font_color", price_color)

func _get_state_style(state: String) -> StyleBoxFlat:
	if locked:
		match state:
			"hover":
				return locked_hover_style
			"pressed":
				return locked_pressed_style
			"normal", "disabled":
				return locked_style
	match state:
		"hover": return hover_style
		"pressed": return pressed_style
		"disabled": return disabled_style
		"accepted": return accepted_style
		"rejected": return rejected_style
		
	return normal_style

func _on_pressed() -> void:
	buy_requested.emit(current_drink.edible_name, price)

func setup(new_drink: Drink, new_limit: int = 2000) -> void:
	current_drink = new_drink
	limit = new_limit
	update_visuals()

func update_visuals() -> void:
	assert(current_drink != null)
	price = current_drink.price
	tooltip_text = current_drink.edible_name
	button.tooltip_text = current_drink.edible_name
	drink_name_label.text = current_drink.edible_name
	drink_price.text = "%.2f coins" % price
	var icon_path: String = DRINK_IMAGES.get(current_drink.edible_name, "")
	drink_image.texture = (load(icon_path) as Texture2D if \
		not icon_path.is_empty() else null)
	
func _make_custom_tooltip(_for_text: String) -> Object:
	var tooltip: DrinkMenuTooltip = TOOLTIP_SCENE.instantiate()
	tooltip.setup(current_drink.edible_name, current_drink.description, current_drink.usage)
	return tooltip
