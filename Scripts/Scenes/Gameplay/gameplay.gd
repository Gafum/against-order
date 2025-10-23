extends Node2D

const VILLAIN_Y := 648
const VILLAIN_ADD_X := 40

#Villain List
var villains := [
	preload("res://Scripts/Characters/Villain/villain.tscn"),
]

var next_villain_x_position: float = 200.0


func _process(_delta: float) -> void:
	if($Player.global_position.x>next_villain_x_position):
		spawn_villain()


func spawn_villain():
	var display_width:float = get_viewport().size.x
	var next_villain_position:float = display_width+VILLAIN_ADD_X
	next_villain_x_position += next_villain_position/3*2

	if(villains[0]):
		var new_villain:CharacterBody2D = villains[0].instantiate()
		new_villain.name = "VILLAIN"+ str(Time.get_ticks_msec())
		new_villain.global_position = Vector2($Player.global_position.x+next_villain_position, VILLAIN_Y)
		new_villain.scale = Vector2(0.5, 0.5)
		add_child(new_villain)
