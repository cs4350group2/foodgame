extends EdibleItem

var item_name = "Mistake"
var price = 0.0
var rarity = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	food_data = Food.new(item_name, price, rarity, 100.0)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
