extends Node2D

const VILLAIN_Y := 648
const MIN_SPEED := 760

@onready var player:CharacterBody2D = $Player
@onready var camera:Camera2D = $Camera2D
@onready var game_floor:StaticBody2D = $Floor

const VILLAIN_LIST := [
	preload("res://Scripts/Environment/Obstacles/StaticObstacles/Liquid/toxic_water.tscn"),
	preload("res://Scripts/Environment/Obstacles/Villains/Villain1/villain_1.tscn"),
	preload("res://Scripts/Environment/Obstacles/StaticObstacles/Traps/trap1.tscn"),
	preload("res://Scripts/Environment/Obstacles/StaticObstacles/FlyingObstacles/Drons/drone.tscn"),
]

var speed := 1000.0

var next_villain_x_position: float = 1500.0

func _ready() -> void:
	next_villain_x_position = player.global_position.x

func _physics_process(delta: float) -> void:
	var player_x = player.global_position.x
	var relative_camera_position = get_viewport().size.x/10*3.2
	camera.global_position.x = player_x + relative_camera_position
	game_floor.global_position.x = player_x + relative_camera_position
	if(speed>MIN_SPEED):
		speed -= delta * 3
	player.position.x += (1570 - speed)/100
	spawn_villain(player_x)

func spawn_villain(player_x: float):
	# check if it is enogth space
	if(player_x<next_villain_x_position):
		return
		
	# set the next position of the villain
	next_villain_x_position = int(player_x + speed + randi_range(-15, 340))
	
	var new_villain_object = VILLAIN_LIST[randi_range(0, VILLAIN_LIST.size()-1)]
	
	if(new_villain_object):
		# creating the new Villain
		var new_villain:CharacterBody2D = new_villain_object.instantiate()
		new_villain.name = "VILLAIN"+ str(Time.get_ticks_msec())
		new_villain.global_position = Vector2(
			int(get_viewport().get_visible_rect().size.x+player_x+speed),
			VILLAIN_Y
		)
		new_villain.scale = Vector2(0.7, 0.7)
		add_child(new_villain)
