extends Control

signal closed

@onready var panel: PanelContainer = $Center/Panel
@onready var scroll: ScrollContainer = %InstructionsScroll
@onready var back_button: Button = %BackButton

func _ready() -> void:
	back_button.pressed.connect(func() -> void: closed.emit())
	resized.connect(_fit_panel)
	visibility_changed.connect(_on_visibility_changed)
	_fit_panel()

func _fit_panel() -> void:
	panel.custom_minimum_size = Vector2(
		minf(800.0, maxf(0.0, size.x - 48.0)),
		minf(640.0, maxf(0.0, size.y - 48.0))
	)

func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		scroll.scroll_vertical = 0
		back_button.grab_focus()
