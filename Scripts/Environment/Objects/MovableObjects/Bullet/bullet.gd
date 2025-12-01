extends Area2D

@export var speed: float = 1200.0
@export var velocity_offset: Vector2 = Vector2.ZERO

var direction: Vector2 = Vector2.ZERO   
var is_active: bool = true

var explosion_scene := preload("res://Scripts/Effects/Explosion/explosion.tscn")

func _ready() -> void:
	rotation = direction.angle()
	name = "Bullet" + str(Time.get_ticks_msec()) 

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	var velocity = direction * speed + velocity_offset
	position += velocity * delta
	rotation = direction.angle()


func _on_body_entered(body: Node2D) -> void:
	if not is_active:
		return

	is_active = false

	_spawn_explosion()

	if body.is_in_group("destroyable"):
		if body.has_method("take_damage"):
			body.take_damage()

	queue_free()


func _spawn_explosion() -> void:
	if explosion_scene == null:
		return

	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)


func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	if is_active:
		queue_free()
