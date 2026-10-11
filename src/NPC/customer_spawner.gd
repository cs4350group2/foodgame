class_name CustomerSpawner
extends Node3D

@export var customer_scene: PackedScene
@onready var spawn_point: Marker3D = $SpawnPoint
@onready var exit_point: Marker3D = $Exit

var available_names: Array[String] = []
var used_names: Dictionary = {}
var to_spawn: int = 0


func _ready() -> void:
	load_names()
	to_spawn = 0
	RestaurantManager.customer_removed.connect(_on_customer_removed)

func _on_customer_removed() -> void:
	# check if seat is avail
	if to_spawn > 0 and RestaurantManager.has_vacant_sittingNode():
		spawn_customer()
		to_spawn -= 1

func _on_spawn_timer_timeout() -> void:
	if RestaurantManager.has_vacant_sittingNode():
		spawn_customer()
	else:
		print("No vacant seats; not spawning a customer.")
		to_spawn += 1

func load_names() -> void:
	var file := FileAccess.open("res://data/customer_names.txt", FileAccess.READ)
	if file == null:
		push_error("Could not open customer_names.txt")
		return

	for line in file.get_as_text().split("\n"):
		var customer_name := line.strip_edges()
		if not customer_name.is_empty() and not available_names.has(customer_name):
			available_names.append(customer_name)

func spawn_customer() -> void:
	if available_names.is_empty():
		print("No unused customer names remain.")
		return
		
	var customer_name: String = available_names.pick_random()
	available_names.erase(customer_name) # Prevents duplicate names.
	
	# var customer_level := randi_range(1, 3)
	var customer_level := 1
	var patience := randf_range(30.0, 50.0)
	
	var customer: Customer = customer_scene.instantiate()
	customer.initialize_customer(customer_name, customer_level, patience)
	customer.exit_point = exit_point
	customer.global_position = spawn_point.global_position
	add_child(customer)
	print("Spawned ", customer.customer_name, " Level: ", customer.customer_lvl)

func release_name(name: String) -> void:
	if !available_names.has(name):
		available_names.append(name)
