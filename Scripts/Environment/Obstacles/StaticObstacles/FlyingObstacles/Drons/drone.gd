extends "res://Scripts/Environment/Obstacles/BaseObstacle/base_obstacle.tres.gd"

func _ready() -> void:
	self.position.y -= get_viewport().get_visible_rect().size.y/2

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("click"):
		queue_free()
