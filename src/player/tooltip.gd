extends PanelContainer
class_name Tooltip

const PRIMARY_CONTROLS := "[E / LMB]"
const SECONDARY_CONTROLS := "[F / RMB]"

@onready var text_label: Label = $MarginContainer/Text


func show_target(component: InteractComponent, player: Player) -> void:
	if not is_instance_valid(component) or not component.enabled:
		hide()
		return

	var data := component.get_tooltip_data(player)
	var lines: PackedStringArray = []

	lines.append(str(data["title"]))

	var details: String = data.get("details", "")
	var primary: String = data.get("primary", "")
	var secondary: String = data.get("secondary", "")

	if not details.is_empty():
		lines.append(details)

	if not primary.is_empty():
		lines.append("%s %s" % [PRIMARY_CONTROLS, primary])

	if not secondary.is_empty():
		lines.append("%s %s" % [SECONDARY_CONTROLS, secondary])

	var next_text := "\n".join(lines)

	if text_label.text != next_text:
		text_label.text = next_text

	show()
