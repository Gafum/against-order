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
	
	if not player:
		return
	
	# Instantiate and spawn the box
	var box = BOX_SCENE.instantiate()
	box.global_position = global_position
	
	# Calculate predictive aim to hit moving player
	var initial_velocity = calculate_predictive_velocity()
	box.linear_velocity = initial_velocity
	
	get_tree().current_scene.add_child(box)


# Calculate the velocity needed for the bomb to hit the moving player
func calculate_predictive_velocity() -> Vector2:
	if not player:
		return Vector2.DOWN * 500
	
	# Get current positions and velocities
	var drone_pos = global_position
	var player_pos = player.global_position
	var player_vel = player.velocity if player.velocity else Vector2.ZERO
	
	# Bomb speed (horizontal component)
	var bomb_speed = 600.0
	
	# Relative position and velocity
	var rel_pos = player_pos - drone_pos
	var rel_vel = player_vel
	
	# Solve for intercept time using quadratic equation
	# We need to find t such that: |rel_pos + rel_vel * t| = bomb_speed * t
	# This expands to: a*t^2 + b*t + c = 0
	var a = rel_vel.dot(rel_vel) - bomb_speed * bomb_speed
	var b = 2 * rel_pos.dot(rel_vel)
	var c = rel_pos.dot(rel_pos)
	
	var intercept_time = 0.0
	
	# Solve quadratic equation
	var discriminant = b * b - 4 * a * c
	
	if abs(a) < 0.001:
		# Linear case: player speed ≈ bomb speed
		if abs(b) > 0.001:
			intercept_time = -c / b
		else:
			intercept_time = 1.0
	elif discriminant >= 0:
		# Two solutions, pick the positive one (future intercept)
		var sqrt_discriminant = sqrt(discriminant)
		var t1 = (-b + sqrt_discriminant) / (2 * a)
		var t2 = (-b - sqrt_discriminant) / (2 * a)
		
		# Choose the smallest positive time
		if t1 > 0 and t2 > 0:
			intercept_time = min(t1, t2)
		elif t1 > 0:
			intercept_time = t1
		elif t2 > 0:
			intercept_time = t2
		else:
			intercept_time = 1.0
	else:
		# No solution - player too fast, aim at current predicted position
		intercept_time = 1.0
	
	# Clamp intercept time to reasonable values
	intercept_time = clamp(intercept_time, 0.1, 3.0)
	
	# Calculate predicted player position
	var predicted_pos = player_pos + player_vel * intercept_time
	
	# Account for gravity during flight
	# y = y0 + vy*t + 0.5*g*t^2
	# We need: predicted_pos.y = drone_pos.y + vy*t + 0.5*g*t^2
	# So: vy = (predicted_pos.y - drone_pos.y) / t - 0.5*g*t
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
	
	var direction = predicted_pos - drone_pos
	var velocity_horizontal = direction.x / intercept_time
	var velocity_vertical = direction.y / intercept_time - 0.5 * gravity * intercept_time
	
	return Vector2(velocity_horizontal, velocity_vertical)
