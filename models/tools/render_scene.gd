extends Node3D

func _ready() -> void:
	print("Starting render...")

	get_viewport().transparent_bg = true

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var image = get_viewport().get_texture().get_image()

	var error = image.save_png("res://rendered_meat.png")

	if error == OK:
		print("Image saved!")
	else:
		print("Failed to save image: ", error)

	get_tree().quit()
