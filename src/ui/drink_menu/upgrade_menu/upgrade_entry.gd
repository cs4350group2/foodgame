extends PanelContainer
class_name UpgradeEntry

signal buy_requested(upgrade_id: StringName)

@onready var name_label: Label = %UpgradeName
@onready var description_label: Label = %Description
@onready var price_label: Label = %Price
@onready var buy_button: Button = %Button
@onready var status_label: Label = %Status

var held_upgrade: Upgrade
var _available := false
var _reason := ""

func _ready() -> void:
	buy_button.pressed.connect(_on_buy_pressed)
	_update_view()


func setup(upgrade: Upgrade) -> void:
	held_upgrade = upgrade

	if is_node_ready():
		_update_view()


func set_availability(available: bool, reason: String = "") -> void:
	_available = available
	_reason = reason

	if is_node_ready():
		_update_availability()


func _update_view() -> void:
	if held_upgrade == null:
		buy_button.disabled = true
		return

	name_label.text = held_upgrade.display_name
	description_label.text = held_upgrade.description
	price_label.text = "%.2f coins" % held_upgrade.price

	_update_availability()


func _update_availability() -> void:
	buy_button.disabled = not _available or held_upgrade == null
	status_label.text = _reason
	status_label.visible = not _reason.is_empty()


func _on_buy_pressed() -> void:
	if held_upgrade == null or not _available:
		return

	buy_requested.emit(held_upgrade.name)
