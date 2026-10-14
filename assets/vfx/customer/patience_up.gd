extends Node3D

@export var icon_scene: PackedScene
@export var icon_count := 1
@export var spread := 2.0

func _ready() -> void:
	for i in icon_count:
		var icon := icon_scene.instantiate() as Node3D
		add_child(icon)

		icon.position = Vector3(
			randf_range(-spread, spread),
			randf_range(-0.5, 0.5),
			0.0
		)

		# Stagger their starts so they don't all rise together.
		await get_tree().create_timer(randf_range(0.0, 0.25)).timeout
		icon.play_float()
