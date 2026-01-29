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
	
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
	
	# Позиції
	var bomb_start = global_position
	var player_pos = player.global_position
	var player_vel = player.velocity
	
	# Вертикальна відстань (завжди позитивна, бо дрон вище гравця)
	var height = player_pos.y - bomb_start.y
	
	# Якщо гравець вище дрона - просто падаємо вниз
	if height <= 0:
		return Vector2(0, 100)
	
	# Час падіння з формули: h = 0.5 * g * t^2
	# t = sqrt(2 * h / g)
	var fall_time = sqrt(2.0 * height / gravity)
	
	# Де буде гравець через цей час
	var predicted_player_x = player_pos.x + player_vel.x * fall_time
	
	# Горизонтальна відстань яку треба покрити
	var horizontal_distance = predicted_player_x - bomb_start.x
	
	# Горизонтальна швидкість = відстань / час
	var horizontal_velocity = horizontal_distance / fall_time
	
	# Вертикальна швидкість = 0 (бомба просто падає під дією гравітації)
	return Vector2(horizontal_velocity, 0)
