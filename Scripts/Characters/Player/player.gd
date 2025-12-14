extends CharacterBody2D


func _ready() -> void:
	add_to_group("Player")
	default_hand_pos = hands_sprite.position


const JUMP_VELOCITY = -1200.0

var bullet_scene = preload("res://Scripts/Environment/Objects/MovableObjects/Bullet/bullet.tscn")

@onready var bullet_marker: Marker2D = $AnimatedSprite2D/Hands/BulletMarker
@onready var hands_sprite: Sprite2D = $AnimatedSprite2D/Hands

var move_speed := 770.0

const MIN_ANGLE = deg_to_rad(-65) # up
const MAX_ANGLE = deg_to_rad(30) # down

var current_shoot_direction: Vector2 = Vector2.RIGHT

var default_hand_pos: Vector2


func _physics_process(delta: float) -> void:
	_update_hand_rotation(delta)

	velocity += get_gravity() * delta
	if is_on_floor_only():
		if Input.is_action_pressed("ui_accept"):
			velocity.y = JUMP_VELOCITY

	move_and_slide()


func _update_hand_rotation(delta: float) -> void:
	var mouse_pos = get_viewport().get_camera_2d().get_global_mouse_position()
	var dir = (mouse_pos - hands_sprite.global_position).normalized()

	var target_angle = dir.angle()
	target_angle = clamp(target_angle, MIN_ANGLE, MAX_ANGLE)

	hands_sprite.rotation = lerp_angle(hands_sprite.rotation, target_angle, delta * 12)
	hands_sprite.position = hands_sprite.position.lerp(default_hand_pos, delta * 5)

	current_shoot_direction = Vector2.from_angle(target_angle)


func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		shoot()


func shoot():
	if bullet_scene == null:
		return

	var bullet = bullet_scene.instantiate()

	bullet.direction = current_shoot_direction.normalized()
	bullet.global_position = bullet_marker.global_position + (bullet.direction * 40)

	bullet.velocity_offset.x = self.velocity.x
	bullet.z_index = -1

	hands_sprite.rotation -= 0.2
	hands_sprite.position -= Vector2.RIGHT.rotated(hands_sprite.rotation) * 10.0

	get_tree().current_scene.add_child(bullet)
