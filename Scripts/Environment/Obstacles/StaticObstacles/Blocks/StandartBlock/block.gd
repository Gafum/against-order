extends "res://Scripts/Environment/Obstacles/BaseObstacle/base_obstacle.tres.gd"

func _ready() -> void:
	var new_scale: float = randf_range(0.35, 0.6)

	self.scale = Vector2(new_scale, new_scale)
