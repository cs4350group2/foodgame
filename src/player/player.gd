extends CharacterBody2D

@export var speed: float = 200.0
@onready var interaction_area: Area2D = $InteractionArea

func _physics_process(_delta):
	var direction = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	velocity = direction * speed
	move_and_slide()
	
	if Input.is_action_just_pressed("interact"):
		interact()

func interact():
	var closest_target: StaticBody2D = null
	var closest_distance := INF

	for body in interaction_area.get_overlapping_bodies():
		if body is StaticBody2D and body.is_in_group("Interactables"):
			var distance := global_position.distance_squared_to(body.global_position)

			if distance < closest_distance:
				closest_target = body
				closest_distance = distance

	if closest_target == null:
		return

	closest_target.interact(self)
