extends "res://Scripts/Environment/Obstacles/BaseObstacle/base_obstacle.tres.gd"

func _ready() -> void:
	super._ready()
	self.position.y -= get_viewport().get_visible_rect().size.y/2
