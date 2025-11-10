extends CharacterBody2D

const JUMP_VELOCITY = -1200.0

var bullet_scene = preload("res://Scripts/Environment/Objects/MovableObjects/Bullet/bullet.tscn")

@onready var bullet_marker:Marker2D = $AnimatedSprite2D/Hands/BulletMarker
@onready var hands_sprite:Sprite2D = $AnimatedSprite2D/Hands

var move_speed := 770.0

func _physics_process(delta: float) -> void:
	var mouse_pos = get_viewport().get_camera_2d().get_global_mouse_position()
	var dir = (mouse_pos - hands_sprite.global_position).normalized()
	hands_sprite.rotation = dir.angle()
	
	velocity += get_gravity() * delta
	if is_on_floor_only():
		if Input.is_action_pressed("ui_accept"):
			velocity.y = JUMP_VELOCITY
	move_and_slide()

 
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		shoot()

func shoot():
	if bullet_scene == null:
		return

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	bullet.global_position = bullet_marker.global_position

	var mouse_pos = get_viewport().get_camera_2d().get_global_mouse_position()
	var dir = (mouse_pos - hands_sprite.global_position).normalized()
	bullet.direction = dir

	bullet.velocity_offset.x = self.velocity.x
