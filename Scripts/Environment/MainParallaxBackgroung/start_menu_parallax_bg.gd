extends "res://Scripts/Environment/MainParallaxBackgroung/main_parallax_background.gd"

var speed = 100

func _physics_process(delta: float) -> void:
	scroll_offset.x -= speed * delta
