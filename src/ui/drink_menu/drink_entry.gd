extends PanelContainer
class_name DrinkEntry

@onready var drink_price: Label = %Price
@onready var drink_name_label: Label = %DrinkName
@onready var drink_image: TextureRect = %DrinkImage
@onready var glass_texture: TextureRect = %GlassTexture
@onready var button: Button = $Button

const TOOLTIP_SCENE: PackedScene = preload("res://src/ui/drink_menu/DrinkMenuTooltip.tscn")
const DRINK_IMAGES: Dictionary[String, String] = {
	
}
var current_drink: Drink
var price: float
var limit: int = 2000

signal buy_requested(drink_name: String, price: float)

func _ready() -> void:
	for child in find_children("*", "Control", true, false):
		if child != button:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.mouse_entered.connect(_on_mouse_entered)
	button.mouse_exited.connect(_on_mouse_exited)
	button.pressed.connect(_on_pressed)

func _on_mouse_entered() -> void:
	if not button.disabled:
		self.drink_image.modulate = Color(0.65, 0.65, 0.65)

func _on_mouse_exited() -> void:
	drink_image.modulate = Color.WHITE

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
