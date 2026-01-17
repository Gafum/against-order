extends "res://Scripts/Environment/Obstacles/BaseObstacle/base_obstacle.tres.gd"

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	super._ready()
	
	name = "Villain" + str(Time.get_ticks_msec())
	var animation_names := animated_sprite_2d.sprite_frames.get_animation_names()
	
	if (!len(animation_names)):
		return
	
	var random_ani_name = animation_names[randi() % animation_names.size()]
	animated_sprite_2d.play(random_ani_name)
