extends "res://Scripts/Environment/Obstacles/BaseObstacle/base_obstacle.tres.gd"

@onready var trap_sprite = $AnimatedSprite2D

func _ready() -> void:
	trap_sprite.frame = randi_range(0, 1)
