extends Node2D

const VILLAIN_Y := 648
const MIN_SPEED := 760

@onready var player:CharacterBody2D = $Player

#Villain List
const VILLAIN_LIST := [
	preload("res://Scripts/Characters/Villain/villain.tscn"),
]

var speed := 1000.0

var next_villain_x_position: float = 1500.0

func _ready() -> void:
	next_villain_x_position = player.global_position.x

func _process(_delta: float) -> void:
	if(speed>MIN_SPEED):
		speed -= _delta * 3
		print(speed)  
	player.velocity.x = 1570 - speed
	spawn_villain()

func spawn_villain():
	var player_x = player.global_position.x
	if(player_x<next_villain_x_position):
		return

	next_villain_x_position = player_x + speed + randf_range(-15, 340)
	if(VILLAIN_LIST[0]):
		var new_villain:CharacterBody2D = VILLAIN_LIST[0].instantiate()
		new_villain.name = "VILLAIN"+ str(Time.get_ticks_msec())
		new_villain.global_position = Vector2(
			int(get_viewport().get_visible_rect().size.x+player_x+speed),
			VILLAIN_Y
		)
		print(new_villain.global_position)  
		new_villain.scale = Vector2(0.5, 0.5)
		add_child(new_villain)
