extends PanelContainer
class_name DrinkMenuTooltip


func setup(title: String, description: String, usage: String) -> void:
	$MarginContainer/VBoxContainer/Title.text = title
	$MarginContainer/VBoxContainer/Description.text = description
	$MarginContainer/VBoxContainer/Usage.text = usage
