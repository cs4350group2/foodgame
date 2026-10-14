extends Node3D

@onready var animation_player: AnimationPlayer = $Sprite3D/AnimationPlayer

func _ready() -> void:
	animation_player.animation_finished.connect(_on_animation_player_animation_finished)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"float_up":
		queue_free()

func play_float() -> void:
	animation_player.play("float_up")
