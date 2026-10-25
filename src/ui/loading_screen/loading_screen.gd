extends CanvasLayer

@onready var status: Label = %Status

const text_options: Array[String] = [
	"broiling",
	"sauteing",
	"cooking",
	"mashing",
	"basting",
	"chopping",
	"restocking",
	"frying",
	"reverse searing",
	"sous-viding",
	"velveting",
	"smoking",
	"barbequing",
	"harvesting",
	"rhythmizing"
]

func _ready() -> void:
	status.text = "%s..." % text_options.pick_random()
