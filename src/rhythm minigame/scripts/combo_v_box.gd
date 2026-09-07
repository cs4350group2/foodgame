extends VBoxContainer

@onready var main: Node2D = $"../../.."

var combo_count : int = 0
@onready var combo_label: Label = $Combo
@onready var combo_count_label: Label = $ComboCount

func _ready() -> void:
	main.hit.connect(update_combo)
	main.miss.connect(update_combo)
	main.cooking_start.connect(reset_combo_display)
	main.results_display.connect(fade_out_combo_counter)

func update_combo(input_judgment : String) -> void:
	if input_judgment == "PERFECT" or input_judgment == "GOOD":
		if combo_label.text == "":
			# if combo was 0, re-add the "COMBO" text on re-acquisition of combo
			combo_label.text = "COMBO"
		combo_count += 1
		combo_count_label.text = str(combo_count)
	else: 
		# a miss has been recorded
		combo_count = 0
		combo_label.text = "" # specifically if combo is 0, remove the "COMBO" text from the screen as well
		combo_count_label.text = ""

func reset_combo_display() -> void:
	modulate.a = 1.0
	combo_count = 0
	combo_label.text = ""
	combo_count_label.text = ""
	
func fade_out_combo_counter() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
		
		
