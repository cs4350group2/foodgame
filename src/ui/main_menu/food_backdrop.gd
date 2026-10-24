extends Node3D
## Decorative mesh-only food, independent of the restaurant's gameplay and RNG.

@export var food_scenes: Array[PackedScene] = []
@export_range(0, 30, 1) var initial_count: int = 10
@export_range(1, 30, 1) var maximum_count: int = 12
@export var spawn_interval_seconds := Vector2(2.0, 3.0)
## X is the minimum upward speed; Y is the maximum, in pixels per second
@export var movement_pixels_per_second := Vector2(30.0, 150.0)
@export var food_size_pixels := Vector2(90.0, 150.0)
## Each axis gets a random speed in this range and a random direction
@export var rotation_degrees_per_second := Vector2(4.0, 40.0)
@export_range(0.0, 1.0) var side_spawn_chance: float = 0.85
@export_range(0.0, 0.1) var sideways_sway: float = 0.025

const OFFSCREEN_MARGIN := 0.2

class FloatingFood:
	var pivot: Node3D
	var progress: float
	var speed_pixels_per_second: float
	var horizontal_position: float
	var phase: float
	var angular_velocity: Vector3
	var size_pixels: float
	var depth: float

var _rng := RandomNumberGenerator.new()
var _templates: Array[Node3D] = []
var _foods: Array[FloatingFood] = []
var _spawn_remaining: float
var _view_size := Vector2.ONE

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	_rng.randomize()
	for scene in food_scenes:
		if scene == null:
			continue
		var template := _make_template(scene)
		if template != null:
			_templates.append(template)
	_update_view_size()
	get_viewport().size_changed.connect(_update_view_size)
	var count := mini(initial_count, maximum_count)
	for index in range(count):
		# Spread the opening population over the height rather than one burst.
		_spawn_food((float(index) + _rng.randf()) / float(count))
	_spawn_remaining = _random_between(spawn_interval_seconds)

func _process(delta: float) -> void:
	var viewport_height := maxf(get_viewport().get_visible_rect().size.y, 1.0)
	for index in range(_foods.size() - 1, -1, -1):
		var food := _foods[index]
		food.progress += delta * food.speed_pixels_per_second / viewport_height
		if food.progress > 1.0 + OFFSCREEN_MARGIN:
			food.pivot.queue_free()
			_foods.remove_at(index)
			continue
		food.pivot.rotation += food.angular_velocity * delta
		_position_food(food)
	_spawn_remaining -= delta
	if _spawn_remaining <= 0.0:
		if _foods.size() < maximum_count:
			_spawn_food(-OFFSCREEN_MARGIN)
		_spawn_remaining = maxf(_random_between(spawn_interval_seconds), 0.1)

func _spawn_food(progress: float) -> void:
	if _templates.is_empty():
		return
	var food := FloatingFood.new()
	food.pivot = Node3D.new()
	food.pivot.add_child(_templates[_rng.randi_range(0, _templates.size() - 1)].duplicate())
	add_child(food.pivot)
	food.progress = progress
	food.speed_pixels_per_second = maxf(_random_between(movement_pixels_per_second), 0.1)
	food.size_pixels = maxf(_random_between(food_size_pixels), 1.0)
	food.depth = _rng.randf_range(-1.0, 1.0)
	food.phase = _rng.randf_range(0.0, TAU)
	food.horizontal_position = _rng.randf_range(0.08, 0.92)
	if _rng.randf() < side_spawn_chance:
		food.horizontal_position = _rng.randf_range(0.07, 0.23)
		if _rng.randf() < 0.5:
			food.horizontal_position = 1.0 - food.horizontal_position
	food.pivot.rotation = Vector3(
		_rng.randf_range(0.0, TAU),
		_rng.randf_range(0.0, TAU),
		_rng.randf_range(0.0, TAU)
	)
	food.angular_velocity = Vector3(_random_spin(), _random_spin(), _random_spin())
	_foods.append(food)
	_position_food(food)

func _position_food(food: FloatingFood) -> void:
	var horizontal := food.horizontal_position + sin(food.progress * TAU + food.phase) * sideways_sway
	food.pivot.position = Vector3(
		(horizontal - 0.5) * _view_size.x,
		(food.progress - 0.5) * _view_size.y,
		food.depth
	)
	var viewport_height := maxf(get_viewport().get_visible_rect().size.y, 1.0)
	food.pivot.scale = Vector3.ONE * food.size_pixels * _view_size.y / viewport_height

func _update_view_size() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	_view_size = Vector2(camera.size * viewport_size.x / maxf(viewport_size.y, 1.0), camera.size)
	for food in _foods:
		_position_food(food)

func _random_between(limits: Vector2) -> float:
	return _rng.randf_range(minf(limits.x, limits.y), maxf(limits.x, limits.y))

func _random_spin() -> float:
	var direction := -1.0 if _rng.randf() < 0.5 else 1.0
	return deg_to_rad(_random_between(rotation_degrees_per_second)) * direction

func _make_template(scene: PackedScene) -> Node3D:
	var source := scene.instantiate()
	var meshes := Node3D.new()
	_copy_meshes(source, Transform3D.IDENTITY, meshes)
	source.free()
	if meshes.get_child_count() == 0:
		meshes.free()
		return null
	var first_mesh := meshes.get_child(0) as MeshInstance3D
	var bounds := first_mesh.transform * first_mesh.get_aabb()
	for child: MeshInstance3D in meshes.get_children():
		bounds = bounds.merge(child.transform * child.get_aabb())
	var longest_side := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	var template := Node3D.new()
	template.add_child(meshes)
	meshes.position = -bounds.get_center()
	template.scale = Vector3.ONE / maxf(longest_side, 0.001)
	return template

func _copy_meshes(source: Node, inherited_transform: Transform3D, target: Node3D) -> void:
	var mesh_transform := inherited_transform
	if source is Node3D:
		mesh_transform *= (source as Node3D).transform
	if source is MeshInstance3D:
		var original := source as MeshInstance3D
		if original.mesh != null:
			var visual := MeshInstance3D.new()
			visual.mesh = original.mesh
			visual.transform = mesh_transform
			visual.material_override = original.material_override
			for surface in range(original.get_surface_override_material_count()):
				visual.set_surface_override_material(surface, original.get_surface_override_material(surface))
			visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			target.add_child(visual)
	for child in source.get_children():
		_copy_meshes(child, mesh_transform, target)

func _exit_tree() -> void:
	for template in _templates:
		template.free()
