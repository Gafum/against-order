extends CharacterBody2D


func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("click"):
		queue_free()
