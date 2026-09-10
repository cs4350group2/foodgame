extends Node

class_name InteractComponent

signal interacted(player: Player)

@export var enabled: bool = true
@onready var highlight_mesh: MeshInstance3D = get_node("../..") as MeshInstance3D
@export var highlight_color := Color(1.0, 0.85, 0.3, 0.3)

var _highlight_material: StandardMaterial3D
var _original_overlay: Material
var _highlighted: bool = false

func _ready() -> void:
	if highlight_mesh == null:
		push_warning("%s: Expected a MeshInstance3D two levels above." % get_path())
		return
	_highlight_material = StandardMaterial3D.new()
	_highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_highlight_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_highlight_material.albedo_color = highlight_color

func set_highlighted(value: bool) -> void:
	value = value and enabled

	if value == _highlighted:
		return

	if not is_instance_valid(highlight_mesh):
		_highlighted = false
		return

	_highlighted = value

	if value:
		_original_overlay = highlight_mesh.material_overlay
		highlight_mesh.material_overlay = _highlight_material
	else:
		highlight_mesh.material_overlay = _original_overlay

func interact(player: Player) -> void:
	if enabled:
		interacted.emit(player)
