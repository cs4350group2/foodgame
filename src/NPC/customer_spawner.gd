class_name CustomerSpawner
extends Node3D

@export var customer_scenes: Array[PackedScene]
@onready var spawn_point: Marker3D = $SpawnPoint
@onready var exit_point: Marker3D = $Exit

# Preload all available customer scenes
var vip_customer_scene: PackedScene = preload("res://src/NPC/customer/vip_customer.tscn")
var impatient_customer_scene: PackedScene = preload("res://src/NPC/customer/impatient_customer.tscn")
var food_critic_customer_scene: PackedScene = preload("res://src/NPC/customer/food_critic_customer.tscn")

var available_names: Array[String] = []
var used_names: Dictionary = {}
var to_spawn: Array[StringName]
var customer_scene: PackedScene

func _ready() -> void:
	load_names()
	to_spawn = []
	RestaurantManager.customer_removed.connect(_on_customer_removed)

func _on_customer_removed() -> void:
	# check if seat is avail
	if len(to_spawn) > 0 and RestaurantManager.has_vacant_sittingNode():
		spawn_customer(to_spawn[0])
		to_spawn.pop_front()

func _on_spawn_timer_timeout(customer_type: StringName) -> void:
	if RestaurantManager.has_vacant_sittingNode():
		spawn_customer(customer_type)
	else:
		print("No vacant seats; not spawning a customer.")
		to_spawn.append(customer_type)

func load_names() -> void:
	var file := FileAccess.open("res://data/customer_names.txt", FileAccess.READ)
	if file == null:
		push_error("Could not open customer_names.txt")
		return

	for line in file.get_as_text().split("\n"):
		var customer_name := line.strip_edges()
		if not customer_name.is_empty() and not available_names.has(customer_name):
			available_names.append(customer_name)

func choose_random_customer_scene() -> void:
	if customer_scenes.is_empty():
		return

	customer_scene = customer_scenes.pick_random()

func spawn_customer(customer_type: StringName = &"") -> void:
	if available_names.is_empty():
		print("No unused customer names remain.")
		return
		
	var rng := RunManager.get_rng()
	var customer_name: String = available_names[rng.randi_range(0, available_names.size() - 1)]
	available_names.erase(customer_name) # Prevents duplicate names.
	
	# var customer_level := randi_range(1, 3)
	var customer_level := 1
	var patience := rng.randf_range(50.0, 70.0)
	
	# Set up customer scene
	var customer: Customer
	match customer_type:
		&"":
			choose_random_customer_scene()
			customer = customer_scene.instantiate()
			customer.initialize_customer(customer_name, customer_level, patience, customer_type)
		&"VIP":
			customer_scene = vip_customer_scene
			customer = customer_scene.instantiate()
			var vip := customer as VIP_Customer
			if vip != null:
				var requirement: float = 50.0
				vip.initialize_vip_customer(customer_name, 
				customer_level, patience, customer_type, requirement)
			customer = vip
		&"Impatient":
			customer_scene = impatient_customer_scene
			customer = customer_scene.instantiate()
			customer.initialize_customer(customer_name, customer_level, patience / 2, customer_type)
		&"FoodCritic":
			customer_scene = food_critic_customer_scene
			customer = customer_scene.instantiate()
			print(customer)
			var food_critic := customer as FoodCritic
			if food_critic != null:
				food_critic.initialize_food_critic(customer_name, customer_level, patience, customer_type)
			customer = food_critic
		_:
			print(customer_type)
			choose_random_customer_scene()
			customer = customer_scene.instantiate()
			customer.initialize_customer(customer_name, customer_level, patience, customer_type)
		
	set_customer_exit_point(customer)
	set_customer_spawn_position(customer)
	add_child(customer)
	print("Spawned ", customer.get_customer_name(), 
	" Level: ", customer.get_customer_lvl(), 
	" Type: ", customer.get_customer_type())

func set_customer_spawn_position(customer: Customer) -> void:
	customer.global_position = spawn_point.global_position

func set_customer_exit_point(customer: Customer) -> void:
	customer.exit_point = exit_point

func release_name(name: String) -> void:
	if !available_names.has(name):
		available_names.append(name)
