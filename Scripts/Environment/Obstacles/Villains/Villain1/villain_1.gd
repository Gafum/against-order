extends "res://Scripts/Environment/Obstacles/BaseObstacle/base_obstacle.tres.gd"

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("click"):
		queue_free()
