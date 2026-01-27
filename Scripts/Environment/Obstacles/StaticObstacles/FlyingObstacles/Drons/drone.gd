extends "res://Scripts/Environment/Obstacles/BaseObstacle/base_obstacle.tres.gd"

const BOX_SCENE = preload("res://Scripts/Environment/Objects/MovableObjects/Box/box.tscn")

@export var speed: float = 200.0

@onready var DroneAnimation = $AnimatedSprite2D

var player: Node2D = null
# can bomb be droped
var can_drop: bool = true

func _ready() -> void:
	super._ready()
	# Set starting random position
	var random_y = randf_range(175.0,
		self.position.y - get_viewport().get_visible_rect().size.y / 2 + 75
	)
	self.global_position.y = random_y
	
	# Find player
	DroneAnimation.play("default")
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]

var time_alive: float = 4.71

func _process(delta: float) -> void:
	if Global.is_game_over:
		DroneAnimation.stop()
		return
		
	time_alive += delta

	var color_val = (sin(time_alive * 5.0) + 1.0) * 0.5
	DroneAnimation.modulate = Color(1.0, 0.7 + 0.25 * color_val, 0.7 + 0.25 * color_val)

func _physics_process(_delta: float) -> void:
	if Global.is_game_over:
		return
		
	if player and can_drop:
		var dist_x = global_position.x - player.global_position.x
		
		# Allow drop at slightly larger range since we aim now
		if dist_x > 140 and dist_x < 400:
			drop_box()

func drop_box() -> void:
	can_drop = false
	
	# Instantiate and spawn the box
	var box = BOX_SCENE.instantiate()
	box.global_position = global_position
	
	# Aim at player with EXACT intercept math
	var projectile_speed := 1000.0
	
	var p_pos = player.global_position
	var p_vel = player.velocity
	var d_pos = global_position
	
	# Relative position
	var dp = p_pos - d_pos

	var a = p_vel.length_squared() - projectile_speed * projectile_speed
	
	# b = 2 * (dp . p_vel)
	var b = 2 * dp.dot(p_vel)
	
	# c = |dp|^2
	var c = dp.length_squared()
	
	# Solve quadratic
	var t = 0.0
	var discriminant = b * b - 4 * a * c
	
	if discriminant >= 0:
		var sqrt_d = sqrt(discriminant)
		var t1 = (-b - sqrt_d) / (2 * a)
		var t2 = (-b + sqrt_d) / (2 * a)
		
		# We want the smallest positive time
		if t1 > 0 and t2 > 0:
			t = min(t1, t2)
		elif t1 > 0:
			t = t1
		elif t2 > 0:
			t = t2
			
	# Fallback if no solution or t is 0 (should rarely happen if speed is enough)
	if t <= 0:
		t = 0.5 # Default small guess
		
	var predicted_pos = p_pos + p_vel * t
	var direction = (predicted_pos - d_pos).normalized()
	
	box.linear_velocity = direction * projectile_speed
	get_tree().current_scene.add_child(box)
