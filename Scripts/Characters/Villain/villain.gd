extends CharacterBody2D


func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()
