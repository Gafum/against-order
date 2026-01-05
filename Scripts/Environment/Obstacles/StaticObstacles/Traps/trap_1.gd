extends "res://Scripts/Environment/Obstacles/BaseObstacle/base_obstacle.tres.gd"

@onready var trap_sprite = $AnimatedSprite2D

func _ready() -> void:
	super._ready()
	trap_sprite.frame = randi_range(0, trap_sprite.get_sprite_frames().get_frame_count("default")-1)
