extends CharacterBody2D


@export var is_destroyable: bool = false

func _ready() -> void:
	add_to_group("Obstacle")
	if (is_destroyable):
		add_to_group("destroyable")

func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()

func take_damage() -> void:
	queue_free()
