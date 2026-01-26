extends CharacterBody2D


signal player_died
signal weapon_reloading(progress: float)

@export var reload_time: float = 0.4
var current_reload_time: float = 0.0


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
	if left_schoulder_marker and left_hand_marker:
		var start = to_local(left_schoulder_marker.global_position)
		var end = to_local(left_hand_marker.global_position)
		var color = Color("#533838")
		var width = 20.0
		var radius = width / 2.0

		draw_line(start, end, color, width)
		draw_circle(start, radius, color)
		draw_circle(end, radius, color)


func spawn_dust():
	if dust_scene:
		var dust = dust_scene.instantiate()
		dust.global_position = global_position + Vector2(0, 100) # Assuming pivot is center and feet are lower
		# Use collision shape offset to guess feet? Or just global_position if pivot is feet?
		# Player CollisionShape pos is (0, -113.5) with size.y 225. Pivot seems to be feet?
		# Looking at `CollisionShape2D` pos `(0, -113.5)` in `player.tscn`.
		# If user pivots are standard, position (0,0) is usually feet.
		# Let's inspect tscn again or assume 0,0 is feet.
		# In tscn earlier: CollisionShape2D pos is -113.5, size is 225. 225/2 = ~112.5. So 0 is indeed bottom/feet.
		dust.global_position = global_position
		get_parent().add_child(dust)


func die():
	player_died.emit()
	muzzle_flash.emitting = false
	muzzle_flash.visible = false
	set_physics_process(false) # Stop player movement
	set_process_input(false) # Stop shooting
