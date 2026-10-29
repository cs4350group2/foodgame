
extends Node3D

@export var vehicles: Array[PackedScene] = []
@export var min_spawn_time: float = 2.0
@export var max_spawn_time: float = 5.0

@export var spawn_point: Marker3D
@onready var timer: Timer = $Timer


func _ready() -> void:
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	schedule_next_spawn()


func schedule_next_spawn() -> void:
	timer.start(randf_range(
		min_spawn_time,
		max_spawn_time
	))


func _on_timer_timeout() -> void:
	spawn_vehicle()
	schedule_next_spawn()


func spawn_vehicle() -> void:
	if vehicles.is_empty():
		return

	var selected_scene: PackedScene = vehicles.pick_random()
	var vehicle := selected_scene.instantiate() as Node3D

	if vehicle == null:
		push_warning("Vehicle scene must have a Node3D root.")
		return

	get_tree().current_scene.add_child(vehicle)
	vehicle.global_transform = spawn_point.global_transform
