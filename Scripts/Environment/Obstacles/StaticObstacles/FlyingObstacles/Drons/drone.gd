extends "res://Scripts/Environment/Obstacles/BaseObstacle/base_obstacle.tres.gd"

const BOX_SCENE = preload("res://Scripts/Environment/Objects/MovableObjects/Box/box.tscn")

@export var speed: float = 200.0
@export var drop_cooldown: float = 2.0

var player: Node2D = null
var can_drop: bool = true

func _ready() -> void:
	super._ready()
	# Adjust starting position
	var viewport_size = get_viewport_rect().size
	self.position.y = viewport_size.y * 0.4 # Lower height (was 0.2)
	
	# Find player
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float) -> void:
	# Move left
	velocity.x = -speed
	move_and_slide()
	
	if player and can_drop:
		# Predictive aiming: Look ahead of the player based on their velocity
		# Assuming player moves right, we want to drop when we are slightly ahead of them
		# or just drop when we are closer to their future position.
		# Simple approach: Drop when x distance is small, but account for player moving away.
		# Since player runs right and drone flies left (usually), they approach each other.
		# If we drop exactly when above, the box falls behind if player keeps moving.
		# So we should drop when the drone is slightly AHEAD (to the right) of the player.
		
		# Calculate horizontal distance
		var dist_x = global_position.x - player.global_position.x
		
		# If drone is to the right of player (positive dist_x) and within range
		# We drop "early" so the box falls into the player's path.
		# User reported 150 was too early (too far ahead). Reducing to 40.
		if dist_x > 0 and dist_x < 40: 
			drop_box()

func drop_box() -> void:
	can_drop = false
	
	# Visual feedback (smoother scale punch)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1) # Reduced from 1.2
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	
	var box = BOX_SCENE.instantiate()
	box.global_position = global_position
	get_tree().current_scene.add_child(box)
	
	await get_tree().create_timer(drop_cooldown).timeout
	can_drop = true
