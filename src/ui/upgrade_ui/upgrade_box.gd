extends Control
class_name UpgradeBox

@onready var name_label: Label = %Name
@onready var desc_label: Label = %Desc
@onready var select_button: Button = %SelectButton
@onready var icon: TextureRect = %Icon

var held_upgrade: Upgrade

signal upgrade_chosen(upgrade: Upgrade)

func _ready() -> void:
	select_button.pressed.connect(_on_button_press)
	# render the box based on the upgrade
	if held_upgrade != null:
		update_view()

func update_view() -> void:
	assert(held_upgrade != null)
	name_label.text = held_upgrade.display_name
	desc_label.text = held_upgrade.description
	if held_upgrade.icon:
		icon.texture = held_upgrade.icon

func _on_button_press() -> void:
	assert(held_upgrade != null)
	upgrade_chosen.emit(held_upgrade)
