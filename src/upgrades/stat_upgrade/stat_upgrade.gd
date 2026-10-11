class_name StatUpgrade
extends Upgrade

@export var speed_multiplier: float = 1.0
@export var jump_multiplier: float = 1.0
@export var can_freefly: bool = false

func apply_effect(level: Level):
	level.player.base_speed *= speed_multiplier
	level.player.jump_velocity *= jump_multiplier
	level.player.can_freefly = level.player.can_freefly or can_freefly
	if can_freefly:
		level.player.freeflying = true
