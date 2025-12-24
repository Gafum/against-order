extends "res://Scripts/Environment/Obstacles/BaseObstacle/base_obstacle.tres.gd"

const BOX_SCENE = preload("res://Scripts/Environment/Objects/MovableObjects/Box/box.tscn")

@export var speed: float = 200.0

var player: Node2D = null
# can bomb be droped
var can_drop: bool = true

func _ready() -> void:
	super._ready()
	# Set starting position
	self.position.y -= get_viewport().get_visible_rect().size.y / 2
	
	# Find player
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]

func _process(_delta: float) -> void:
	# Visual pulsing effect: Cycle between White and Reddish
	var t = Time.get_ticks_msec() * 0.005
	var color_val = (sin(t) + 1.0) * 0.5 # 0 to 1
	$Drone1.modulate = Color(1.0, 0.7 + 0.25 * color_val, 0.7 + 0.25 * color_val)

func _physics_process(_delta: float) -> void:
	if player and can_drop:
		var dist_x = global_position.x - player.global_position.x
		
		if dist_x > 140 and dist_x < 220:
			drop_box()

func drop_box() -> void:
	can_drop = false
	
	# Instantiate and spawn the box
	var box = BOX_SCENE.instantiate()
	box.global_position = global_position
	box.linear_velocity = Vector2(0, 500) # Add initial downward velocity
	get_tree().current_scene.add_child(box)
