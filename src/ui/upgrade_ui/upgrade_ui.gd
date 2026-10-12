extends Control
class_name UpgradeUi

@onready var container: HBoxContainer = $CenterContainer/HBoxContainer

@export var fade_in_duration: float = 0.15
@export var box_delay = 0.1

var upgrade_box_scene: PackedScene = preload("res://src/ui/upgrade_ui/UpgradeBox.tscn")
var selection_chosen: bool = false
var upgrade_boxes: Array[UpgradeBox]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	RunManager.upgrade_selection_requested.connect(_on_upgrade_requested)
	hide()

func _on_upgrade_requested(upgrades: Array[Upgrade]):
	if len(upgrade_boxes) != 0:
		cleanup()
	selection_chosen = false
	for u: Upgrade in upgrades:
		var upgrade_box: UpgradeBox = upgrade_box_scene.instantiate()
		upgrade_box.upgrade_chosen.connect(choose_upgrade)
		upgrade_box.held_upgrade = u
		# apparently _ready only runs when it's added to the tree
		container.add_child(upgrade_box)
		upgrade_boxes.append(upgrade_box)
	
	RunManager.release_player_mouse()
	show()
	fade_in_boxes()

func fade_in_boxes() -> void:
	var tween := create_tween().set_parallel(true)
	
	for i in range(upgrade_boxes.size()):
		var box := upgrade_boxes[i]
		box.modulate.a = 0.0
		
		tween.tween_property(box, "modulate:a", 1.0, 
			fade_in_duration).set_delay(i * box_delay)

func choose_upgrade(upgrade: Upgrade) -> void:
	if selection_chosen:
		return
	selection_chosen = true
	RunManager.complete_upgrade_selection(upgrade)
	RunManager.capture_player_mouse()
	cleanup()

func cleanup() -> void:
	for ub: UpgradeBox in upgrade_boxes:
		ub.queue_free()
	upgrade_boxes.clear()
	hide()
