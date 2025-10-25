extends "res://Scripts/Environment/MainParallaxBackgroung/main_parallax_background.gd"

var speed = 100

func _process(delta):
	scroll_offset.x -= speed * delta
