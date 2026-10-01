extends EdibleItem

var item_name = "Steak"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interaction.interacted.connect(_on_interacted)
	initialize_data(item_name)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
