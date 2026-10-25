extends Button

signal unavailable_pressed()

func _gui_input(event: InputEvent) -> void:
	if disabled and event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		unavailable_pressed.emit()
		accept_event()

func _make_custom_tooltip(for_text: String) -> Object:
	return get_parent()._make_custom_tooltip(for_text)
