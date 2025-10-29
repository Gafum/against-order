extends CharacterBody2D

const JUMP_VELOCITY = -1600.0

func _physics_process(delta: float) -> void:
	velocity += get_gravity() * delta
	if is_on_floor():
		if Input.is_action_pressed("ui_accept"):
			velocity.y = JUMP_VELOCITY
	move_and_slide()
