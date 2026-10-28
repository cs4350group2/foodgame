extends Node

class_name InteractComponent

signal interacted(player: Player)
signal alt_interacted(player: Player)

@export var supports_primary: bool = false
@export var supports_secondary: bool = false
@export var accepts_primary_while_holding: bool = false
@export var enabled: bool = true

@export_node_path("Node3D") var highlight_root_path: NodePath = NodePath("../..")
@export var highlight_color := Color(1.0, 0.85, 0.3, 0.3)

@export_group("Tooltip")
@export var display_name: String = ""
@export var primary_description: String = "Interact"
@export var secondary_description: String = "Use"

# Optional function supplied by the owning interactable.
# Returns descriptions and details based on its current state.
var tooltip_provider: Callable

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
	if enabled and supports_primary:
		interacted.emit(player)


func alt_interact(player: Player) -> void:
	if enabled and supports_secondary:
		alt_interacted.emit(player)


func get_tooltip_data(player: Player) -> Dictionary:
	var title := display_name
	var details := ""
	var primary := primary_description
	var secondary := secondary_description

	var target := get_parent() as EdibleItem
	var holding := is_instance_valid(player.held_edible)

	# Food already has a naming system; reuse it.
	if is_instance_valid(target):
		title = target.get_edible_item_name()

	if title.is_empty():
		title = str(get_parent().name).capitalize()

	# Stations can provide state-dependent descriptions.
	if tooltip_provider.is_valid():
		var descriptions: Dictionary = tooltip_provider.call(player)
		details = descriptions.get("details", "")
		primary = descriptions.get("primary", primary)
		secondary = descriptions.get("secondary", secondary)

	# Do not advertise unsupported component actions.
	if not supports_primary:
		primary = ""
	if not supports_secondary:
		secondary = ""

	# Match the routing in Player.try_interact().
	if holding:
		if is_instance_valid(target):
			primary = "Swap held item"
		elif not supports_primary or not accepts_primary_while_holding:
			primary = "Drop held item"

	return {
		"title": title,
		"category": _get_tooltip_category(),
		"details": details,
		"primary": primary,
		"secondary": secondary,
	}
	
func _get_tooltip_category() -> String:
	var owner_node := get_parent()

	if owner_node is Customer:
		return ""

	var edible := owner_node as EdibleItem
	if edible != null:
		if edible.is_drink:
			return "Drink"

		if edible.is_ingredient():
			if edible.scene_file_path in [
				"res://models/physics/food/ingredients/meatRaw.tscn",
				"res://models/physics/food/ingredients/fishSkinned.tscn",
				"res://models/physics/food/ingredients/cleanPotato.tscn",
				"res://models/physics/food/ingredients/cleanTomato.tscn",
			]:
				return "Choppable Ingredient"
			elif edible.scene_file_path in [
				"res://models/physics/food/ingredients/fishRaw.tscn",
				"res://models/physics/food/ingredients/dirtyPotato.tscn",
				"res://models/physics/food/ingredients/dirtyTomato.tscn",
			]:
				return "Dirty Ingredient"
			return "Ingredient"
		
		elif edible.scene_file_path == "res://models/physics/food/pooOnAPlate/mistake.tscn":
			return "Dish?"
			
		return "Dish"

	return "Interactable Station"
