extends Node

class_name InteractComponent

signal interacted(player: Player)

@export var enabled: bool = true
@export_node_path("Node3D") var highlight_root_path: NodePath = NodePath("../..")
@export var highlight_color := Color(1.0, 0.85, 0.3, 0.3)

var _meshes: Array[MeshInstance3D] = []
var _original_overlays: Array[Material] = []
var _highlight_material: StandardMaterial3D
var _highlighted: bool = false

func _ready() -> void:
	var visual_root := get_node_or_null(highlight_root_path)

	if visual_root == null:
		push_warning("%s: Highlight root was not found." % get_path())
		return

	_collect_meshes(visual_root)

	_highlight_material = StandardMaterial3D.new()
	_highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_highlight_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_highlight_material.albedo_color = highlight_color

func _collect_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		_meshes.append(node)

	for child in node.get_children():
		_collect_meshes(child)
		
func set_highlighted(value: bool) -> void:
	value = value and enabled

	if value == _highlighted:
		return

	_highlighted = value

	if value:
		_original_overlays.clear()

		for mesh in _meshes:
			if is_instance_valid(mesh):
				_original_overlays.append(mesh.material_overlay)
				mesh.material_overlay = _highlight_material
			else:
				_original_overlays.append(null)
	else:
		for i in _meshes.size():
			if is_instance_valid(_meshes[i]):
				_meshes[i].material_overlay = _original_overlays[i]

		_original_overlays.clear()
func interact(player: Player) -> void:
	if enabled:
		interacted.emit(player)
