extends Area2D

@export var speed: float = 1200.0
@export var lifetime: float = 1.8
@export var velocity_offset: Vector2 = Vector2.ZERO

var direction: Vector2 = Vector2.ZERO
var is_active: bool = true

func _ready() -> void:
	await get_tree().create_timer(lifetime).timeout
	if is_active:
		queue_free()

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

	if body.is_in_group("destroyable"):
		if body.has_method("take_damage"):
			body.take_damage()

	queue_free()
