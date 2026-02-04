extends CharacterBody2D


signal player_died
signal weapon_reloading(progress: float)

@export var reload_time: float = 0.4
var current_reload_time: float = 0.0

# Leg animation variables
@export var pants_color: Color = Color("#373737") # Gray pants
var leg_animation_time: float = 0.0
# Increased speed and angle to match high movement speed (770)
var leg_swing_speed: float = 12.0 # Was 10.0 - faster swing for running
var max_leg_swing_angle: float = deg_to_rad(25) # Was 25 - wider stride for running
var leg_width: float = 40.0
var leg_height: float = 58.0


func _ready() -> void:
	add_to_group("Player")
	default_hand_scale = hands_sprite.scale
	current_reload_time = reload_time # Start with cooldown


const JUMP_VELOCITY = -1200.0

var bullet_scene = preload("res://Scripts/Environment/Objects/MovableObjects/Bullet/bullet.tscn")
var dust_scene = preload("res://Scripts/Effects/Dust/dust.tscn")

@onready var bullet_marker: Marker2D = $AnimatedSprite2D/Hands/BulletMarker
@onready var muzzle_flash: CPUParticles2D = %MuzzleFlash
@onready var hands_sprite: Sprite2D = $AnimatedSprite2D/Hands
@onready var left_schoulder_marker: Marker2D = $AnimatedSprite2D/LeftSchoulderMarker
@onready var left_hand_marker: Marker2D = $AnimatedSprite2D/Hands/LeftHandMarker

var move_speed := 770.0

const MIN_ANGLE = deg_to_rad(-65) # up
const MAX_ANGLE = deg_to_rad(30) # down

var current_shoot_direction: Vector2 = Vector2.RIGHT

var default_hand_scale: Vector2
var was_on_floor: bool = false


func _physics_process(delta: float) -> void:
	_update_hand_rotation(delta)

	if current_reload_time > 0:
		current_reload_time -= delta
		if current_reload_time <= 0:
			current_reload_time = 0
			weapon_reloading.emit(1.0)
		else:
			weapon_reloading.emit(1.0 - (current_reload_time / reload_time))

	# Horizontal movement
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		velocity.x = direction * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed * delta * 5)

	# Update leg animation based on movement
	if abs(velocity.x) > 10:
		# Sync animation speed with movement velocity more directly
		leg_animation_time += delta * leg_swing_speed * (abs(velocity.x) / move_speed)
	else:
		# Reset legs to neutral position smoothly or instantly when stopped
		leg_animation_time = 0

	velocity += get_gravity() * delta
	if is_on_floor_only():
		if Input.is_action_pressed("ui_accept"):
			velocity.y = JUMP_VELOCITY

	move_and_slide()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider().is_in_group("Obstacle"):
			die()

	if not was_on_floor and is_on_floor():
		spawn_dust()

	was_on_floor = is_on_floor()


func _update_hand_rotation(delta: float) -> void:
	var mouse_pos = get_viewport().get_camera_2d().get_global_mouse_position()
	var dir = (mouse_pos - hands_sprite.global_position).normalized()

	var target_angle = dir.angle()
	target_angle = clamp(target_angle, MIN_ANGLE, MAX_ANGLE)

	hands_sprite.rotation = lerp_angle(hands_sprite.rotation, target_angle, delta * 12)
	hands_sprite.scale = hands_sprite.scale.lerp(default_hand_scale, delta * 3)

	current_shoot_direction = Vector2.from_angle(target_angle)

	queue_redraw()


# Shoot
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		shoot()


func shoot():
	if bullet_scene == null or current_reload_time > 0:
		return

	current_reload_time = reload_time
	weapon_reloading.emit(0.0)

	var bullet = bullet_scene.instantiate()

	bullet.direction = current_shoot_direction.normalized()
	bullet.global_position = bullet_marker.global_position + (bullet.direction * 40)

	bullet.velocity_offset.x = self.velocity.x
	bullet.z_index = -1

	hands_sprite.rotation -= 0.2
	hands_sprite.scale.x = 0.87

	get_tree().current_scene.add_child(bullet)

	# Add muzzle flash effect with a tiny delay
	await get_tree().create_timer(0.03).timeout
	if !Global.is_game_over:
		# Dynamically adjust velocity based on player speed to make it "hit hard" but keep it modest
		var speed_boost = abs(velocity.x) * 0.16
		muzzle_flash.initial_velocity_min = 200.0 + speed_boost
		muzzle_flash.initial_velocity_max = 400.0 + speed_boost
		muzzle_flash.restart()


func _draw() -> void:
	# Draw legs (pants)
	# Position legs slightly higher to overlap body (-65 feels better connected than -55)
	var body_bottom_y = -58
	var leg_separation = 48.0 # Distance between legs
	
	# Calculate leg swing angles
	var left_leg_angle = 0.0
	var right_leg_angle = 0.0
	
	if leg_animation_time > 0:
		# Legs swing in opposite directions
		left_leg_angle = sin(leg_animation_time) * max_leg_swing_angle
		right_leg_angle = - sin(leg_animation_time) * max_leg_swing_angle
	
	# Draw right leg - position is at the TOP of the leg (hip attachment point)
	var right_leg_offset = Vector2(leg_separation / 2, body_bottom_y)
	draw_rotated_rect(right_leg_offset, leg_width, leg_height, right_leg_angle, pants_color)

	# Draw left leg - position is at the TOP of the leg (hip attachment point)
	var left_leg_offset = Vector2(-leg_separation / 2, body_bottom_y)
	draw_rotated_rect(left_leg_offset, leg_width, leg_height, left_leg_angle, pants_color)
	
	# Draw arm (existing code)
	if left_schoulder_marker and left_hand_marker:
		var start = to_local(left_schoulder_marker.global_position)
		var end = to_local(left_hand_marker.global_position)
		var color = Color("#533838")
		var width = 20.0
		var radius = width / 2.0

		draw_line(start, end, color, width)
		draw_circle(start, radius, color)
		draw_circle(end, radius, color)


# Helper function to draw rotated rectangle
# Rotates from the top center (hip pivot point)
func draw_rotated_rect(center: Vector2, width: float, height: float, angle: float, color: Color) -> void:
	var half_width = width / 2.0
	
	# Define corners of rectangle with rotation origin at TOP center
	# (0, 0) is at the top center where the hip attaches
	var corners = [
		Vector2(-half_width, 0), # top-left
		Vector2(half_width, 0), # top-right
		Vector2(half_width, height), # bottom-right
		Vector2(-half_width, height) # bottom-left
	]
	
	# Rotate and translate corners
	var transformed_corners = []
	for corner in corners:
		var rotated = corner.rotated(angle)
		transformed_corners.append(center + rotated)
	
	# Draw filled polygon
	draw_colored_polygon(transformed_corners, color)


func spawn_dust():
	if dust_scene:
		var dust = dust_scene.instantiate()
		dust.global_position = global_position + Vector2(0, 100)
		dust.global_position = global_position
		get_parent().add_child(dust)


func die():
	player_died.emit()
	muzzle_flash.emitting = false
	muzzle_flash.visible = false
	set_physics_process(false) # Stop player movement
	set_process_input(false) # Stop shooting
