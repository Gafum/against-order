extends Node2D

const VILLAIN_Y := 648
const MAX_SPEED := 1700

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var game_floor: StaticBody2D = $Floor

const VILLAIN_LIST := [
	preload("res://Scripts/Environment/Obstacles/StaticObstacles/Liquid/toxic_water.tscn"),
	preload("res://Scripts/Environment/Obstacles/Villains/Villain1/villain_1.tscn"),
	preload("res://Scripts/Environment/Obstacles/StaticObstacles/Traps/trap1.tscn"),
	preload("res://Scripts/Environment/Obstacles/StaticObstacles/Blocks/StandartBlock/block.tscn"),
	preload("res://Scripts/Environment/Obstacles/StaticObstacles/FlyingObstacles/Drons/drone.tscn"),
	preload("res://Scripts/Environment/Obstacles/StaticObstacles/Blocks/Barrel/barrel.tscn")
]

var game_over_ui_scene = preload("res://Scripts/Interface/GameOver/game_over_ui.tscn")

var speed := 1300.0
var score: float = 0.0
var is_game_over: bool = false
@onready var score_label = $CanvasLayer/UIMarginContainer/VBoxContainer/Label
@onready var reload_bar: ProgressBar = %ReloadBar

var next_villain_x_position: float = 1500.0

func _ready() -> void:
	Global.is_game_over = false
	next_villain_x_position = player.global_position.x
	player.player_died.connect(_on_player_died)
	player.weapon_reloading.connect(_on_player_weapon_reloading)

func _on_player_weapon_reloading(progress: float):
	reload_bar.value = progress * 100

func _physics_process(delta: float) -> void:
	if is_game_over:
		return
		 
	player.velocity.x = speed * delta * 100
	var player_x = player.global_position.x
	
	# Update Score
	score += speed * delta * 0.01
	score_label.text = "Score: %d" % int(score)
	
	var relative_camera_position = get_viewport().size.x / 10 * 3.2
	camera.global_position.x = player_x + relative_camera_position
	game_floor.global_position.x = player_x + relative_camera_position
	if (speed < MAX_SPEED):
		speed += delta * 7 # Increased acceleration slightly as requested ("just increase speed little by little")
	spawn_villain(player_x)


func spawn_villain(player_x: float):
	# check if it is enogth space
	if (player_x < next_villain_x_position):
		return
		
	# set the next position of the villain
	next_villain_x_position = int(player_x + max(720, speed / 2) + randi_range(0, 200))
	
	var new_villain_object = VILLAIN_LIST[randi_range(0, VILLAIN_LIST.size() - 1)]
	
	if (new_villain_object):
		# creating the new Villain
		var new_villain: CharacterBody2D = new_villain_object.instantiate()
		new_villain.name = "VILLAIN" + str(Time.get_ticks_msec())
		
		# Always spawn at a fixed distance from the player, regardless of screen resolution
		var spawn_x = player_x + 1500 + speed
		
		new_villain.global_position = Vector2(spawn_x, VILLAIN_Y)
		new_villain.scale = Vector2(0.7, 0.7)
		add_child(new_villain)


func _on_player_died():
	is_game_over = true
	Global.is_game_over = true
	
	score_label.visible = false
	reload_bar.visible = false
	
	var game_over_ui = game_over_ui_scene.instantiate()
	$CanvasLayer.add_child(game_over_ui)
	game_over_ui.set_score(int(score))
