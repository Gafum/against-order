extends "res://Scripts/Environment/Obstacles/StaticObstacles/Blocks/StandartBlock/block.gd"

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	super._ready()
	name = "Barrel" + str(Time.get_ticks_msec())
	
	var animation_names := animated_sprite_2d.sprite_frames.get_animation_names()
	
	if (!len(animation_names)):
		return
	
	var random_ani_name = animation_names[randi() % animation_names.size()]
	if(random_ani_name == "box" || random_ani_name == "barrel"):
		random_ani_name = "barrel"
	else:
		self.scale = Vector2(0.5, 0.5)
		
	animated_sprite_2d.play(random_ani_name)
