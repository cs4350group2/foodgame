extends Button


func _make_custom_tooltip(for_text: String) -> Object:
	return get_parent()._make_custom_tooltip(for_text)
