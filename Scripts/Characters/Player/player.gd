extends CharacterBody2D

const JUMP_VELOCITY = -1200.0

func _physics_process(delta: float) -> void:
	velocity += get_gravity() * delta
	if is_on_floor_only():
		if Input.is_action_pressed("ui_accept"):
			velocity.y = JUMP_VELOCITY
	move_and_slide()
